
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const resendKey = Deno.env.get("RESEND_API_KEY");
    const emailFrom = Deno.env.get("EMAIL_FROM");
    const appUrl = Deno.env.get("APP_URL");

    if (!resendKey || !emailFrom || !appUrl) {
      return json({ error: "Configuration e-mail incomplète." }, 500);
    }

    const authorization = req.headers.get("Authorization");

    if (!authorization) {
      return json({ error: "Authentification requise." }, 401);
    }

    // Vérifie l'identité de l'utilisateur connecté.
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return json({ error: "Session invalide." }, 401);
    }

    const body = await req.json();
    const businessId = String(body.business_id ?? "");
    const email = String(body.email ?? "").trim().toLowerCase();
    const token = String(body.token ?? "");

    if (!businessId || !email || !token) {
      return json({ error: "Paramètres d'invitation manquants." }, 400);
    }

    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Seul le propriétaire de cette entreprise peut envoyer l'invitation.
    const { data: membership, error: membershipError } = await admin
      .from("business_members")
      .select("role")
      .eq("business_id", businessId)
      .eq("user_id", user.id)
      .maybeSingle();

    if (
      membershipError ||
      !membership ||
      membership.role !== "owner"
    ) {
      return json({ error: "Action réservée au propriétaire." }, 403);
    }

    // Vérifie que le token correspond bien à une invitation en attente.
    const { data: invitation, error: invitationError } = await admin
      .from("invitations")
      .select("email, role, token, expires_at, status")
      .eq("business_id", businessId)
      .eq("email", email)
      .eq("token", token)
      .eq("status", "pending")
      .maybeSingle();

    if (invitationError || !invitation) {
      return json({ error: "Invitation introuvable ou invalide." }, 404);
    }

    if (new Date(invitation.expires_at).getTime() <= Date.now()) {
      return json({ error: "Cette invitation a expiré." }, 400);
    }

    const { data: business, error: businessError } = await admin
      .from("businesses")
      .select("name")
      .eq("id", businessId)
      .maybeSingle();

    if (businessError || !business) {
      return json({ error: "Entreprise introuvable." }, 404);
    }

    const invitationUrl = new URL(appUrl);
    invitationUrl.searchParams.set("invite", token);

    const safe = (value: string) =>
      value.replace(/[&<>"']/g, (char) => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;",
      })[char]!);

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: emailFrom,
        to: [email],
        subject: `Invitation à rejoindre ${business.name} sur StockMind`,
        html: `
          <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;color:#14264B">
            <h1>Vous êtes invité(e) sur StockMind !</h1>
            <p>Bonjour,</p>
            <p>
              Vous avez été invité(e) à rejoindre
              <strong>${safe(business.name)}</strong>
              en tant que <strong>${safe(String(invitation.role))}</strong>.
            </p>
            <p>
              Cliquez sur le bouton ci-dessous pour accéder à votre invitation.
            </p>
            <p style="margin:28px 0">
              <a href="${safe(invitationUrl.toString())}"
                 style="background:#F21D3D;color:white;padding:14px 22px;
                        border-radius:8px;text-decoration:none;font-weight:bold">
                Accepter l'invitation
              </a>
            </p>
            <p>Ce lien expire le ${new Date(invitation.expires_at).toLocaleDateString("fr-FR")}.</p>
            <p>Si vous ne vous attendiez pas à cette invitation, ignorez cet e-mail.</p>
            <p>L'équipe StockMind</p>
          </div>
        `,
      }),
    });

    if (!response.ok) {
      const details = await response.text();
      console.error("Erreur Resend:", response.status, details);
      return json({ error: "Le fournisseur e-mail a refusé l'envoi." }, 502);
    }

    return json({ success: true, email });
  } catch (error) {
    console.error("Erreur send-business-invitation:", error);
    return json({ error: "Erreur lors de l'envoi de l'invitation." }, 500);
  }
});

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _muted = Color(0xFF7B8498);
const Color _background = Color(0xFFF7F8FC);

class AcceptInvitationPage extends StatefulWidget {
  final String token;

  const AcceptInvitationPage({super.key, required this.token});

  @override
  State<AcceptInvitationPage> createState() => _AcceptInvitationPageState();
}

class _AcceptInvitationPageState extends State<AcceptInvitationPage> {
  bool _loading = true;
  bool _accepted = false;
  String? _error;
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _acceptInvitation();
  }

  Future<void> _acceptInvitation() async {
    final supabase = Supabase.instance.client;

    if (supabase.auth.currentUser == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Connectez-vous au compte associé à l’adresse e-mail invitée, puis ouvrez à nouveau ce lien.';
      });
      return;
    }

    try {
      final result = await supabase.rpc(
        'accept_business_invitation',
        params: {'p_token': widget.token},
      );

      if (!mounted) return;

      setState(() {
        _businessId = result.toString();
        _accepted = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('email') || message.contains('invitation')) {
      return 'Cette invitation est invalide, expirée ou associée à une autre adresse e-mail.';
    }

    if (message.contains('expired')) {
      return 'Cette invitation a expiré. Demandez au propriétaire de l’entreprise d’en créer une nouvelle.';
    }

    return 'Impossible d’accepter cette invitation. Vérifiez votre connexion et réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE9ECF3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9ED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _accepted
                        ? Icons.check_circle_outline_rounded
                        : Icons.mail_outline_rounded,
                    color: _red,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Invitation StockMind',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: _red),
                      SizedBox(height: 18),
                      Text(
                        'Vérification de votre invitation...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted),
                      ),
                    ],
                  )
                else if (_accepted)
                  Column(
                    children: [
                      const Text(
                        'Vous avez rejoint l’entreprise avec succès !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Votre adhésion est enregistrée. Vous pouvez maintenant retourner à StockMind et ouvrir cette entreprise depuis votre espace.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Retourner à StockMind'),
                      ),
                      if (_businessId != null) ...[
                        const SizedBox(height: 10),
                        SelectableText(
                          'Entreprise : $_businessId',
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        _error ?? 'Une erreur est survenue.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _acceptInvitation,
                        style: FilledButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Réessayer'),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Si vous n’êtes pas connecté, connectez-vous d’abord avec le compte invité, puis rouvrez le lien.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

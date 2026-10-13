import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

import '../../onboarding/pages/company_onboarding_page.dart';

enum AuthMode { login, signUp }

/// Ouvre la page d'authentification depuis n'importe quel écran.
Future<void> openAuthPage(BuildContext context, AuthMode mode) async {
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => AuthPage(initialMode: mode)));
}

class AuthPage extends StatefulWidget {
  final AuthMode initialMode;

  const AuthPage({super.key, this.initialMode = AuthMode.login});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AuthMode _mode;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  bool get _isLogin => _mode == AuthMode.login;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _formKey.currentState?.reset();
      _nameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _acceptTerms = false;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin && !_acceptTerms) {
      _showMessage('Veuillez accepter les conditions pour continuer.');
      return;
    }

    if (_isLogin) {
      _showMessage('La connexion Supabase sera intégrée à la prochaine étape.');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const CompanyOnboardingPage()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 850;

            return Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: mobile ? 18 : 40,
                      vertical: mobile ? 22 : 35,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1050),
                        child: mobile
                            ? _buildMobileLayout()
                            : _buildDesktopLayout(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // TOP BAR
  // ----------------------------------------------------------

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy),
          ),
          const SizedBox(width: 8),
          const _AuthLogo(),
          const Spacer(),
          Text(
            _isLogin ? 'Nouveau sur StockMind ?' : 'Déjà un compte ?',
            style: GoogleFonts.poppins(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: () =>
                _switchMode(_isLogin ? AuthMode.signUp : AuthMode.login),
            child: Text(
              _isLogin ? 'Créer un compte' : 'Se connecter',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // RESPONSIVE LAYOUTS
  // ----------------------------------------------------------

  Widget _buildDesktopLayout() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 650),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: _buildWelcomePanel()),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 42,
                  vertical: 38,
                ),
                child: _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileWelcome(),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: _buildForm(),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // WELCOME PANEL
  // ----------------------------------------------------------

  Widget _buildWelcomePanel() {
    return Container(
      padding: const EdgeInsets.all(38),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF14264B), Color(0xFF243D70), Color(0xFF364C78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeIcon(),
          const SizedBox(height: 35),
          _welcomeTitle(),
          const SizedBox(height: 16),
          Text(
            _isLogin
                ? 'Retrouvez vos produits, vos commandes et vos indicateurs '
                      'depuis un espace unique.'
                : 'Créez votre espace de travail et commencez à organiser '
                      'votre stock plus simplement.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              height: 1.9,
            ),
          ),
          const SizedBox(height: 30),
          _welcomeBenefit(
            Icons.inventory_2_outlined,
            'Centralisez vos produits',
          ),
          _welcomeBenefit(Icons.query_stats_rounded, 'Suivez vos performances'),
          _welcomeBenefit(
            Icons.auto_awesome_rounded,
            'Préparez-vous à l’assistance IA',
          ),
          const Spacer(),
          const _MiniDashboard(),
        ],
      ),
    );
  }

  Widget _buildMobileWelcome() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF354D7B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeIcon(),
          const SizedBox(height: 20),
          _welcomeTitle(),
          const SizedBox(height: 10),
          Text(
            _isLogin
                ? 'Connectez-vous pour retrouver votre espace de travail.'
                : 'Configurez votre espace professionnel avec StockMind.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeIcon() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _welcomeTitle() {
    return Text(
      _isLogin
          ? 'Bon retour sur StockMind !'
          : 'Construisons la suite ensemble.',
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
    );
  }

  Widget _welcomeBenefit(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // AUTH FORM
  // ----------------------------------------------------------

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isLogin ? 'Connexion' : 'Créer un compte',
            style: GoogleFonts.poppins(
              color: AppColors.navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin
                ? 'Saisissez vos identifiants pour continuer.'
                : 'Quelques informations pour commencer.',
            style: GoogleFonts.poppins(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 27),

          if (!_isLogin) ...[
            _buildLabel('Nom complet'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'Ex. : Marie Dupont',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Veuillez saisir votre nom.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
          ],

          _buildLabel('Adresse e-mail'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'vous@entreprise.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty ||
                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'Saisissez une adresse e-mail valide.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          _buildLabel('Mot de passe'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: 'Au moins 8 caractères',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? 'Afficher le mot de passe'
                  : 'Masquer le mot de passe',
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.muted,
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 8) {
                return 'Le mot de passe doit contenir au moins 8 caractères.';
              }
              return null;
            },
          ),

          if (_isLogin) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 30,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Se souvenir de moi',
                    style: GoogleFonts.poppins(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showMessage(
                    'La récupération du mot de passe sera ajoutée avec Supabase.',
                  ),
                  child: Text(
                    'Mot de passe oublié ?',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 18),
            _buildLabel('Confirmer le mot de passe'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _confirmPasswordController,
              hint: 'Retapez votre mot de passe',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.muted,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas.';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  height: 24,
                  child: Checkbox(
                    value: _acceptTerms,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() => _acceptTerms = value ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'J’accepte les conditions d’utilisation et la politique '
                    'de confidentialité.',
                    style: GoogleFonts.poppins(
                      color: AppColors.muted,
                      fontSize: 10,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? 'Se connecter' : 'Créer mon compte',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OU',
                  style: GoogleFonts.poppins(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showMessage(
                'La connexion Google pourra être configurée ultérieurement.',
              ),
              icon: const Icon(
                Icons.g_mobiledata_rounded,
                size: 28,
                color: AppColors.navy,
              ),
              label: Text(
                'Continuer avec Google',
                style: GoogleFonts.poppins(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 23),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(
                  _isLogin
                      ? 'Vous n’avez pas encore de compte ? '
                      : 'Vous avez déjà un compte ? ',
                  style: GoogleFonts.poppins(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      _switchMode(_isLogin ? AuthMode.signUp : AuthMode.login),
                  child: Text(
                    _isLogin ? 'Inscrivez-vous' : 'Connectez-vous',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        color: AppColors.navy,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(color: AppColors.navy, fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF9AA7BC),
          fontSize: 11,
        ),
        prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFCFDFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        errorMaxLines: 3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

// ============================================================
// BRAND AND MINI DASHBOARD
// ============================================================

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 9),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: AppColors.navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
            children: const [
              TextSpan(text: 'Stock'),
              TextSpan(
                text: 'Mind',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniDashboard extends StatelessWidget {
  const _MiniDashboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                color: Color(0xFFFFA5B3),
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                'Votre activité, en un coup d’œil',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          const Row(
            children: [
              Expanded(
                child: _MiniMetric(label: 'Produits', value: '248'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(label: 'Stock faible', value: '12'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.72,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF758C),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

import '../../sidebar/overview/pages/overview_page.dart';

class CompanyOnboardingPage extends StatefulWidget {
  const CompanyOnboardingPage({super.key});

  @override
  State<CompanyOnboardingPage> createState() => _CompanyOnboardingPageState();
}

class _CompanyOnboardingPageState extends State<CompanyOnboardingPage> {
  final _formKey = GlobalKey<FormState>();

  final _companyName = TextEditingController();
  final _sector = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _shopName = TextEditingController();
  final _slug = TextEditingController();
  final _logoUrl = TextEditingController();

  int _step = 0;
  Color _brandColor = AppColors.primary;
  bool _sameShopName = true;

  final List<String> _steps = [
    'Entreprise',
    'Coordonnées',
    'Identité visuelle',
    'Boutique en ligne',
    'Confirmation',
  ];

  @override
  void dispose() {
    _companyName.dispose();
    _sector.dispose();
    _phone.dispose();
    _city.dispose();
    _address.dispose();
    _shopName.dispose();
    _slug.dispose();
    _logoUrl.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();

    if (_step == 0) {
      if (_companyName.text.trim().isEmpty || _sector.text.trim().isEmpty) {
        _showMessage('Renseignez le nom et le secteur de votre entreprise.');
        return;
      }
    }

    if (_step == 1) {
      if (_phone.text.trim().isEmpty ||
          _city.text.trim().isEmpty ||
          _address.text.trim().isEmpty) {
        _showMessage('Complétez vos coordonnées.');
        return;
      }
    }

    if (_step == 3) {
      if (_shopName.text.trim().isEmpty || _slug.text.trim().isEmpty) {
        _showMessage('Renseignez le nom et l’adresse de votre boutique.');
        return;
      }

      final slugPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
      if (!slugPattern.hasMatch(_slug.text.trim())) {
        _showMessage(
          'Utilisez uniquement des minuscules, des chiffres et des tirets.',
        );
        return;
      }
    }

    if (_step < 4) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _previous() {
    if (_step > 0) {
      setState(() => _step--);
    }
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

  void _finish() {
    // Les données seront enregistrées dans Supabase
    // lors de l'étape d'intégration de la base de données.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 55,
          ),
          title: Text(
            'Configuration terminée !',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          content: Text(
            'Votre espace ${_companyName.text.trim()} est prêt à être configuré. '
            'La prochaine étape sera votre tableau de bord.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.muted,
              height: 1.8,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const OverviewPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Continuer'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        Text(
                          'Configurons votre espace',
                          style: GoogleFonts.poppins(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quelques informations pour personnaliser StockMind '
                          'selon les besoins de votre entreprise.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildProgress(),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width < 600 ? 20 : 32,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navy.withValues(alpha: 0.035),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: _buildCurrentStep(),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildFooterButtons(),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 21,
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
          const Spacer(),
          Text(
            'Configuration initiale',
            style: GoogleFonts.poppins(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Row(
          children: List.generate(_steps.length, (index) {
            final active = index == _step;
            final completed = index < _step;

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: active || completed
                          ? AppColors.primary
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active || completed
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: completed
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : Text(
                              '${index + 1}',
                              style: GoogleFonts.poppins(
                                color: active ? Colors.white : AppColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  if (index < _steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        color: completed ? AppColors.primary : AppColors.border,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Étape ${_step + 1} sur ${_steps.length} : ${_steps[_step]}',
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildCompanyStep();
      case 1:
        return _buildContactStep();
      case 2:
        return _buildIdentityStep();
      case 3:
        return _buildShopStep();
      default:
        return _buildReviewStep();
    }
  }

  // ÉTAPE 1 : ENTREPRISE

  Widget _buildCompanyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Parlez-nous de votre entreprise',
          'Ces informations permettront de personnaliser votre espace.',
          Icons.business_outlined,
        ),
        const SizedBox(height: 28),
        _label('Nom de l’entreprise'),
        const SizedBox(height: 8),
        _input(
          controller: _companyName,
          hint: 'Ex. : Koodland Market',
          icon: Icons.business_rounded,
        ),
        const SizedBox(height: 20),
        _label('Secteur d’activité'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _sector.text.isEmpty ? null : _sector.text,
          decoration: _decoration(
            hint: 'Sélectionnez votre secteur',
            icon: Icons.category_outlined,
          ),
          items: const [
            DropdownMenuItem(
              value: 'Commerce général',
              child: Text('Commerce général'),
            ),
            DropdownMenuItem(
              value: 'Mode et vêtements',
              child: Text('Mode et vêtements'),
            ),
            DropdownMenuItem(
              value: 'Électronique',
              child: Text('Électronique'),
            ),
            DropdownMenuItem(
              value: 'Alimentation',
              child: Text('Alimentation'),
            ),
            DropdownMenuItem(value: 'Cosmétique', child: Text('Cosmétique')),
            DropdownMenuItem(value: 'Autre', child: Text('Autre')),
          ],
          onChanged: (value) {
            setState(() => _sector.text = value ?? '');
          },
        ),
        const SizedBox(height: 24),
        _infoBox(
          'Vous pourrez compléter les informations de votre entreprise '
          'plus tard depuis les paramètres.',
        ),
      ],
    );
  }

  // ÉTAPE 2 : COORDONNÉES

  Widget _buildContactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Comment vous contacter ?',
          'Ces coordonnées serviront à identifier votre entreprise.',
          Icons.location_on_outlined,
        ),
        const SizedBox(height: 28),
        _label('Téléphone professionnel'),
        const SizedBox(height: 8),
        _input(
          controller: _phone,
          hint: '+216 XX XXX XXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _label('Ville'),
        const SizedBox(height: 8),
        _input(
          controller: _city,
          hint: 'Ex. : Sfax',
          icon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 20),
        _label('Adresse de l’entreprise'),
        const SizedBox(height: 8),
        _input(
          controller: _address,
          hint: 'Rue, quartier, numéro...',
          icon: Icons.home_outlined,
          maxLines: 2,
        ),
      ],
    );
  }

  // ÉTAPE 3 : IDENTITÉ VISUELLE

  Widget _buildIdentityStep() {
    final colors = [
      const Color(0xFFF21D3D),
      const Color(0xFF2563EB),
      const Color(0xFF0F9D78),
      const Color(0xFF7C3AED),
      const Color(0xFFEA580C),
      const Color(0xFF14264B),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Personnalisez votre identité',
          'Choisissez une couleur pour représenter votre entreprise.',
          Icons.palette_outlined,
        ),
        const SizedBox(height: 28),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _brandColor,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: _brandColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _companyName.text.isEmpty ? 'Votre entreprise' : _companyName.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _label('Couleur principale'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: colors.map((color) {
            final selected = color == _brandColor;

            return GestureDetector(
              onTap: () => setState(() => _brandColor = color),
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.navy : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 21,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        _label('Logo de l’entreprise (facultatif)'),
        const SizedBox(height: 8),
        _input(
          controller: _logoUrl,
          hint: 'URL de votre logo (facultatif)',
          icon: Icons.image_outlined,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 10),
        Text(
          'Pour le moment, tu peux renseigner une URL d’image. '
          'L’importation d’un fichier depuis ton appareil sera ajoutée ensuite.',
          style: GoogleFonts.poppins(
            color: AppColors.muted,
            fontSize: 10,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  // ÉTAPE 4 : BOUTIQUE EN LIGNE

  Widget _buildShopStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Préparez votre boutique en ligne',
          'Choisissez le nom et l’adresse publique de votre boutique.',
          Icons.storefront_outlined,
        ),
        const SizedBox(height: 28),
        _label('Nom de la boutique'),
        const SizedBox(height: 8),
        _input(
          controller: _shopName,
          hint: 'Ex. : Boutique Marie',
          icon: Icons.store_outlined,
          onChanged: (value) {
            if (_sameShopName) {
              _slug.text = _makeSlug(value);
            }
          },
        ),
        const SizedBox(height: 14),
        CheckboxListTile(
          value: _sameShopName,
          onChanged: (value) {
            setState(() {
              _sameShopName = value ?? true;
              if (_sameShopName) {
                _slug.text = _makeSlug(_shopName.text);
              }
            });
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
          title: Text(
            'Utiliser le nom de la boutique pour son adresse',
            style: GoogleFonts.poppins(color: AppColors.navy, fontSize: 11),
          ),
        ),
        const SizedBox(height: 10),
        _label('Adresse personnalisée'),
        const SizedBox(height: 8),
        _input(
          controller: _slug,
          hint: 'ma-boutique',
          icon: Icons.link_rounded,
          enabled: !_sameShopName,
          onChanged: (value) {
            final normalized = _makeSlug(value);
            if (normalized != value) {
              _slug.value = TextEditingValue(
                text: normalized,
                selection: TextSelection.collapsed(offset: normalized.length),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(color: AppColors.muted, fontSize: 11),
              children: [
                const TextSpan(text: 'Votre adresse :\n'),
                TextSpan(
                  text:
                      'stockmind.app/${_slug.text.isEmpty ? "ma-boutique" : _slug.text}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _infoBox(
          'Cette adresse est un aperçu. Sa disponibilité et la création '
          'réelle de votre boutique seront vérifiées au moment de '
          'l’enregistrement dans la base de données.',
        ),
      ],
    );
  }

  // ÉTAPE 5 : RÉCAPITULATIF

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Vérifiez vos informations',
          'Vérifiez les informations avant de terminer cette étape.',
          Icons.fact_check_outlined,
        ),
        const SizedBox(height: 25),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _reviewRow('Entreprise', _companyName.text),
              _reviewRow('Secteur', _sector.text),
              _reviewRow('Téléphone', _phone.text),
              _reviewRow('Ville', _city.text),
              _reviewRow('Adresse', _address.text),
              _reviewRow('Boutique', _shopName.text),
              _reviewRow('Adresse en ligne', 'stockmind.app/${_slug.text}'),
              _reviewRow(
                'Logo',
                _logoUrl.text.trim().isEmpty
                    ? 'Aucun logo ajouté'
                    : 'URL renseignée',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Identité visuelle'),
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _brandColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _infoBox(
          'En terminant, tu valides ces informations dans le formulaire. '
          'Elles ne seront réellement sauvegardées qu’après la connexion '
          'de StockMind à Supabase.',
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // REUSABLE COMPONENTS
  // ----------------------------------------------------------

  Widget _sectionTitle(String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDF0),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primary, size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: AppColors.muted,
                  fontSize: 11,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: AppColors.navy,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _decoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFF9AA7BC),
        fontSize: 11,
      ),
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      filled: true,
      fillColor: const Color(0xFFFCFDFF),
      contentPadding: const EdgeInsets.all(15),
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
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      onChanged: onChanged,
      style: GoogleFonts.poppins(color: AppColors.navy, fontSize: 12),
      decoration: _decoration(hint: hint, icon: icon),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0EAFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF2563EB),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: AppColors.muted,
                fontSize: 10,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: AppColors.muted, fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'Non renseigné' : value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                color: AppColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      children: [
        if (_step > 0)
          OutlinedButton.icon(
            onPressed: _previous,
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Précédent'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _step == 4 ? 'Terminer' : 'Continuer',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 9),
              Icon(
                _step == 4 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                size: 17,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _makeSlug(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[àáâäãå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôöõ]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

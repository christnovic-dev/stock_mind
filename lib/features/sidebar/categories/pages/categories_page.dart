import 'package:flutter/material.dart';

import '../data/mock_categorie.dart';
import '../services/categorie_service.dart';

const _red = Color(0xFFF21D3D);
const _navy = Color(0xFF14264B);
const _muted = Color(0xFF7B8498);
const _border = Color(0xFFE9ECF3);
const _background = Color(0xFFF7F8FC);

class CategoriesPage extends StatefulWidget {
  final String businessId;
  final ValueChanged<String> onViewProducts;

  const CategoriesPage({
    super.key,
    required this.businessId,
    required this.onViewProducts,
  });

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final CategoryService categoryService;

  List<StockCategory> categories = [];
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();

    categoryService = CategoryService(businessId: widget.businessId);

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final result = await categoryService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadError = e.toString();
        isLoading = false;
      });
    }
  }

  int get totalProducts =>
      categories.fold<int>(0, (sum, category) => sum + category.productCount);

  Future<void> openCategoryForm({StockCategory? category}) async {
    final result = await showDialog<StockCategory>(
      context: context,
      builder: (_) => _CategoryFormDialog(category: category),
    );

    if (result == null || !mounted) return;

    try {
      await categoryService.saveCategory(result);
      await _loadCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == null
                ? 'Catégorie créée avec succès.'
                : 'Catégorie modifiée avec succès.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l’enregistrement : $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> deleteCategory(StockCategory category) async {
    if (category.productCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cette catégorie contient des produits et ne peut pas être supprimée.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text('Supprimer « ${category.name} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await categoryService.deleteCategory(category.id);
      await _loadCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catégorie supprimée avec succès.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression : $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _red));
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: _muted),
              const SizedBox(height: 12),
              const Text(
                'Impossible de charger les catégories.',
                style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadCategories,
                style: FilledButton.styleFrom(backgroundColor: _red),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestion des catégories',
          style: TextStyle(
            color: _navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Organisez vos produits pour retrouver rapidement votre stock.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 22),

        // Résumé
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 600 ? 2 : 3;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

            final stats = [
              ('Catégories', '${categories.length}', Icons.category_outlined),
              (
                'Produits classés',
                '$totalProducts',
                Icons.inventory_2_outlined,
              ),
              (
                'Catégories vides',
                '${categories.where((c) => c.productCount == 0).length}',
                Icons.folder_open_outlined,
              ),
            ];

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: stats.map((stat) {
                return SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8EC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(stat.$3, color: _red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.$2,
                                style: const TextStyle(
                                  color: _navy,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                stat.$1,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 25),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Toutes les catégories',
                style: TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh_rounded, color: _navy),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: () => openCategoryForm(),
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (categories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _border),
            ),
            child: const Column(
              children: [
                Icon(Icons.folder_open_outlined, size: 42, color: _muted),
                SizedBox(height: 12),
                Text(
                  'Aucune catégorie pour le moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted),
                ),
                SizedBox(height: 5),
                Text(
                  'Cliquez sur Ajouter pour créer votre première catégorie.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 600
                  ? 1
                  : constraints.maxWidth < 1000
                  ? 2
                  : 3;

              const spacing = 16.0;

              final width =
                  (constraints.maxWidth - (columns - 1) * spacing) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: categories.map((category) {
                  return SizedBox(
                    width: width,
                    child: _CategoryCard(
                      category: category,
                      onEdit: () => openCategoryForm(category: category),
                      onDelete: () => deleteCategory(category),
                      onViewProducts: () =>
                          widget.onViewProducts(category.name),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        const SizedBox(height: 25),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final StockCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewProducts;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onViewProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8EC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.folder_outlined, color: _red, size: 25),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'Actions',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            category.name,
            style: const TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            category.description.isEmpty
                ? 'Aucune description'
                : category.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: _border),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 17, color: _muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${category.productCount} produit(s)',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewProducts,
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: const Text('Voir les produits'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final StockCategory? category;

  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.category?.name ?? '');

    descriptionController = TextEditingController(
      text: widget.category?.description ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.category == null
            ? 'Nouvelle catégorie'
            : 'Modifier la catégorie',
        style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
                decoration: _decoration('Nom de la catégorie'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: _decoration('Description (facultative)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _red),
          onPressed: () {
            if (!formKey.currentState!.validate()) return;

            final old = widget.category;

            final result = StockCategory(
              id: old?.id ?? '',
              name: nameController.text.trim(),
              description: descriptionController.text.trim(),
              productCount: old?.productCount ?? 0,
            );

            Navigator.pop(context, result);
          },
          child: Text(widget.category == null ? 'Créer' : 'Enregistrer'),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}

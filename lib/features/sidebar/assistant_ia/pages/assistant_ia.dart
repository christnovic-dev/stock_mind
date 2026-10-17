import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

import '../services/stock_ia_service.dart';

class AssistantIaPage extends StatefulWidget {
  final String businessId;

  const AssistantIaPage({super.key, required this.businessId});

  @override
  State<AssistantIaPage> createState() => _AssistantIaPageState();
}

class _AssistantIaPageState extends State<AssistantIaPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Bonjour ! 👋 Je suis l’assistant StockMind.\n\n'
          'Je peux t’aider à comprendre ton stock, repérer les risques '
          'de rupture et prendre de meilleures décisions pour ta boutique.\n\n'
          'Pose-moi une question sur ton stock réel !',
      isUser: false,
      time: 'Maintenant',
    ),
  ];

  bool _isTyping = false;
  bool _loadingStock = true;
  String? _stockError;
  Map<String, dynamic>? _stockContext;

  final List<String> _suggestions = const [
    'Quels produits réapprovisionner ?',
    'Quels sont les risques de rupture ?',
    'Combien de produits ai-je en stock ?',
    'Quelle est la valeur de mon stock ?',
  ];

  @override
  void initState() {
    super.initState();
    _loadStockContext();
  }

  @override
  void didUpdateWidget(covariant AssistantIaPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recharge les données si l'utilisateur change d'entreprise.
    if (oldWidget.businessId != widget.businessId) {
      _loadStockContext();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Récupère les données réelles via la fonction Edge Supabase.
  Future<void> _loadStockContext() async {
    if (widget.businessId.isEmpty) {
      setState(() {
        _loadingStock = false;
        _stockError = 'Aucune entreprise sélectionnée.';
        _stockContext = null;
      });
      return;
    }

    setState(() {
      _loadingStock = true;
      _stockError = null;
    });

    try {
      final result = await getStockContext(businessId: widget.businessId);
      ;

      final rawContext = result['stock_context'];

      if (rawContext is! Map) {
        throw Exception(
          'La fonction Supabase n’a pas retourné de contexte de stock valide.',
        );
      }

      if (!mounted) return;

      setState(() {
        _stockContext = Map<String, dynamic>.from(rawContext);
        _stockError = null;
        _loadingStock = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _stockError = e.toString();
        _loadingStock = false;
      });

      debugPrint('Erreur de chargement du stock : $e');
    }
  }

  // Envoie la question, récupère les données et construit une réponse.
  Future<void> _sendMessage([String? suggestedMessage]) async {
    final question = (suggestedMessage ?? _messageController.text).trim();

    if (question.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(
        _ChatMessage(text: question, isUser: true, time: _currentTime()),
      );

      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final result = await askStockAi(
        businessId: widget.businessId,
        question: question,
      );

      final rawContext = result['stock_context'];

      if (rawContext is! Map) {
        throw Exception('Le contexte de stock retourné est invalide.');
      }

      final context = Map<String, dynamic>.from(rawContext);

      final answer = result['answer']?.toString().trim();

      if (answer == null || answer.isEmpty) {
        throw Exception('Le service IA a retourné une réponse vide.');
      }

      if (!mounted) return;

      setState(() {
        _stockContext = context;
        _stockError = null;
        _loadingStock = false;

        _messages.add(
          _ChatMessage(text: answer, isUser: false, time: _currentTime()),
        );

        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _stockError = e.toString();
        _loadingStock = false;

        _messages.add(
          _ChatMessage(
            text:
                'Je n’ai pas pu récupérer les données de ton stock.\n\n'
                'Vérifie que tu es connecté, que ton entreprise est '
                'accessible et que la fonction Edge Supabase fonctionne.\n\n'
                'Détail technique : $e',
            isUser: false,
            time: _currentTime(),
          ),
        );

        _isTyping = false;
      });

      debugPrint('Erreur assistant IA : $e');
    }

    _scrollToBottom();
  }

  // Réponses déterministes basées sur les données de Supabase.
  // Cette méthode ne fait pas encore appel à un modèle génératif.
  String _buildStockAnswer(String question, Map<String, dynamic> stock) {
    final q = _normalize(question);

    final totalProducts = _asInt(stock['total_products']);
    final totalUnits = _asInt(stock['total_units']);
    final lowStockCount = _asInt(stock['low_stock_count']);
    final outOfStockCount = _asInt(stock['out_of_stock_count']);
    final stockValue = _asDouble(stock['stock_value']);

    final rawProducts = stock['low_stock_products'];

    final products = rawProducts is List
        ? rawProducts
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    final asksForProducts =
        q.contains('rupture') ||
        q.contains('reapprovision') ||
        q.contains('commander') ||
        q.contains('stock faible') ||
        q.contains('produits faibles') ||
        q.contains('surveiller');

    final asksForValue =
        q.contains('valeur') ||
        q.contains('combien vaut') ||
        q.contains('cout du stock') ||
        q.contains('coût du stock');

    final asksForSummary =
        q.contains('resume') ||
        q.contains('situation') ||
        q.contains('etat du stock') ||
        q.contains('etat actuel') ||
        q.contains('combien de produits') ||
        q.contains('nombre de produits') ||
        q.contains('combien ai-je') ||
        q.contains('quantite totale') ||
        q.contains('quantité totale');

    if (asksForProducts) {
      if (products.isEmpty) {
        return 'D’après les données actuelles de Supabase, aucun produit '
            'n’est signalé en stock faible ou en rupture selon les seuils '
            'enregistrés.\n\n'
            'Cela ne garantit pas qu’il n’y aura pas de rupture : il faut '
            'également tenir compte de la vitesse des ventes et des délais '
            'de livraison.';
      }

      final details = products
          .map((product) {
            final name = product['name']?.toString() ?? 'Produit sans nom';
            final quantity = _asInt(product['quantity']);
            final minimum = _asInt(product['minimum_quantity']);
            final status = quantity == 0 ? 'RUPTURE' : 'Stock faible';

            return '• $name\n'
                '  Quantité : $quantity unité(s)\n'
                '  Seuil minimum : $minimum\n'
                '  État : $status';
          })
          .join('\n\n');

      return 'Voici les produits à surveiller dans ton stock réel :\n\n'
          '$details\n\n'
          'Conseil : vérifie les ventes récentes et les délais de tes '
          'fournisseurs avant de déterminer les quantités à commander.';
    }

    if (asksForValue) {
      return 'La valeur estimée de ton stock est de '
          '${_formatNumber(stockValue)}.\n\n'
          'Ce montant est calculé à partir des quantités disponibles '
          'et des prix enregistrés dans Supabase. Il utilise la devise '
          'de tes prix et ne représente pas nécessairement le bénéfice '
          'ou la valeur de revente de tes produits.';
    }

    if (asksForSummary) {
      return 'Voici le résumé du stock de ton entreprise :\n\n'
          '• Produits enregistrés : $totalProducts\n'
          '• Unités disponibles : $totalUnits\n'
          '• Produits en stock faible ou en rupture : $lowStockCount\n'
          '• Produits en rupture : $outOfStockCount\n'
          '• Valeur estimée : ${_formatNumber(stockValue)}\n\n'
          'Tu peux aussi me demander quels produits nécessitent une '
          'attention particulière.';
    }

    return 'J’ai consulté les données de stock disponibles pour '
        'ton entreprise :\n\n'
        '• Produits enregistrés : $totalProducts\n'
        '• Unités disponibles : $totalUnits\n'
        '• Produits à surveiller : $lowStockCount\n'
        '• Produits en rupture : $outOfStockCount\n\n'
        'Pour le moment, je peux répondre aux questions sur le résumé '
        'du stock, les produits à surveiller et la valeur estimée '
        'de l’inventaire.\n\n'
        'L’analyse des ventes et les recommandations prédictives '
        'nécessiteront des données supplémentaires.';
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c');
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatNumber(num value) {
    final text = value.toStringAsFixed(2);
    final parts = text.split('.');
    final integerPart = parts.first;
    final buffer = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(integerPart[i]);
    }

    return '${buffer.toString()},${parts.last}';
  }

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _newConversation() {
    setState(() {
      _messages
        ..clear()
        ..add(
          _ChatMessage(
            text: 'Nouvelle conversation ! Que veux-tu analyser ?',
            isUser: false,
            time: _currentTime(),
          ),
        );
      _isTyping = false;
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1050;

          return SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (wide)
                  SizedBox(
                    height: 690,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 7, child: _buildChatPanel()),
                        const SizedBox(width: 20),
                        Expanded(flex: 3, child: _buildInsightsPanel()),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      SizedBox(height: 610, child: _buildChatPanel()),
                      const SizedBox(height: 20),
                      _buildInsightsPanel(),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final message = _loadingStock
        ? 'Connexion à Supabase et chargement du stock...'
        : _stockError != null
        ? 'Les données du stock ne sont pas disponibles. '
              'Vérifie la connexion à Supabase.'
        : 'Connexion active : les chiffres affichés proviennent '
              'des données de ton entreprise.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assistant IA',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ton copilote intelligent pour gérer ton stock.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Actualiser le stock',
              onPressed: _loadingStock ? null : _loadStockContext,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: _stockError != null
                ? const Color(0xFFFFF0F0)
                : const Color(0xFFFFF8E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _stockError != null
                  ? const Color(0xFFF3C5C5)
                  : const Color(0xFFF5E5BD),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _stockError != null
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                size: 18,
                color: _stockError != null
                    ? AppColors.primary
                    : AppColors.orange,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildChatHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(18),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  return _buildTypingIndicator();
                }

                return _buildMessage(_messages[index]);
              },
            ),
          ),
          if (_messages.length == 1 && !_isTyping) _buildSuggestions(),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'StockMind AI',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: _stockError == null
                          ? AppColors.green
                          : AppColors.orange,
                      size: 8,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _loadingStock
                            ? 'Connexion en cours'
                            : _stockError == null
                            ? 'Données de stock connectées'
                            : 'Connexion à vérifier',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Nouvelle conversation',
            onPressed: _newConversation,
            icon: const Icon(
              Icons.add_comment_outlined,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    final user = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!user) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: user
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: user ? AppColors.primary : const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(15),
                      topRight: const Radius.circular(15),
                      bottomLeft: Radius.circular(user ? 15 : 4),
                      bottomRight: Radius.circular(user ? 4 : 15),
                    ),
                  ),
                  child: SelectableText(
                    message.text,
                    style: TextStyle(
                      color: user ? Colors.white : AppColors.navy,
                      fontSize: 13,
                      height: 1.65,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message.time,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          if (user) ...[
            const SizedBox(width: 9),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 17,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 39, bottom: 16),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 9),
            Text(
              'StockMind analyse les données...',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POUR COMMENCER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((suggestion) {
              return InkWell(
                onTap: _isTyping ? null : () => _sendMessage(suggestion),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Pose une question sur ton stock...',
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            width: 46,
            child: ElevatedButton(
              onPressed: _isTyping ? null : () => _sendMessage(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.5,
                ),
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Icon(Icons.arrow_upward_rounded, size: 21),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsPanel() {
    final stock = _stockContext ?? <String, dynamic>{};

    final totalProducts = _asInt(stock['total_products']);
    final lowStockCount = _asInt(stock['low_stock_count']);
    final outOfStockCount = _asInt(stock['out_of_stock_count']);
    final totalUnits = _asInt(stock['total_units']);
    final stockValue = _asDouble(stock['stock_value']);

    final rawProducts = stock['low_stock_products'];
    final products = rawProducts is List
        ? rawProducts
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue rapide du stock',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _loadingStock
              ? 'Chargement des données...'
              : _stockError != null
              ? 'Données indisponibles'
              : 'Données réelles de ton entreprise',
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.inventory_2_outlined,
                label: 'Produits',
                value: _loadingStock ? '…' : '$totalProducts',
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.warning_amber_rounded,
                label: 'Stock faible',
                value: _loadingStock ? '…' : '$lowStockCount',
                color: AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.inventory_outlined,
                label: 'Unités en stock',
                value: _loadingStock ? '…' : '$totalUnits',
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.remove_shopping_cart_outlined,
                label: 'En rupture',
                value: _loadingStock ? '…' : '$outOfStockCount',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Points à surveiller',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (_loadingStock)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_stockError != null)
                _buildEmptyState(
                  'Impossible de charger les produits.',
                  Icons.cloud_off_rounded,
                )
              else if (products.isEmpty)
                _buildEmptyState(
                  'Aucun produit en stock faible ou en rupture.',
                  Icons.check_circle_outline_rounded,
                )
              else
                ...products.take(8).map(_buildInsightItem),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, Color(0xFF243E70)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Le conseil StockMind',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _loadingStock
                          ? 'Chargement des données du stock en cours.'
                          : _stockError != null
                          ? 'Vérifie la connexion à Supabase pour obtenir '
                                'des recommandations liées à ton stock.'
                          : 'Valeur estimée du stock : '
                                '${_formatNumber(stockValue)}. '
                                'Surveille les $lowStockCount produits '
                                'en stock faible ou en rupture.',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.6,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Produit sans nom';
    final quantity = _asInt(product['quantity']);
    final minimum = _asInt(product['minimum_quantity']);
    final outOfStock = quantity == 0;

    final color = outOfStock ? AppColors.primary : AppColors.orange;
    final status = outOfStock ? 'Rupture' : 'Stock faible';

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              outOfStock
                  ? Icons.remove_shopping_cart_rounded
                  : Icons.warning_amber_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantity unité(s) · Seuil : $minimum',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

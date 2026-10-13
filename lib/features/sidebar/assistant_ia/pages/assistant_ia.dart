import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

class AssistantIaPage extends StatefulWidget {
  const AssistantIaPage({super.key});

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
          'Que souhaites-tu savoir aujourd’hui ?',
      isUser: false,
      time: 'Maintenant',
    ),
  ];

  final List<_StockInsight> _insights = const [
    _StockInsight(
      name: 'Casque Bluetooth',
      detail: 'Stock restant : 4 unités',
      status: 'Stock faible',
      color: AppColors.orange,
      icon: Icons.headphones_rounded,
    ),
    _StockInsight(
      name: 'Chargeur USB-C',
      detail: 'Stock restant : 2 unités',
      status: 'À surveiller',
      color: AppColors.primary,
      icon: Icons.bolt_rounded,
    ),
    _StockInsight(
      name: 'Souris sans fil',
      detail: 'Stock restant : 18 unités',
      status: 'Stock correct',
      color: AppColors.green,
      icon: Icons.mouse_rounded,
    ),
  ];

  bool _isTyping = false;

  final List<String> _suggestions = const [
    'Quels produits réapprovisionner ?',
    'Quels sont les risques de rupture ?',
    'Quels produits se vendent le mieux ?',
    'Comment améliorer mon stock ?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? suggestedMessage]) {
    final text = (suggestedMessage ?? _messageController.text).trim();

    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(
        _ChatMessage(text: text, isUser: true, time: _currentTime()),
      );
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Réponse simulée en attendant la connexion à une véritable IA.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            text: _getMockResponse(text),
            isUser: false,
            time: _currentTime(),
          ),
        );
        _isTyping = false;
      });

      _scrollToBottom();
    });
  }

  String _getMockResponse(String question) {
    final q = question.toLowerCase();

    if (q.contains('réapprovision') ||
        q.contains('rupture') ||
        q.contains('commander')) {
      return 'Voici un exemple de recommandation basée sur les données '
          'de démonstration :\n\n'
          '• Chargeur USB-C : 2 unités restantes. Vérifie les ventes '
          'récentes et envisage une commande.\n'
          '• Casque Bluetooth : 4 unités restantes. Surveille la demande '
          'pour anticiper une éventuelle rupture.\n\n'
          'Pour calculer précisément les quantités à commander, je devrai '
          'analyser tes ventes, tes délais fournisseurs et ton stock réel.';
    }

    if (q.contains('mieux') ||
        q.contains('vend') ||
        q.contains('performance')) {
      return 'Pour identifier tes produits les plus vendus, il faudra '
          'comparer les quantités vendues sur une période donnée.\n\n'
          'Je pourrai ensuite te présenter le classement des produits, '
          'leur chiffre d’affaires et leur évolution. Les données de '
          'démonstration actuelles ne suffisent pas pour établir un '
          'classement réel.';
    }

    if (q.contains('améliorer') || q.contains('conseil')) {
      return 'Voici trois bonnes pratiques pour mieux gérer ton stock :\n\n'
          '1. Définis un seuil d’alerte pour chaque produit.\n'
          '2. Suis régulièrement les ventes et les délais de livraison.\n'
          '3. Identifie les produits qui restent longtemps en stock.\n\n'
          'Avec tes données réelles, je pourrai adapter ces conseils '
          'à ta boutique.';
    }

    return 'Bonne question ! Pour te répondre précisément, je devrai '
        'consulter les produits, les quantités disponibles, les ventes '
        'et les informations de tes fournisseurs.\n\n'
        'Pour le moment, je fonctionne en mode démonstration. Tu peux '
        'essayer une question sur les ruptures, le réapprovisionnement '
        'ou les performances des produits.';
  }

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF5E5BD)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.orange,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Mode démonstration : les réponses et les stocks affichés '
                  'ne proviennent pas encore de ta boutique.',
                  style: TextStyle(
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StockMind AI',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, color: AppColors.green, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'Assistant de démonstration',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Nouvelle conversation',
            onPressed: () {
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
            },
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
              'StockMind réfléchit...',
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
                onTap: () => _sendMessage(suggestion),
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
        const Text(
          'Exemples de données pour la démonstration',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.inventory_2_outlined,
                label: 'Produits',
                value: '128',
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.warning_amber_rounded,
                label: 'Stock faible',
                value: '08',
                color: AppColors.navy,
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
              ..._insights.map(_buildInsightItem),
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
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Le conseil StockMind',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Un bon réapprovisionnement prend en compte les ventes, '
                      'le stock disponible et les délais de livraison.',
                      style: TextStyle(
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

  Widget _buildInsightItem(_StockInsight insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(insight.icon, color: insight.color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.detail,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              insight.status,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: insight.color,
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

class _StockInsight {
  final String name;
  final String detail;
  final String status;
  final Color color;
  final IconData icon;

  const _StockInsight({
    required this.name,
    required this.detail,
    required this.status,
    required this.color,
    required this.icon,
  });
}

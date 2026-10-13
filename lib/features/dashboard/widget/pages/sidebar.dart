import 'package:flutter/material.dart';

import '../../presentation/pages/overview_page.dart';

class MenuItem {
  final String label;
  final IconData icon;

  const MenuItem(this.label, this.icon);
}

class Sidebar extends StatelessWidget {
  final List<MenuItem> items;
  final int selectedIndex;
  final bool expanded;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;

  const Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.expanded,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: expanded ? 252 : 78,
      color: stockNavy,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 22 : 12,
              vertical: 26,
            ),
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: stockRed,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'StockMind',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Align(
              alignment: expanded ? Alignment.centerLeft : Alignment.center,
              child: Text(
                expanded ? 'MENU PRINCIPAL' : '•••',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: Color(0xFF9AA7C3),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Tooltip(
                    message: expanded ? '' : item.label,
                    child: Material(
                      color: selected ? stockRed : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(11),
                        onTap: () => onSelect(index),
                        child: SizedBox(
                          height: 47,
                          child: Row(
                            mainAxisAlignment: expanded
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 15),
                              Icon(
                                item.icon,
                                size: 20,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFFB9C3D8),
                              ),
                              if (expanded) ...[
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFFD5DCEC),
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              if (expanded) const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(height: 1, color: const Color(0xFF344565)),
                const SizedBox(height: 10),
                if (expanded)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21375E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFFFC857),
                          size: 21,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'StockMind IA\nBientôt disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: expanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Icon(
                          expanded
                              ? Icons.keyboard_double_arrow_left
                              : Icons.keyboard_double_arrow_right,
                          color: Colors.white70,
                        ),
                        if (expanded) ...[
                          const SizedBox(width: 10),
                          const Text(
                            'Réduire le menu',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
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
}

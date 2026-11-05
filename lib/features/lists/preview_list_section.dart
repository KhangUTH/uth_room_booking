import 'package:flutter/material.dart';

class PreviewListSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String Function(T) titleOf;
  final String Function(T) subtitleOf;
  final VoidCallback onSeeMore;
  final int maxItems;

  const PreviewListSection({
    super.key,
    required this.title,
    required this.items,
    required this.titleOf,
    required this.subtitleOf,
    required this.onSeeMore,
    this.maxItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    final shown = items.take(maxItems).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0DEDF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...shown.map(
            (item) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(titleOf(item), style: const TextStyle(fontSize: 14)),
                  Text(
                    subtitleOf(item),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: onSeeMore,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Xem thêm >'),
            ),
          ),
        ],
      ),
    );
  }
}
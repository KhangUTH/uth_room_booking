import 'package:flutter/material.dart';

import '../../features/booking/data/asset_catalog.dart';

class ShellCatalogContent extends StatelessWidget {
  const ShellCatalogContent({
    super.key,
    required this.catalog,
    required this.lastCatalog,
    required this.onRefresh,
    required this.builder,
  });

  final Future<AssetCatalog>? catalog;
  final AssetCatalog? lastCatalog;
  final Future<AssetCatalog?> Function() onRefresh;
  final Widget Function(AssetCatalog?) builder;

  @override
  Widget build(BuildContext context) {
    final catalog = this.catalog;
    if (catalog == null) return builder(null);
    return FutureBuilder<AssetCatalog>(
      future: catalog,
      builder: (context, snapshot) {
        final available = snapshot.data ?? lastCatalog;
        if (available != null) return builder(available);
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: TextButton(
                      onPressed: onRefresh,
                      child: const Text('Không tải được danh mục. Thử lại'),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return builder(snapshot.requireData);
      },
    );
  }
}

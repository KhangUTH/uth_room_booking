import 'package:flutter/material.dart';

import '../../features/booking/data/asset_catalog.dart';

class ShellCatalogController {
  ShellCatalogController({required this.load, required this.onReload});

  final Future<AssetCatalog>? Function() load;
  final VoidCallback onReload;
  AssetCatalog? _lastCatalog;
  Future<AssetCatalog?>? _reloading;
  late Future<AssetCatalog>? _catalog = _request();

  Future<AssetCatalog>? _request() =>
      load()?.then((catalog) => _lastCatalog = catalog);

  Future<AssetCatalog?> reload() =>
      _reloading ??= _reloadOnce().whenComplete(() => _reloading = null);

  Future<AssetCatalog?> _reloadOnce() async {
    final request = _request();
    if (request == null) return null;
    _catalog = request;
    onReload();
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }

  Widget content(Widget Function(AssetCatalog?) builder) => ShellCatalogContent(
    catalog: _catalog,
    lastCatalog: _lastCatalog,
    onRefresh: reload,
    builder: builder,
  );
}

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

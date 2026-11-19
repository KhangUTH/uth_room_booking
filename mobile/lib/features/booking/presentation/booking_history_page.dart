import 'package:flutter/material.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

import '../controllers/booking_controller.dart';
import '../widgets/booking_category_tabs.dart';
import '../widgets/booking_history_card.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key, required this.bookings});

  final BookingController bookings;

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  bool _rooms = true;
  Future<void>? _history;

  @override
  void initState() {
    super.initState();
    if (widget.bookings.store != null) {
      _history = widget.bookings.refreshHistory();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _history,
    builder: (context, snapshot) => _buildPage(snapshot),
  );

  Widget _buildPage(AsyncSnapshot<void> snapshot) {
    final entries = widget.bookings
        .indicesFor(null)
        .map(widget.bookings.bookingAt)
        .where((booking) => (booking.asset.capacity > 0) == _rooms)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đăng ký'),
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: BookingCategoryTabs(
                options: const [(true, 'Phòng máy'), (false, 'Thiết bị')],
                selected: _rooms,
                onChanged: (rooms) => setState(() => _rooms = rooms),
              ),
            ),
            Expanded(
              child: _refreshable(
                snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : snapshot.hasError
                    ? _message(
                        child: TextButton(
                          onPressed: _refresh,
                          child: const Text('Không tải được lịch sử. Thử lại'),
                        ),
                      )
                    : entries.isEmpty
                    ? _message(
                        child: Text(
                          _rooms
                              ? 'Bạn chưa đăng ký phòng máy.'
                              : 'Bạn chưa đăng ký thiết bị.',
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        key: ValueKey(_rooms),
                        padding: const EdgeInsets.all(16),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) =>
                            BookingHistoryCard(booking: entries[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final history = widget.bookings.refreshHistory();
    setState(() {
      _history = history;
    });
    try {
      await history;
    } catch (_) {
      // FutureBuilder shows the retry state.
    }
  }

  Widget _refreshable(Widget child) => widget.bookings.store == null
      ? child
      : RefreshIndicator(onRefresh: _refresh, child: child);

  Widget _message({required Widget child}) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
    ],
  );
}

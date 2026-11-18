
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/controller/payment_controller.dart';
import 'cart_service.dart';
import 'payment_page.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final PaymentController _paymentController = PaymentController();

  List<Map<String, dynamic>> allOrders = [];
  bool isLoading = true;
  String? errorMessage;
  Timer? countdownTimer;

  final List<String> statuses = [
    'To Pay',
    'To Ship',
    'To Receive',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: statuses.length,
      vsync: this,
    );

    if (CartService.history.isNotEmpty) {
      allOrders = List<Map<String, dynamic>>.from(CartService.history);
      isLoading = false;
    }

    // Update countdown every second.
    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (mounted) {
          setState(() {});
        }
      },
    );

    loadOrders();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    tabController.dispose();
    super.dispose();
  }

  // Convert database status into the five order tabs.
  String _mapOrderTabStatus(Map<String, dynamic> raw) {
    final status = (raw['status'] ?? '').toString().toLowerCase();
    final shipStatus =
        (raw['shipping_status'] ?? '').toString().toLowerCase();

    if (status == 'cancelled' || status == 'expired') {
      return 'Cancelled';
    }

    if (status == 'pending') {
      return 'To Pay';
    }

    if (status == 'completed' || status == 'paid') {
      if (shipStatus.contains('deliver') ||
          shipStatus.contains('complete')) {
        return 'Completed';
      }

      if (shipStatus.contains('ship') ||
          shipStatus.contains('transit')) {
        return 'To Receive';
      }

      return 'To Ship';
    }

    return 'To Pay';
  }

  Future<void> loadOrders() async {
    if (mounted && CartService.history.isEmpty) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final rawOrders = await _paymentController.getMyOrders();

      final mapped = rawOrders.map((row) {
        final tabStatus = _mapOrderTabStatus(row);

        final showDate = DateTime.tryParse(
          row['show_datetime']?.toString() ?? '',
        );

        final dateText = showDate != null
            ? '${showDate.day.toString().padLeft(2, '0')}/'
                '${showDate.month.toString().padLeft(2, '0')}/'
                '${showDate.year}'
            : '-';

        final timeText = showDate != null
            ? '${showDate.hour.toString().padLeft(2, '0')}:'
                '${showDate.minute.toString().padLeft(2, '0')}'
            : '-';

        return {
          ...row,

          'orderId': 'ORD-${row['payment_id']}',
          'status': tabStatus,

          'orderDate': row['paid_at'] ??
              row['created_at'] ??
              row['expires_at'],

          'totalPrice': row['amount'] ?? 0,
          'paymentStatus': row['status'] ?? '-',
          'shippingStatus': row['shipping_status'] ?? 'preparing',

          'seller_id': row['seller_id'],
          'seller_name': row['seller_name'] ?? row['seller_username'] ?? '-',
          'seller_username': row['seller_username'] ?? '-',
          'seller_email': row['seller_email'] ?? '-',
          'buyer_id': row['buyer_id'],
          'buyer_name': row['buyer_name'] ?? row['buyer_username'] ?? '-',
          'buyer_email': row['buyer_email'] ?? '-',
          'is_seller': row['is_seller'] == 1 || row['is_seller'] == true,
          'is_buyer': row['is_buyer'] == 1 || row['is_buyer'] == true,
          'fromBackend': true,

          // Keep the original expires_at from the database.
          'expires_at': row['expires_at'],

          'items': [
            {
              'listing_id': row['listing_id'],
              'payment_id': row['payment_id'],
              'ticket_id': row['ticket_id'],
              'ticket_code': row['ticket_code'],
              'concertName':
                  row['concert_title'] ?? 'Concert Ticket',
              'artist': row['artist'] ?? '',
              'zone': row['zone_name'] ?? '-',
              'seat': row['seat_number'] ?? '-',
              'location': row['venue'] ?? '-',
              'date': dateText,
              'time': timeText,
              'price': row['resell_price'] ?? row['amount'] ?? 0,
            },
          ],
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        allOrders = mapped.isNotEmpty || CartService.history.isEmpty
            ? mapped
            : List<Map<String, dynamic>>.from(CartService.history);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        if (CartService.history.isNotEmpty) {
          allOrders = List<Map<String, dynamic>>.from(CartService.history);
          errorMessage = null;
        } else {
          errorMessage =
              e.toString().replaceAll('Exception: ', '');
        }
      });
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    DateTime? date;

    if (value is DateTime) {
      date = value;
    } else {
      date = DateTime.tryParse(value.toString());
    }

    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String money(dynamic value) {
    final price = double.tryParse(value.toString()) ?? 0;
    return '฿${price.toStringAsFixed(0)}';
  }

  // Countdown widget for To Pay orders.
  Widget _buildCountdown(Map<String, dynamic> order) {
    final expiresAt = order['expires_at']?.toString();

    if (expiresAt == null || expiresAt.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Payment expiration time is unavailable.',
                style: TextStyle(
                  color: darkPink,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final remainingSeconds =
        PaymentController.getRemainingSeconds(expiresAt);

    if (remainingSeconds <= 0) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Payment time expired',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    final timeText =
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            color: Colors.deepOrange,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Complete payment within',
              style: TextStyle(
                color: darkPink,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            timeText,
            style: const TextStyle(
              color: Colors.deepOrange,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> ordersFor(String status) {
    if (status == 'To Ship') {
      return allOrders
          .where(
            (o) =>
                o['status'] == 'To Ship' ||
                (o['status'] == 'To Receive' && o['fromBackend'] == true),
          )
          .toList();
    }
    return allOrders.where((o) => o['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: darkPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          labelColor: pink,
          unselectedLabelColor: Colors.grey,
          indicatorColor: pink,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'To Pay'),
            Tab(text: 'To Ship'),
            Tab(text: 'To Receive'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: pink),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: pink,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadOrders,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pink,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: tabController,
                  children: statuses.map((status) {
                    return _buildOrderList(status);
                  }).toList(),
                ),
    );
  }

  Widget _buildOrderList(String status) {
    final orders = ordersFor(status);

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 65,
              color: pink.withOpacity(0.5),
            ),
            const SizedBox(height: 15),
            Text(
              'No $status orders',
              style: const TextStyle(
                color: darkPink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Your orders will appear here.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: pink,
      onRefresh: loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? '';
    final orderItems =
        order['items'] is List ? order['items'] as List : [];

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: pink,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['orderId']?.toString() ?? 'Order',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkPink,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            // Show countdown only in To Pay.
            if (status == 'To Pay') _buildCountdown(order),

            ...orderItems.map((item) {
              final ticket = Map<String, dynamic>.from(item);
              return _buildTicketItem(ticket);
            }),

            const Divider(height: 25),

            _infoRow(
              Icons.calendar_month,
              'Order date',
              formatDate(order['orderDate']),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total payment',
                  style: TextStyle(
                    color: darkPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  money(order['totalPrice'] ?? 0),
                  style: const TextStyle(
                    color: pink,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            if (status == 'To Ship' ||
                status == 'To Receive' ||
                status == 'Completed')
              _buildTrackingInfo(order),

            if (status == 'To Ship' || status == 'To Receive') ...[
              const SizedBox(height: 12),
              _buildShipReceiveActions(order),
            ],

            const SizedBox(height: 15),

            if (status == 'To Pay')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelOrder(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Cancel Order'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _payOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pink,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pay Now'),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 5),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showOrderDetails(order),
                icon: const Icon(
                  Icons.visibility_outlined,
                  size: 17,
                ),
                label: const Text('Order Details'),
                style: TextButton.styleFrom(
                  foregroundColor: darkPink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketItem(Map<String, dynamic> ticket) {
    final concertName =
        ticket['concertName'] ?? 'Concert Ticket';
    final artist = ticket['artist'] ?? '';
    final zone = ticket['zone'] ?? 'General Zone';
    final price = ticket['price'] ?? 0;
    final seat = ticket['seat'] ?? '-';
    final location = ticket['location'] ?? '-';
    final date = ticket['date'] ?? '-';
    final time = ticket['time'] ?? '-';
    final code = ticket['ticket_code'] ?? '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: pink,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concertName.toString(),
                      style: const TextStyle(
                        color: darkPink,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (artist.toString().isNotEmpty)
                      Text(
                        artist.toString(),
                        style: const TextStyle(
                          color: pink,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      zone.toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                money(price),
                style: const TextStyle(
                  color: darkPink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightPink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ticket Information',
                  style: TextStyle(
                    color: darkPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),

                _ticketInfoRow(
                  Icons.qr_code_2,
                  'Code',
                  code.toString(),
                ),
                const SizedBox(height: 8),

                _ticketInfoRow(
                  Icons.event_seat_outlined,
                  'Seat',
                  seat.toString(),
                ),
                const SizedBox(height: 8),

                _ticketInfoRow(
                  Icons.location_on_outlined,
                  'Venue',
                  location.toString(),
                ),
                const SizedBox(height: 8),

                _ticketInfoRow(
                  Icons.calendar_month_outlined,
                  'Date',
                  date.toString(),
                ),
                const SizedBox(height: 8),

                _ticketInfoRow(
                  Icons.access_time,
                  'Time',
                  time.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: pink),
        const SizedBox(width: 8),
        SizedBox(
          width: 55,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: darkPink,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingInfo(Map<String, dynamic> order) {
    final sellerName = order['seller_name']?.toString() ?? '-';
    final sellerEmail = order['seller_email']?.toString() ?? '-';
    final buyerName = order['buyer_name']?.toString() ?? '-';
    final buyerEmail = order['buyer_email']?.toString() ?? '-';
    final bool isSeller = order['is_seller'] == true || order['is_seller'] == 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Delivery & Shipping',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkPink,
                  ),
                ),
              ),
              if (order['fromBackend'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isSeller
                        ? Colors.orange.withOpacity(0.15)
                        : pink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSeller ? 'Role: Seller (ผู้ขาย)' : 'Role: Buyer (ผู้ซื้อ)',
                    style: TextStyle(
                      color: isSeller ? Colors.deepOrange : pink,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 15, color: darkPink),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Seller: $sellerName ($sellerEmail)',
                  style: const TextStyle(
                    color: darkPink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (isSeller && buyerEmail != '-') ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 15, color: darkPink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Buyer: $buyerName ($buyerEmail)',
                    style: const TextStyle(
                      color: darkPink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Status: ${order['shippingStatus'] ?? 'Preparing'}',
            style: const TextStyle(
              color: pink,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (order['tracking_number'] != null &&
              order['tracking_number'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Tracking: ${order['tracking_number']}',
                style: const TextStyle(
                  color: darkPink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (order['shipping_info'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                order['shipping_info'].toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShipReceiveActions(Map<String, dynamic> order) {
    final bool isSeller = order['is_seller'] == true || order['is_seller'] == 1;
    final bool isBuyer = order['is_buyer'] == null
        ? !isSeller
        : (order['is_buyer'] == true || order['is_buyer'] == 1);
    final String shipStatus =
        (order['shippingStatus'] ?? order['shipping_status'] ?? '')
            .toString()
            .toLowerCase();
    final bool isShipped = shipStatus.contains('ship') ||
        shipStatus.contains('transit') ||
        order['status'] == 'To Receive';

    // 1. Seller can ship the ticket when it hasn't been shipped yet
    if (!isShipped && isSeller) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _shipOrder(order),
          icon: const Icon(Icons.local_shipping_outlined, size: 18),
          label: const Text(
            'Ship Ticket (กดส่งบัตร)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    // 2. Buyer can confirm received once the seller has shipped the ticket
    if (isShipped && isBuyer) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _receiveOrder(order),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text(
            'Confirm Received (กดรับบัตร)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    // 3. Status message while waiting for the other party
    if (!isShipped && isBuyer) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Waiting for seller to ship the ticket (รอผู้ขายกดส่งบัตร)',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isShipped && isSeller) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.local_shipping, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ticket shipped! Waiting for buyer to confirm receipt (ส่งบัตรแล้ว รอผู้ซื้อกดรับบัตร)',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: darkPink,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'To Pay':
        return Colors.orange;
      case 'To Ship':
        return Colors.blue;
      case 'To Receive':
        return Colors.deepPurple;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _payOrder(Map<String, dynamic> order) {
    final orderItems =
        (order['items'] as List?)
            ?.map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList() ??
        [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(items: orderItems),
      ),
    ).then((_) {
      loadOrders();
    });
  }

  Future<void> _cancelOrder(
    Map<String, dynamic> order,
  ) async {
    final paymentId = int.tryParse(
      order['payment_id']?.toString() ?? '',
    );

    if (paymentId == null) return;

    try {
      await _paymentController.cancelPayment(
        paymentId: paymentId,
      );

      await loadOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shipOrder(Map<String, dynamic> order) async {
    final paymentId = int.tryParse(
      order['payment_id']?.toString() ?? '',
    );

    if (paymentId == null) return;

    try {
      await _paymentController.shipOrder(paymentId: paymentId);
      await loadOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ส่งบัตรเรียบร้อยแล้ว! รอผู้ซื้อกดยืนยันรับบัตร (Ticket shipped!)',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _receiveOrder(Map<String, dynamic> order) async {
    final paymentId = int.tryParse(
      order['payment_id']?.toString() ?? '',
    );

    if (paymentId == null) return;

    try {
      await _paymentController.confirmReceived(paymentId: paymentId);
      await loadOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ยืนยันรับบัตรเรียบร้อยแล้ว! คำสั่งซื้อเสร็จสมบูรณ์ (Ticket received!)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text(
                      'Order Details',
                      style: TextStyle(
                        color: darkPink,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _infoRow(
                    Icons.receipt,
                    'Order ID',
                    order['orderId']?.toString() ?? '-',
                  ),
                  const SizedBox(height: 12),

                  _infoRow(
                    Icons.payment,
                    'Payment method',
                    order['payment_method']?.toString() ?? '-',
                  ),
                  const SizedBox(height: 12),

                  _infoRow(
                    Icons.verified,
                    'Payment status',
                    order['paymentStatus']?.toString() ?? '-',
                  ),
                  const SizedBox(height: 12),

                  _infoRow(
                    Icons.local_shipping,
                    'Shipping status',
                    order['shippingStatus']?.toString() ?? '-',
                  ),
                  const SizedBox(height: 12),

                  _infoRow(
                    Icons.storefront_outlined,
                    'Seller',
                    order['seller_name']?.toString() ?? '-',
                  ),
                  const SizedBox(height: 12),

                  _infoRow(
                    Icons.email_outlined,
                    'Seller Email',
                    order['seller_email']?.toString() ?? '-',
                  ),
                  const SizedBox(height: 12),

                  _infoRow(
                    Icons.attach_money,
                    'Total',
                    money(order['totalPrice'] ?? 0),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pink,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

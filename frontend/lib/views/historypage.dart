import 'dart:async';
import 'package:flutter/material.dart';
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
  Timer? refreshTimer;

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

    // อัปเดตเวลานับถอยหลังทุก 1 วินาที
    refreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        CartService.refreshExpiredOrders();
        setState(() {});
      },
    );

    CartService.refreshExpiredOrders();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    tabController.dispose();
    super.dispose();
  }

  void refreshPage() {
    CartService.refreshExpiredOrders();

    if (mounted) {
      setState(() {});
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

  List<Map<String, dynamic>> ordersFor(String status) {
    return CartService.getOrdersByStatus(status);
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
      body: TabBarView(
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
      onRefresh: () async {
        refreshPage();
      },
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
    final orderItems = order['items'] is List
        ? order['items'] as List
        : [];

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

            if (status == 'To Pay')
              _buildPaymentCountdown(order),

            if (status == 'To Ship' ||
                status == 'To Receive' ||
                status == 'Completed')
              _buildTrackingInfo(order),

            const SizedBox(height: 15),

            _buildActionButtons(order),

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
    final concertName = ticket['concertName'] ??
        ticket['name'] ??
        ticket['concert'] ??
        'Concert Ticket';

    final artist = ticket['artist'] ?? '';
    final zone = ticket['zone'] ?? 'General Zone';
    final price = ticket['price'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
    );
  }

  Widget _buildPaymentCountdown(
    Map<String, dynamic> order,
  ) {
    final remaining =
        CartService.remainingPaymentTime(order);

    final expired = remaining <= Duration.zero;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: expired
            ? Colors.red.shade50
            : const Color(0xFFFFF2E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: expired ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Payment countdown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkPink,
                  ),
                ),
              ),
              Text(
                CartService.formatRemainingTime(order),
                style: TextStyle(
                  color: expired ? Colors.red : Colors.deepOrange,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            expired
                ? 'Payment time has expired.'
                : 'Please complete payment within 15 minutes.',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingInfo(
    Map<String, dynamic> order,
  ) {
    final trackingNumber =
        order['trackingNumber']?.toString();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order tracking',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: darkPink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order['shippingStatus']?.toString() ?? '',
            style: const TextStyle(
              color: pink,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trackingNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                'Tracking number: $trackingNumber',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 10),
          _buildTimeline(order),
        ],
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> order) {
    final timeline = order['timeline'];

    if (timeline is! List || timeline.isEmpty) {
      return const Text(
        'No tracking updates yet.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: timeline.map<Widget>((event) {
        final data = Map<String, dynamic>.from(event);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                size: 17,
                color: pink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['message']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: darkPink,
                      ),
                    ),
                    Text(
                      formatDate(data['date']),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(
    Map<String, dynamic> order,
  ) {
    final status = order['status'];

    if (status == 'To Pay') {
      return Row(
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
      );
    }

    if (status == 'To Ship') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _simulateShipping(order),
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Update Shipping (Demo)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: pink,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (status == 'To Receive') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _confirmReceived(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: pink,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Received Ticket'),
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
    // นำทางไปยังหน้า PaymentPage เพื่อชำระเงินและดูเวลานับถอยหลังต่อ
    final orderItems = (order['items'] as List?)
            ?.map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(items: orderItems),
      ),
    ).then((_) {
      refreshPage();
    });
  }

  void _cancelOrder(Map<String, dynamic> order) {
    final success = CartService.cancelOrder(order);

    refreshPage();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Order cancelled.'
              : 'Unable to cancel this order.',
        ),
      ),
    );
  }

  void _simulateShipping(Map<String, dynamic> order) {
    final success = CartService.shipOrder(order);

    refreshPage();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Ticket shipped successfully.'
              : 'Unable to update shipping.',
        ),
      ),
    );
  }

  void _confirmReceived(Map<String, dynamic> order) {
    final success = CartService.confirmReceived(order);

    refreshPage();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Order completed successfully!'
              : 'Unable to confirm this order.',
        ),
      ),
    );
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
                    Icons.calendar_month,
                    'Order date',
                    formatDate(order['orderDate']),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.payment,
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
                    Icons.attach_money,
                    'Total',
                    money(order['totalPrice'] ?? 0),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Order timeline',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkPink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimeline(order),
                  const SizedBox(height: 15),
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
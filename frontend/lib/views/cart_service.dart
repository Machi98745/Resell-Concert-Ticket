import 'dart:math';

class CartService {
  // ==========================================
  // CART & RESALE DATA
  // ==========================================

  static final List<Map<String, dynamic>> items = [];
  static final List<Map<String, dynamic>> history = [];
  
  // รายการตั๋วที่ผู้ใช้งานนำมาประกาศขาย
  static final List<Map<String, dynamic>> resaleListings = [];

  static const Duration paymentLimit = Duration(minutes: 15);
  static int _orderCounter = 1;

  // ==========================================
  // UNPAID ORDER CHECK (เช็ครายการค้างชำระ)
  // ==========================================

  // เช็คว่ามีรายการที่รอชำระเงิน (To Pay) อยู่แล้วหรือไม่
  static bool hasActiveUnpaidOrder() {
    refreshExpiredOrders();
    final unpaid = getOrdersByStatus('To Pay');
    return unpaid.isNotEmpty;
  }

  // ==========================================
  // RESALE TICKET MANAGEMENT
  // ==========================================

  static void createResaleListing(Map<String, dynamic> listingData) {
    final newListing = {
      ...listingData,
      'listingId': 'LIST_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'Available',
      'createdDate': DateTime.now(),
      'isShippedBySeller': false,
    };
    resaleListings.add(newListing);
  }

  static List<Map<String, dynamic>> getResaleListingsForConcert(String concertName) {
    final target = concertName.trim().toLowerCase();
    
    return resaleListings.where((item) {
      final itemConcert = (item['concert'] ?? item['concertName'] ?? '').toString().trim().toLowerCase();
      final status = (item['status'] ?? 'Available').toString().toLowerCase();

      final isMatch = itemConcert.contains(target) || target.contains(itemConcert);
      
      return isMatch && status == 'available';
    }).toList();
  }

  static bool markTicketAsShipped(String listingId) {
    final index = resaleListings.indexWhere((item) => item['listingId'] == listingId);
    if (index != -1) {
      resaleListings[index]['status'] = 'Shipped';
      resaleListings[index]['isShippedBySeller'] = true;

      for (final order in history) {
        final orderItems = order['items'] as List?;
        if (orderItems != null) {
          for (final item in orderItems) {
            if (item['listingId'] == listingId) {
              order['status'] = 'To Receive';
              order['shippingStatus'] = 'Seller has shipped your ticket';
              _addTimeline(order, 'Seller confirmed ticket shipment.');
            }
          }
        }
      }
      return true;
    }
    return false;
  }

  // ==========================================
  // CONCERT DATE FUNCTIONS
  // ==========================================

  static DateTime? _parseConcertDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    final text = value.toString().trim();

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    final match = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$',
    ).firstMatch(text);

    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final monthName = match.group(2)!.toLowerCase();
    final year = int.tryParse(match.group(3)!);

    const months = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };

    final month = months[monthName];

    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  static bool isConcertFinished(Map<String, dynamic> concert) {
    final date = _parseConcertDate(
      concert['date'] ?? concert['concertDate'],
    );

    if (date == null) return false;

    final today = DateTime.now();

    final concertDay = DateTime(date.year, date.month, date.day);
    final currentDay = DateTime(today.year, today.month, today.day);

    return concertDay.isBefore(currentDay);
  }

  static bool isTicketSold(Map<String, dynamic> ticket) {
    final status = ticket['status']
        ?.toString()
        .trim()
        .toLowerCase();

    return ticket['isSold'] == true ||
        status == 'sold' ||
        status == 'sold out';
  }

  static bool isConcertSoldOut(Map<String, dynamic> concert) {
    final tickets = concert['tickets'];

    if (tickets is! List || tickets.isEmpty) {
      return false;
    }

    return tickets.every(
      (ticket) =>
          ticket is Map &&
          isTicketSold(Map<String, dynamic>.from(ticket)),
    );
  }

  static String getConcertStatus(Map<String, dynamic> concert) {
    if (isConcertFinished(concert)) {
      return 'Finished';
    }

    if (isConcertSoldOut(concert)) {
      return 'Sold Out';
    }

    final tickets = concert['tickets'];

    if (tickets is! List || tickets.isEmpty) {
      return 'No Tickets';
    }

    return 'Available';
  }

  // ==========================================
  // CART FUNCTIONS
  // ==========================================

  static bool canBuy(Map<String, dynamic> ticket) {
    return !isTicketSold(ticket);
  }

  static bool addToCart(Map<String, dynamic> ticket) {
    if (!canBuy(ticket)) {
      return false;
    }

    final ticketId = ticket['ticketId'] ?? ticket['id'];

    if (ticketId != null) {
      final alreadyAdded = items.any(
        (item) =>
            (item['ticketId'] ?? item['id']) == ticketId,
      );

      if (alreadyAdded) {
        return false;
      }
    }

    items.add(Map<String, dynamic>.from(ticket));

    return true;
  }

  static void removeFromCart(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  static double get totalPrice {
    return items.fold<double>(
      0,
      (total, item) {
        final price =
            double.tryParse(item['price'].toString()) ?? 0;

        return total + price;
      },
    );
  }

  // ==========================================
  // CREATE ORDER FROM CART
  // ==========================================

  static Map<String, dynamic>? createOrder() {
    if (items.isEmpty) return null;

    return createOrderFromItems(items);
  }

  static Map<String, dynamic>? createOrderFromItems(
    List<Map<String, dynamic>> sourceItems,
  ) {
    if (sourceItems.isEmpty) return null;

    // เช็คว่ามีออเดอร์ค้างชำระอยู่ก่อนแล้วหรือไม่
    if (hasActiveUnpaidOrder()) {
      return null;
    }

    final now = DateTime.now();

    final orderItems = sourceItems
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final orderTotal = orderItems.fold<double>(
      0,
      (total, item) {
        final price =
            double.tryParse(item['price'].toString()) ?? 0;

        return total + price;
      },
    );

    final order = <String, dynamic>{
      'orderId':
          'ORD${now.millisecondsSinceEpoch}$_orderCounter',
      'items': orderItems,
      'totalPrice': orderTotal,
      'orderDate': now,
      'paymentDeadline': now.add(paymentLimit),
      'status': 'To Pay',
      'paymentStatus': 'Unpaid',
      'shippingStatus': 'Waiting for payment',
      'trackingNumber': null,
      'timeline': [
        {
          'message': 'Order placed successfully.',
          'date': now.toString(),
        },
        {
          'message': 'Waiting for payment.',
          'date': now.toString(),
        },
      ],
    };

    _orderCounter++;

    history.add(order);

    items.clear();

    return order;
  }

  // ==========================================
  // PAYMENT COUNTDOWN & EXPIRE
  // ==========================================

  static DateTime? _getPaymentDeadline(
    Map<String, dynamic> order,
  ) {
    final value = order['paymentDeadline'];

    if (value is DateTime) {
      return value;
    }

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static Duration remainingPaymentTime(
    Map<String, dynamic> order,
  ) {
    final deadline = _getPaymentDeadline(order);

    if (deadline == null) {
      return Duration.zero;
    }

    final remaining = deadline.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  static String formatRemainingTime(
    Map<String, dynamic> order,
  ) {
    final remaining = remainingPaymentTime(order);

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static void refreshExpiredOrders() {
    final now = DateTime.now();

    for (final order in history) {
      if (order['status'] != 'To Pay') {
        continue;
      }

      final deadline = _getPaymentDeadline(order);

      if (deadline == null) {
        continue;
      }

      if (!now.isBefore(deadline)) {
        order['status'] = 'Cancelled';
        order['paymentStatus'] = 'Expired';
        order['shippingStatus'] = 'Payment expired';

        _addTimeline(
          order,
          'Order cancelled because payment time expired.',
        );
      }
    }
  }

  // ==========================================
  // ORDER ACTIONS (PAY, SHIP, RECEIVE)
  // ==========================================

  static bool payOrder(Map<String, dynamic> order) {
    refreshExpiredOrders();

    if (order['status'] != 'To Pay') {
      return false;
    }

    if (remainingPaymentTime(order) <= Duration.zero) {
      refreshExpiredOrders();
      return false;
    }

    order['status'] = 'To Ship';
    order['paymentStatus'] = 'Paid';
    order['shippingStatus'] =
        'Seller is preparing your ticket';

    _addTimeline(
      order,
      'Payment successful. Waiting for seller to ship.',
    );

    final orderItems = order['items'] as List?;
    if (orderItems != null) {
      for (final item in orderItems) {
        final listingId = item['listingId'];
        if (listingId != null) {
          final resIndex = resaleListings.indexWhere((res) => res['listingId'] == listingId);
          if (resIndex != -1) {
            resaleListings[resIndex]['status'] = 'Sold';
          }
        }
      }
    }

    return true;
  }

  static bool shipOrder(Map<String, dynamic> order) {
    if (order['status'] != 'To Ship') {
      return false;
    }

    final random = Random();

    final trackingCode =
        'TP${DateTime.now().millisecondsSinceEpoch}'
        '${random.nextInt(900) + 100}';

    order['status'] = 'To Receive';
    order['shippingStatus'] = 'Shipped';
    order['trackingNumber'] = trackingCode;

    _addTimeline(
      order,
      'Seller has shipped your ticket. Tracking: $trackingCode',
    );

    final orderItems = order['items'] as List?;
    if (orderItems != null) {
      for (final item in orderItems) {
        final listingId = item['listingId'];
        if (listingId != null) {
          markTicketAsShipped(listingId.toString());
        }
      }
    }

    return true;
  }

  static bool confirmReceived(
    Map<String, dynamic> order,
  ) {
    if (order['status'] != 'To Receive') {
      return false;
    }

    order['status'] = 'Completed';
    order['shippingStatus'] = 'Delivered & Received';
    order['receivedDate'] = DateTime.now();

    _addTimeline(
      order,
      'Buyer confirmed that the ticket was received.',
    );

    final orderItems = order['items'] as List?;
    if (orderItems != null) {
      for (final item in orderItems) {
        final listingId = item['listingId'];
        if (listingId != null) {
          final resIndex = resaleListings.indexWhere((res) => res['listingId'] == listingId);
          if (resIndex != -1) {
            resaleListings[resIndex]['status'] = 'Completed';
          }
        }
      }
    }

    return true;
  }

  static bool cancelOrder(Map<String, dynamic> order) {
    if (order['status'] != 'To Pay') {
      return false;
    }

    order['status'] = 'Cancelled';
    order['paymentStatus'] = 'Cancelled';
    order['shippingStatus'] = 'Order cancelled';

    _addTimeline(
      order,
      'Buyer cancelled the order.',
    );

    return true;
  }

  static void _addTimeline(
    Map<String, dynamic> order,
    String message,
  ) {
    final timeline = order['timeline'];

    if (timeline is List) {
      timeline.add({
        'message': message,
        'date': DateTime.now().toString(),
      });
    } else {
      order['timeline'] = [
        {
          'message': message,
          'date': DateTime.now().toString(),
        },
      ];
    }
  }

  static List<Map<String, dynamic>> getOrdersByStatus(
    String status,
  ) {
    refreshExpiredOrders();

    return history
        .where((order) => order['status'] == status)
        .toList()
        .reversed
        .toList();
  }

  static void completePurchase() {
    final order = createOrder();

    if (order != null) {
      payOrder(order);
    }
  }
}
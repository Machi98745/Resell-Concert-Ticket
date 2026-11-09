
class CartService {
  static final List<Map<String, dynamic>> items = [];
  static final List<Map<String, dynamic>> history = [];

  // แปลงวันที่คอนเสิร์ต
  static DateTime? _parseConcertDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      final parts = value.trim().split(RegExp(r'\s+'));

      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final year = int.tryParse(parts[2]);

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

      final month = months[parts[1].toLowerCase()];

      if (day == null || year == null || month == null) {
        return null;
      }

      return DateTime(year, month, day);
    }
  }

  // ตรวจสอบว่าคอนเสิร์ตจบแล้วหรือยัง
  static bool isConcertFinished(Map<String, dynamic> concert) {
    final date = _parseConcertDate(
      concert['date']?.toString() ?? '',
    );

    if (date == null) return false;

    final today = DateTime.now();

    return DateTime(today.year, today.month, today.day)
        .isAfter(DateTime(date.year, date.month, date.day));
  }

  // ตรวจสอบว่าบัตรถูกขายแล้วหรือไม่
  static bool isTicketSold(Map<String, dynamic> ticket) {
    final status = ticket['status']?.toString().toLowerCase();
    final condition = ticket['condition']?.toString().toLowerCase();

    return ticket['isSold'] == true ||
        ticket['available'] == false ||
        (ticket['quantity'] is num && ticket['quantity'] <= 0) ||
        status == 'sold' ||
        status == 'sold out' ||
        condition == 'sold' ||
        condition == 'sold out';
  }

  // ตรวจสอบว่าบัตรทุกใบขายหมดแล้วหรือไม่
  static bool isConcertSoldOut(Map<String, dynamic> concert) {
    final tickets = concert['tickets'];

    // ไม่มีบัตร ไม่ถือว่าขายหมด
    if (tickets == null || tickets is! List || tickets.isEmpty) {
      return false;
    }

    return tickets.every((ticket) {
      if (ticket is! Map) return true;

      return isTicketSold(
        Map<String, dynamic>.from(ticket),
      );
    });
  }

  // สถานะคอนเสิร์ต
  static String getConcertStatus(Map<String, dynamic> concert) {
    if (isConcertFinished(concert)) {
      return 'finished';
    }

    final tickets = concert['tickets'];

    if (tickets == null || tickets is! List || tickets.isEmpty) {
      return 'no tickets';
    }

    if (isConcertSoldOut(concert)) {
      return 'sold out';
    }

    return 'available';
  }

  // เพิ่มบัตรใหม่จากหน้าขายบัตร
  static bool addResaleTicket(
    Map<String, dynamic> concert,
    Map<String, dynamic> ticket,
  ) {
    if (isConcertFinished(concert)) return false;

    if (concert['tickets'] is! List) {
      concert['tickets'] = <Map<String, dynamic>>[];
    }

    ticket['status'] = 'available';
    ticket['condition'] = 'Available';
    ticket['isSold'] = false;
    ticket['available'] = true;

    concert['tickets'].add(ticket);

    return true;
  }

  // ตรวจสอบว่าสามารถซื้อบัตรได้หรือไม่
  static bool canBuy(
    Map<String, dynamic> concert,
    Map<String, dynamic> ticket,
  ) {
    return !isConcertFinished(concert) &&
        !isTicketSold(ticket);
  }

  // เพิ่มบัตรลงตะกร้า
  static bool addToCart(
    Map<String, dynamic> concert,
    Map<String, dynamic> ticket,
  ) {
    if (!canBuy(concert, ticket)) return false;

    items.add({
      'concertName': concert['name'],
      'artist': concert['artist'],
      'date': concert['date'],
      'location': concert['location'],
      'image': concert['image'],
      'seller': ticket['seller'] ?? 'Ticket Pink',
      'seat': ticket['seat'] ?? ticket['zone'] ?? '',
      'zone': ticket['zone'] ?? 'General',
      'price': ticket['price'] ?? 0,
      'condition': ticket['condition'] ?? 'Available',
    });

    return true;
  }

  // ลบบัตรออกจากตะกร้า
  static void removeFromCart(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  // เรียกใช้หลังชำระเงินสำเร็จ
  static void completePurchase() {
    if (items.isEmpty) return;

    final purchaseDate = DateTime.now();

    for (final item in items) {
      history.add({
        ...item,
        'purchaseDate': purchaseDate,
        'status': 'Purchased',
      });
    }

    items.clear();
  }

  // ราคารวมในตะกร้า
  static double get totalPrice {
    return items.fold(
      0.0,
      (total, item) =>
          total + ((item['price'] as num?)?.toDouble() ?? 0.0),
    );
  }
}

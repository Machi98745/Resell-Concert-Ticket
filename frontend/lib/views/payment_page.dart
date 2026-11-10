import 'dart:async';
import 'package:flutter/material.dart';
import 'cart_service.dart';
import 'historypage.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const PaymentPage({
    super.key,
    required this.items,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Color pinkAccent = const Color(0xFFFF4081);

  String delivery = 'Parcel Shipping';
  String payment = 'PromptPay';

  // คำนวณราคารวมตั๋วทั้งหมดจากข้อมูลที่รับเข้ามา
  int get price {
    final total = widget.items.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item['price'].toString()) ?? 0),
    );
    return total.round();
  }

  int time = 900; // 15 นาที
  Timer? timer;

  bool success = false;
  bool expired = false;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (time > 0) {
        setState(() {
          time--;
        });
      } else {
        t.cancel();
        setState(() {
          expired = true;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // แถวซ้าย-ขวา สำหรับ Order Summary
  Widget row(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(a), Text(b)],
        ),
      );

  @override
  Widget build(BuildContext context) {
    int fee = price * 2 ~/ 100; // ค่าคอมมิชชั่น 2%
    int ship = delivery == 'Parcel Shipping' ? 50 : 0;
    int totalPrice = price + fee + ship;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: expired
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_off, size: 70, color: Colors.pink),
                  const SizedBox(height: 12),
                  const Text(
                    'Reservation Expired',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Your reservation has expired.'),
                ],
              ),
            )
          : success
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 80, color: pinkAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'Payment Successful!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Paid Total: ฿$totalPrice',
                          style: TextStyle(
                            fontSize: 18,
                            color: pinkAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Thank you for your purchase!',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pinkAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HistoryPage(),
                              ),
                              (route) => route.isFirst,
                            );
                          },
                          child: const Text('Go to Order History'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reservation Timer
                      Card(
                        child: ListTile(
                          title: const Text('Reservation Time'),
                          subtitle: Text(
                            '${(time ~/ 60).toString().padLeft(2, '0')}:'
                            '${(time % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 30,
                              color: pinkAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Order Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Order Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                ...widget.items.map((item) {
                                  final name = item['concertName'] ??
                                      item['name'] ??
                                      item['concert'] ??
                                      'Concert Ticket';
                                  final seat = item['seat'] ?? item['zone'] ?? '-';
                                  final itemPrice =
                                      double.tryParse(item['price'].toString()) ?? 0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Zone / Seat: $seat',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '฿${itemPrice.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: pinkAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(),
                                row('Ticket Price', '฿$price'),
                                row('Commission Fee (2%)', '฿$fee'),
                                if (ship > 0) row('Shipping Fee', '฿$ship'),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Delivery
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              DropdownButton<String>(
                                value: delivery,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Parcel Shipping',
                                    child: Text('Parcel Shipping'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Digital Transfer',
                                    child: Text('Digital Transfer'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      delivery = value;
                                    });
                                  }
                                },
                              ),
                              if (delivery == 'Parcel Shipping') ...[
                                const TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Recipient Name',
                                  ),
                                ),
                                const TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                  ),
                                ),
                                const TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Shipping Address',
                                  ),
                                ),
                                const TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Province / Postal Code',
                                  ),
                                ),
                              ] else ...[
                                const TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Payment Method
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Payment Method',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              RadioListTile<String>(
                                title: const Text('PromptPay'),
                                value: 'PromptPay',
                                groupValue: payment,
                                activeColor: pinkAccent,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      payment = value;
                                    });
                                  }
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('Credit / Debit Card'),
                                value: 'Credit / Debit Card',
                                groupValue: payment,
                                activeColor: pinkAccent,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      payment = value;
                                    });
                                  }
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('TrueMoney Wallet'),
                                value: 'TrueMoney Wallet',
                                groupValue: payment,
                                activeColor: pinkAccent,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      payment = value;
                                    });
                                  }
                                },
                              ),
                              const Divider(),
                              if (payment == 'PromptPay')
                                Column(
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      size: 100,
                                      color: pinkAccent,
                                    ),
                                    const Text('Scan QR Code'),
                                  ],
                                ),
                              if (payment == 'Credit / Debit Card') ...[
                                const TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Card Number',
                                  ),
                                ),
                                const TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Cardholder Name',
                                  ),
                                ),
                                const TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Expiry Date',
                                  ),
                                ),
                                const TextField(
                                  decoration: InputDecoration(labelText: 'CVV'),
                                ),
                              ],
                              if (payment == 'TrueMoney Wallet')
                                const TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Mobile Number',
                                  ),
                                ),
                              const SizedBox(height: 15),
                              Text(
                                'Total Payment: ฿$totalPrice',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: pinkAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: pinkAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      success = true;
                                      timer?.cancel();
                                      // สั่งล้างข้อมูลในตระกร้าและบันทึกคำสั่งซื้อ
                                      CartService.completePurchase();
                                    });
                                  },
                                  child: const Text('Pay Now'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
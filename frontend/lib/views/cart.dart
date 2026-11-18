
import 'package:flutter/material.dart';
import 'package:frontend/controller/payment_controller.dart';
import 'package:frontend/server/api_service.dart';

import 'cart_service.dart';
import 'payment_page.dart';
import 'historypage.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final PaymentController _paymentController = PaymentController();

  bool isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    ApiService.ensureCurrentUserCart().then((_) {
      if (mounted) setState(() {});
    });
  }

  // แจ้งเตือนเมื่อมีรายการค้างชำระ
  void _showPendingOrderDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pending Order',
                style: TextStyle(
                  color: darkPink,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'You already have a pending ticket reservation. '
          'Please complete payment or cancel your previous order '
          'before reserving new tickets.',
          style: TextStyle(
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryPage(),
                ),
              );
            },
            child: const Text('Go to My Orders'),
          ),
        ],
      ),
    );
  }

  // ยืนยันคำสั่งซื้อและบันทึกลง MySQL
  Future<void> _checkout() async {
    if (isCheckingOut) return;

    if (CartService.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty.'),
        ),
      );
      return;
    }

    // ตรวจสอบรายการค้างชำระ
    if (CartService.hasActiveUnpaidOrder()) {
      _showPendingOrderDialog();
      return;
    }

    // ยืนยันก่อนสร้างรายการ
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Confirm Order',
          style: TextStyle(
            color: darkPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Do you want to proceed to payment?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: pink,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final checkoutItems = CartService.items
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    setState(() {
      isCheckingOut = true;
    });

    try {
      // สร้างรายการ Pending ในฐานข้อมูล
      for (final item in checkoutItems) {
        final rawListingId = item['listing_id'] ?? item['id'];

        final listingId = int.tryParse(
          rawListingId?.toString() ?? '',
        );

        if (listingId == null || listingId <= 0) {
          throw Exception(
            'Unable to find ticket listing ID.',
          );
        }

        final result = await _paymentController.checkout(
          listingId: listingId,
          paymentMethod: 'PromptPay',
          deliveryMethod: 'Parcel Shipping',
          shippingInfo: 'To be provided',
        );

        final paymentData = result['payment'] is Map
            ? Map<String, dynamic>.from(result['payment'])
            : result;

        final paymentId = paymentData['payment_id'];

        if (paymentId == null) {
          throw Exception(
            'Unable to create payment record.',
          );
        }

        // ส่ง payment_id ไปยัง PaymentPage
        item['payment_id'] = paymentId;
      }

      // ล้างตะกร้าของ User ปัจจุบันหลังสร้างรายการรอชำระเงินแล้ว
      CartService.items.clear();

      if (!mounted) return;

      // เปิดหน้าชำระเงินหลังสร้างรายการสำเร็จ
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            items: checkoutItems,
          ),
        ),
      );

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCheckingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = CartService.items;

    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: darkPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 0,
      ),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 75,
                    color: pink,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: darkPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Add some tickets to get started!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      final price = double.tryParse(
                            (item['price'] ?? item['resell_price'] ?? 0)
                                .toString(),
                          ) ??
                          0;

                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: item['image'] != null
                                    ? Image.network(
                                        item['image'].toString(),
                                        width: 85,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) {
                                          return _imagePlaceholder();
                                        },
                                      )
                                    : _imagePlaceholder(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['concertName']?.toString() ??
                                          item['name']?.toString() ??
                                          'Concert',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: darkPink,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Artist: ${item['artist'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Seller: ${item['seller'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Seat: ${item['seat'] ?? item['seat_number'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '฿${price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: pink,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: isCheckingOut
                                    ? null
                                    : () {
                                        setState(() {
                                          CartService.removeFromCart(index);
                                        });
                                      },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Total and Checkout Button
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    24,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: darkPink,
                            ),
                          ),
                          Text(
                            '฿${CartService.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 21,
                              color: pink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isCheckingOut ? null : _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isCheckingOut
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Proceed to Payment',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
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

  Widget _imagePlaceholder() {
    return Container(
      width: 85,
      height: 100,
      color: lightPink,
      child: const Icon(
        Icons.music_note,
        size: 35,
        color: pink,
      ),
    );
  }
}

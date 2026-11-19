import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/controller/payment_controller.dart';
import 'cart_service.dart';
import 'historypage.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const PaymentPage({super.key, required this.items});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final Color pinkAccent = const Color(0xFFFF4081);
  final PaymentController _paymentController = PaymentController();

  String delivery = 'Parcel Shipping';
  String payment = 'PromptPay';

  Map<String, dynamic>? currentOrder;
  Timer? timer;
  int remainingSeconds = 900;

  bool isProcessing = false;
  bool success = false;
  bool expired = false;

  // Form Key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Delivery Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _provinceZipController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Payment Controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  final TextEditingController _walletPhoneController = TextEditingController();

  int get price {
    int sum = 0;
    for (final item in widget.items) {
      final value = item['price'] ?? item['resell_price'];
      if (value is num) {
        sum += value.round();
      } else {
        sum += num.tryParse(value?.toString() ?? '')?.round() ?? 0;
      }
    }
    return sum;
  }

  String formatMoney(int amount) {
    return '฿${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }

  @override
  void initState() {
    super.initState();
    _initOrderAndTimer();
  }

  void _initOrderAndTimer() {
    // 1. ดึงเวลานับถอยหลังจาก Backend payment record (ถ้ามี)
    int? backendRemaining;
    for (final item in widget.items) {
      final expiresAt = item['expires_at']?.toString();
      if (expiresAt != null && expiresAt.isNotEmpty) {
        final sec = PaymentController.getRemainingSeconds(expiresAt);
        if (sec > 0) {
          backendRemaining = sec;
          break;
        }
      }
    }

    // 2. ถ้าเป็นออเดอร์ใหม่ หรือไม่มี active order ให้รีเซ็ตเวลาใหม่เต็ม 15 นาที
    final unpaidOrders = CartService.getOrdersByStatus('To Pay');

    if (unpaidOrders.isNotEmpty) {
      currentOrder = unpaidOrders.first;
    } else if (widget.items.isNotEmpty) {
      currentOrder = CartService.createOrderFromItems(widget.items);
    } else {
      currentOrder = null;
    }

    if (backendRemaining != null && backendRemaining > 0) {
      remainingSeconds = backendRemaining;
      if (currentOrder != null) {
        currentOrder!['paymentDeadline'] =
            DateTime.now().add(Duration(seconds: backendRemaining));
      }
    } else if (currentOrder != null) {
      // รีเซ็ตเวลากลับมาเต็มโควต้าหากสร้างใหม่
      final deadline = currentOrder!['paymentDeadline'];
      if (deadline is! DateTime || deadline.isBefore(DateTime.now())) {
        currentOrder!['paymentDeadline'] =
            DateTime.now().add(CartService.paymentLimit);
      }
      remainingSeconds = CartService.remainingPaymentTime(currentOrder!).inSeconds;
    } else {
      remainingSeconds = CartService.paymentLimit.inSeconds;
    }

    _updateTime();
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (remainingSeconds <= 0) {
      timer?.cancel();
      if (mounted) {
        setState(() {
          expired = true;
          remainingSeconds = 0;
        });
      }
      return;
    }

    if (currentOrder != null && currentOrder!['status'] == 'Cancelled') {
      timer?.cancel();
      if (mounted) {
        setState(() {
          expired = true;
          remainingSeconds = 0;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        remainingSeconds--;
        if (remainingSeconds <= 0) {
          expired = true;
          remainingSeconds = 0;
          timer?.cancel();
        }
      });
    }
  }

  // ==========================================================================
  // CANCEL ORDER (ยกเลิกคำสั่งซื้อจากหน้า Payment)
  // ==========================================================================
  Future<void> _cancelPaymentOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Cancel Order',
              style: TextStyle(
                color: Color(0xFF54283D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this order? '
          'The reserved ticket will be released immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    timer?.cancel();

    // 1. ยกเลิกใน CartService (in-memory)
    if (currentOrder != null) {
      CartService.cancelOrder(currentOrder!);
    }
    for (final order in CartService.getOrdersByStatus('To Pay')) {
      CartService.cancelOrder(order);
    }

    // 2. ยกเลิกใน Backend ผ่าน API (ถ้ามี payment_id)
    try {
      for (final item in widget.items) {
        final pid = int.tryParse((item['payment_id'] ?? '').toString());
        if (pid != null && pid > 0) {
          await _paymentController.cancelPayment(paymentId: pid);
        }
      }
    } catch (e) {
      debugPrint('Cancel payment on backend error: $e');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order cancelled successfully. Ticket has been released.'),
        backgroundColor: Colors.redAccent,
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    timer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _provinceZipController.dispose();
    _emailController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _walletPhoneController.dispose();
    super.dispose();
  }

  String _buildShippingInfo() {
    if (delivery == 'Parcel Shipping') {
      return '${_nameController.text.trim()} | '
          'Tel: ${_phoneController.text.trim()} | '
          '${_addressController.text.trim()}, '
          '${_provinceZipController.text.trim()}';
    }
    return 'Email: ${_emailController.text.trim()}';
  }

  int? _extractListingId(Map<String, dynamic> item) {
    final raw = item['listing_id'] ?? item['id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  Future<void> _validateAndPay() async {
  if (isProcessing) return;

  if (widget.items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No tickets selected'),
      ),
    );
    return;
  }

  if (!(_formKey.currentState?.validate() ?? false)) {
    return;
  }

  final shippingInfo = _buildShippingInfo();

  setState(() {
    isProcessing = true;
  });

  try {
    for (final item in widget.items) {
      int paymentId;

      final existingPaymentId = int.tryParse(
        (item['payment_id'] ?? '').toString(),
      );

      if (existingPaymentId != null && existingPaymentId > 0) {
        paymentId = existingPaymentId;

        await _paymentController.getPaymentById(
          paymentId: paymentId,
        );
      } else {
        final listingId = _extractListingId(item);

        if (listingId == null || listingId <= 0) {
          throw Exception('Missing listing ID');
        }

        final createdRes = await _paymentController.checkout(
          listingId: listingId,
          paymentMethod: payment,
          deliveryMethod: delivery,
          shippingInfo: shippingInfo,
        );

        final paymentObj = createdRes['payment'] is Map
            ? Map<String, dynamic>.from(createdRes['payment'])
            : Map<String, dynamic>.from(createdRes);

        final rawPaymentId = paymentObj['payment_id'];

        if (rawPaymentId == null) {
          throw Exception('Payment ID not found');
        }

        paymentId = int.parse(rawPaymentId.toString());
      }

      // ยืนยันการชำระเงินเฉพาะเมื่อกด Pay Now
      await _paymentController.confirmPayment(
        paymentId: paymentId,
      );
    }

    if (!mounted) return;

    setState(() {
      isProcessing = false;
      success = true;
      timer?.cancel();
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceAll('Exception: ', ''),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

  Widget row(String a, String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(a), Text(b)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    int fee = price * 2 ~/ 100;
    int ship = delivery == 'Parcel Shipping' ? 50 : 0;
    int totalPrice = price + fee + ship;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: pinkAccent,
        foregroundColor: Colors.white,
        actions: [
          if (!expired && !success)
            TextButton(
              onPressed: isProcessing ? null : _cancelPaymentOrder,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: expired
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_off, size: 70, color: Colors.pink),
                    const SizedBox(height: 12),
                    const Text(
                      'Reservation Expired',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your reservation has expired and ticket has been released.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pinkAccent,
                      ),
                      child: const Text(
                        'Back to Concert Detail',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
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
                      'Paid Total: ${formatMoney(totalPrice)}',
                      style: TextStyle(
                        fontSize: 18,
                        color: pinkAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your payment has been recorded and ticket ownership transferred.',
                      textAlign: TextAlign.center,
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
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reservation Timer
                    Card(
                      child: ListTile(
                        title: const Text('Reservation Time Remaining'),
                        subtitle: Text(
                          '${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:'
                          '${(remainingSeconds % 60).toString().padLeft(2, '0')}',
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
                              if (widget.items.isEmpty)
                                const Text('No tickets selected'),
                              ...widget.items.map((item) {
                                final name =
                                    item['concertName'] ??
                                    item['concert_title'] ??
                                    item['name'] ??
                                    item['concert'] ??
                                    'Concert Ticket';
                                final zone =
                                    item['zone'] ?? item['zone_name'] ?? '-';
                                final seat =
                                    item['seat'] ?? item['seat_number'] ?? '-';
                                final itemPrice =
                                    num.tryParse(
                                      (item['price'] ??
                                              item['resell_price'] ??
                                              '0')
                                          .toString(),
                                    )?.round() ??
                                    0;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Zone $zone · Seat $seat',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          formatMoney(itemPrice),
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
                              row('Ticket Price', formatMoney(price)),
                              row('Commission Fee (2%)', formatMoney(fee)),
                              if (ship > 0)
                                row('Shipping Fee', formatMoney(ship)),
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
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Recipient Name',
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter recipient name';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter phone number';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: 'Shipping Address',
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter shipping address';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _provinceZipController,
                                decoration: const InputDecoration(
                                  labelText: 'Province / Postal Code',
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter province and postal code';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter email address';
                                  }
                                  if (!RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(val.trim())) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
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
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      size: 100,
                                      color: pinkAccent,
                                    ),
                                    const Text('Scan QR Code'),
                                  ],
                                ),
                              ),
                            if (payment == 'Credit / Debit Card') ...[
                              TextFormField(
                                controller: _cardNumberController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Card Number',
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter card number';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _cardNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Cardholder Name',
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter cardholder name';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _cardExpiryController,
                                decoration: const InputDecoration(
                                  labelText: 'Expiry Date',
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter expiry date';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _cardCvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter CVV';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            if (payment == 'TrueMoney Wallet')
                              TextFormField(
                                controller: _walletPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile Number',
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter mobile number';
                                  }
                                  return null;
                                },
                              ),
                            const SizedBox(height: 15),
                            Text(
                              'Total Payment: ${formatMoney(totalPrice)}',
                              style: TextStyle(
                                fontSize: 20,
                                color: pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: pinkAccent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: isProcessing
                                    ? null
                                    : _validateAndPay,
                                child: isProcessing
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text('Pay Now'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                onPressed: isProcessing
                                    ? null
                                    : _cancelPaymentOrder,
                                child: const Text(
                                  'Cancel Order',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

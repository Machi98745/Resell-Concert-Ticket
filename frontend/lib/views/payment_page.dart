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
  final Color pinkAccent = const Color(0xFFFF4081);

  String delivery = 'Parcel Shipping';
  String payment = 'PromptPay';

  Map<String, dynamic>? currentOrder;
  Timer? timer;
  int remainingSeconds = 900;

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
    final total = widget.items.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item['price'].toString()) ?? 0),
    );
    return total.round();
  }

  @override
  void initState() {
    super.initState();
    _initOrderAndTimer();
  }

  void _initOrderAndTimer() {
    final unpaidOrders = CartService.getOrdersByStatus('To Pay');
    
    if (unpaidOrders.isNotEmpty) {
      currentOrder = unpaidOrders.first;
    } else {
      currentOrder = CartService.createOrderFromItems(widget.items);
    }

    _updateTime();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (currentOrder == null) return;

    final duration = CartService.remainingPaymentTime(currentOrder!);
    
    if (duration <= Duration.zero || currentOrder!['status'] == 'Cancelled') {
      timer?.cancel();
      if (mounted) {
        setState(() {
          expired = true;
          remainingSeconds = 0;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          remainingSeconds = duration.inSeconds;
        });
      }
    }
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

  void _validateAndPay() {
    if (_formKey.currentState?.validate() ?? false) {
      if (currentOrder != null) {
        setState(() {
          CartService.payOrder(currentOrder!);
          success = true;
          timer?.cancel();
        });
      }
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
                  const Text('Your reservation has expired and ticket has been released.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: pinkAccent),
                    child: const Text('Back to Concert Detail', style: TextStyle(color: Colors.white)),
                  ),
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
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Recipient Name',
                                      errorStyle: TextStyle(color: Colors.redAccent),
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
                                      errorStyle: TextStyle(color: Colors.redAccent),
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
                                      errorStyle: TextStyle(color: Colors.redAccent),
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
                                      errorStyle: TextStyle(color: Colors.redAccent),
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
                                      errorStyle: TextStyle(color: Colors.redAccent),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Please enter email address';
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
                                  TextFormField(
                                    controller: _cardNumberController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Card Number',
                                      errorStyle: TextStyle(color: Colors.redAccent),
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
                                      errorStyle: TextStyle(color: Colors.redAccent),
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
                                      errorStyle: TextStyle(color: Colors.redAccent),
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
                                      errorStyle: TextStyle(color: Colors.redAccent),
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
                                      errorStyle: TextStyle(color: Colors.redAccent),
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
                                    onPressed: _validateAndPay,
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
                ),
    );
  }
}
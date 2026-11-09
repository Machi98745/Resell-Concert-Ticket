import 'package:flutter/material.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const CheckoutPage({
    super.key,
    required this.items,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  String paymentMethod = 'Bank Transfer';

  double get totalPrice {
    return widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0),
    );
  }

  String formatPrice(dynamic price) {
    final value = (price as num?)?.toStringAsFixed(0) ?? '0';
    return '฿${value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  void confirmPayment() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 65,
              ),
              const SizedBox(height: 15),
              const Text(
                'Order Confirmed!',
                style: TextStyle(
                  color: darkPink,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your order has been submitted successfully.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: pink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: darkPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 21,
                  color: darkPink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              ...widget.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: lightPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number,
                        color: pink,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['concertName']?.toString() ?? 'Concert',
                              style: const TextStyle(
                                color: darkPink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item['seat']?.toString() ??
                                  item['zone']?.toString() ??
                                  'General',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatPrice(item['price']),
                        style: const TextStyle(
                          color: pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 21,
                  color: darkPink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              _field(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _field(
                controller: emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                type: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _field(
                controller: phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                type: TextInputType.phone,
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Enter a 10-digit phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 21,
                  color: darkPink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              RadioListTile<String>(
                value: 'Bank Transfer',
                groupValue: paymentMethod,
                activeColor: pink,
                title: const Text('Bank Transfer'),
                onChanged: (value) {
                  setState(() => paymentMethod = value!);
                },
              ),
              RadioListTile<String>(
                value: 'PromptPay',
                groupValue: paymentMethod,
                activeColor: pink,
                title: const Text('PromptPay'),
                onChanged: (value) {
                  setState(() => paymentMethod = value!);
                },
              ),

              const Divider(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkPink,
                    ),
                  ),
                  Text(
                    formatPrice(totalPrice),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: pink,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm Payment',
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
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: pink),
        filled: true,
        fillColor: lightPink,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'cart_service.dart';

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

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  String paymentMethod = 'Bank Transfer';

  double get totalPrice {
    return widget.items.fold<double>(
      0,
      (sum, item) {
        return sum +
            (double.tryParse(item['price'].toString()) ?? 0);
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

  void confirmPayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty.'),
        ),
      );
      return;
    }

    final order = CartService.createOrderFromItems(
      widget.items,
    );

    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create order.'),
        ),
      );
      return;
    }

    order['buyerName'] = nameController.text.trim();
    order['email'] = emailController.text.trim();
    order['phone'] = phoneController.text.trim();
    order['paymentMethod'] = paymentMethod;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Order Created!',
            style: TextStyle(
              color: pink,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Your order has been created successfully.\n\n'
            'Please complete your payment within 15 minutes.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context, true);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: darkPink,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }

            if (label == 'Email' &&
                !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                    .hasMatch(value.trim())) {
              return 'Please enter a valid email';
            }

            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: pink,
            ),
            filled: true,
            fillColor: lightPink,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: pink,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final name = item['concertName'] ??
        item['name'] ??
        item['concert'] ??
        'Concert Ticket';

    final price =
        double.tryParse(item['price'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(14),
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
            child: Text(
              name.toString(),
              style: const TextStyle(
                color: darkPink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '฿${price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: pink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkPink,
                ),
              ),
              const SizedBox(height: 18),

              _field(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: nameController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _field(
                label: 'Email',
                hint: 'Enter your email',
                controller: emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _field(
                label: 'Phone Number',
                hint: 'Enter your phone number',
                controller: phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 28),

              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkPink,
                ),
              ),
              const SizedBox(height: 14),

              if (widget.items.isEmpty)
                const Text('No items in your cart.')
              else
                ...widget.items.map(_buildOrderItem),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
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
                      '฿${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: pink,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkPink,
                ),
              ),
              const SizedBox(height: 14),

              _paymentOption(
                title: 'Bank Transfer',
                subtitle: 'Pay through bank transfer',
                value: 'Bank Transfer',
                icon: Icons.account_balance,
              ),

              const SizedBox(height: 10),

              _paymentOption(
                title: 'PromptPay',
                subtitle: 'Pay using PromptPay',
                value: 'PromptPay',
                icon: Icons.qr_code,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Confirm Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final selected = paymentMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          paymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? lightPink : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? pink : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: pink, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkPink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: paymentMethod,
              activeColor: pink,
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    paymentMethod = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
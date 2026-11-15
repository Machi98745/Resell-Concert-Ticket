import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const PaymentPage({super.key, required this.items});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const Color pink = Color(0xFFFF4081);
  static const Color background = Color(0xFFFFF5F8);

  String delivery = 'Parcel Shipping';
  String payment = 'PromptPay';
  String page = 'checkout';

  int selectedAddress = 0;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();

  final cardNumberController = TextEditingController();
  final cardNameController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();
  final walletController = TextEditingController();

  final addressFormKey = GlobalKey<FormState>();
  final cardFormKey = GlobalKey<FormState>();
  final walletFormKey = GlobalKey<FormState>();

  final List<Map<String, String>> addresses = [
    {
      'label': 'Home',
      'name': 'Somying Jaidee',
      'phone': '0812345678',
      'address': '99/12 Moo 3, Mueang Phayao, Phayao 56000',
    },
    {
      'label': 'Dormitory',
      'name': 'Somying Jaidee',
      'phone': '0891112233',
      'address': '88/5 Mae Ka, Mueang Phayao, Phayao 56000',
    },
    {
      'label': 'Work',
      'name': 'Somying Jaidee',
      'phone': '0865557788',
      'address': '125 Phahonyothin Road, Phayao 56000',
    },
  ];

  int get ticketPrice {
    int sum = 0;

    for (final item in widget.items) {
      final value = item['price'];

      if (value is num) {
        sum += value.round();
      } else {
        sum += num.tryParse(value?.toString() ?? '')?.round() ?? 0;
      }
    }

    return sum;
  }

  int get fee => ticketPrice * 2 ~/ 100;

  int get shipping => delivery == 'Parcel Shipping' ? 50 : 0;

  int get total => ticketPrice + fee + shipping;

  String money(int amount) {
    return '฿${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    emailController.dispose();
    cardNumberController.dispose();
    cardNameController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    walletController.dispose();
    super.dispose();
  }

  void changePage(String nextPage) {
    setState(() {
      page = nextPage;
    });
  }

  void completePayment() {
    // Frontend-only payment flow for the project.
    // No real money is charged or transferred.
    setState(() {
      page = 'success';
    });
  }

  void goBack() {
    if (page == 'newAddress') {
      changePage('addresses');
    } else if (page == 'addresses' ||
        page == 'qr' ||
        page == 'card' ||
        page == 'wallet' ||
        page == 'success') {
      changePage('checkout');
    } else {
      Navigator.maybePop(context);
    }
  }

  void continuePayment() {
    if (widget.items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No tickets selected')));
      return;
    }

    if (delivery == 'Digital Transfer') {
      final email = emailController.text.trim();

      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')),
        );
        return;
      }
    }

    if (payment == 'PromptPay') {
      changePage('qr');
    } else if (payment == 'Credit / Debit Card') {
      changePage('card');
    } else {
      changePage('wallet');
    }
  }

  Widget panel(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget heading(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: pink),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget button(String text, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: pink),
        ),
      ),
    );
  }

  Widget priceRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isTotal ? pink : Colors.black87,
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget checkoutPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading(
                Icons.confirmation_number_outlined,
                'Concert Information',
              ),
              const SizedBox(height: 15),
              if (widget.items.isEmpty) const Text('No tickets selected'),
              for (final item in widget.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: pink,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (item['concertName'] ??
                                      item['name'] ??
                                      item['concert'] ??
                                      'Concert Ticket')
                                  .toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Zone ${item['zone'] ?? '-'} · "
                              "Seat ${item['seat'] ?? '-'}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        money(
                          num.tryParse(item['price']?.toString() ?? '0')
                                  ?.round() ??
                              0,
                        ),
                        style: const TextStyle(
                          color: pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading(Icons.local_shipping_outlined, 'Delivery Information'),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: delivery,
                decoration: const InputDecoration(border: OutlineInputBorder()),
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
              const SizedBox(height: 14),
              if (delivery == 'Parcel Shipping')
                InkWell(
                  onTap: () => changePage('addresses'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: pink),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Addresses',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${addresses[selectedAddress]['name']} · '
                                '${addresses[selectedAddress]['phone']}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                addresses[selectedAddress]['address'] ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: pink),
                      ],
                    ),
                  ),
                )
              else
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading(Icons.credit_card_outlined, 'Payment Method'),
              const SizedBox(height: 8),
              for (final method in [
                'PromptPay',
                'Credit / Debit Card',
                'TrueMoney Wallet',
              ])
                RadioListTile<String>(
                  title: Text(method),
                  value: method,
                  groupValue: payment,
                  activeColor: pink,
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    method == 'PromptPay'
                        ? Icons.qr_code_2
                        : method == 'Credit / Debit Card'
                        ? Icons.credit_card
                        : Icons.account_balance_wallet_outlined,
                    color: pink,
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        payment = value;
                      });
                    }
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading(Icons.receipt_long_outlined, 'Payment Summary'),
              const SizedBox(height: 12),
              priceRow('Ticket Price', money(ticketPrice)),
              priceRow('Commission Fee (2%)', money(fee)),
              if (shipping > 0) priceRow('Shipping Fee', money(shipping)),
              const Divider(),
              priceRow('Total Payment', money(total), isTotal: true),
              const SizedBox(height: 15),
              button('Pay Now', continuePayment),
            ],
          ),
        ),
      ],
    );
  }

  Widget addressesPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select Delivery Address',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < addresses.length; i++) ...[
          InkWell(
            onTap: () {
              setState(() {
                selectedAddress = i;
                page = 'checkout';
              });
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedAddress == i ? pink : Colors.black12,
                  width: selectedAddress == i ? 2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selectedAddress == i
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selectedAddress == i ? pink : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${addresses[i]['name']} · '
                          '${addresses[i]['phone']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(addresses[i]['address'] ?? ''),
                        const SizedBox(height: 6),
                        Text(
                          addresses[i]['label'] ?? '',
                          style: const TextStyle(color: pink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: () => changePage('newAddress'),
          icon: const Icon(Icons.add),
          label: const Text('Enter New Address'),
          style: OutlinedButton.styleFrom(
            foregroundColor: pink,
            side: const BorderSide(color: pink),
          ),
        ),
      ],
    );
  }

  Widget newAddressPage() {
    return panel(
      Form(
        key: addressFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading(Icons.add_location_alt_outlined, 'New Shipping Address'),
            const SizedBox(height: 20),
            field('Recipient Name', nameController),
            const SizedBox(height: 12),
            field(
              'Phone Number',
              phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            field('Full Address', addressController),
            const SizedBox(height: 20),
            button('Save & Use This Address', () {
              if (!addressFormKey.currentState!.validate()) {
                return;
              }

              setState(() {
                addresses.add({
                  'label': 'Other',
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'address': addressController.text.trim(),
                });

                selectedAddress = addresses.length - 1;
                page = 'checkout';
              });

              nameController.clear();
              phoneController.clear();
              addressController.clear();
            }),
          ],
        ),
      ),
    );
  }

  Widget qrPage() {
    return panel(
      Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'PromptPay',
            style: TextStyle(
              color: pink,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          Container(
            width: 230,
            height: 230,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_2,
              size: 200,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Total Payment', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            money(total),
            style: const TextStyle(
              color: pink,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Please confirm your payment',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          button('Confirm Payment', completePayment),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget cardPage() {
    return panel(
      Form(
        key: cardFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading(Icons.credit_card, 'Credit / Debit Card'),
            const SizedBox(height: 20),
            field(
              'Card Number',
              cardNumberController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            field('Cardholder Name', cardNameController),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: field('MM/YY', expiryController)),
                const SizedBox(width: 12),
                Expanded(
                  child: field(
                    'CVV',
                    cvvController,
                    keyboardType: TextInputType.number,
                    obscure: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            priceRow('Total Payment', money(total), isTotal: true),
            const SizedBox(height: 15),
            button('Pay Now', () {
              if (cardFormKey.currentState!.validate()) {
                completePayment();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget walletPage() {
    return panel(
      Form(
        key: walletFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading(Icons.account_balance_wallet_outlined, 'TrueMoney Wallet'),
            const SizedBox(height: 20),
            field(
              'Mobile Number',
              walletController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            priceRow('Total Payment', money(total), isTotal: true),
            const SizedBox(height: 15),
            button('Pay Now', () {
              if (walletFormKey.currentState!.validate()) {
                completePayment();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget successPage() {
    return panel(
      Column(
        children: [
          const SizedBox(height: 35),
          const Icon(Icons.check_circle, color: Colors.green, size: 90),
          const SizedBox(height: 20),
          const Text(
            'Payment Successful!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your order has been placed successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Text(
            money(total),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: pink,
            ),
          ),
          const SizedBox(height: 35),
          button('Back to Checkout', () {
            changePage('checkout');
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Payment';
    Widget content;

    switch (page) {
      case 'addresses':
        title = 'Your Addresses';
        content = addressesPage();
        break;

      case 'newAddress':
        title = 'Add New Address';
        content = newAddressPage();
        break;

      case 'qr':
        title = 'PromptPay';
        content = qrPage();
        break;

      case 'card':
        title = 'Credit / Debit Card';
        content = cardPage();
        break;

      case 'wallet':
        title = 'TrueMoney Wallet';
        content = walletPage();
        break;

      case 'success':
        title = 'Payment Successful';
        content = successPage();
        break;

      default:
        content = checkoutPage();
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: pink,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }
}

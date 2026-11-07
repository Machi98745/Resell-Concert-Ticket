
import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    this.concertName = 'ใบเตยคนที่สวยที่สุดในโลก',
    this.date = 'Sat, Mar 8, 2025, 19:00',
    this.zone = 'A',
    this.seat = 'A1',
    this.quantity = 1,
    this.total = 1500,
  });

  final String concertName;
  final String date;
  final String zone;
  final String seat;
  final int quantity;
  final double total;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String paymentMethod = 'credit_card';
  final Color pink = const Color(0xFFF23883);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/concert_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              color: const Color.fromRGBO(25, 0, 30, 0.35),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 960,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(
                        255, 255, 255, 0.94,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth > 680;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Page title
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mic,
                                  color: pink,
                                  size: 36,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Payment',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: pink,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 25),

                            if (wide)
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 280,
                                    height: 460,
                                    child: artistImage(),
                                  ),
                                  const SizedBox(width: 28),
                                  Expanded(
                                    child: paymentDetails(),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  SizedBox(
                                    width: 220,
                                    height: 270,
                                    child: artistImage(),
                                  ),
                                  const SizedBox(height: 24),
                                  paymentDetails(),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Artist image
  Widget artistImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/images/baitoey.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const ColoredBox(
            color: Color(0xFFF5E5EF),
            child: Icon(
              Icons.person,
              size: 100,
              color: Colors.pink,
            ),
          );
        },
      ),
    );
  }

  // Payment information
  Widget paymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.concertName,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 20),

        infoRow(Icons.calendar_month, 'Date', widget.date),
        infoRow(Icons.location_on, 'Zone', widget.zone),
        infoRow(Icons.event_seat, 'Seat', widget.seat),
        infoRow(
          Icons.confirmation_number,
          'Quantity',
          '${widget.quantity} Ticket(s)',
        ),

        const SizedBox(height: 15),
        Divider(color: pink, thickness: 1),
        const SizedBox(height: 15),

        Text(
          'Total: ${widget.total.toStringAsFixed(2)} THB',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: pink,
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        DropdownButtonFormField<String>(
          value: paymentMethod,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.credit_card,
              color: pink,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: pink, width: 1.5),
            ),
          ),
          items: const [
  DropdownMenuItem(
    value: 'credit_card',
    child: Text('Credit Card'),
  ),
  DropdownMenuItem(
    value: 'promptpay',
    child: Text('PromptPay'),
  ),
  DropdownMenuItem(
    value: 'truemoney',
    child: Text('TrueMoney Wallet'),
  ),
],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                paymentMethod = value;
              });
            }
          },
        ),

        const SizedBox(height: 22),

        // Confirm payment
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: confirmPayment,
            icon: const Icon(Icons.lock_outline),
            label: const Text(
              'Confirm Payment',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Back button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: pink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(icon, color: pink, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Demo confirmation only (not connected to a payment gateway)
  void confirmPayment() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text(
            'Payment Method: $paymentMethod\n'
            'Total: ${widget.total.toStringAsFixed(2)} THB\n\n'
            'Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Demo only: Payment gateway is not connected yet.',
                    ),
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}

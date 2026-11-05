
import 'package:flutter/material.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  String? selectedTicket;
  final TextEditingController price = TextEditingController();

  final List<String> tickets = [
    'Concert A - Zone A',
    'Concert B - Zone B',
    'Concert C - VIP',
  ];

  @override
  void dispose() {
    price.dispose();
    super.dispose();
  }

  void sellTicket() {
    if (selectedTicket == null || price.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }

    final amount = double.tryParse(price.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket information is ready'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Sell Ticket',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/concert_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                  ),
                  child: Card(
                    color: Colors.white.withValues(alpha: 0.92),
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Icon(
                              Icons.confirmation_number,
                              size: 55,
                              color: Colors.pinkAccent,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Center(
                            child: Text(
                              'Sell Your Ticket',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.pinkAccent,
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          const Text(
                            'Select your ticket',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          DropdownButtonFormField<String>(
                            initialValue: selectedTicket,
                            isExpanded: true,
                            hint: const Text('Choose ticket'),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Colors.pinkAccent,
                                  width: 2,
                                ),
                              ),
                            ),
                            items: tickets.map((ticket) {
                              return DropdownMenuItem(
                                value: ticket,
                                child: Text(ticket),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedTicket = value;
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            'Selling Price (THB)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextField(
                            controller: price,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your price',
                              prefixIcon: const Icon(
                                Icons.payments,
                                color: Colors.pinkAccent,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Colors.pinkAccent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: sellTicket,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Confirm Sell',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

import 'dart:async';
import 'package:flutter/material.dart';


class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});


  @override
  State<PaymentPage> createState() => _PaymentPageState();
}


class _PaymentPageState extends State<PaymentPage> {
  Color pinkAccent = const Color(0xFFFF4081);


  String delivery = 'Parcel Shipping';
  String payment = 'PromptPay';


  int time = 900;
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


  @override
  Widget build(BuildContext context) {
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
                  const Icon(Icons.timer_off,
                      size: 70, color: Colors.pink),
                  const Text(
                    'Reservation Expired',
                    style: TextStyle(fontSize: 22),
                  ),
                  const Text('Your reservation has expired.'),
                ],
              ),
            )
          : success
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          size: 80, color: pinkAccent),
                      const Text(
                        'Payment Successful!',
                        style: TextStyle(fontSize: 24),
                      ),
                      const Text('BODYSLAM EVERYBODYSLAM 2026'),
                      const Text('VIP A1 / A1-02'),
                      const Text('Thank you for your purchase!'),
                    ],
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
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: const [
                              Text('Order Summary',
                                  style: TextStyle(fontSize: 18)),
                              SizedBox(height: 10),
                              Text(
                                  'BODYSLAM EVERYBODYSLAM 2026'),
                              Text('Zone / Seat: VIP A1 / A1-02'),
                              Text('Ticket Price: ฿4,200'),
                            ],
                          ),
                        ),
                      ),


                      // Delivery
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Delivery Information'),
                              DropdownButton(
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
                                  setState(() {
                                    delivery = value!;
                                  });
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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Payment Method',
                                style: TextStyle(fontSize: 18),
                              ),


                              RadioListTile(
                                title: const Text('PromptPay'),
                                value: 'PromptPay',
                                groupValue: payment,
                                activeColor: pinkAccent,
                                onChanged: (value) {
                                  setState(() {
                                    payment = value!;
                                  });
                                },
                              ),


                              RadioListTile(
                                title: const Text(
                                    'Credit / Debit Card'),
                                value: 'Credit / Debit Card',
                                groupValue: payment,
                                activeColor: pinkAccent,
                                onChanged: (value) {
                                  setState(() {
                                    payment = value!;
                                  });
                                },
                              ),


                              RadioListTile(
                                title: const Text(
                                    'TrueMoney Wallet'),
                                value: 'TrueMoney Wallet',
                                groupValue: payment,
                                activeColor: pinkAccent,
                                onChanged: (value) {
                                  setState(() {
                                    payment = value!;
                                  });
                                },
                              ),


                              const Divider(),


                              if (payment == 'PromptPay')
                                Column(
                                  children: [
                                    Icon(Icons.qr_code,
                                        size: 100,
                                        color: pinkAccent),
                                    const Text('Scan QR Code'),
                                  ],
                                ),


                              if (payment ==
                                  'Credit / Debit Card') ...[
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
                                  decoration: InputDecoration(
                                    labelText: 'CVV',
                                  ),
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
                                'Total Payment: '
                                '฿${delivery == 'Parcel Shipping' ? 4250 : 4200}',
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
                                      // Demo: simulate payment result
                                      success = true;
                                      timer?.cancel();
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
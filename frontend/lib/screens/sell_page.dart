import 'package:flutter/material.dart';


class SellPage extends StatefulWidget {
  const SellPage({super.key});


  @override
  State<SellPage> createState() => _SellPageState();
}


class _SellPageState extends State<SellPage> {
  String? selectedTicket;
  TextEditingController price = TextEditingController();


  List<String> tickets = [
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
        const SnackBar(content: Text('Please fill in all fields')),
      );
    } else if (double.tryParse(price.text) == null ||
        double.parse(price.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket information is ready')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Ticket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your ticket',
              style: TextStyle(fontSize: 18),
            ),


            DropdownButton<String>(
              value: selectedTicket,
              hint: const Text('Choose ticket'),
              isExpanded: true,
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


            const SizedBox(height: 20),


            const Text(
              'Selling Price (THB)',
              style: TextStyle(fontSize: 18),
            ),


            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter price',
                border: OutlineInputBorder(),
              ),
            ),


            const SizedBox(height: 30),


            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sellTicket,
                child: const Text('Confirm Sell'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
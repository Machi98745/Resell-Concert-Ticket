import 'package:flutter/material.dart';


class SellPage extends StatefulWidget {
  const SellPage({super.key});


  @override
  State<SellPage> createState() => _SellPageState();
}


class _SellPageState extends State<SellPage> {
  // Colors
  final Color pink = Colors.pinkAccent;
  final Color lightPink = const Color(0xFFFFF0F5);


  // Page: 0 = Sell, 1 = Review, 2 = Success
  int page = 0;


  // Mock ticket data
  List<String> tickets = [
    'BODYSLAM - VIP A1 - A1-02',
    'BODYSLAM - VIP A1 - A1-88',
    'BODYSLAM - VIP A1 - A1-55',
  ];


  String selectedTicket = 'BODYSLAM - VIP A1 - A1-02';


  // Form values
  TextEditingController priceController =
      TextEditingController(text: '4200');


  TextEditingController shippingController =
      TextEditingController(text: '50');


  TextEditingController appController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController accountController = TextEditingController();


  String deliveryMethod = 'Parcel Shipping';
  String shippingCompany = 'Thailand Post';
  String transferApp = 'Email (PDF)';
  String? bank;


  double get price =>
      double.tryParse(priceController.text) ?? 0;


  double get shippingFee => deliveryMethod == 'Parcel Shipping'
      ? double.tryParse(shippingController.text) ?? 0
      : 0;


  double get total => price + shippingFee;


  @override
  void dispose() {
    priceController.dispose();
    shippingController.dispose();
    appController.dispose();
    noteController.dispose();
    nameController.dispose();
    accountController.dispose();
    super.dispose();
  }


  // Check form before review
  void goToReview() {
    if (price <= 0 || !price.isFinite) {
      showMessage('Please enter a valid selling price.');
      return;
    }


    if (deliveryMethod == 'Parcel Shipping' &&
        (shippingController.text.trim().isEmpty ||
            shippingFee < 0 ||
            !shippingFee.isFinite)) {
      showMessage('Please enter a valid shipping fee.');
      return;
    }


    if (deliveryMethod == 'Digital Transfer' &&
        transferApp == 'Other Application' &&
        appController.text.trim().isEmpty) {
      showMessage('Please enter the application name.');
      return;
    }


    if (bank == null ||
        nameController.text.trim().isEmpty ||
        !RegExp(r'^\d{9,15}$')
            .hasMatch(accountController.text.trim())) {
      showMessage('Please complete your payout account.');
      return;
    }


    setState(() {
      page = 1;
    });
  }


  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  // Input field
  Widget inputBox(
    String label,
    TextEditingController controller, {
    bool number = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        maxLines: lines,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: pink, width: 2),
          ),
        ),
      ),
    );
  }


  Widget title(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  Widget pinkBox(Widget child) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }


  Widget mainButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
        ),
        child: Text(text),
      ),
    );
  }


  // First page
  Widget sellForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title('Ticket Details'),


        DropdownButtonFormField<String>(
          value: selectedTicket,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Select Your Ticket',
            border: OutlineInputBorder(),
          ),
          items: tickets.map((ticket) {
            return DropdownMenuItem(
              value: ticket,
              child: Text(
                ticket,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedTicket = value!;
            });
          },
        ),


        const SizedBox(height: 15),


        pinkBox(
          Column(
            children: [
              detail('Concert', 'BODYSLAM EVERYBODYSLAM 2026'),
              detail('Date', '15 Dec 2026'),
              detail('Venue', 'Impact Arena'),
              detail('Zone', 'VIP A1'),
              detail('Seat', selectedTicket.split(' - ').last),
              detail('Original Price', 'THB 4500'),
            ],
          ),
        ),


        const Divider(height: 30),


        title('Selling Price'),
        inputBox(
          'Selling Price (THB)',
          priceController,
          number: true,
        ),


        const Divider(),


        title('Ticket Delivery Method'),


        RadioListTile<String>(
          title: const Text('Parcel Shipping'),
          value: 'Parcel Shipping',
          groupValue: deliveryMethod,
          activeColor: pink,
          onChanged: (value) {
            setState(() {
              deliveryMethod = value!;
            });
          },
        ),


        RadioListTile<String>(
          title: const Text('Digital Transfer'),
          value: 'Digital Transfer',
          groupValue: deliveryMethod,
          activeColor: pink,
          onChanged: (value) {
            setState(() {
              deliveryMethod = value!;
            });
          },
        ),


        if (deliveryMethod == 'Parcel Shipping') ...[
          const SizedBox(height: 10),


          DropdownButtonFormField<String>(
            value: shippingCompany,
            decoration: const InputDecoration(
              labelText: 'Shipping Company',
              border: OutlineInputBorder(),
            ),
            items: [
              'Thailand Post',
              'Flash Express',
              'Kerry Express',
            ].map((company) {
              return DropdownMenuItem(
                value: company,
                child: Text(company),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                shippingCompany = value!;
              });
            },
          ),


          const SizedBox(height: 15),


          inputBox(
            'Shipping Fee (THB)',
            shippingController,
            number: true,
          ),
        ] else ...[
          const SizedBox(height: 10),


          ...[
            'Email (PDF)',
            'Eventpop App',
            'I Have Ticket App',
            'Ticketier App',
            'Other Application',
          ].map((app) {
            return RadioListTile<String>(
              title: Text(app),
              value: app,
              groupValue: transferApp,
              activeColor: pink,
              onChanged: (value) {
                setState(() {
                  transferApp = value!;
                });
              },
            );
          }),


          if (transferApp == 'Other Application')
            inputBox('Application Name', appController),
        ],


        inputBox(
          'Delivery Notes (Optional)',
          noteController,
          lines: 2,
        ),


        const Divider(),


        title('Payout Account'),


        DropdownButtonFormField<String>(
          value: bank,
          decoration: const InputDecoration(
            labelText: 'Bank Name',
            border: OutlineInputBorder(),
          ),
          items: [
            'Bangkok Bank',
            'Kasikornbank',
            'SCB',
            'Krungthai Bank',
            'Krungsri',
          ].map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              bank = value;
            });
          },
        ),


        const SizedBox(height: 15),


        inputBox('Account Holder Name', nameController),
        inputBox(
          'Bank Account Number',
          accountController,
          number: true,
        ),


        const Text(
          'Demo only. Do not enter real bank details.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),


        const SizedBox(height: 20),


        pinkBox(
          Column(
            children: [
              detail('Selling Price', 'THB ${price.toStringAsFixed(2)}'),
              detail(
                'Shipping Fee',
                'THB ${shippingFee.toStringAsFixed(2)}',
              ),
              const Divider(),
              detail('Buyer Total', 'THB ${total.toStringAsFixed(2)}'),
            ],
          ),
        ),


        const SizedBox(height: 20),


        mainButton('Continue to Review', goToReview),
      ],
    );
  }


  // Review page
  Widget reviewPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title('Review Your Listing'),


        pinkBox(
          Column(
            children: [
              detail('Ticket', selectedTicket),
              detail('Selling Price', 'THB ${price.toStringAsFixed(2)}'),
              detail('Delivery Method', deliveryMethod),


              if (deliveryMethod == 'Parcel Shipping') ...[
                detail('Shipping Company', shippingCompany),
                detail(
                  'Shipping Fee',
                  'THB ${shippingFee.toStringAsFixed(2)}',
                ),
              ] else
                detail(
                  'Transfer Channel',
                  transferApp == 'Other Application'
                      ? appController.text
                      : transferApp,
                ),


              if (noteController.text.trim().isNotEmpty)
                detail('Delivery Notes', noteController.text),


              const Divider(),


              detail('Bank', bank ?? ''),
              detail('Account Holder', nameController.text),
              detail(
                'Account Number',
                'Ending in ${accountController.text.trim().substring(accountController.text.trim().length - 4)}',
              ),


              const Divider(),


              detail('Buyer Total', 'THB ${total.toStringAsFixed(2)}'),
            ],
          ),
        ),


        const SizedBox(height: 20),


        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    page = 0;
                  });
                },
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: mainButton('Confirm Sell', () {
                setState(() {
                  page = 2;
                });
              }),
            ),
          ],
        ),
      ],
    );
  }


  // Success page
  Widget successPage() {
    return Column(
      children: [
        Icon(Icons.check_circle, color: pink, size: 75),
        const SizedBox(height: 15),


        const Text(
          'Listing Created!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),


        const SizedBox(height: 10),


        const Text(
          'Your ticket listing has been created in this demo.',
          textAlign: TextAlign.center,
        ),


        const SizedBox(height: 20),


        pinkBox(
          Column(
            children: [
              detail('Ticket', selectedTicket),
              detail('Selling Price', 'THB ${price.toStringAsFixed(2)}'),
            ],
          ),
        ),


        const SizedBox(height: 20),


        mainButton('Create Another Listing', () {
          setState(() {
            page = 0;
            selectedTicket = tickets.first;
            deliveryMethod = 'Parcel Shipping';
            shippingCompany = 'Thailand Post';
            transferApp = 'Email (PDF)';
            bank = null;
            priceController.text = '4200';
            shippingController.text = '50';
            appController.clear();
            noteController.clear();
            nameController.clear();
            accountController.clear();
          });
        }),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        title: const Text('Sell Your Ticket'),
        backgroundColor: pink,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        key: ValueKey(page),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: page == 0
                ? sellForm()
                : page == 1
                    ? reviewPage()
                    : successPage(),
          ),
        ),
      ),
    );
  }
}
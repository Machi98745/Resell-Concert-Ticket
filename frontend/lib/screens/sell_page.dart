import 'package:flutter/material.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  Color pink = Colors.pinkAccent;
  Color lightPink = const Color(0xFFFFF0F5);

  int page = 0; // 0 = form, 1 = review, 2 = success

  // Text fields
  var concert = TextEditingController();
  var date = TextEditingController();
  var venue = TextEditingController();
  var zone = TextEditingController();
  var seat = TextEditingController();
  var originalPrice = TextEditingController();
  var price = TextEditingController(text: '4200');
  var shipping = TextEditingController(text: '50');
  var appName = TextEditingController();
  var note = TextEditingController();
  var accName = TextEditingController();
  var accNumber = TextEditingController();

  // Choices
  String delivery = 'Parcel Shipping';
  String company = 'Thailand Post';
  String channel = 'Email (PDF)';
  String? bank;

  // Numbers
  double get priceNum => double.tryParse(price.text) ?? 0;
  double get shipNum =>
      delivery == 'Parcel Shipping' ? double.tryParse(shipping.text) ?? 0 : 0;
  double get total => priceNum + shipNum;

  // Returns an error message, or null if everything is OK
  String? check() {
    if (concert.text.trim().isEmpty) return 'Please enter the concert name.';
    if (date.text.trim().isEmpty) return 'Please enter the date and time.';
    if (venue.text.trim().isEmpty) return 'Please enter the venue.';
    if (zone.text.trim().isEmpty) return 'Please enter the zone.';
    if (seat.text.trim().isEmpty) return 'Please enter your seat.';
    if ((double.tryParse(originalPrice.text) ?? 0) <= 0) {
      return 'Please enter a valid original price.';
    }
    if (priceNum <= 0) return 'Please enter a valid selling price.';
    if (delivery == 'Parcel Shipping' &&
        (shipping.text.trim().isEmpty || shipNum < 0)) {
      return 'Please enter a valid shipping fee.';
    }
    if (delivery == 'Digital Transfer' &&
        channel == 'Other Application' &&
        appName.text.trim().isEmpty) {
      return 'Please enter the application name.';
    }
    if (bank == null ||
        accName.text.trim().isEmpty ||
        !RegExp(r'^\d{9,15}$').hasMatch(accNumber.text.trim())) {
      return 'Please complete your payout account.';
    }
    return null;
  }

  void goToReview() {
    String? error = check();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      setState(() => page = 1);
    }
  }

  void reset() {
    for (var c in [
      concert,
      date,
      venue,
      zone,
      seat,
      originalPrice,
      appName,
      note,
      accName,
      accNumber,
    ]) {
      c.clear();
    }
    setState(() {
      page = 0;
      price.text = '4200';
      shipping.text = '50';
      delivery = 'Parcel Shipping';
      company = 'Thailand Post';
      channel = 'Email (PDF)';
      bank = null;
    });
  }

  // ---------- small helpers ----------

  Widget field(
    String label,
    TextEditingController c, {
    bool number = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        maxLines: lines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget title(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget row(String label, String value) {
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

  Widget pinkBox(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget button(String text, VoidCallback onTap) {
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

  // ---------- page 1: form ----------

  Widget sellForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title('Ticket Details'),
        field('Concert Name', concert),
        field('Date & Time (e.g. 15 Dec 2026, 18:00)', date),
        field('Venue', venue),
        field('Zone', zone),
        field('Seat', seat),
        field('Original Price (THB)', originalPrice, number: true),

        title('Selling Price'),
        field('Selling Price (THB)', price, number: true),

        title('Ticket Delivery Method'),
        RadioListTile<String>(
          title: const Text('Parcel Shipping'),
          value: 'Parcel Shipping',
          groupValue: delivery,
          activeColor: pink,
          onChanged: (v) => setState(() => delivery = v!),
        ),
        RadioListTile<String>(
          title: const Text('Digital Transfer'),
          value: 'Digital Transfer',
          groupValue: delivery,
          activeColor: pink,
          onChanged: (v) => setState(() => delivery = v!),
        ),

        if (delivery == 'Parcel Shipping') ...[
          DropdownButtonFormField<String>(
            value: company,
            decoration: const InputDecoration(
              labelText: 'Shipping Company',
              border: OutlineInputBorder(),
            ),
            items: [
              'Thailand Post',
              'Flash Express',
              'Kerry Express',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => company = v!),
          ),
          const SizedBox(height: 15),
          field('Shipping Fee (THB)', shipping, number: true),
        ] else
          // Separate box so it looks different from the group above
          Container(
            margin: const EdgeInsets.only(left: 16, bottom: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightPink,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pink),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select transfer channel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                for (var app in [
                  'Email (PDF)',
                  'Eventpop App',
                  'I Have Ticket App',
                  'Ticketier App',
                  'Other Application',
                ])
                  RadioListTile<String>(
                    title: Text(app),
                    value: app,
                    groupValue: channel,
                    activeColor: pink,
                    dense: true,
                    onChanged: (v) => setState(() => channel = v!),
                  ),
                if (channel == 'Other Application')
                  field('Application Name', appName),
              ],
            ),
          ),

        field('Delivery Notes (Optional)', note, lines: 2),

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
          ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: (v) => setState(() => bank = v),
        ),
        const SizedBox(height: 15),
        field('Account Holder Name', accName),
        field('Bank Account Number', accNumber, number: true),
        const Text(
          'Demo only. Do not enter real bank details.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 20),

        pinkBox([
          row('Selling Price', 'THB ${priceNum.toStringAsFixed(2)}'),
          row('Shipping Fee', 'THB ${shipNum.toStringAsFixed(2)}'),
          const Divider(),
          row('Buyer Total', 'THB ${total.toStringAsFixed(2)}'),
        ]),
        const SizedBox(height: 20),

        button('Continue to Review', goToReview),
      ],
    );
  }

  // ---------- page 2: review ----------

  Widget reviewPage() {
    String acc = accNumber.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title('Review Your Listing'),
        pinkBox([
          row('Concert', concert.text.trim()),
          row('Date & Time', date.text.trim()),
          row('Venue', venue.text.trim()),
          row('Zone', zone.text.trim()),
          row('Seat', seat.text.trim()),
          row('Original Price', 'THB ${originalPrice.text}'),
          const Divider(),
          row('Selling Price', 'THB ${priceNum.toStringAsFixed(2)}'),
          row('Delivery Method', delivery),
          if (delivery == 'Parcel Shipping') ...[
            row('Shipping Company', company),
            row('Shipping Fee', 'THB ${shipNum.toStringAsFixed(2)}'),
          ] else
            row(
              'Transfer Channel',
              channel == 'Other Application' ? appName.text : channel,
            ),
          if (note.text.trim().isNotEmpty) row('Delivery Notes', note.text),
          const Divider(),
          row('Bank', bank ?? ''),
          row('Account Holder', accName.text),
          row('Account Number', 'Ending in ${acc.substring(acc.length - 4)}'),
          const Divider(),
          row('Buyer Total', 'THB ${total.toStringAsFixed(2)}'),
        ]),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => page = 0),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: button('Confirm Sell', () => setState(() => page = 2)),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- page 3: success ----------

  Widget successPage() {
    return Column(
      children: [
        Icon(Icons.check_circle, color: pink, size: 75),
        const SizedBox(height: 15),
        const Text(
          'Listing Created!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your ticket listing has been created in this demo.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        pinkBox([
          row('Ticket', '${concert.text.trim()} - ${seat.text.trim()}'),
          row('Selling Price', 'THB ${priceNum.toStringAsFixed(2)}'),
        ]),
        const SizedBox(height: 20),
        button('Create Another Listing', reset),
      ],
    );
  }

  // ---------- main ----------

  @override
  Widget build(BuildContext context) {
    Widget body = page == 0
        ? sellForm()
        : page == 1
        ? reviewPage()
        : successPage();

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
            child: body,
          ),
        ),
      ),
    );
  }
}

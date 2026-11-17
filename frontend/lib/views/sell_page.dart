
import 'package:flutter/material.dart';
import 'package:frontend/server/api_service.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final Color pink = Colors.pinkAccent;
  final Color lightPink = const Color(0xFFFFF0F5);

  int page = 0; // 0 = form, 1 = review, 2 = success

  List<Map<String, dynamic>> myTickets = [];
  Map<String, dynamic>? selectedTicket;

  bool isLoadingTickets = false;
  bool isSubmitting = false;

  int? createdListingId;

  // Text controllers
  final concert = TextEditingController();
  final date = TextEditingController();
  final venue = TextEditingController();
  final zone = TextEditingController();
  final seat = TextEditingController();
  final originalPrice = TextEditingController();

  final price = TextEditingController(text: '4200');
  final shipping = TextEditingController(text: '50');

  final appName = TextEditingController();
  final note = TextEditingController();

  final accName = TextEditingController();
  final accNumber = TextEditingController();

  // Delivery choices
  String delivery = 'Parcel Shipping';
  String company = 'Thailand Post';
  String channel = 'Email (PDF)';
  String? bank;

  double get priceNum => double.tryParse(price.text) ?? 0;

  double get shipNum {
    if (delivery == 'Parcel Shipping') {
      return double.tryParse(shipping.text) ?? 0;
    }
    return 0;
  }

  double get total => priceNum + shipNum;

  @override
  void initState() {
    super.initState();
    loadMyTickets();
  }

  @override
  void dispose() {
    concert.dispose();
    date.dispose();
    venue.dispose();
    zone.dispose();
    seat.dispose();
    originalPrice.dispose();
    price.dispose();
    shipping.dispose();
    appName.dispose();
    note.dispose();
    accName.dispose();
    accNumber.dispose();
    super.dispose();
  }

  // ==========================================
  // LOAD MY TICKETS
  // ==========================================

  Future<void> loadMyTickets() async {
    if (isLoadingTickets) return;

    setState(() {
      isLoadingTickets = true;
    });

    try {
      final tickets = await ApiService.getMyTickets();

      if (!mounted) return;

      setState(() {
        myTickets = tickets;
        isLoadingTickets = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingTickets = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot load your tickets: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // SELECT TICKET
  // ==========================================

  Future<void> chooseConcert() async {
    if (isLoadingTickets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading your tickets. Please wait.'),
        ),
      );
      return;
    }

    if (myTickets.isEmpty) {
      await loadMyTickets();

      if (!mounted) return;

      if (myTickets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have no tickets available for resale.'),
          ),
        );
        return;
      }
    }

    final searchController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        List<Map<String, dynamic>> results = List.from(myTickets);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Your Ticket'),
              content: SizedBox(
                width: 420,
                height: 350,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search concert name...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          results = myTickets.where((item) {
                            final name =
                                item['concert_title']?.toString() ?? '';

                            final artist =
                                item['artist']?.toString() ?? '';

                            return name
                                    .toLowerCase()
                                    .contains(value.toLowerCase()) ||
                                artist
                                    .toLowerCase()
                                    .contains(value.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: results.isEmpty
                          ? const Center(
                              child: Text('No tickets found.'),
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final ticket = results[index];

                                final name =
                                    ticket['concert_title']?.toString() ??
                                        'Unknown Concert';

                                final artist =
                                    ticket['artist']?.toString() ?? '';

                                final ticketZone =
                                    ticket['zone_name']?.toString() ?? '';

                                final ticketSeat =
                                    ticket['seat_number']?.toString() ?? '';

                                final ticketVenue =
                                    ticket['venue']?.toString() ?? '';

                                return Card(
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.confirmation_number,
                                      color: pink,
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '$artist\n'
                                      '$ticketVenue\n'
                                      'Zone: $ticketZone | Seat: $ticketSeat',
                                    ),
                                    isThreeLine: true,
                                    onTap: () {
                                      Navigator.pop(
                                        dialogContext,
                                        ticket,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      selectedTicket = result;

      concert.text =
          result['concert_title']?.toString() ?? '';

      date.text =
          result['show_datetime']?.toString() ?? '';

      venue.text =
          result['venue']?.toString() ?? '';

      zone.text =
          result['zone_name']?.toString() ?? '';

      seat.text =
          result['seat_number']?.toString() ?? '';

      originalPrice.text =
          result['original_price']?.toString() ?? '';
    });
  }

  // ==========================================
  // VALIDATION
  // ==========================================

  String? check() {
    if (selectedTicket == null ||
        selectedTicket!['ticket_id'] == null) {
      return 'Please select one of your tickets.';
    }

    if (concert.text.trim().isEmpty) {
      return 'Please select a concert.';
    }

    if (zone.text.trim().isEmpty) {
      return 'Please enter the zone.';
    }

    if (seat.text.trim().isEmpty) {
      return 'Please enter your seat.';
    }

    if ((double.tryParse(originalPrice.text) ?? 0) <= 0) {
      return 'Invalid original ticket price.';
    }

    if (priceNum <= 0) {
      return 'Please enter a valid selling price.';
    }

    if (delivery == 'Parcel Shipping') {
      if (shipping.text.trim().isEmpty || shipNum < 0) {
        return 'Please enter a valid shipping fee.';
      }
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

  // ==========================================
  // GO TO REVIEW
  // ==========================================

  void goToReview() {
    final error = check();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() {
      page = 1;
    });
  }

  // ==========================================
  // CREATE LISTING
  // POST /api/resell/create
  // ==========================================

  Future<void> submitListing() async {
    if (isSubmitting) return;

    final error = check();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final transferNote = delivery == 'Digital Transfer'
          ? 'Transfer Channel: ${channel == 'Other Application' ? appName.text.trim() : channel}'
          : null;

      final notes = [
        if (transferNote != null) transferNote,
        if (note.text.trim().isNotEmpty) note.text.trim(),
      ].join('\n');

      final result = await ApiService.createResellListing({
        'ticket_id': selectedTicket!['ticket_id'],
        'resell_price': priceNum,
        'delivery_type': delivery,
        'shipping_company':
            delivery == 'Parcel Shipping' ? company : null,
        'shipping_fee': shipNum,
        'delivery_note': notes.isEmpty ? null : notes,
        'bank_name': bank,
        'bank_account_name': accName.text.trim(),
        'bank_account_number': accNumber.text.trim(),
      });

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        page = 2;
        createdListingId =
            int.tryParse(result['listing_id']?.toString() ?? '');
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create listing: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ==========================================
  // RESET
  // ==========================================

  void reset() {
    for (final controller in [
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
      controller.clear();
    }

    setState(() {
      page = 0;
      selectedTicket = null;
      createdListingId = null;

      price.text = '4200';
      shipping.text = '50';

      delivery = 'Parcel Shipping';
      company = 'Thailand Post';
      channel = 'Email (PDF)';
      bank = null;
    });

    loadMyTickets();
  }

  // ==========================================
  // REUSABLE WIDGETS
  // ==========================================

  Widget field(
    String label,
    TextEditingController controller, {
    bool number = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: lines,
        keyboardType:
            number ? TextInputType.number : TextInputType.text,
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
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget pinkBox(List<Widget> children) {
    return Container(
      width: double.infinity,
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

  // ==========================================
  // SELL FORM
  // ==========================================

  Widget sellForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title('Ticket Details'),

        InkWell(
          onTap: chooseConcert,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Select Your Ticket',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              selectedTicket == null
                  ? 'Choose one of your tickets'
                  : concert.text,
            ),
          ),
        ),

        if (isLoadingTickets)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),

        if (!isLoadingTickets && myTickets.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No tickets available. Please check your ticket history.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),

        const SizedBox(height: 15),

        if (selectedTicket != null) ...[
          pinkBox([
            row('Concert', concert.text),
            row('Date & Time', date.text),
            row('Venue', venue.text),
            row('Zone', zone.text),
            row('Seat', seat.text),
            row('Original Price', 'THB ${originalPrice.text}'),
          ]),
          const SizedBox(height: 15),
        ],

        title('Selling Price'),

        field('Selling Price (THB)', price, number: true),

        title('Ticket Delivery Method'),

        RadioListTile<String>(
          title: const Text('Parcel Shipping'),
          value: 'Parcel Shipping',
          groupValue: delivery,
          activeColor: pink,
          onChanged: (v) {
            if (v != null) {
              setState(() => delivery = v);
            }
          },
        ),

        RadioListTile<String>(
          title: const Text('Digital Transfer'),
          value: 'Digital Transfer',
          groupValue: delivery,
          activeColor: pink,
          onChanged: (v) {
            if (v != null) {
              setState(() => delivery = v);
            }
          },
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
            ].map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => company = v);
              }
            },
          ),

          const SizedBox(height: 15),

          field('Shipping Fee (THB)', shipping, number: true),
        ] else
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
                for (final app in [
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
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => channel = v);
                      }
                    },
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
          ].map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (v) {
            setState(() => bank = v);
          },
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

  // ==========================================
  // REVIEW PAGE
  // ==========================================

  Widget reviewPage() {
    final acc = accNumber.text.trim();

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

          if (note.text.trim().isNotEmpty)
            row('Delivery Notes', note.text.trim()),

          const Divider(),

          row('Bank', bank ?? ''),
          row('Account Holder', accName.text.trim()),
          row(
            'Account Number',
            'Ending in ${acc.substring(acc.length - 4)}',
          ),

          const Divider(),

          row('Buyer Total', 'THB ${total.toStringAsFixed(2)}'),
        ]),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        setState(() => page = 0);
                      },
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: isSubmitting ? null : submitListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Confirm Sell'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // SUCCESS PAGE
  // ==========================================

  Widget successPage() {
    return Column(
      children: [
        Icon(
          Icons.check_circle,
          color: pink,
          size: 75,
        ),

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
          'Your ticket listing has been created successfully.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        pinkBox([
          row(
            'Ticket',
            '${concert.text.trim()} - ${seat.text.trim()}',
          ),
          row('Selling Price', 'THB ${priceNum.toStringAsFixed(2)}'),
          if (createdListingId != null)
            row('Listing ID', createdListingId.toString()),
        ]),

        const SizedBox(height: 20),

        button('Done', () {
          Navigator.pop(context, true);
        }),

        const SizedBox(height: 10),

        TextButton(
          onPressed: reset,
          child: Text(
            'Sell Another Ticket',
            style: TextStyle(color: pink),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (page == 0) {
      body = sellForm();
    } else if (page == 1) {
      body = reviewPage();
    } else {
      body = successPage();
    }

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

import 'package:flutter/material.dart';
import 'package:frontend/controller/resell_controller.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final Color pink = const Color(0xFFE85D9E);
  final Color lightPink = const Color(0xFFFFF0F5);
  final Color darkPink = const Color(0xFF54283D);

  final ResellController _resellController = ResellController();

  int page = 0; // 0 = form, 1 = review, 2 = success

  List<Map<String, dynamic>> concerts = [];
  Map<String, dynamic>? selectedConcert;

  bool isLoadingConcerts = false;
  bool isSubmitting = false;

  int? createdListingId;

  // ข้อมูลคอนเสิร์ต (ดึงจากคอนเสิร์ตที่เลือก)
  final concert = TextEditingController();
  final artist = TextEditingController();
  final date = TextEditingController();
  final venue = TextEditingController();

  // ข้อมูลบัตรที่ผู้ขายกรอกเอง (ตรงตามตาราง tickets)
  final ticketCode = TextEditingController();
  final zone = TextEditingController();
  final seat = TextEditingController();
  final originalPrice = TextEditingController();

  // ราคาขายและค่าส่ง (ตรงตามตาราง resell_listings)
  final price = TextEditingController();
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

  double get originalPriceNum =>
      double.tryParse(originalPrice.text.trim()) ?? 0;

  double get maxAllowedPrice => originalPriceNum * 5;

  double get priceNum => double.tryParse(price.text.trim()) ?? 0;

  bool get isPriceExceedingLimit =>
      originalPriceNum > 0 && priceNum > maxAllowedPrice;

  double get shipNum {
    if (delivery == 'Parcel Shipping') {
      return double.tryParse(shipping.text.trim()) ?? 0;
    }
    return 0;
  }

  double get total => priceNum + shipNum;

  @override
  void initState() {
    super.initState();
    loadConcerts();
  }

  @override
  void dispose() {
    concert.dispose();
    artist.dispose();
    date.dispose();
    venue.dispose();
    ticketCode.dispose();
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
  // LOAD CONCERTS FROM BACKEND
  // ==========================================

  Future<void> loadConcerts() async {
    if (isLoadingConcerts) return;

    setState(() {
      isLoadingConcerts = true;
    });

    try {
      final list = await _resellController.getConcerts();

      if (!mounted) return;

      setState(() {
        concerts = list;
        isLoadingConcerts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingConcerts = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot load concerts: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatShowDateTime(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return raw?.toString() ?? 'Date TBA';
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final y = parsed.year;
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$d/$m/$y  $hh:$mm';
  }

  // ==========================================
  // SELECT CONCERT (DROPDOWN LIST + SEARCH)
  // ==========================================

  Future<void> chooseConcert() async {
    if (isLoadingConcerts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading concerts. Please wait.')),
      );
      return;
    }

    if (concerts.isEmpty) {
      await loadConcerts();
      if (!mounted || concerts.isEmpty) return;
    }

    final searchController = TextEditingController();

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        List<Map<String, dynamic>> filtered = List.from(concerts);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.music_note_rounded, color: pink),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Select Concert',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search concert title, artist, or venue...',
                          prefixIcon: Icon(Icons.search, color: pink),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    setSheetState(() {
                                      filtered = List.from(concerts);
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: lightPink,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          final q = value.trim().toLowerCase();
                          setSheetState(() {
                            filtered = concerts.where((item) {
                              final title =
                                  (item['title'] ?? '').toString().toLowerCase();
                              final art =
                                  (item['artist'] ?? '').toString().toLowerCase();
                              final ven =
                                  (item['venue'] ?? '').toString().toLowerCase();
                              return title.contains(q) ||
                                  art.contains(q) ||
                                  ven.contains(q);
                            }).toList();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching concerts found.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final isSelected = selectedConcert != null &&
                                      selectedConcert!['concert_id'] ==
                                          item['concert_id'];

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: lightPink,
                                      child: Icon(
                                        Icons.confirmation_number_outlined,
                                        color: pink,
                                      ),
                                    ),
                                    title: Text(
                                      item['title']?.toString() ??
                                          'Untitled Concert',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item['artist'] ?? ''} • ${item['venue'] ?? ''}\n${_formatShowDateTime(item['show_datetime'])}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    isThreeLine: true,
                                    trailing: isSelected
                                        ? Icon(Icons.check_circle, color: pink)
                                        : const Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey,
                                          ),
                                    onTap: () =>
                                        Navigator.pop(sheetContext, item),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
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
      selectedConcert = result;
      concert.text = result['title']?.toString() ?? '';
      artist.text = result['artist']?.toString() ?? '';
      date.text = _formatShowDateTime(result['show_datetime']);
      venue.text = result['venue']?.toString() ?? '';
    });
  }

  // ==========================================
  // VALIDATION VIA RESELL CONTROLLER
  // ==========================================

  String? check() {
    final concertId = selectedConcert == null
        ? null
        : int.tryParse(selectedConcert!['concert_id'].toString());

    final ticketAndPriceError = ResellController.validateResellInput(
      concertId: concertId,
      ticketCode: ticketCode.text,
      zoneName: zone.text,
      seatNumber: seat.text,
      originalPriceText: originalPrice.text,
      sellingPriceText: price.text,
    );

    if (ticketAndPriceError != null) {
      return ticketAndPriceError;
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
      return 'Please complete your payout account (9-15 digits).';
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
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() {
      page = 1;
    });
  }

  // ==========================================
  // CREATE LISTING VIA RESELL CONTROLLER
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

      final concertId = int.parse(selectedConcert!['concert_id'].toString());

      final result = await _resellController.createResellListing(
        concertId: concertId,
        ticketCode: ticketCode.text.trim(),
        zoneName: zone.text.trim(),
        seatNumber: seat.text.trim(),
        originalPrice: originalPriceNum,
        resellPrice: priceNum,
        deliveryType: delivery,
        shippingCompany: delivery == 'Parcel Shipping' ? company : null,
        shippingFee: shipNum,
        deliveryNote: notes.isEmpty ? null : notes,
        bankName: bank,
        bankAccountName: accName.text.trim(),
        bankAccountNumber: accNumber.text.trim(),
      );

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
          content: Text(
            'Failed to create listing: ${e.toString().replaceAll('Exception: ', '')}',
          ),
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
      artist,
      date,
      venue,
      ticketCode,
      zone,
      seat,
      originalPrice,
      price,
      appName,
      note,
      accName,
      accNumber,
    ]) {
      controller.clear();
    }

    setState(() {
      page = 0;
      selectedConcert = null;
      createdListingId = null;

      shipping.text = '50';

      delivery = 'Parcel Shipping';
      company = 'Thailand Post';
      channel = 'Email (PDF)';
      bank = null;
    });
  }

  // ==========================================
  // REUSABLE WIDGETS
  // ==========================================

  Widget field(
    String label,
    TextEditingController controller, {
    bool number = false,
    int lines = 1,
    String? hint,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: lines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
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
        title('1. Select Concert'),

        InkWell(
          onTap: chooseConcert,
          borderRadius: BorderRadius.circular(6),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Concert',
              prefixIcon: Icon(Icons.search, color: pink),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              border: const OutlineInputBorder(),
            ),
            child: Text(
              selectedConcert == null
                  ? 'Tap to search & select a concert'
                  : concert.text,
              style: TextStyle(
                color: selectedConcert == null ? Colors.grey.shade600 : Colors.black87,
                fontWeight: selectedConcert == null
                    ? FontWeight.normal
                    : FontWeight.w600,
              ),
            ),
          ),
        ),

        if (isLoadingConcerts)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),

        if (selectedConcert != null) ...[
          const SizedBox(height: 12),
          pinkBox([
            row('Concert', concert.text),
            row('Artist', artist.text),
            row('Date & Time', date.text),
            row('Venue', venue.text),
          ]),
        ],

        const SizedBox(height: 10),
        title('2. Ticket Details'),

        field(
          'Ticket Code',
          ticketCode,
          hint: 'e.g. TKT-BS2026-A105',
        ),

        field(
          'Zone Name',
          zone,
          hint: 'e.g. VIP A1, Zone S1, Standing B',
        ),

        field(
          'Seat Number',
          seat,
          hint: 'e.g. A1-05 or Standing',
        ),

        field(
          'Original Face-Value Price (THB)',
          originalPrice,
          number: true,
          hint: 'e.g. 4500',
        ),

        if (originalPriceNum > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Maximum allowed resale price (5x): THB ${maxAllowedPrice.toStringAsFixed(0)}',
              style: TextStyle(
                color: darkPink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        title('3. Selling Price'),

        field(
          'Selling Price (THB)',
          price,
          number: true,
          hint: originalPriceNum > 0
              ? 'Enter selling price (Max THB ${maxAllowedPrice.toStringAsFixed(0)})'
              : 'Enter original price above first',
          errorText: isPriceExceedingLimit
              ? 'Price cannot exceed 5x of original price (Max: THB ${maxAllowedPrice.toStringAsFixed(0)})'
              : null,
        ),

        title('4. Ticket Delivery Method'),

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
            initialValue: company,
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

        title('5. Payout Account'),

        DropdownButtonFormField<String>(
          initialValue: bank,
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
          row('Artist', artist.text.trim()),
          row('Date & Time', date.text.trim()),
          row('Venue', venue.text.trim()),
          const Divider(),
          row('Ticket Code', ticketCode.text.trim()),
          row('Zone', zone.text.trim()),
          row('Seat', seat.text.trim()),
          row('Original Price', 'THB ${originalPriceNum.toStringAsFixed(2)}'),
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
          row('Ticket Code', ticketCode.text.trim()),
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
            child: Material(
              color: Colors.transparent,
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
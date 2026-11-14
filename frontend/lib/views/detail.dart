import 'package:flutter/material.dart';
import 'favorite_service.dart';
import 'cart_service.dart';
import 'payment_page.dart';
import 'historypage.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> concert;

  const DetailPage({super.key, required this.concert});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final GlobalKey ticketSectionKey = GlobalKey();

  Map<String, dynamic> get concert => widget.concert;

  List<Map<String, dynamic>> get baseTickets {
    final rawTickets = concert['tickets'];
    if (rawTickets is List) {
      return rawTickets
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  String get eventName => concert['name']?.toString() ?? 'Concert Event';

  String get artist => concert['artist']?.toString() ?? '';

  String get eventDate => concert['date']?.toString() ?? 'Date to be announced';

  String get eventLocation =>
      concert['location']?.toString() ?? 'Location to be announced';

  String get eventImage => concert['image']?.toString() ?? '';

  String get eventDescription =>
      concert['description']?.toString() ??
      'Enjoy an unforgettable concert experience.';

  bool get isFavorite => FavoriteService.isFavorite(concert);

  bool get isFinished => CartService.isConcertFinished(concert);

  bool get isSoldOut => CartService.isConcertSoldOut(concert);

  String get ticketStatus {
    if (isFinished) return 'EVENT FINISHED';
    if (isSoldOut && ticketMaps.isEmpty) return 'SOLD OUT';
    return 'ON SALE NOW';
  }

  String selectedZone = 'All';
  final Map<String, String> selectedSeats = {};

  // ==========================================
  // TICKET DATA
  // ==========================================

  List<Map<String, dynamic>> get ticketMaps {
    final List<Map<String, dynamic>> list = [];
    for (var item in baseTickets) {
      list.add(Map<String, dynamic>.from(item));
    }

    final resaleListings = CartService.getResaleListingsForConcert(eventName);
    for (final listing in resaleListings) {
      list.add({
        'listingId': listing['listingId'],
        'zone': listing['zone'] ?? 'General',
        'seat': listing['seat'] ?? 'General',
        'price': listing['price'] ?? 0,
        'seller':
            listing['accName'] != null &&
                listing['accName'].toString().isNotEmpty
            ? listing['accName']
            : 'Resell Seller',
        'condition': 'Resell Ticket',
        'delivery': listing['delivery'],
      });
    }

    return list;
  }

  List<String> get availableZones {
    final zones = <String>{};

    for (final ticket in ticketMaps) {
      if (!CartService.isTicketSold(ticket)) {
        zones.add((ticket['zone'] ?? ticket['seat'] ?? 'General').toString());
      }
    }

    return zones.toList();
  }

  List<Map<String, dynamic>> get filteredTickets {
    return ticketMaps.where((ticket) {
      final zone = (ticket['zone'] ?? ticket['seat'] ?? 'General').toString();

      final matchesZone = selectedZone == 'All' || zone == selectedZone;

      return matchesZone;
    }).toList();
  }

  List<String> getSeats(Map<String, dynamic> ticket) {
    final rawSeats = ticket['seats'];

    if (rawSeats is List) {
      return rawSeats.map((seat) => seat.toString()).toList();
    }

    final rawSeatNumbers = ticket['seatNumbers'];

    if (rawSeatNumbers is List) {
      return rawSeatNumbers.map((seat) => seat.toString()).toList();
    }

    final singleSeat = ticket['seat']?.toString();

    if (singleSeat != null &&
        singleSeat.isNotEmpty &&
        singleSeat != (ticket['zone'] ?? '').toString()) {
      return [singleSeat];
    }

    return [];
  }

  String ticketKey(Map<String, dynamic> ticket) {
    return '${ticket['zone']}_${ticket['seller']}_${ticket['price']}_${ticketMaps.indexOf(ticket)}';
  }

  String? getSelectedSeat(Map<String, dynamic> ticket) {
    final key = ticketKey(ticket);
    final seats = getSeats(ticket);

    if (seats.isEmpty) return null;

    final selected = selectedSeats[key];

    if (selected != null && seats.contains(selected)) {
      return selected;
    }

    return null;
  }

  void toggleFavorite() {
    final wasFavorite = isFavorite;

    setState(() {
      FavoriteService.toggleFavorite(concert);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: darkPink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          content: Text(
            wasFavorite
                ? 'Removed from My Favorites!'
                : 'Added to My Favorites!',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
  }

  String formatPrice(dynamic price) {
    final number = double.tryParse(price.toString()) ?? 0;
    final value = number.toStringAsFixed(0);

    return '฿${value.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }

  void scrollToTickets() {
    final targetContext = ticketSectionKey.currentContext;

    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  Map<String, dynamic> createTicketItem(Map<String, dynamic> ticket) {
    final selectedSeat = getSelectedSeat(ticket);

    return {
      ...concert,
      ...ticket,
      'concertName': eventName,
      'artist': artist,
      'date': eventDate,
      'location': eventLocation,
      'image': eventImage,
      'seller': ticket['seller'] ?? 'Ticket Pink',
      'seat': selectedSeat ?? ticket['seat'] ?? ticket['zone'] ?? 'General',
      'zone': ticket['zone'] ?? 'General',
      'price': ticket['price'] ?? 0,
      'condition': ticket['condition'] ?? 'Available',
    };
  }

  // ==========================================
  // SEAT SELECTION POP-UP
  // ==========================================

  void _showSeatAlert() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.event_seat, color: pink, size: 45),
        title: const Text(
          'Please Select Your Seat',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: darkPink,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Please choose your preferred seat before adding the ticket to your cart or proceeding to checkout.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'OK, Got it',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool validateSeatSelection(Map<String, dynamic> ticket) {
    final seats = getSeats(ticket);

    if (seats.isEmpty) {
      return true;
    }

    if (getSelectedSeat(ticket) == null) {
      _showSeatAlert();
      return false;
    }

    return true;
  }

  void showUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: darkPink,
        content: Text(
          isFinished
              ? 'This concert has already finished.'
              : 'Sorry, this ticket is sold out.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ==========================================
  // POP-UP DIALOG (PENDING ORDER)
  // ==========================================

  void _showPendingOrderDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pending Order',
                style: TextStyle(
                  color: darkPink,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'You already have a pending ticket reservation. Please complete payment or cancel your previous order before reserving new tickets.',
          style: TextStyle(color: Colors.black87, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
            child: const Text('Go to My Orders'),
          ),
        ],
      ),
    );
  }

  void addToCart(Map<String, dynamic> ticket) {
    if (isFinished || !CartService.canBuy(ticket)) {
      showUnavailableMessage();
      setState(() {});
      return;
    }

    if (!validateSeatSelection(ticket)) return;

    final cartItem = createTicketItem(ticket);
    final added = CartService.addToCart(cartItem);

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: darkPink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(
            added
                ? 'Ticket added to your cart!'
                : 'This ticket is already in your cart!',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
  }

  void buyNow(Map<String, dynamic> ticket) {
    if (isFinished || !CartService.canBuy(ticket)) {
      showUnavailableMessage();
      setState(() {});
      return;
    }

    // ตรวจสอบว่าผู้ใช้มีรายการค้างชำระอยู่แล้วหรือไม่
    if (CartService.hasActiveUnpaidOrder()) {
      _showPendingOrderDialog();
      return;
    }

    if (!validateSeatSelection(ticket)) return;

    final checkoutItem = createTicketItem(ticket);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentPage(items: [checkoutItem])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth < 800
                    ? _buildMobileHeader()
                    : _buildDesktopHeader();
              },
            ),
          ),
          SliverToBoxAdapter(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Stack(
      children: [
        Container(
          height: 310,
          width: double.infinity,
          decoration: BoxDecoration(
            color: darkPink,
            image: eventImage.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(eventImage),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
        Container(height: 310, color: darkPink.withOpacity(0.86)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 15),
              _buildBreadcrumb(),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 115,
                      height: 165,
                      child: _buildEventImage(),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CONCERT',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            eventName,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildStatusBadge(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isFinished ? null : scrollToTickets,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  label: const Text('Choose Tickets'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Stack(
      children: [
        Container(
          height: 480,
          width: double.infinity,
          decoration: BoxDecoration(
            color: darkPink,
            image: eventImage.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(eventImage),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
        Container(height: 480, color: darkPink.withOpacity(0.84)),
        Padding(
          padding: const EdgeInsets.fromLTRB(35, 20, 35, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 25),
              _buildBreadcrumb(),
              const SizedBox(height: 35),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 220,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 0.68,
                            child: _buildEventImage(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isFinished ? null : scrollToTickets,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pink,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Choose Tickets'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 35),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CONCERT',
                            style: TextStyle(
                              color: Colors.white70,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            eventName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildInformationGrid(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const Text(
          'Ticket Pink',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: toggleFavorite,
          tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? pink : Colors.white,
            size: 26,
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return const Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text('Home', style: TextStyle(color: Colors.white70, fontSize: 13)),
        Icon(Icons.chevron_right, color: Colors.white54, size: 16),
        Text('Concerts', style: TextStyle(color: Colors.white70, fontSize: 13)),
        Icon(Icons.chevron_right, color: Colors.white54, size: 16),
        Text(
          'Event Details',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildEventImage() {
    if (eventImage.isEmpty) return _imagePlaceholder();

    return Image.network(
      eventImage,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: lightPink,
      child: const Center(child: Icon(Icons.music_note, size: 55, color: pink)),
    );
  }

  Widget _buildStatusBadge() {
    final badgeColor = isFinished
        ? Colors.grey
        : isSoldOut && ticketMaps.isEmpty
        ? Colors.red
        : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        border: Border.all(color: badgeColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        ticketStatus,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInformationGrid() {
    return Wrap(
      spacing: 25,
      runSpacing: 22,
      children: [
        _desktopInfo(Icons.calendar_month, 'Show Date', eventDate),
        _desktopInfo(Icons.location_on_outlined, 'Venue', eventLocation),
        _desktopInfo(
          Icons.confirmation_number_outlined,
          'Ticket Price',
          _ticketPriceText(),
        ),
        _desktopInfo(
          Icons.local_activity_outlined,
          'Ticket Status',
          ticketStatus,
        ),
      ],
    );
  }

  String _ticketPriceText() {
    final availableTickets = ticketMaps.where((ticket) {
      return !CartService.isTicketSold(ticket);
    }).toList();

    if (availableTickets.isEmpty) return 'Price unavailable';

    return availableTickets
        .map((ticket) => formatPrice(ticket['price']))
        .join(' / ');
  }

  Widget _desktopInfo(IconData icon, String title, String value) {
    return SizedBox(
      width: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 35,
            vertical: 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                _buildMobileInformation(),
                const SizedBox(height: 30),
              ],
              _buildSeatingPlan(),
              const SizedBox(height: 35),
              _buildTicketSection(),
              const SizedBox(height: 30),
              _buildDescription(),
              const SizedBox(height: 30),
              _buildVideoSection(),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Information',
          style: TextStyle(
            color: darkPink,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _mobileInfoCard(
                  width,
                  Icons.calendar_month,
                  'Show Date',
                  eventDate,
                ),
                _mobileInfoCard(
                  width,
                  Icons.location_on_outlined,
                  'Venue',
                  eventLocation,
                ),
                _mobileInfoCard(
                  width,
                  Icons.confirmation_number_outlined,
                  'Ticket Price',
                  _ticketPriceText(),
                ),
                _mobileInfoCard(
                  width,
                  Icons.local_activity_outlined,
                  'Ticket Status',
                  ticketStatus,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _mobileInfoCard(
    double width,
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 105),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: pink, size: 22),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: darkPink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatingPlan() {
    final zones = availableZones;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seating Plan',
          style: TextStyle(
            color: darkPink,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a zone to see its available tickets.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: darkPink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.music_note, color: Colors.white, size: 22),
                    SizedBox(height: 4),
                    Text(
                      'STAGE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (zones.isEmpty)
                const Text(
                  'No available seating zones.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: zones.map((zone) {
                    final zoneTickets = ticketMaps.where((ticket) {
                      final ticketZone =
                          (ticket['zone'] ?? ticket['seat'] ?? 'General')
                              .toString();

                      return ticketZone == zone &&
                          !CartService.isTicketSold(ticket);
                    }).toList();

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedZone = zone;
                        });

                        scrollToTickets();
                      },
                      child: Container(
                        width: 105,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selectedZone == zone ? pink : Colors.white,
                          border: Border.all(
                            color: selectedZone == zone
                                ? pink
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_seat,
                              color: selectedZone == zone
                                  ? Colors.white
                                  : darkPink,
                              size: 24,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              zone,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selectedZone == zone
                                    ? Colors.white
                                    : darkPink,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${zoneTickets.length} tickets',
                              style: TextStyle(
                                color: selectedZone == zone
                                    ? Colors.white70
                                    : Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Choose a zone above to filter tickets below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '* Seating plan shows the zones listed by ticket sellers.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketSection() {
    final displayedTickets = filteredTickets;

    return Column(
      key: ticketSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Tickets',
          style: TextStyle(
            color: darkPink,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose your preferred ticket zone and seat.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _zoneFilterChip('All'),
              ...availableZones.map(_zoneFilterChip),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (isFinished)
          _unavailableMessage('This concert has already finished.')
        else if (ticketMaps.isEmpty)
          _unavailableMessage('No tickets available.')
        else if (displayedTickets.isEmpty)
          _unavailableMessage('No tickets found in this zone.')
        else
          ...displayedTickets.map(_buildTicketCard),
      ],
    );
  }

  Widget _zoneFilterChip(String zone) {
    final selected = selectedZone == zone;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(zone),
        selected: selected,
        onSelected: (_) {
          setState(() {
            selectedZone = zone;
          });
        },
        selectedColor: pink,
        backgroundColor: lightPink,
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: selected ? Colors.white : darkPink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final sold = CartService.isTicketSold(ticket);
    final seats = getSeats(ticket);
    final selectedSeat = getSelectedSeat(ticket);

    final zone = (ticket['zone'] ?? ticket['seat'] ?? 'General').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone,
                      style: const TextStyle(
                        color: darkPink,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Seller: ${ticket['seller'] ?? 'Ticket Pink'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (!sold) ...[
                      const SizedBox(height: 5),
                      Text(
                        (ticket['condition'] ?? 'Available').toString(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                formatPrice(ticket['price']),
                style: const TextStyle(
                  color: pink,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!sold && seats.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Select Your Seat',
              style: TextStyle(
                color: darkPink,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: seats.map((seat) {
                final selected = selectedSeat == seat;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      final key = ticketKey(ticket);

                      if (selectedSeats[key] == seat) {
                        // กดที่นั่งเดิมซ้ำ เพื่อยกเลิกการเลือก
                        selectedSeats.remove(key);
                      } else {
                        // เลือกที่นั่ง
                        selectedSeats[key] = seat;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? pink : lightPink,
                      border: Border.all(
                        color: selected ? pink : Colors.pink.shade100,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      seat,
                      style: TextStyle(
                        color: selected ? Colors.white : darkPink,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedSeat != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected seat: $selectedSeat',
                style: const TextStyle(
                  color: pink,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ] else if (!sold) ...[
            const SizedBox(height: 12),
            Text(
              ticket['seat'] != null
                  ? 'Seat: ${ticket['seat']}'
                  : 'Seat details have not been provided by the seller.',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
          const SizedBox(height: 15),
          if (sold)
            const Text(
              'SOLD OUT',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _actionButton(
                        'Add to Cart',
                        () => addToCart(ticket),
                        outlined: true,
                      ),
                      const SizedBox(height: 8),
                      _actionButton('Buy Now', () => buyNow(ticket)),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        'Add to Cart',
                        () => addToCart(ticket),
                        outlined: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton('Buy Now', () => buyNow(ticket)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _unavailableMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: darkPink, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _actionButton(
    String label,
    VoidCallback onPressed, {
    bool outlined = false,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: outlined ? Colors.white : pink,
          foregroundColor: outlined ? pink : Colors.white,
          side: outlined ? const BorderSide(color: pink) : BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Event',
            style: TextStyle(
              color: darkPink,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            eventDescription,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Preview',
          style: TextStyle(
            color: darkPink,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: darkPink,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (eventImage.isNotEmpty)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.35,
                        child: Image.network(eventImage, fit: BoxFit.cover),
                      ),
                    ),
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 65,
                  ),
                  const Positioned(
                    bottom: 15,
                    left: 15,
                    child: Text(
                      'Concert Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

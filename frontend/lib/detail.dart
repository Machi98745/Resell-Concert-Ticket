
import 'package:flutter/material.dart';
import 'favorite_service.dart';
import 'cart.dart';
import 'cart_service.dart';
import 'checkout.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> concert;

  const DetailPage({
    super.key,
    required this.concert,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final GlobalKey ticketSectionKey = GlobalKey();

  Map<String, dynamic> get concert => widget.concert;

  List get tickets => concert['tickets'] ?? [];

  String get eventName => concert['name']?.toString() ?? 'Concert Event';
  String get artist => concert['artist']?.toString() ?? '';
  String get eventDate =>
      concert['date']?.toString() ?? 'Date to be announced';
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
    if (isSoldOut) return 'SOLD OUT';
    return 'ON SALE NOW';
  }

  // FAVORITE FUNCTION
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
    final value = (price as num?)?.toStringAsFixed(0) ?? '0';

    return '฿${value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
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

  void addToCart(Map<String, dynamic> ticket) {
    if (!CartService.canBuy(concert, ticket)) {
      showUnavailableMessage();
      setState(() {});
      return;
    }

    final added = CartService.addToCart(concert, ticket);

    if (!added) {
      showUnavailableMessage();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: darkPink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          content: const Text(
            'Ticket added to your cart!',
            style: TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CartPage(),
                ),
              );
            },
          ),
        ),
      );
  }

  void buyNow(Map<String, dynamic> ticket) {
    if (!CartService.canBuy(concert, ticket)) {
      showUnavailableMessage();
      setState(() {});
      return;
    }

    final checkoutItem = <String, dynamic>{
      'concertName': eventName,
      'artist': artist,
      'date': eventDate,
      'location': eventLocation,
      'image': eventImage,
      'seller': ticket['seller'] ?? 'Ticket Pink',
      'seat': ticket['seat'] ?? ticket['zone'] ?? 'General',
      'zone': ticket['zone'] ?? 'General',
      'price': ticket['price'] ?? 0,
      'condition': ticket['condition'] ?? 'Available',
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutPage(items: [checkoutItem]),
      ),
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
                  onPressed:
                      isFinished || isSoldOut ? null : scrollToTickets,
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
                            onPressed:
                                isFinished || isSoldOut ? null : scrollToTickets,
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

  // TOP BAR WITH WORKING FAVORITE BUTTON
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
          onPressed: () {},
          icon: const Icon(Icons.share_outlined, color: Colors.white),
        ),
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
        Text('Event Details', style: TextStyle(color: Colors.white, fontSize: 13)),
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
      child: const Center(
        child: Icon(Icons.music_note, size: 55, color: pink),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final finished = isFinished;
    final sold = isSoldOut;

    final badgeColor =
        finished ? Colors.grey : sold ? Colors.red : Colors.green;

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
    final availableTickets = tickets.where((ticket) {
      final map = Map<String, dynamic>.from(ticket);
      return !CartService.isTicketSold(map);
    }).toList();

    if (availableTickets.isEmpty) return 'Price unavailable';

    return availableTickets.map((t) => formatPrice(t['price'])).join(' / ');
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
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
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
          'Choose your preferred seating zone.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 20),
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
              Row(
                children: [
                  Expanded(child: _seatZone('A1', Colors.pink)),
                  const SizedBox(width: 8),
                  Expanded(child: _seatZone('A2', Colors.red)),
                  const SizedBox(width: 8),
                  Expanded(child: _seatZone('A3', Colors.pink)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _seatZone('B1', Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _seatZone('B2', Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _seatZone('B3', Colors.orange)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _seatZone('C1', Colors.lightGreen)),
                  const SizedBox(width: 8),
                  Expanded(child: _seatZone('C2', Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _seatZone('C3', Colors.lightGreen)),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'BACK SEATING',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _seatZone('D1', Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _seatZone('D2', Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _seatZone('D3', Colors.blue)),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 15,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _SeatLegend(color: Colors.red, label: 'VIP'),
                  _SeatLegend(color: Colors.orange, label: 'Premium'),
                  _SeatLegend(color: Colors.green, label: 'Standard'),
                  _SeatLegend(color: Colors.blue, label: 'Regular'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '* Seating plan is for illustration purposes.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _seatZone(String zone, Color color) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Text(
        zone,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTicketSection() {
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
          'Choose your preferred ticket zone.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 18),
        if (isFinished)
          _unavailableMessage('This concert has already finished.')
        else if (tickets.isEmpty)
          _unavailableMessage('No tickets available.')
        else if (isSoldOut)
          _unavailableMessage('SOLD OUT - All tickets have been sold.')
        else
          ...List.generate(tickets.length, (index) {
            final ticket = Map<String, dynamic>.from(tickets[index]);
            final sold = CartService.isTicketSold(ticket);

            return Container(
              margin: const EdgeInsets.only(bottom: 13),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 390;

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (ticket['zone'] ??
                                      ticket['seat'] ??
                                      'General')
                                  .toString(),
                              style: const TextStyle(
                                color: darkPink,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Seller: ${ticket['seller'] ?? 'Ticket Pink'}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sold
                                  ? 'SOLD OUT'
                                  : (ticket['condition'] ?? 'Available')
                                      .toString(),
                              style: TextStyle(
                                color: sold ? Colors.red : Colors.green,
                                fontSize: 12,
                                fontWeight: sold
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatPrice(ticket['price']),
                            style: const TextStyle(
                              color: pink,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (sold)
                            const Text(
                              'SOLD OUT',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            )
                          else if (compact)
                            Column(
                              children: [
                                _actionButton(
                                  'Add Cart',
                                  () => addToCart(ticket),
                                  outlined: true,
                                ),
                                const SizedBox(height: 6),
                                _actionButton(
                                  'Buy Now',
                                  () => buyNow(ticket),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _actionButton(
                                  'Add to Cart',
                                  () => addToCart(ticket),
                                  outlined: true,
                                ),
                                const SizedBox(width: 6),
                                _actionButton(
                                  'Buy Now',
                                  () => buyNow(ticket),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          }),
      ],
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
        style: const TextStyle(
          color: darkPink,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    VoidCallback onPressed, {
    bool outlined = false,
  }) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: outlined ? Colors.white : pink,
          foregroundColor: outlined ? pink : Colors.white,
          side: outlined ? const BorderSide(color: pink) : BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
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
                        child: Image.network(
                          eventImage,
                          fit: BoxFit.cover,
                        ),
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

class _SeatLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _SeatLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

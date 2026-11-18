import 'dart:async';
import 'package:flutter/material.dart';
import 'detail.dart';
import 'cart.dart';
import 'cart_service.dart';
import 'profile.dart';
import 'sell_page.dart';
import 'seller_registration_page.dart';
import 'package:frontend/server/api_service.dart';
import 'package:frontend/controller/resell_controller.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final PageController bannerController = PageController();
  final ResellController _resellController = ResellController();

  Timer? bannerTimer;

  String selectedCategory = 'All';
  int currentBannerIndex = 0;
  bool showBannerControls = false;
  bool isLoading = false;

  bool isCheckingSeller = true;
  bool isRegisteredSeller = false;
  String sellerVerificationStatus = 'not_submitted';
  String? errorMessage;

  List<Map<String, dynamic>> concerts = [
    {
      'id': 1,
      'concert_id': 1,
      'name': 'BLACKPINK WORLD TOUR',
      'artist': 'BLACKPINK',
      'date': '15 December 2026',
      'time': '19:00',
      'location': 'Rajamangala National Stadium, Bangkok',
      'category': 'K-Pop',
      'image': 'assets/images/blackpink.jpg',
      'description': 'Experience an unforgettable night with BLACKPINK.',
      'tickets': [
        {
          'seller': 'BlackPinkFan',
          'zone': 'VIP Zone',
          'price': 6500,
          'condition': 'Available',
          'status': 'available',
          'seats': ['VIP-A1'],
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    ApiService.ensureCurrentUserCart().then((_) {
      if (mounted) setState(() {});
    });
    loadConcerts();
    checkSellerStatus();
    startBannerAutoSlide();
  }

  // ==========================================
  // CHECK SELLER STATUS VIA RESELL CONTROLLER
  // ==========================================

  Future<void> checkSellerStatus() async {
    if (mounted) {
      setState(() => isCheckingSeller = true);
    }

    final statusRes = await _resellController.getSellerStatus();

    if (!mounted) return;
    setState(() {
      sellerVerificationStatus =
          (statusRes['status'] ?? 'not_submitted').toString();
      isRegisteredSeller = statusRes['is_verified'] == true;
      isCheckingSeller = false;
    });
  }

  // ==========================================
  // RESOLVE POSTER FROM DATABASE / UPLOADS
  // ==========================================

  String _resolvePosterUrl(dynamic rawUrl) {
    final raw = rawUrl?.toString().trim() ?? '';

    if (raw.isEmpty) {
      return '';
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    if (raw.startsWith('/')) {
      return 'http://localhost:3000$raw';
    }

    if (raw.startsWith('uploads/')) {
      return 'http://localhost:3000/$raw';
    }

    if (raw.startsWith('assets/')) {
      return raw;
    }

    return 'http://localhost:3000/uploads/posters/$raw';
  }

  // ==========================================
  // LOAD CONCERTS & RESELL LISTINGS
  // ==========================================

  Future<void> loadConcerts() async {
    if (mounted && concerts.isEmpty) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await ApiService.getConcerts();

      final List<Map<String, dynamic>> loadedConcerts = [];

      for (final concert in result) {
        final concertId = int.tryParse(
          concert['concert_id'].toString(),
        );

        if (concertId == null) continue;

        List<Map<String, dynamic>> tickets = [];

        try {
          tickets =
              await _resellController.getResellListings(concertId: concertId);
        } catch (e) {
          debugPrint(
            'Failed to load tickets for concert $concertId: $e',
          );
        }

        final showDateTime = concert['show_datetime'];
        final parsedDate = DateTime.tryParse(
          showDateTime?.toString() ?? '',
        );

        loadedConcerts.add({
          ...concert,
          'id': concertId,
          'concert_id': concertId,
          'name': concert['title'] ?? 'Untitled Concert',
          'artist': concert['artist'] ?? 'Unknown Artist',
          'date': parsedDate != null
              ? _formatDate(parsedDate)
              : 'Date TBA',
          'time': parsedDate != null
              ? _formatTime(parsedDate)
              : '',
          'location': concert['venue'] ?? 'Venue TBA',
          'category': concert['category'] ?? 'Other',
          'image': _resolvePosterUrl(concert['poster_url']),
          'description': concert['description'] ?? '',
          'tickets': tickets.map((ticket) {
            return {
              ...ticket,
              'id': ticket['listing_id'],
              'listing_id': ticket['listing_id'],
              'ticketId': ticket['ticket_id'],
              'zone': ticket['zone_name'] ?? 'General',
              'seat': ticket['seat_number'] ?? 'Seat TBA',
              'seller': ticket['seller_name'] ?? 'Ticket Seller',
              'price': ticket['resell_price'] ?? 0,
              'condition': ticket['status'] ?? 'available',
              'status': ticket['status'] ?? 'available',
              'isSold': ticket['status'] != 'available',
            };
          }).toList(),
        });
      }

      if (!mounted) return;

      setState(() {
        if (loadedConcerts.isNotEmpty) {
          concerts = loadedConcerts;
        }
        isLoading = false;
        errorMessage = null;
        currentBannerIndex = 0;
      });

      if (bannerController.hasClients) {
        bannerController.jumpToPage(0);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        if (concerts.isEmpty) {
          errorMessage = e.toString();
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ==========================================
  // AUTO SLIDE
  // ==========================================

  void startBannerAutoSlide() {
    bannerTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        if (!mounted || !bannerController.hasClients) return;

        final list = upcomingConcerts;
        if (list.length <= 1) return;

        final nextPage =
            (currentBannerIndex + 1) % list.length;

        bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  void dispose() {
    bannerTimer?.cancel();
    bannerController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // CONCERT LIST
  // ==========================================

  List<Map<String, dynamic>> get upcomingConcerts {
    return concerts.where((concert) {
      return !CartService.isConcertFinished(concert);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredConcerts {
    final searchText = searchController.text.toLowerCase();

    return upcomingConcerts.where((concert) {
      final name = concert['name'].toString().toLowerCase();
      final artist = concert['artist'].toString().toLowerCase();

      final matchesSearch =
          name.contains(searchText) ||
          artist.contains(searchText);

      final matchesCategory =
          selectedCategory == 'All' ||
          concert['category'] == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get categories {
    final values = concerts
        .map((concert) => concert['category'].toString())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    values.sort();
    return ['All', ...values];
  }

  bool isSoldOut(Map<String, dynamic> concert) {
    final tickets = concert['tickets'];
    return tickets is! List || tickets.isEmpty;
  }

  // ==========================================
  // NAVIGATION
  // ==========================================

  void openDetail(Map<String, dynamic> concert) {
    if (CartService.isConcertFinished(concert)) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(concert: concert),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CartPage(),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfilePage(),
      ),
    ).then((_) {
      if (mounted) {
        checkSellerStatus();
      }
    });
  }

  Future<void> openSellerRegistration() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const SellerRegistrationPage(),
      ),
    );

    if (!mounted) return;
    await checkSellerStatus();
  }

  void openSellTickets() {
    if (!isRegisteredSeller) {
      final bool isPending = sellerVerificationStatus == 'pending';

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Icon(
                  isPending
                      ? Icons.hourglass_top_rounded
                      : Icons.verified_user_outlined,
                  color: pink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPending
                        ? 'Verification Pending'
                        : 'Seller Registration Required',
                    style: const TextStyle(
                      color: darkPink,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              isPending
                  ? 'Your seller verification request is under review. You can sell tickets once it is approved.'
                  : 'You must register and verify your identity as a seller before listing tickets for sale.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (!isPending)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    openSellerRegistration();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Register Now'),
                ),
            ],
          );
        },
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SellPage(),
      ),
    ).then((_) {
      if (mounted) {
        loadConcerts();
      }
    });
  }

  // ==========================================
  // BANNER NAVIGATION
  // ==========================================

  void previousBanner() {
    final list = upcomingConcerts;
    if (list.length <= 1) return;

    final previous = currentBannerIndex == 0
        ? list.length - 1
        : currentBannerIndex - 1;

    bannerController.animateToPage(
      previous,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void nextBanner() {
    final list = upcomingConcerts;
    if (list.length <= 1) return;

    final next = (currentBannerIndex + 1) % list.length;

    bannerController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ==========================================
  // IMAGE - NETWORK & LOCAL ASSETS
  // ==========================================

  Widget _concertImage(String? imagePath) {
    final path = imagePath?.trim() ?? '';

    if (path.isEmpty) {
      return _imagePlaceholder();
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Cannot load network image: $path ($error)');
          return _imagePlaceholder();
        },
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Cannot load asset: $path');
        return _imagePlaceholder();
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: lightPink,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 42,
            color: pink,
          ),
          SizedBox(height: 8),
          Text(
            'Image unavailable',
            style: TextStyle(
              color: darkPink,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: pink,
                  onRefresh: () async {
                    await loadConcerts();
                    await checkSellerStatus();
                  },
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (isLoading)
                          const SizedBox(
                            height: 350,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: pink,
                              ),
                            ),
                          )
                        else if (errorMessage != null)
                          _buildError()
                        else ...[
                          if (upcomingConcerts.isNotEmpty)
                            _buildBanner(),
                          const SizedBox(height: 35),
                          _buildSearch(),
                          const SizedBox(height: 25),
                          _buildCategories(),
                          const SizedBox(height: 25),
                          _buildConcertSection(),
                          const SizedBox(height: 40),
                          _buildFooter(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: 350,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                color: pink,
                size: 55,
              ),
              const SizedBox(height: 15),
              const Text(
                'Unable to load concerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: loadConcerts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    final isMobile =
        MediaQuery.of(context).size.width <= 680;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 35,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Ticket Pink',
            style: TextStyle(
              fontSize: isMobile ? 18 : 25,
              fontWeight: FontWeight.bold,
              color: pink,
            ),
          ),
          const Spacer(),
          if (!isCheckingSeller) ...[
            if (!isRegisteredSeller)
              OutlinedButton.icon(
                onPressed: sellerVerificationStatus == 'pending'
                    ? null
                    : openSellerRegistration,
                icon: Icon(
                  sellerVerificationStatus == 'pending'
                      ? Icons.hourglass_top_rounded
                      : Icons.storefront_outlined,
                  size: isMobile ? 15 : 18,
                ),
                label: Text(
                  sellerVerificationStatus == 'pending'
                      ? (isMobile ? 'Pending' : 'Verification Pending')
                      : (isMobile ? 'Register Seller' : 'Become a Seller'),
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: pink,
                  side: BorderSide(
                    color: sellerVerificationStatus == 'pending'
                        ? Colors.orange
                        : pink,
                    width: 1.4,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else if (!isMobile)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: pink.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: pink, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Verified Seller',
                      style: TextStyle(
                        color: darkPink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(width: isMobile ? 6 : 10),
          ],
          ElevatedButton.icon(
            onPressed: isCheckingSeller ? null : openSellTickets,
            icon: Icon(
              isRegisteredSeller
                  ? Icons.confirmation_number_outlined
                  : Icons.lock_outline,
              size: isMobile ? 15 : 18,
            ),
            label: Text(
              'Sell Tickets',
              style: TextStyle(
                fontSize: isMobile ? 11 : 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isRegisteredSeller ? pink : Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 9 : 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 2 : 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: openCart,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 40,
                ),
                icon: Icon(
                  Icons.shopping_bag_outlined,
                  color: darkPink,
                  size: isMobile ? 22 : 26,
                ),
              ),
              if (CartService.items.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: pink,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${CartService.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: openProfile,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 40,
            ),
            tooltip: 'My Profile',
            icon: Icon(
              Icons.account_circle_outlined,
              color: darkPink,
              size: isMobile ? 23 : 27,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BANNER
  // ==========================================

  Widget _buildBanner() {
    final list = upcomingConcerts;

    if (list.isEmpty) return const SizedBox.shrink();

    final safeIndex =
        currentBannerIndex.clamp(0, list.length - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 25, 12, 0),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => showBannerControls = true);
        },
        onExit: (_) {
          setState(() => showBannerControls = false);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: SizedBox(
            height: 540,
            width: double.infinity,
            child: Stack(
              children: [
                PageView.builder(
                  controller: bannerController,
                  itemCount: list.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentBannerIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final concert = list[index];

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _concertImage(
                          concert['image']?.toString(),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.75),
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 35,
                          top: 0,
                          bottom: 0,
                          child: SizedBox(
                            width:
                                MediaQuery.of(context).size.width *
                                0.55,
                            child: _buildBannerInfo(concert),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (showBannerControls && list.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _bannerArrowButton(
                        icon: Icons.chevron_left,
                        onPressed: previousBanner,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _bannerArrowButton(
                        icon: Icons.chevron_right,
                        onPressed: nextBanner,
                      ),
                    ),
                  ),
                ],
                if (list.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: List.generate(
                        list.length,
                        (index) {
                          final selected =
                              safeIndex == index;

                          return AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 300),
                            margin:
                                const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            width: selected ? 25 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: selected
                                  ? pink
                                  : Colors.white70,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerInfo(
    Map<String, dynamic> concert,
  ) {
    final soldOut = isSoldOut(concert);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: soldOut ? Colors.red : pink,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            soldOut ? 'SOLD OUT' : 'FEATURED EVENT',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          concert['name'].toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${concert['date']}  •  ${concert['time'] ?? ''}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          concert['location'].toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => openDetail(concert),
          style: ElevatedButton.styleFrom(
            backgroundColor: pink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text('Explore Tickets'),
        ),
      ],
    );
  }

  Widget _bannerArrowButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  // ==========================================
  // SEARCH
  // ==========================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search concerts, artists...',
          prefixIcon: const Icon(
            Icons.search,
            color: pink,
          ),
          filled: true,
          fillColor: lightPink,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CATEGORIES
  // ==========================================

  Widget _buildCategories() {
    final categoryList = categories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Wrap(
        spacing: 12,
        children: categoryList.map((category) {
          final selected =
              selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) {
              setState(() {
                selectedCategory = category;
              });
            },
            selectedColor: pink,
            backgroundColor: lightPink,
            labelStyle: TextStyle(
              color: selected ? Colors.white : darkPink,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide.none,
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // CONCERT SECTION
  // ==========================================

  Widget _buildConcertSection() {
    final list = filteredConcerts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Concerts',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: darkPink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Find your favorite concert tickets',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 22),
          if (list.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No upcoming concerts found.',
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                int columns = 1;

                if (constraints.maxWidth >= 1100) {
                  columns = 4;
                } else if (constraints.maxWidth >= 850) {
                  columns = 3;
                } else if (constraints.maxWidth >= 560) {
                  columns = 2;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    mainAxisExtent: 490,
                  ),
                  itemBuilder: (context, index) {
                    return _buildConcertCard(
                      list[index],
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // CONCERT CARD
  // ==========================================

  Widget _buildConcertCard(
    Map<String, dynamic> concert,
  ) {
    final soldOut = isSoldOut(concert);

    final statusText =
        soldOut ? 'SOLD OUT' : 'AVAILABLE';
    final statusColor =
        soldOut ? Colors.red : Colors.green;

    return GestureDetector(
      onTap: () => openDetail(concert),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: _concertImage(
                        concert['image']?.toString(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius:
                            BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      concert['name'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: darkPink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      concert['artist'].toString(),
                      style: const TextStyle(
                        color: pink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 15,
                          color: pink,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${concert['date']?.toString() ?? 'Date TBA'}${(concert['time'] != null && concert['time'].toString().trim().isNotEmpty) ? ' • ${concert['time']}' : ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (concert['time'] != null &&
                        concert['time'].toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 15,
                            color: pink,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Time: ${concert['time']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 15,
                          color: pink,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            concert['location']?.toString() ??
                                'Venue TBA',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => openDetail(concert),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          soldOut
                              ? 'View Details'
                              : 'View Tickets',
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
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

  // ==========================================
  // FOOTER
  // ==========================================

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: darkPink,
      padding: const EdgeInsets.all(30),
      child: const Column(
        children: [
          Text(
            'Ticket Pink',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Your favorite place for concert tickets.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 15),
          Text(
            '© 2026 Ticket Pink. All rights reserved.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
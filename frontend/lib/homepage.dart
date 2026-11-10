import 'dart:async';
import 'package:flutter/material.dart';
import 'detail.dart';
import 'cart.dart';
import 'cart_service.dart';
import 'profile.dart';

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

  Timer? bannerTimer;

  String selectedCategory = 'All';
  int currentBannerIndex = 0;
  bool showBannerControls = false;

  final List<Map<String, dynamic>> concerts = [
    {
      'name': 'BLACKPINK WORLD TOUR',
      'artist': 'BLACKPINK',
      'date': '15 December 2026',
      'time': '19:00',
      'location': 'Rajamangala National Stadium, Bangkok',
      'category': 'K-Pop',
      'image':
          'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=900',
      'images': [
        'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=1200',
        'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=1200',
        'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=1200',
      ],
      'description': 'Experience an unforgettable night with BLACKPINK.',
      'tickets': [
        {
          'seller': 'LisaFan',
          'zone': 'VIP Zone',
          'price': 6500,
          'condition': 'Available',
          'status': 'available',
          'seats': ['VIP-A1', 'VIP-A2', 'VIP-A3'],
        },
        {
          'seller': 'LisaFan2',
          'zone': 'Premium Zone',
          'price': 4800,
          'condition': 'Available',
          'status': 'available',
          'seats': ['P-A1', 'P-A2', 'P-A3'],
        },
        {
          'seller': 'LisaFan3',
          'zone': 'Standard Zone',
          'price': 3200,
          'condition': 'Available',
          'status': 'available',
          'seats': ['S-A1', 'S-A2', 'S-A3'],
        },
      ],
    },
    {
      'name': 'LISA FAN MEETING',
      'artist': 'LISA',
      'date': '1 December 2026',
      'time': '18:00',
      'location': 'Impact Arena, Bangkok',
      'category': 'K-Pop',
      'image':
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=900',
      'images': [
        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200',
        'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=1200',
        'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=1200',
      ],
      'description': 'Meet and enjoy a special event with LISA.',
      'tickets': [
        {
          'zone': 'VIP Zone',
          'price': 6500,
          'condition': 'Sold Out',
          'status': 'sold',
        },
      ],
    },
    {
      'name': 'THE ERAS TOUR',
      'artist': 'Taylor Swift',
      'date': '25 December 2026',
      'time': '19:00',
      'location': 'National Stadium, Singapore',
      'category': 'Pop',
      'image':
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=900',
      'images': [
        'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=1200',
        'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=1200',
        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200',
      ],
      'description': 'Enjoy an amazing live music experience.',
      'tickets': [
        {
          'seller': 'SwiftieShop',
          'zone': 'CAT 1',
          'price': 5200,
          'condition': 'Available',
          'status': 'available',
        },
      ],
    },
    {
      'name': 'BTS WORLD TOUR',
      'artist': 'BTS',
      'date': '30 December 2026',
      'time': '19:00',
      'location': 'Rajamangala National Stadium, Bangkok',
      'category': 'K-Pop',
      'image':
          'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=900',
      'images': [
        'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=1200',
        'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=1200',
        'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=1200',
      ],
      'description': 'A special concert experience for ARMY.',
      'tickets': [
        {
          'seller': 'ArmyStore',
          'zone': 'VIP Zone',
          'price': 4800,
          'condition': 'Available',
          'status': 'available',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    startBannerAutoSlide();
  }

  void startBannerAutoSlide() {
    bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !bannerController.hasClients) return;

      final activeConcerts = upcomingConcerts;
      if (activeConcerts.isEmpty) return;

      final images = activeConcerts.first['images'] as List;
      if (images.isEmpty) return;

      final nextPage = (currentBannerIndex + 1) % images.length;

      bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
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
      final matchesSearch =
          concert['name'].toString().toLowerCase().contains(searchText) ||
          concert['artist'].toString().toLowerCase().contains(searchText);

      final matchesCategory =
          selectedCategory == 'All' || concert['category'] == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void openDetail(Map<String, dynamic> concert) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(concert: concert)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  void openSellTickets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selling feature coming soon!')),
    );
  }

  void previousBanner(List images) {
    if (images.isEmpty) return;

    final previous = currentBannerIndex == 0
        ? images.length - 1
        : currentBannerIndex - 1;

    bannerController.animateToPage(
      previous,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void nextBanner(List images) {
    if (images.isEmpty) return;

    final next = (currentBannerIndex + 1) % images.length;

    bannerController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (upcomingConcerts.isNotEmpty) _buildBanner(),
                      const SizedBox(height: 35),
                      _buildSearch(),
                      const SizedBox(height: 25),
                      _buildCategories(),
                      const SizedBox(height: 25),
                      _buildConcertSection(),
                      const SizedBox(height: 40),
                      _buildFooter(),
                    ],
                  ),
                ),
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
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 35,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              fontSize: isMobile ? 20 : 25,
              fontWeight: FontWeight.bold,
              color: pink,
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            _headerText('Home'),
            const SizedBox(width: 25),
            _headerText('Concerts'),
            const SizedBox(width: 20),
          ],
          ElevatedButton.icon(
            onPressed: openSellTickets,
            icon: Icon(
              Icons.confirmation_number_outlined,
              size: isMobile ? 16 : 18,
            ),
            label: Text(
              'Sell Tickets',
              style: TextStyle(fontSize: isMobile ? 11 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: pink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 16,
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
                constraints: const BoxConstraints(minWidth: 38, minHeight: 40),
                icon: Icon(
                  Icons.shopping_bag_outlined,
                  color: darkPink,
                  size: isMobile ? 23 : 26,
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
            constraints: const BoxConstraints(minWidth: 38, minHeight: 40),
            tooltip: 'My Profile',
            icon: Icon(
              Icons.account_circle_outlined,
              color: darkPink,
              size: isMobile ? 24 : 27,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: darkPink,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    );
  }

  // ==========================================
  // BANNER
  // ==========================================

  Widget _buildBanner() {
    final featured = upcomingConcerts.first;
    final images = featured['images'] as List;

    if (images.isEmpty) return const SizedBox.shrink();

    final concertStatus = CartService.getConcertStatus(featured);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 25, 12, 0),
      child: MouseRegion(
        onEnter: (_) {
          if (!showBannerControls) {
            setState(() {
              showBannerControls = true;
            });
          }
        },
        onExit: (_) {
          if (showBannerControls) {
            setState(() {
              showBannerControls = false;
            });
          }
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
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentBannerIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index].toString(),
                      width: double.infinity,
                      height: 540,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: darkPink,
                          child: const Center(
                            child: Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 35,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: concertStatus == 'Sold Out'
                                ? Colors.red
                                : concertStatus == 'No Tickets'
                                ? Colors.orange
                                : pink,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            concertStatus == 'Sold Out'
                                ? 'SOLD OUT'
                                : concertStatus == 'No Tickets'
                                ? 'NO TICKETS'
                                : 'FEATURED EVENT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          featured['name'].toString(),
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
                          '${featured['date']}  •  ${featured['time'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          featured['location'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed:
                              concertStatus == 'Sold Out' ||
                                  concertStatus == 'No Tickets'
                              ? null
                              : () => openDetail(featured),
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
                    ),
                  ),
                ),
                if (showBannerControls) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _bannerArrowButton(
                        icon: Icons.chevron_left,
                        onPressed: () => previousBanner(images),
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
                        onPressed: () => nextBanner(images),
                      ),
                    ),
                  ),
                ],
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      final selected = currentBannerIndex == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selected ? 25 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selected ? pink : Colors.white70,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerArrowButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 40),
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
          prefixIcon: const Icon(Icons.search, color: pink),
          filled: true,
          fillColor: lightPink,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
    const categories = ['All', 'K-Pop', 'Pop'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Wrap(
        spacing: 12,
        children: categories.map((category) {
          final selected = selectedCategory == category;

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
    final concertList = filteredConcerts;

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
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 22),
          if (concertList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text('No upcoming concerts found.'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                int columns = 2;

                if (constraints.maxWidth >= 1000) {
                  columns = 4;
                } else if (constraints.maxWidth >= 650) {
                  columns = 3;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: concertList.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.65,
                  ),
                  itemBuilder: (context, index) {
                    return _buildConcertCard(concertList[index]);
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

  Widget _buildConcertCard(Map<String, dynamic> concert) {
    final concertStatus = CartService.getConcertStatus(concert);

    final soldOut = concertStatus == 'Sold Out';
    final noTickets = concertStatus == 'No Tickets';

    final statusText = soldOut
        ? 'SOLD OUT'
        : noTickets
        ? 'NO TICKETS'
        : 'AVAILABLE';

    final statusColor = soldOut
        ? Colors.red
        : noTickets
        ? Colors.orange
        : Colors.green;

    return GestureDetector(
      onTap: () => openDetail(concert),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        concert['image']?.toString() ?? '',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: lightPink,
                            child: const Center(
                              child: Icon(
                                Icons.music_note,
                                size: 45,
                                color: pink,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.calendar_month, size: 15, color: pink),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            concert['date']?.toString() ?? 'Date TBA',
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
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 15, color: pink),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            concert['location']?.toString() ?? 'Venue TBA',
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
                          backgroundColor: soldOut ? Colors.grey : pink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          soldOut || noTickets
                              ? 'View Details'
                              : 'View Tickets',
                          style: const TextStyle(fontSize: 12),
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
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          SizedBox(height: 15),
          Text(
            '© 2026 Ticket Pink. All rights reserved.',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

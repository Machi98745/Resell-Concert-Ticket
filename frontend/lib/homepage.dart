import 'dart:async';

import 'package:flutter/material.dart';
import 'detail.dart';
import 'cart.dart';
import 'cart_service.dart';
import 'screens/sell_page.dart';

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

  final List<Map<String, dynamic>> concerts = [
    {
      'name': 'BLACKPINK WORLD TOUR',
      'artist': 'BLACKPINK',
      'date': '15 December 2026',
      'location': 'Bangkok, Thailand',
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
          'seller': 'PinkSeller',
          'zone': 'VIP Zone',
          'price': 6500,
          'condition': 'Available',
        },
        {
          'seller': 'LisaFan',
          'zone': 'Standing Zone',
          'price': 4200,
          'condition': 'Available',
        },
      ],
    },
    {
      'name': 'LISA FAN MEETING',
      'artist': 'LISA',
      'date': '20 December 2026',
      'location': 'Bangkok, Thailand',
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
          'seller': 'LisaWorld',
          'zone': 'Zone A',
          'price': 3500,
          'condition': 'Available',
        },
      ],
    },
    {
      'name': 'THE ERAS TOUR',
      'artist': 'Taylor Swift',
      'date': '25 December 2026',
      'location': 'Singapore',
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
        },
      ],
    },
    {
      'name': 'BTS WORLD TOUR',
      'artist': 'BTS',
      'date': '30 December 2026',
      'location': 'Bangkok, Thailand',
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

      final images = concerts[0]['images'] as List;
      int nextPage = currentBannerIndex + 1;

      if (nextPage >= images.length) {
        nextPage = 0;
      }

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

  List<Map<String, dynamic>> get filteredConcerts {
    final searchText = searchController.text.toLowerCase();

    return concerts.where((concert) {
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
      MaterialPageRoute(builder: (context) => DetailPage(concert: concert)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    _buildBanner(),
                    const SizedBox(height: 35),
                    _buildSearch(),
                    const SizedBox(height: 25),
                    _buildCategories(),
                    const SizedBox(height: 25),
                    _buildConcertSection(),
                    const SizedBox(height: 40),
                    _buildResellSection(),
                    const SizedBox(height: 40),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
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
          const Text(
            'Ticket Pink',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: pink,
            ),
          ),
          const Spacer(),
          if (MediaQuery.of(context).size.width > 600) ...[
            _headerText('Home'),
            const SizedBox(width: 25),
            _headerText('Concerts'),
            const SizedBox(width: 25),
            _headerText('Sell Tickets'),
            const SizedBox(width: 25),
          ],
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: openCart,
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: darkPink,
                  size: 26,
                ),
              ),
              if (CartService.items.isNotEmpty)
                Positioned(
                  right: 3,
                  top: 2,
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
          const SizedBox(width: 8),
          const Icon(Icons.account_circle_outlined, color: darkPink, size: 27),
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

  // AUTO SLIDE BANNER
  Widget _buildBanner() {
    final images = concerts[0]['images'] as List;

    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 360,
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
                  return GestureDetector(
                    onTap: () => openDetail(concerts[0]),
                    child: Image.network(
                      images[index],
                      width: double.infinity,
                      height: 360,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
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
                    ),
                  );
                },
              ),

              // DARK OVERLAY
              Container(
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

              // BANNER TEXT
              Positioned(
                left: 40,
                top: 75,
                bottom: 75,
                child: SizedBox(
                  width: 350,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: pink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'FEATURED EVENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'BLACKPINK\nWORLD TOUR 2026',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Get your tickets and enjoy the show!',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => openDetail(concerts[0]),
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

              // PAGE INDICATORS
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    final isSelected = currentBannerIndex == index;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isSelected ? 25 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? pink
                            : Colors.white.withOpacity(0.7),
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
    );
  }

  // SEARCH
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {});
        },
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

  // CATEGORY
  Widget _buildCategories() {
    final categories = ['All', 'K-Pop', 'Pop'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Wrap(
        spacing: 12,
        children: categories.map((category) {
          final selected = selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (value) {
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

  // CONCERT SECTION
  Widget _buildConcertSection() {
    final items = filteredConcerts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
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

          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text('No concerts found.'),
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
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    return _buildConcertCard(items[index]);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  // CONCERT CARD
  Widget _buildConcertCard(Map<String, dynamic> concert) {
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
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  concert['image'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: lightPink,
                      child: const Center(
                        child: Icon(Icons.music_note, size: 45, color: pink),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concert['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: darkPink,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      concert['artist'],
                      style: const TextStyle(
                        color: pink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            concert['date'],
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
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => openDetail(concert),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'View Tickets',
                          style: TextStyle(fontSize: 12),
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

  // RESELL SECTION
  Widget _buildResellSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.confirmation_number_outlined, color: pink, size: 45),
          const SizedBox(height: 15),
          const Text(
            'Have a ticket to sell?',
            style: TextStyle(
              color: darkPink,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sell your concert tickets easily with Ticket Pink.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SellPage()),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selling feature coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            ),
            child: const Text('Start Selling'),
          ),
        ],
      ),
    );
  }

  // FOOTER
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

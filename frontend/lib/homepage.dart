
import 'package:flutter/material.dart';
import 'detail.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController =
      TextEditingController();

  String selectedCategory = 'All';

  final List<Map<String, dynamic>> concerts = [
    {
      'name': 'BLACKPINK WORLD TOUR',
      'artist': 'BLACKPINK',
      'date': '15 December 2026',
      'location': 'Bangkok, Thailand',
      'category': 'K-Pop',
      'image':
          'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=1000',
      'description':
          'Experience an amazing night with BLACKPINK.',
      'tickets': [
        {
          'seller': 'PinkSeller',
          'seat': 'VIP Zone',
          'price': 6500,
          'condition': 'Available',
        },
        {
          'seller': 'LisaFan',
          'seat': 'Standing Zone',
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
          'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=1000',
      'description':
          'Enjoy a special event with LISA.',
      'tickets': [
        {
          'seller': 'LisaWorld',
          'seat': 'Zone A',
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
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1000',
      'description':
          'Enjoy music from Taylor Swift different eras.',
      'tickets': [
        {
          'seller': 'SwiftieShop',
          'seat': 'CAT 1',
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
          'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=1000',
      'description':
          'Experience an unforgettable BTS concert.',
      'tickets': [
        {
          'seller': 'ArmyStore',
          'seat': 'VIP Zone',
          'price': 4800,
          'condition': 'Available',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get filteredConcerts {
    return concerts.where((concert) {
      final keyword = searchController.text.toLowerCase();

      final matchesSearch =
          concert['name']
                  .toString()
                  .toLowerCase()
                  .contains(keyword) ||
              concert['artist']
                  .toString()
                  .toLowerCase()
                  .contains(keyword);

      final matchesCategory =
          selectedCategory == 'All' ||
              concert['category'] == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPink,

      appBar: AppBar(
        backgroundColor: lightPink,
        elevation: 0,
        title: const Text(
          'RESELL TICKET',
          style: TextStyle(
            color: darkPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.notifications_none,
              color: darkPink,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find Your Next',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: darkPink,
              ),
            ),

            const Text(
              'Favorite Concert!',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: pink,
              ),
            ),

            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search concerts or artists...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: pink,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Categories
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkPink,
              ),
            ),

            const SizedBox(height: 12),

            // Category Filter
            Wrap(
              spacing: 10,
              children: ['All', 'K-Pop', 'Pop'].map((category) {
                return ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  selectedColor: pink,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selectedCategory == category
                        ? Colors.white
                        : darkPink,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            // Popular Concerts
            const Text(
              'Popular Concerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkPink,
              ),
            ),

            const SizedBox(height: 15),

            // Concert List
            if (filteredConcerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('No concerts found.'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredConcerts.length,

                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 15,

                  // Adjust card height
                  childAspectRatio: 1.4,
                ),

                itemBuilder: (context, index) {
                  final concert = filteredConcerts[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            concert: concert,
                          ),
                        ),
                      );
                    },

                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Concert Image
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            child: Image.network(
                              concert['image'],
                              height: 125,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return Container(
                                  height: 125,
                                  color: Colors.pink.shade100,
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),

                          // Concert Information
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  concert['artist'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: darkPink,
                                    fontSize: 15,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  concert['name'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  concert['date'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                const Row(
                                  children: [
                                    Icon(
                                      Icons.confirmation_number_outlined,
                                      size: 15,
                                      color: pink,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'View Tickets',
                                      style: TextStyle(
                                        color: pink,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

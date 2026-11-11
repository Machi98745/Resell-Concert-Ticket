
import 'package:flutter/material.dart';
import 'detail.dart';
import 'favorite_service.dart';
import 'homepage.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  void openDetail(Map<String, dynamic> concert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(concert: concert),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // กลับไปหน้า HomePage
  void goToHomePage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
      (route) => false,
    );
  }

  void removeFavorite(Map<String, dynamic> concert) {
    setState(() {
      FavoriteService.removeFavorite(concert);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from favorites'),
        backgroundColor: darkPink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = FavoriteService.favorites;

    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: darkPink),
        ),
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: darkPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: favorites.isEmpty
          ? _buildEmptyState()
          : LayoutBuilder(
              builder: (context, constraints) {
                int columns = 1;

                if (constraints.maxWidth >= 1000) {
                  columns = 3;
                } else if (constraints.maxWidth >= 650) {
                  columns = 2;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: favorites.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: columns == 1 ? 2.1 : 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final concert = favorites[index];
                    return _buildFavoriteCard(concert);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border,
              color: pink,
              size: 75,
            ),
            const SizedBox(height: 15),
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                color: darkPink,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save your favorite concerts and find them here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: goToHomePage,
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Explore Concerts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> concert) {
    final image = concert['image']?.toString() ?? '';

    return GestureDetector(
      onTap: () => openDetail(concert),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                        top: Radius.circular(15),
                      ),
                      child: image.isEmpty
                          ? _imagePlaceholder()
                          : Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _imagePlaceholder(),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => removeFavorite(concert),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.favorite,
                        color: pink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concert['name']?.toString() ?? 'Concert',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkPink,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      concert['artist']?.toString() ?? '',
                      style: const TextStyle(
                        color: pink,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      concert['date']?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
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

  Widget _imagePlaceholder() {
    return Container(
      color: lightPink,
      child: const Center(
        child: Icon(
          Icons.music_note,
          color: pink,
          size: 40,
        ),
      ),
    );
  }
}

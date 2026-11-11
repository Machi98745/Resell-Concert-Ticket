
class FavoriteService {
  static final List<Map<String, dynamic>> favorites = [];

  static bool isFavorite(Map<String, dynamic> concert) {
    return favorites.any(
      (item) => item['name'] == concert['name'],
    );
  }

  static void toggleFavorite(Map<String, dynamic> concert) {
    if (isFavorite(concert)) {
      favorites.removeWhere(
        (item) => item['name'] == concert['name'],
      );
    } else {
      favorites.add(concert);
    }
  }

  static void removeFavorite(Map<String, dynamic> concert) {
    favorites.removeWhere(
      (item) => item['name'] == concert['name'],
    );
  }
}

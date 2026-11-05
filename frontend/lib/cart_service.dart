
class CartService {
  static final List<Map<String, dynamic>> items = [];

  static void addToCart(Map<String, dynamic> concert, Map<String, dynamic> ticket) {
    items.add({
      'concertName': concert['name'],
      'artist': concert['artist'],
      'date': concert['date'],
      'location': concert['location'],
      'image': concert['image'],
      'seller': ticket['seller'],
      'seat': ticket['seat'] ?? ticket['zone'] ?? '',
      'price': ticket['price'],
    });
  }

  static void removeFromCart(int index) {
    items.removeAt(index);
  }

  static double get totalPrice {
    return items.fold(
      0,
      (total, item) => total + (item['price'] as num).toDouble(),
    );
  }
}

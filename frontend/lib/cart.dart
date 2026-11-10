
import 'package:flutter/material.dart';
import 'cart_service.dart';
import 'historypage.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Future<void> _checkout() async {
    if (CartService.items.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text(
          'Do you want to proceed with this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: pink,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    CartService.createOrder();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = CartService.items;

    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: darkPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 0,
      ),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 75,
                    color: pink,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: darkPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Add some tickets to get started!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      final price =
                          double.tryParse(
                            item['price'].toString(),
                          ) ??
                          0;

                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: item['image'] != null
                                    ? Image.network(
                                        item['image'].toString(),
                                        width: 85,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _imagePlaceholder(),
                                      )
                                    : _imagePlaceholder(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['concertName']?.toString() ??
                                          'Concert',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: darkPink,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Artist: ${item['artist'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Seller: ${item['seller'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Seat: ${item['seat'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '฿${price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: pink,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: () {
                                  setState(() {
                                    CartService.removeFromCart(index);
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: darkPink,
                            ),
                          ),
                          Text(
                            '฿${CartService.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 21,
                              color: pink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Proceed to Checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 85,
      height: 100,
      color: lightPink,
      child: const Icon(
        Icons.music_note,
        size: 35,
        color: pink,
      ),
    );
  }
}

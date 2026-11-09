
import 'package:flutter/material.dart';
import 'cart_service.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    final tickets = CartService.history.reversed.toList();

    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        backgroundColor: pink,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ticket History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: tickets.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                return _buildTicketCard(tickets[index]);
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
            Icon(
              Icons.confirmation_number_outlined,
              size: 75,
              color: pink.withOpacity(0.6),
            ),
            const SizedBox(height: 15),
            const Text(
              'No Ticket History',
              style: TextStyle(
                color: darkPink,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your purchased tickets will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final price = (ticket['price'] as num?)?.toDouble() ?? 0;
    final purchaseDate = ticket['purchaseDate'];

    String formattedPurchaseDate = 'Unknown date';

    if (purchaseDate is DateTime) {
      formattedPurchaseDate =
          '${purchaseDate.day}/${purchaseDate.month}/${purchaseDate.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: Image.network(
              ticket['image']?.toString() ?? '',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: lightPink,
                child: const Icon(
                  Icons.music_note,
                  size: 50,
                  color: pink,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket['concertName']?.toString() ?? 'Concert',
                        style: const TextStyle(
                          color: darkPink,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PURCHASED',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ticket['artist']?.toString() ?? '',
                  style: const TextStyle(
                    color: pink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 25),
                _detailRow(Icons.calendar_today_outlined, 'Concert Date',
                    ticket['date']?.toString() ?? '-'),
                _detailRow(Icons.location_on_outlined, 'Location',
                    ticket['location']?.toString() ?? '-'),
                _detailRow(Icons.event_seat_outlined, 'Seat / Zone',
                    ticket['seat']?.toString() ?? '-'),
                _detailRow(Icons.shopping_bag_outlined, 'Purchased On',
                    formattedPurchaseDate),
                const Divider(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(
                        color: darkPink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '฿${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: pink,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: pink),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: darkPink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

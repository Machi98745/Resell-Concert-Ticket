import 'package:flutter/material.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> concert;

  const DetailPage({
    super.key,
    required this.concert,
  });

  @override
  Widget build(BuildContext context) {
    final List tickets = concert['tickets'] ?? [];

    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        backgroundColor: lightPink,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkPink),
        title: const Text(
          'Concert Details',
          style: TextStyle(
            color: darkPink,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Concert Image
            Image.network(
              concert['image'],
              width: double.infinity,
              height: 230,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 230,
                  color: Colors.pink.shade100,
                  child: const Center(
                    child: Icon(
                      Icons.music_note,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    concert['artist'],
                    style: const TextStyle(
                      color: pink,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    concert['name'],
                    style: const TextStyle(
                      color: darkPink,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Concert Information
                  infoRow(
                    Icons.calendar_month,
                    'Date',
                    concert['date'],
                  ),
                  infoRow(
                    Icons.location_on_outlined,
                    'Location',
                    concert['location'],
                  ),
                  infoRow(
                    Icons.music_note,
                    'Category',
                    concert['category'],
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'About This Concert',
                    style: TextStyle(
                      color: darkPink,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    concert['description'],
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Resell Ticket Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Resell Tickets',
                        style: TextStyle(
                          color: darkPink,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${tickets.length} Tickets',
                        style: const TextStyle(
                          color: pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  if (tickets.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No resale tickets available.'),
                      ),
                    )
                  else
                    ...tickets.map((ticket) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: pink.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: lightPink,
                                  child: Icon(
                                    Icons.person,
                                    color: pink,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    ticket['seller'],
                                    style: const TextStyle(
                                      color: darkPink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const Text(
                                  'Resell',
                                  style: TextStyle(
                                    color: pink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 25),

                            Text(
                              'Seat: ${ticket['seat']}',
                              style: const TextStyle(
                                color: darkPink,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '฿${ticket['price']}',
                                  style: const TextStyle(
                                    color: pink,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: pink,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Purchase feature coming soon!',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Buy Ticket'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Text(
                              'Status: ${ticket['condition']}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(icon, color: pink, size: 21),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: const TextStyle(
              color: darkPink,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

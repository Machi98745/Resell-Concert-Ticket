import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/controller/admin_controller.dart';
import 'package:frontend/views/login.dart';

// Palette: White, Pink, Dark Charcoal, Slate Grey
const Color primaryPink = Color(0xFFE85D9E);
const Color softPink = Color(0xFFFFF0F5);
const Color darkCharcoal = Color(0xFF191923);
const Color slateGrey = Color(0xFF6C757D);
const Color lightBg = Color(0xFFF8F9FA);

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController searchController = TextEditingController();
  final AdminController _adminController = AdminController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String selectedFilter = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // ดึงข้อมูลผู้ใช้ทั้งหมดจาก Backend API (กรองเฉพาะบัญชีที่ไม่ใช่ admin และตัดคำว่า (Verified Seller) ออก)
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final rawUsers = await _adminController.getAllUsers();
      setState(() {
        users = rawUsers
            .where(
              (u) =>
                  (u['role'] ?? 'customer').toString().toLowerCase() != 'admin',
            )
            .map((u) {
              final bool active = u['is_active'] == 1 || u['is_active'] == true;
              final bool verified =
                  u['is_verified'] == 1 || u['is_verified'] == true;
              final String createdAt = (u['created_at'] ?? '').toString();
              final String formattedDate =
                  createdAt.length >= 10 ? createdAt.substring(0, 10) : 'N/A';

              final String cleanFullName = (u['full_name'] ?? 'Unknown')
                  .toString()
                  .replaceAll(
                    RegExp(r'\s*\(Verified Seller\)', caseSensitive: false),
                    '',
                  )
                  .trim();

              return {
                'id': u['user_id'].toString(),
                'full_name': cleanFullName,
                'email': u['email'] ?? 'N/A',
                'phone': u['phone'] ?? 'N/A',
                'kycStatus': verified ? 'Verified' : 'Pending',
                'ticketsSold': u['tickets_sold'] ?? 0,
                'ticketsBought': u['tickets_bought'] ?? 0,
                'isActive': active,
                'joinedDate': formattedDate,
                'username': u['username'] ?? '',
                'role': u['role'] ?? 'customer',
                'isVerified': verified ? 1 : 0,
                'ownedTickets': u['ownedTickets'] ?? [],
                'resellListings': u['resellListings'] ?? [],
              };
            })
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // filter bar
  List<Map<String, dynamic>> get filteredUsers {
    final query = searchController.text.toLowerCase();
    return users.where((user) {
      final matchesSearch =
          user['full_name'].toString().toLowerCase().contains(query) ||
          user['email'].toString().toLowerCase().contains(query) ||
          user['id'].toString().toLowerCase().contains(query);

      final matchesFilter =
          selectedFilter == 'All' ||
          (selectedFilter == 'Active' && user['isActive'] == true) ||
          (selectedFilter == 'Suspended' && user['isActive'] == false);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // เช็กว่าเป็นการจัดส่งแบบไปรษณีย์ (Parcel Shipping) หรือไม่
  bool _isParcelShipping(Map<String, dynamic> item) {
    final String method = (item['deliveryType'] ??
            item['delivery_type'] ??
            item['delivery_method'] ??
            'Parcel Shipping')
        .toString()
        .toLowerCase();

    return method.contains('parcel') ||
        method.contains('delivery') ||
        method.contains('post') ||
        method.contains('mail');
  }

  // =============================== logic ======================================
  /// logout + ลบ JWT Token ออกจากเครื่อง
  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(color: darkCharcoal, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: slateGrey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: slateGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _storage.delete(key: 'jwt_token');
                await _storage.delete(key: 'user_role');
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  /// คำนวณ Success Rate (ถ้ายังไม่เคยขายเลยแสดง 0%)
  String _calculateSuccessRate(Map<String, dynamic> user) {
    final int sold = (user['ticketsSold'] as num?)?.toInt() ?? 0;
    final List listings = (user['resellListings'] as List?) ?? [];
    final int uncompleted = listings.where((l) => l['status'] != 'sold').length;
    final int totalAttempts = sold + uncompleted;

    if (totalAttempts == 0) return '0%';

    final double rate = (sold / totalAttempts) * 100;
    return '${rate.toStringAsFixed(0)}%';
  }

  /// disable / enable user account (ยิง API จริง)
  Future<void> _toggleUserStatusDirectly(String userId) async {
    final index = users.indexWhere((user) => user['id'].toString() == userId);
    if (index == -1) return;

    final bool oldStatus = users[index]['isActive'];
    final bool newStatus = !oldStatus;
    final String name = users[index]['full_name'].toString();

    setState(() {
      users[index]['isActive'] = newStatus;
    });

    try {
      await _adminController.updateUserStatus(
        userId: userId,
        isActive: newStatus,
      );
      if (!mounted) return;
      _showSnackBar(
        newStatus
            ? 'Account "$name" is now ACTIVE.'
            : 'Account "$name" is now SUSPENDED.',
        newStatus ? primaryPink : darkCharcoal,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        users[index]['isActive'] = oldStatus;
      });
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        Colors.redAccent,
      );
    }
  }

  /// delete user account (ยิง API จริง)
  Future<void> _deleteUser(String userId) async {
    final index = users.indexWhere((user) => user['id'].toString() == userId);
    if (index == -1) return;

    final String name = users[index]['full_name'].toString();

    try {
      await _adminController.deleteUser(userId);
      if (!mounted) return;
      setState(() {
        users.removeAt(index);
      });
      _showSnackBar(
        'Account "$name" deleted successfully.',
        Colors.redAccent,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        Colors.redAccent,
      );
    }
  }

  // =============================== Dialogs and popups ======================================
  /// ยืนยันลบบัญชี
  void _showDeleteDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                'Delete Account',
                style: TextStyle(
                  color: darkCharcoal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${user['full_name']}"? This action cannot be undone.',
            style: const TextStyle(color: slateGrey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: slateGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteUser(user['id'].toString());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog My Tickets
  void _showTicketAndPaymentDetailsDialog(Map<String, dynamic> ticket) {
    final bool isParcel = _isParcelShipping(ticket);
    final int basePaid =
        ((ticket['paidAmount'] ?? ticket['originalPrice']) as num?)?.toInt() ??
            0;
    final int shippingFee = isParcel
        ? (((ticket['shippingFee'] ?? ticket['shipping_fee']) as num?)
                    ?.toInt() ??
                50)
        : 0;
    final int totalPaid = basePaid + shippingFee;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: softPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_outlined,
                        color: primaryPink,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket['concert']?.toString() ?? 'Concert Ticket',
                            style: const TextStyle(
                              color: darkCharcoal,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Code: ${ticket['ticketCode']}',
                            style: const TextStyle(
                              color: primaryPink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: slateGrey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _simpleInfoRow('Venue', ticket['venue'] ?? 'N/A'),
                      const SizedBox(height: 10),
                      _simpleInfoRow(
                        'Zone / Seat',
                        '${ticket['zone'] ?? 'N/A'} (${ticket['seat'] ?? 'N/A'})',
                      ),
                      const SizedBox(height: 10),
                      _simpleInfoRow(
                        'Delivery Method',
                        isParcel
                            ? 'Parcel Shipping'
                            : (ticket['delivery_method'] ?? 'Digital Transfer')
                                .toString(),
                      ),
                      const SizedBox(height: 10),
                      _simpleInfoRow('Ticket Price', '฿$basePaid'),
                      if (shippingFee > 0) ...[
                        const SizedBox(height: 10),
                        _simpleInfoRow(
                          'Shipping Fee (Parcel)',
                          '+ ฿$shippingFee',
                        ),
                      ],
                      const SizedBox(height: 10),
                      _simpleInfoRow(
                        'Total Paid Amount',
                        '฿$totalPaid',
                        isBold: true,
                      ),
                      if (ticket['paymentMethod'] != null) ...[
                        const SizedBox(height: 10),
                        _simpleInfoRow(
                          'Payment Method',
                          ticket['paymentMethod'].toString().toUpperCase(),
                        ),
                      ],
                      if (ticket['paidAt'] != null) ...[
                        const SizedBox(height: 10),
                        _simpleInfoRow(
                          'Transaction Date',
                          ticket['paidAt'].toString(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seller Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkCharcoal,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _simpleInfoRow(
                        'Name',
                        ticket['sellerName'] ?? 'Unknown Seller',
                      ),
                      const SizedBox(height: 8),
                      _simpleInfoRow('Email', ticket['sellerEmail'] ?? 'N/A'),
                      const SizedBox(height: 8),
                      _simpleInfoRow('Phone', ticket['sellerPhone'] ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog Resell (คำนวณค่าธรรมเนียม + ค่าส่งไปรษณีย์ 50 บาท)
  void _showResellDetailsDialog(Map<String, dynamic> resell) {
    final bool isSold = resell['status'] == 'sold';
    final bool isParcel = _isParcelShipping(resell);
    final double resellPrice =
        (resell['resellPrice'] ?? resell['resell_price'] as num?)?.toDouble() ??
            0.0;
    final int commissionFee = (resellPrice * 0.02).round();

    final int rawShipping =
        ((resell['shippingFee'] ?? resell['shipping_fee']) as num?)?.toInt() ??
            0;
    final int shippingFee = isParcel ? (rawShipping > 0 ? rawShipping : 50) : 0;

    final int totalBuyerPrice =
        resellPrice.toInt() + commissionFee + shippingFee;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: softPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sell_outlined,
                        color: primaryPink,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resell['concert']?.toString() ?? 'Concert Ticket',
                            style: const TextStyle(
                              color: darkCharcoal,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: #${resell['listingId']}',
                            style: const TextStyle(
                              color: primaryPink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: slateGrey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _simpleInfoRow(
                        'Ticket Code',
                        resell['ticketCode'].toString(),
                      ),
                      const SizedBox(height: 10),
                      _simpleInfoRow(
                        'Zone / Seat',
                        '${resell['zone'] ?? 'N/A'} (${resell['seat'] ?? 'N/A'})',
                      ),
                      const SizedBox(height: 10),
                      _simpleInfoRow(
                        'Delivery Type',
                        isParcel
                            ? 'Parcel Shipping'
                            : (resell['deliveryType'] ??
                                    resell['delivery_type'] ??
                                    'Digital Transfer')
                                .toString(),
                      ),
                      const SizedBox(height: 10),
                      _simpleInfoRow(
                        'Status',
                        isSold ? 'Sold' : resell['status'].toString(),
                      ),
                      const SizedBox(height: 10),
                      _simpleInfoRow(
                        'Shipping Status',
                        isSold
                            ? 'Shipped'
                            : (resell['shippingStatus'] ?? 'Pending'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkCharcoal,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _simpleInfoRow(
                        'Seller Ticket Price',
                        '฿${resellPrice.toInt()}',
                      ),
                      const SizedBox(height: 8),
                      _simpleInfoRow('Platform Fee (+2%)', '+ ฿$commissionFee'),
                      if (shippingFee > 0) ...[
                        const SizedBox(height: 8),
                        _simpleInfoRow(
                          'Shipping Fee (Parcel)',
                          '+ ฿$shippingFee',
                        ),
                      ],
                      const Divider(height: 16),
                      _simpleInfoRow(
                        'Total Buyer Payment',
                        '฿$totalBuyerPrice',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// btn show user details
  void _showUserDetailsSheet(Map<String, dynamic> user) {
    final ownedTickets = List.from(user['ownedTickets'] ?? []);
    final resellListings = List.from(user['resellListings'] ?? []);
    final String calculatedSuccessRate = _calculateSuccessRate(user);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: softPink,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: primaryPink,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['full_name'].toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkCharcoal,
                              ),
                            ),
                            Text(
                              'ID: ${user['id']}',
                              style: const TextStyle(
                                color: slateGrey,
                                fontSize: 13,
                              ),
                            ),
                            if (user['username'] != null)
                              Row(
                                children: [
                                  Text(
                                    '@${user['username']}',
                                    style: const TextStyle(
                                      color: slateGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: softPink,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      (user['role'] ?? 'customer')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: primaryPink,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: slateGrey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _detailTile(
                        'Tickets Sold',
                        '${user['ticketsSold']}',
                        Icons.confirmation_number_outlined,
                      ),
                      const SizedBox(width: 12),
                      _detailTile(
                        'Tickets Bought',
                        '${user['ticketsBought']}',
                        Icons.shopping_bag_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _detailTile(
                        'Success Rate',
                        calculatedSuccessRate,
                        Icons.star_outline,
                      ),
                      const SizedBox(width: 12),
                      _detailTile(
                        'Verification',
                        '${user['kycStatus']}',
                        Icons.verified_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _simpleInfoRow('Email', user['email'].toString()),
                        const Divider(height: 20),
                        _simpleInfoRow('Phone', user['phone'].toString()),
                        const Divider(height: 20),
                        _simpleInfoRow(
                          'Member Since',
                          user['joinedDate'].toString(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number,
                        size: 18,
                        color: primaryPink,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'My Tickets (${ownedTickets.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: darkCharcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (ownedTickets.isEmpty)
                    _buildEmptyState('No tickets owned.')
                  else
                    ...ownedTickets.map((t) {
                      final bool isParcel = _isParcelShipping(t);
                      final int basePaid =
                          ((t['paidAmount'] ?? t['originalPrice']) as num?)
                                  ?.toInt() ??
                              0;
                      final int shipFee = isParcel
                          ? (((t['shippingFee'] ?? t['shipping_fee']) as num?)
                                      ?.toInt() ??
                                  50)
                          : 0;
                      final int totalPaid = basePaid + shipFee;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['concert']?.toString() ??
                                        'Concert Ticket',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkCharcoal,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Code: ${t['ticketCode']} | From: ${t['sellerName'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      color: slateGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '฿$totalPaid',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryPink,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () =>
                                      _showTicketAndPaymentDetailsDialog(t),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: softPink,
                                    foregroundColor: primaryPink,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'View',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.sell_outlined,
                        size: 18,
                        color: primaryPink,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Resell (${resellListings.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: darkCharcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (resellListings.isEmpty)
                    _buildEmptyState('No resell items.')
                  else
                    ...resellListings.map((r) {
                      final bool isSold = r['status'] == 'sold';
                      final bool isParcel = _isParcelShipping(r);
                      final double price =
                          (r['resellPrice'] ?? r['resell_price'] as num?)
                                  ?.toDouble() ??
                              0.0;
                      final int fee = (price * 0.02).round();
                      final int shipFee = isParcel ? 50 : 0;
                      final int totalWithShipping =
                          price.toInt() + fee + shipFee;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['concert']?.toString() ??
                                        'Concert Ticket',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: darkCharcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Zone: ${r['zone'] ?? 'N/A'} | Seat: ${r['seat'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      color: darkCharcoal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Code: ${r['ticketCode']}',
                                        style: const TextStyle(
                                          color: slateGrey,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSold
                                              ? Colors.green.shade50
                                              : softPink,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: isSold
                                                ? Colors.green.shade300
                                                : primaryPink.withOpacity(0.4),
                                          ),
                                        ),
                                        child: Text(
                                          isSold ? 'Shipped' : 'Available',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isSold
                                                ? Colors.green.shade700
                                                : primaryPink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '฿$totalWithShipping',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryPink,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (shipFee > 0)
                                      const Text(
                                        '(incl. ฿50 ship)',
                                        style: TextStyle(
                                          color: slateGrey,
                                          fontSize: 9,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _showResellDetailsDialog(r),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: softPink,
                                    foregroundColor: primaryPink,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'View',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =============================== main build ================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryPink),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetricsSection(),
                          const SizedBox(height: 28),
                          _buildTitleSection(),
                          const SizedBox(height: 16),
                          _buildSearchAndFilterBar(),
                          const SizedBox(height: 20),
                          _buildUserCardsList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================== widget components ===============================
  /// Header (มีเฉพาะปุ่ม Log Out ไม่มีปุ่ม Refresh)
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Ticket',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: darkCharcoal,
                  ),
                ),
                TextSpan(
                  text: 'Pink',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryPink,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: darkCharcoal,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout, color: slateGrey, size: 20),
            tooltip: 'Log Out',
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  /// total active suspended
  Widget _buildMetricsSection() {
    final total = users.length;
    final active = users.where((u) => u['isActive'] == true).length;
    final suspended = users.where((u) => u['isActive'] == false).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;
        return Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          children: [
            _metricCard(
              'Total Members',
              '$total',
              Icons.people_outline,
              darkCharcoal,
              softPink,
            ),
            SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 12 : 0),
            _metricCard(
              'Active Accounts',
              '$active',
              Icons.check_circle_outline,
              primaryPink,
              softPink,
            ),
            SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 12 : 0),
            _metricCard(
              'Suspended',
              '$suspended',
              Icons.block_outlined,
              slateGrey,
              Colors.grey.shade200,
            ),
          ],
        );
      },
    );
  }

  /// Card total active suspended
  Widget _metricCard(
    String label,
    String value,
    IconData icon,
    Color accentColor,
    Color bgIconColor,
  ) {
    return Expanded(
      flex: MediaQuery.of(context).size.width < 700 ? 0 : 1,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgIconColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: slateGrey, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkCharcoal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// หัวข้อ User Management
  Widget _buildTitleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkCharcoal,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Toggle account access or view detailed user activity.',
          style: TextStyle(color: slateGrey, fontSize: 13),
        ),
      ],
    );
  }

  /// search bar and filter dropdown
  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (val) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search user, email, or ID...',
                hintStyle: TextStyle(color: slateGrey, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: primaryPink),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFilter,
              icon: const Icon(Icons.tune, color: darkCharcoal, size: 20),
              style: const TextStyle(
                color: darkCharcoal,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedFilter = value);
                }
              },
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Status')),
                DropdownMenuItem(value: 'Active', child: Text('Active Only')),
                DropdownMenuItem(
                  value: 'Suspended',
                  child: Text('Suspended Only'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// card user
  Widget _buildUserCardsList() {
    final list = filteredUsers;

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'No matching users found.',
            style: TextStyle(color: slateGrey, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = list[index];
        final bool isActive = user['isActive'] == true;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive ? softPink : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: isActive ? primaryPink : slateGrey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user['full_name'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: darkCharcoal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user['id'].toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: slateGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user['email'].toString(),
                      style: const TextStyle(color: slateGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showUserDetailsSheet(user),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details & History',
                            style: TextStyle(
                              fontSize: 11,
                              color: primaryPink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: primaryPink,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isActive ? 'Active' : 'Suspended',
                        style: TextStyle(
                          color: isActive ? primaryPink : slateGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Switch(
                        value: isActive,
                        activeColor: primaryPink,
                        activeTrackColor: softPink,
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade200,
                        onChanged: (_) =>
                            _toggleUserStatusDirectly(user['id'].toString()),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => _showDeleteDialog(user),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Empty State Helper
  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: const TextStyle(color: slateGrey, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Detail Tile Helper ใน Btn view user details
  Widget _detailTile(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lightBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: primaryPink),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: slateGrey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkCharcoal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Simple Info Row Helper สำหรับแสดงข้อมูลคู่ key-value
  Widget _simpleInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? darkCharcoal : slateGrey,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isBold ? primaryPink : darkCharcoal,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
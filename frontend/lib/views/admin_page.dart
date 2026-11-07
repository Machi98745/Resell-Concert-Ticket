import 'package:flutter/material.dart';

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
  String selectedFilter = 'All';

  // Mock data 
  final List<Map<String, dynamic>> users = [
    {
      'id': 'USR-001',
      'name': 'PinkSeller',
      'email': 'pinkseller@example.com',
      'phone': '+66 81 234 5678',
      'kycStatus': 'Verified',
      'ticketsSold': 12,
      'ticketsBought': 3,
      'successRate': '100%',
      'isActive': true,
      'joinedDate': '10 Jan 2026',
    },
    {
      'id': 'USR-002',
      'name': 'LisaFan',
      'email': 'lisafan@example.com',
      'phone': '+66 89 987 6543',
      'kycStatus': 'Verified',
      'ticketsSold': 5,
      'ticketsBought': 8,
      'successRate': '100%',
      'isActive': true,
      'joinedDate': '15 Feb 2026',
    },
    {
      'id': 'USR-003',
      'name': 'Scammer101',
      'email': 'fakeuser@example.com',
      'phone': '+66 61 111 2222',
      'kycStatus': 'Pending',
      'ticketsSold': 0,
      'ticketsBought': 0,
      'successRate': '0%',
      'isActive': false,
      'joinedDate': '01 Mar 2026',
    },
    {
      'id': 'USR-004',
      'name': 'SwiftieShop',
      'email': 'swiftie@example.com',
      'phone': '+66 82 444 5555',
      'kycStatus': 'Verified',
      'ticketsSold': 24,
      'ticketsBought': 15,
      'successRate': '98%',
      'isActive': true,
      'joinedDate': '20 Nov 2025',
    },
    {
      'id': 'USR-005',
      'name': 'BlinkBuyer',
      'email': 'blinkbuyer@example.com',
      'phone': '+66 95 333 7777',
      'kycStatus': 'Verified',
      'ticketsSold': 2,
      'ticketsBought': 11,
      'successRate': '100%',
      'isActive': true,
      'joinedDate': '05 Mar 2026',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  
  void _toggleUserStatusDirectly(String userId) {
    final index = users.indexWhere((user) => user['id'].toString() == userId);
    if (index == -1) return;

    final bool newStatus = !users[index]['isActive'];

    setState(() {
      users[index]['isActive'] = newStatus;
    });

    final String name = users[index]['name'].toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus
              ? 'Account "$name" is now ACTIVE.'
              : 'Account "$name" is now SUSPENDED.',
        ),
        backgroundColor: newStatus ? primaryPink : darkCharcoal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // delete
  void _deleteUser(String userId) {
    final index = users.indexWhere((user) => user['id'].toString() == userId);
    if (index == -1) return;

    final String name = users[index]['name'].toString();

    setState(() {
      users.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account "$name" deleted successfully.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  
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
            'Are you sure you want to delete "${user['name']}"? This action cannot be undone.',
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

  // show each data
  void _showUserDetailsSheet(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Sheet
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
                          user['name'].toString(),
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

              // Overview Title
              const Text(
                'Account Statistics & Info',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkCharcoal,
                ),
              ),
              const SizedBox(height: 14),

              // Detail Cards
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
                    '${user['successRate']}',
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
              // Personal Info List
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.email_outlined,
                      'Email',
                      user['email'].toString(),
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      Icons.phone_outlined,
                      'Phone',
                      user['phone'].toString(),
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      Icons.calendar_today_outlined,
                      'Member Since',
                      user['joinedDate'].toString(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: slateGrey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: slateGrey, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: darkCharcoal,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> get filteredUsers {
    final query = searchController.text.toLowerCase();
    return users.where((user) {
      final matchesSearch =
          user['name'].toString().toLowerCase().contains(query) ||
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
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

  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: darkCharcoal,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
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
              'ADMIN PANEL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 18,
            backgroundColor: softPink,
            child: Icon(
              Icons.admin_panel_settings,
              color: primaryPink,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // METRICS CARDS SECTION
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

  // TITLE & SUBTITLE
  Widget _buildTitleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Directory',
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

  // SEARCH & FILTER BAR
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

  // LIST OF USER CARDS
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
              // Icon แทนรูปภาพ
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
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user['name'].toString(),
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
                    // ปุ่มเปิดดูข้อมูลประวัติผู้ใช้
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
              // Direct Toggle Switch & Actions
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
                        // กดแล้วสลับสถานะทันทีแบบไม่มี Pop-up ยืนยัน
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
}

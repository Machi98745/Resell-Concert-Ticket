import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cart_service.dart';
import 'historypage.dart';
import 'favorite.dart';
import 'login.dart';
import 'package:frontend/server/api_service.dart';

const Color pink = Color(0xFFE85D9E);
const Color lightPink = Color(0xFFFFF5F8);
const Color darkPink = Color(0xFF54283D);

// =====================================================
// PROFILE PAGE
// =====================================================

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = '';
  String email = '';
  String phone = '';

  String? profileImageUrl;
  bool isUploadingImage = false;

  final ImagePicker picker = ImagePicker();

  bool isLoading = true;
  bool isSaving = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // LOAD PROFILE FROM MYSQL
  Future<void> loadProfile() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final user = await ApiService.getProfile();

      if (!mounted) return;

      final imagePath = user['profile_image']?.toString();

      setState(() {
        name = user['full_name']?.toString() ?? '';
        email = user['email']?.toString() ?? '';
        phone = user['phone']?.toString() ?? '';

        profileImageUrl = imagePath == null || imagePath.isEmpty
            ? null
            : _withCacheBuster(ApiService.getImageUrl(imagePath));

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = e.toString();
      });
    }
  }

  // PREVENT OLD IMAGE FROM BEING CACHED
  String _withCacheBuster(String url) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  // SELECT AND UPLOAD PROFILE IMAGE
  Future<void> pickProfileImage() async {
    if (isUploadingImage) return;

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null || !mounted) return;

      setState(() {
        isUploadingImage = true;
      });

      final imagePath = await ApiService.uploadProfileImage(image);

      if (!mounted) return;

      setState(() {
        profileImageUrl = _withCacheBuster(ApiService.getImageUrl(imagePath));
        isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // PROFILE AVATAR
  Widget profileAvatar({double radius = 48}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      backgroundImage: profileImageUrl != null
          ? NetworkImage(profileImageUrl!)
          : null,
      child: profileImageUrl == null
          ? Icon(Icons.person, size: radius * 1.15, color: pink)
          : null,
    );
  }

  // UPLOAD BUTTON
  Widget cameraButton({
    double size = 18,
    Color backgroundColor = pink,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: isUploadingImage ? null : pickProfileImage,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: isUploadingImage
            ? SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  color: iconColor,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.camera_alt, color: iconColor, size: size),
      ),
    );
  }

  // EDIT PROFILE AND SAVE TO MYSQL
  Future<void> editProfile() async {
    if (isLoading || isSaving) return;

    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);

    bool dialogSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveProfile() async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              final newPhone = phoneController.text.trim();

              if (newName.isEmpty || newEmail.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Name and email cannot be empty.'),
                  ),
                );
                return;
              }

              final emailPattern = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

              if (!emailPattern.hasMatch(newEmail)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address.'),
                  ),
                );
                return;
              }

              setDialogState(() {
                dialogSaving = true;
              });

              try {
                final updatedUser = await ApiService.updateProfile({
                  'full_name': newName,
                  'email': newEmail,
                  'phone': newPhone,
                });

                if (!mounted || !dialogContext.mounted) return;

                setState(() {
                  name = updatedUser['full_name']?.toString() ?? newName;
                  email = updatedUser['email']?.toString() ?? newEmail;
                  phone = updatedUser['phone']?.toString() ?? newPhone;
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  dialogSaving = false;
                });

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Unable to update profile: $e')),
                );
              }
            }

            return AlertDialog(
              title: const Text(
                'Edit Profile',
                style: TextStyle(color: darkPink, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        profileAvatar(radius: 48),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: dialogSaving || isUploadingImage
                                ? null
                                : () async {
                                    await pickProfileImage();

                                    if (dialogContext.mounted) {
                                      setDialogState(() {});
                                    }
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: pink,
                                shape: BoxShape.circle,
                              ),
                              child: isUploadingImage
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _editField('Full Name', nameController),
                    const SizedBox(height: 12),
                    _editField('Email', emailController),
                    const SizedBox(height: 12),
                    _editField('Phone Number', phoneController),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: dialogSaving || isUploadingImage
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: dialogSaving || isUploadingImage
                      ? null
                      : saveProfile,
                  child: dialogSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  Widget _editField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pink),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // NAVIGATION
  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
  }

  void openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoritePage()),
    );
  }

  void openReselling() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyResellingPage()),
    );
  }

  void openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  void openHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpSupportPage()),
    );
  }

  // LOG OUT
  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Log Out',
            style: TextStyle(color: darkPink, fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.clearToken();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPink,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: pink))
            : loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: pink, size: 55),
                      const SizedBox(height: 12),
                      const Text(
                        'Unable to load profile',
                        style: TextStyle(
                          color: darkPink,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: loadProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pink,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: pink,
                onRefresh: loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 25),
                      _buildProfileCard(),
                      const SizedBox(height: 20),
                      _buildAccountMenu(),
                      const SizedBox(height: 20),
                      _buildLogoutButton(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // PROFILE HEADER
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [pink, darkPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              const Text(
                'MY PROFILE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: editProfile,
                tooltip: 'Edit Profile',
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              profileAvatar(radius: 48),
              Positioned(
                bottom: 0,
                right: 0,
                child: cameraButton(
                  backgroundColor: Colors.white,
                  iconColor: pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // PERSONAL INFORMATION
  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _whiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                color: darkPink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            _infoRow(Icons.person_outline, 'Full Name', name),
            const Divider(height: 25),
            _infoRow(Icons.email_outlined, 'Email', email),
            const Divider(height: 25),
            _infoRow(
              Icons.phone_outlined,
              'Phone Number',
              phone.isEmpty ? '-' : phone,
            ),
          ],
        ),
      ),
    );
  }

  // ACCOUNT MENU
  Widget _buildAccountMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _whiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Account',
              style: TextStyle(
                color: darkPink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _menuItem(
              Icons.confirmation_number_outlined,
              'My Tickets',
              openHistory,
            ),
            _menuItem(Icons.favorite_border, 'My Favorites', openFavorites),
            _menuItem(Icons.sell_outlined, 'My Reselling', openReselling),
            _menuItem(Icons.settings_outlined, 'Settings', openSettings),
            _menuItem(Icons.help_outline, 'Help & Support', openHelp),
          ],
        ),
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: pink, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: darkPink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: pink),
      title: Text(
        title,
        style: const TextStyle(
          color: darkPink,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: logout,
          icon: const Icon(Icons.logout),
          label: const Text('Log Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: pink,
            side: const BorderSide(color: pink),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// MY RESELLING PAGE
// =====================================================

class MyResellingPage extends StatefulWidget {
  const MyResellingPage({super.key});

  @override
  State<MyResellingPage> createState() => _MyResellingPageState();
}

class _MyResellingPageState extends State<MyResellingPage> {
  List<Map<String, dynamic>> myListings = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadMyListings();
  }

  // LOAD LISTINGS FROM BACKEND
  Future<void> loadMyListings() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getMyResellListings();

      if (!mounted) return;

      setState(() {
        myListings = result;
        isLoading = false;
      });

      debugPrint('My resell listings: $result');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });

      debugPrint('Load my resell listings error: $e');
    }
  }

  String getValue(
    Map<String, dynamic> ticket,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final value = ticket[key];

      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sold':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return pink;
    }
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sell_outlined, color: pink, size: 55),
            ),
            const SizedBox(height: 20),
            const Text(
              'No tickets for sale yet',
              style: TextStyle(
                color: darkPink,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your reselling tickets will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: loadMyListings,
              icon: const Icon(Icons.refresh, color: pink),
              label: const Text('Refresh', style: TextStyle(color: pink)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: pink, size: 50),
            const SizedBox(height: 12),
            const Text(
              'Unable to load your listings',
              style: TextStyle(
                color: darkPink,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: loadMyListings,
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTicketCard(Map<String, dynamic> ticket) {
    final status = getValue(ticket, [
      'status',
      'listing_status',
    ], fallback: 'Available');

    final concert = getValue(ticket, [
      'concert',
      'concert_name',
      'title',
    ], fallback: 'Concert Ticket');

    final zone = getValue(ticket, ['zone', 'zone_name']);

    final seat = getValue(ticket, ['seat', 'seat_number']);

    final price = getValue(ticket, ['resell_price', 'price'], fallback: '0');

    final statusColor = getStatusColor(status);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    concert,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: darkPink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Zone: $zone',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Seat: $seat',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Resell Price: ฿$price',
              style: const TextStyle(
                color: pink,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        title: const Text(
          'My Reselling',
          style: TextStyle(color: darkPink, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadMyListings,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: pink))
          : errorMessage != null
          ? buildErrorState()
          : myListings.isEmpty
          ? buildEmptyState()
          : RefreshIndicator(
              color: pink,
              onRefresh: loadMyListings,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: myListings.length,
                itemBuilder: (context, index) {
                  return buildTicketCard(myListings[index]);
                },
              ),
            ),
    );
  }
}

// =====================================================
// SETTINGS PAGE
// =====================================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool emailNotifications = true;
  bool darkModeEnabled = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void changePassword() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Change Password',
            style: TextStyle(color: darkPink),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passwordField('Current Password', currentController),
                const SizedBox(height: 12),
                _passwordField('New Password', newController),
                const SizedBox(height: 12),
                _passwordField('Confirm New Password', confirmController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (currentController.text.isEmpty ||
                    newController.text.length < 6 ||
                    newController.text != confirmController.text) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Check your password. New password must be at least 6 characters and match.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                showMessage(
                  'Password change UI completed. Connect to your API to save it.',
                );
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    ).then((_) {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    });
  }

  Widget _passwordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pink),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: darkPink, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('Notifications'),
          _settingsCard([
            SwitchListTile(
              activeColor: pink,
              secondary: const Icon(Icons.notifications_outlined, color: pink),
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive app notifications'),
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() => notificationsEnabled = value);
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              activeColor: pink,
              secondary: const Icon(Icons.email_outlined, color: pink),
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive updates by email'),
              value: emailNotifications,
              onChanged: (value) {
                setState(() => emailNotifications = value);
              },
            ),
          ]),
          const SizedBox(height: 25),
          _sectionTitle('Appearance'),
          _settingsCard([
            SwitchListTile(
              activeColor: pink,
              secondary: const Icon(Icons.dark_mode_outlined, color: pink),
              title: const Text('Dark Mode'),
              subtitle: const Text('Change the app appearance'),
              value: darkModeEnabled,
              onChanged: (value) {
                setState(() => darkModeEnabled = value);
                showMessage(
                  value
                      ? 'Dark Mode selected. Apply it through your app theme.'
                      : 'Light Mode selected.',
                );
              },
            ),
          ]),
          const SizedBox(height: 25),
          _sectionTitle('Account Security'),
          _settingsCard([
            ListTile(
              leading: const Icon(Icons.lock_outline, color: pink),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: changePassword,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: pink),
              title: const Text('Privacy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InformationPage(
                      title: 'Privacy',
                      content:
                          'Your account information should only be used to manage your Ticket Pink account and ticket transactions. Please keep your password private.',
                    ),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 25),
          const Center(
            child: Text(
              'Ticket Pink • Version 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// HELP & SUPPORT PAGE
// =====================================================

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  final List<Map<String, dynamic>> faqs = const [
    {
      'question': 'How can I buy a concert ticket?',
      'answer':
          'Browse upcoming concerts, select a concert, choose an available ticket, and add it to your cart. Review your order before checkout.',
    },
    {
      'question': 'How can I resell my ticket?',
      'answer':
          'Open the Sell Tickets feature, select the concert, enter your ticket zone and price, and submit your ticket for listing.',
    },
    {
      'question': 'How can I check my ticket status?',
      'answer':
          'Open My Tickets to see your purchase history and ticket information.',
    },
    {
      'question': 'How do I receive money from a sale?',
      'answer':
          'Payment and payout details depend on the platform payment system. Contact support for assistance with a transaction.',
    },
    {
      'question': 'What should I do if I have a problem?',
      'answer':
          'Use the Contact Support option and provide your email address and a description of the problem.',
    },
  ];

  void contactSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactSupportPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(color: darkPink, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [pink, darkPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent, color: Colors.white, size: 42),
                SizedBox(height: 12),
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Find answers to common questions about Ticket Pink.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              color: darkPink,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...faqs.map(
            (faq) => Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                iconColor: pink,
                collapsedIconColor: pink,
                title: Text(
                  faq['question']!,
                  style: const TextStyle(
                    color: darkPink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq['answer']!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Need more help?',
            style: TextStyle(
              color: darkPink,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 0,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: lightPink,
                child: Icon(Icons.mail_outline, color: pink),
              ),
              title: const Text(
                'Contact Support',
                style: TextStyle(color: darkPink, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Send us a message about your problem'),
              trailing: const Icon(Icons.chevron_right, color: pink),
              onTap: () => contactSupport(context),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// CONTACT SUPPORT PAGE
// =====================================================

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({super.key});

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final messageController = TextEditingController();

  String selectedTopic = 'Buying Tickets';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void submitMessage() {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: pink, size: 45),
        title: const Text('Message Prepared'),
        content: const Text(
          'Your support message has been prepared. Connect this form to your backend or email service to send it.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: pink,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pink),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        title: const Text(
          'Contact Support',
          style: TextStyle(color: darkPink, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Send us a message',
            style: TextStyle(
              color: darkPink,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us how we can help you.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 25),
          inputField('Your Name', nameController),
          const SizedBox(height: 15),
          inputField('Email Address', emailController),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: selectedTopic,
            decoration: InputDecoration(
              labelText: 'Topic',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items:
                const [
                  'Buying Tickets',
                  'Selling Tickets',
                  'Payment',
                  'Account',
                  'Other',
                ].map((topic) {
                  return DropdownMenuItem(value: topic, child: Text(topic));
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedTopic = value);
              }
            },
          ),
          const SizedBox(height: 15),
          inputField('Describe your problem', messageController, maxLines: 5),
          const SizedBox(height: 25),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: submitMessage,
              icon: const Icon(Icons.send),
              label: const Text('Submit Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// INFORMATION PAGE
// =====================================================

class InformationPage extends StatelessWidget {
  final String title;
  final String content;

  const InformationPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPink,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: darkPink, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            content,
            style: const TextStyle(color: darkPink, fontSize: 15, height: 1.6),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SHARED SETTINGS WIDGETS
// =====================================================

Widget _sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        color: darkPink,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _settingsCard(List<Widget> children) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: children),
  );
}

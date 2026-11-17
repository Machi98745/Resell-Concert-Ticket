import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController concertSearchController = TextEditingController();
  final AdminController _adminController = AdminController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 0 = User Management, 1 = Concert Management
  int _selectedTab = 0;

  String selectedFilter = 'All';
  bool _isLoading = true;
  bool _isLoadingConcerts = false;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> concerts = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchConcerts();
  }

  @override
  void dispose() {
    searchController.dispose();
    concertSearchController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }
    return token;
  }

  // =============================== API CALLS =================================
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final rawUsers = await _adminController.getAllUsers(token);
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

  Future<void> _fetchConcerts() async {
    setState(() => _isLoadingConcerts = true);
    try {
      final token = await _getToken();
      final rawConcerts = await _adminController.getAllConcerts(token);
      setState(() => concerts = List<Map<String, dynamic>>.from(rawConcerts));
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingConcerts = false);
      }
    }
  }

  // Filter Users
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

  // Filter Concerts
  List<Map<String, dynamic>> get filteredConcerts {
    final query = concertSearchController.text.toLowerCase();
    return concerts.where((c) {
      return (c['title'] ?? '').toString().toLowerCase().contains(query) ||
          (c['venue'] ?? '').toString().toLowerCase().contains(query) ||
          (c['artist'] ?? '').toString().toLowerCase().contains(query);
    }).toList();
  }

  void _showSnackBar(String message, Color bgColor) {
    if (!mounted) return;
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

  String _formatShowDateTime(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString().trim();
    if (str.isEmpty) return '';
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      final local = parsed.toLocal();
      final y = local.year.toString().padLeft(4, '0');
      final m = local.month.toString().padLeft(2, '0');
      final d = local.day.toString().padLeft(2, '0');
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      final ss = local.second.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm:$ss';
    }
    return str;
  }

  // =============================== CONCERT LOGIC =============================
  /// Dialog เพิ่ม หรือ แก้ไข คอนเสิร์ต (ป้ายชื่อคงที่ด้านบน ไม่ลอย + กดเพิ่มรูปจากเครื่อง)
  void _showConcertFormDialog({Map<String, dynamic>? existingConcert}) {
    final bool isEditing = existingConcert != null;

    final titleCtrl = TextEditingController(
      text: existingConcert?['title']?.toString() ?? '',
    );
    final artistCtrl = TextEditingController(
      text: existingConcert?['artist']?.toString() ?? '',
    );
    final venueCtrl = TextEditingController(
      text: existingConcert?['venue']?.toString() ?? '',
    );
    final posterCtrl = TextEditingController(
      text: existingConcert?['poster_url']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: existingConcert?['description']?.toString() ?? '',
    );

    final categories = [
      'Pop',
      'Rock',
      'K-Pop',
      'T-Pop',
      'Indie',
      'EDM',
      'Festival',
      'Other',
    ];
    String selectedCategory =
        (existingConcert?['category'] ?? 'T-Pop').toString();
    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'Other';
    }

    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 14));
    if (existingConcert?['show_datetime'] != null) {
      final parsed =
          DateTime.tryParse(existingConcert!['show_datetime'].toString());
      if (parsed != null) selectedDateTime = parsed.toLocal();
    }

    Uint8List? pickedImageBytes;
    String? pickedImageName;
    bool isSaving = false;

    String formatSqlDateTime(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm:00';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            Future<void> pickPosterImage() async {
              final picker = ImagePicker();
              final XFile? file = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1200,
                imageQuality: 85,
              );
              if (file != null) {
                final bytes = await file.readAsBytes();
                setModalState(() {
                  pickedImageBytes = bytes;
                  pickedImageName = file.name;
                });
              }
            }

            Future<void> pickDateAndTime() async {
              final pickedDate = await showDatePicker(
                context: dialogContext,
                initialDate: selectedDateTime,
                firstDate: DateTime(2024),
                lastDate: DateTime(2035),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme:
                          const ColorScheme.light(primary: primaryPink),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate == null || !dialogContext.mounted) return;

              final pickedTime = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme:
                          const ColorScheme.light(primary: primaryPink),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedTime == null) return;

              setModalState(() {
                selectedDateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header (ไม่มีไอคอนและคำอธิบายรอง)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 14, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Concert' : 'Add New Concert',
                              style: const TextStyle(
                                color: darkCharcoal,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, color: slateGrey),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),

                    // Form Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Poster Image Picker
                            const Text(
                              'Concert Poster',
                              style: TextStyle(
                                color: darkCharcoal,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: isSaving ? null : pickPosterImage,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 175,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: lightBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: pickedImageBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.memory(
                                              pickedImageBytes!,
                                              fit: BoxFit.cover,
                                            ),
                                            Positioned(
                                              right: 10,
                                              bottom: 10,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: darkCharcoal
                                                      .withOpacity(0.75),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      color: Colors.white,
                                                      size: 13,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Change Image',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : (posterCtrl.text.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.network(
                                                  posterCtrl.text,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Center(
                                                    child: Text(
                                                      'Tap to select poster image',
                                                      style: TextStyle(
                                                        color: slateGrey,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 10,
                                                  bottom: 10,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: darkCharcoal
                                                          .withOpacity(0.75),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        20,
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Change Image',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: const BoxDecoration(
                                                  color: softPink,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons
                                                      .add_photo_alternate_outlined,
                                                  color: primaryPink,
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Tap to upload poster image',
                                                style: TextStyle(
                                                  color: darkCharcoal,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'Supports JPG, PNG, WEBP (Max 5MB)',
                                                style: TextStyle(
                                                  color: slateGrey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          )),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _concertStaticField(
                              controller: titleCtrl,
                              label: 'Concert Name *',
                              hint: 'e.g. BODYSLAM EVERYBODYSLAM 2026',
                            ),
                            const SizedBox(height: 14),

                            _concertStaticField(
                              controller: artistCtrl,
                              label: 'Artist / Performer',
                              hint: 'e.g. Bodyslam',
                            ),
                            const SizedBox(height: 14),

                            // Category Static Label + Dropdown
                            const Text(
                              'Category',
                              style: TextStyle(
                                color: darkCharcoal,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: lightBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCategory,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: darkCharcoal,
                                  ),
                                  style: const TextStyle(
                                    color: darkCharcoal,
                                    fontSize: 14,
                                  ),
                                  items: categories
                                      .map(
                                        (cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text(cat),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(
                                        () => selectedCategory = val,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            _concertStaticField(
                              controller: venueCtrl,
                              label: 'Venue *',
                              hint: 'e.g. Impact Arena Muang Thong Thani',
                            ),
                            const SizedBox(height: 14),

                            // Show Date & Time Static Label + Picker
                            const Text(
                              'Show Date & Time *',
                              style: TextStyle(
                                color: darkCharcoal,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: isSaving ? null : pickDateAndTime,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: lightBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      formatSqlDateTime(selectedDateTime),
                                      style: const TextStyle(
                                        color: darkCharcoal,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text(
                                      'Select',
                                      style: TextStyle(
                                        color: primaryPink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            _concertStaticField(
                              controller: descCtrl,
                              label: 'Description',
                              hint: 'Concert details...',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Divider(height: 1, color: Colors.grey.shade200),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: slateGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (titleCtrl.text.trim().isEmpty ||
                                          venueCtrl.text.trim().isEmpty) {
                                        _showSnackBar(
                                          'Please enter concert name and venue.',
                                          Colors.redAccent,
                                        );
                                        return;
                                      }

                                      setModalState(() => isSaving = true);

                                      try {
                                        final token = await _getToken();
                                        String finalPosterUrl =
                                            posterCtrl.text.trim();

                                        if (pickedImageBytes != null &&
                                            pickedImageName != null) {
                                          finalPosterUrl =
                                              await _adminController
                                                  .uploadConcertPoster(
                                            token: token,
                                            fileBytes: pickedImageBytes!,
                                            fileName: pickedImageName!,
                                          );
                                        }

                                        final payload = {
                                          'title': titleCtrl.text.trim(),
                                          'artist': artistCtrl.text.trim(),
                                          'category': selectedCategory,
                                          'venue': venueCtrl.text.trim(),
                                          'show_datetime': formatSqlDateTime(
                                            selectedDateTime,
                                          ),
                                          'poster_url': finalPosterUrl,
                                          'description': descCtrl.text.trim(),
                                        };

                                        if (isEditing) {
                                          final updated = await _adminController
                                              .updateConcert(
                                            token: token,
                                            concertId:
                                                existingConcert['concert_id']
                                                    .toString(),
                                            payload: payload,
                                          );
                                          if (!dialogContext.mounted) return;
                                          Navigator.pop(dialogContext);
                                          setState(() {
                                            final idx = concerts.indexWhere(
                                              (c) =>
                                                  c['concert_id'] ==
                                                  existingConcert['concert_id'],
                                            );
                                            if (idx != -1) {
                                              concerts[idx] =
                                                  updated['concert'] != null
                                                      ? Map<String,
                                                          dynamic>.from(
                                                          updated['concert'],
                                                        )
                                                      : {
                                                          ...concerts[idx],
                                                          ...payload,
                                                        };
                                            }
                                          });
                                          _showSnackBar(
                                            'Updated "${payload['title']}" successfully.',
                                            primaryPink,
                                          );
                                        } else {
                                          final created = await _adminController
                                              .createConcert(
                                            token: token,
                                            payload: payload,
                                          );
                                          if (!dialogContext.mounted) return;
                                          Navigator.pop(dialogContext);
                                          setState(() {
                                            if (created['concert'] != null) {
                                              concerts.insert(
                                                0,
                                                Map<String, dynamic>.from(
                                                  created['concert'],
                                                ),
                                              );
                                            } else {
                                              _fetchConcerts();
                                            }
                                          });
                                          _showSnackBar(
                                            'Added "${payload['title']}" successfully.',
                                            primaryPink,
                                          );
                                        }
                                      } catch (e) {
                                        setModalState(() => isSaving = false);
                                        _showSnackBar(
                                          e
                                              .toString()
                                              .replaceAll('Exception: ', ''),
                                          Colors.redAccent,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryPink,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isEditing
                                          ? 'Save Changes'
                                          : 'Add Concert',
                                      style: const TextStyle(
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
              ),
            );
          },
        );
      },
    );
  }

  /// ยืนยันลบคอนเสิร์ต (เอาไอคอนออก + ข้อความสั้น)
  void _showDeleteConcertDialog(Map<String, dynamic> concert) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Concert',
            style: TextStyle(
              color: darkCharcoal,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure?',
            style: TextStyle(color: slateGrey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: slateGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  final token = await _getToken();
                  await _adminController.deleteConcert(
                    token: token,
                    concertId: concert['concert_id'].toString(),
                  );
                  setState(() {
                    concerts.removeWhere(
                      (c) => c['concert_id'] == concert['concert_id'],
                    );
                  });
                  _showSnackBar(
                    'Deleted "${concert['title']}" successfully.',
                    Colors.redAccent,
                  );
                } catch (e) {
                  _showSnackBar(
                    e.toString().replaceAll('Exception: ', ''),
                    Colors.redAccent,
                  );
                }
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

  /// ช่องกรอกข้อมูลแบบ Static Label ด้านบน (ไม่มีไอคอนด้านใน)
  Widget _concertStaticField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: darkCharcoal,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: darkCharcoal, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: slateGrey, fontSize: 13),
            filled: true,
            fillColor: lightBg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryPink, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  // =============================== USER LOGIC ================================
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

  String _calculateSuccessRate(Map<String, dynamic> user) {
    final int sold = (user['ticketsSold'] as num?)?.toInt() ?? 0;
    final List listings = (user['resellListings'] as List?) ?? [];
    final int uncompleted = listings.where((l) => l['status'] != 'sold').length;
    final int totalAttempts = sold + uncompleted;

    if (totalAttempts == 0) return '0%';

    final double rate = (sold / totalAttempts) * 100;
    return '${rate.toStringAsFixed(0)}%';
  }

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
      final token = await _getToken();
      await _adminController.updateUserStatus(
        token: token,
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

  Future<void> _deleteUser(String userId) async {
    final index = users.indexWhere((user) => user['id'].toString() == userId);
    if (index == -1) return;

    final String name = users[index]['full_name'].toString();

    try {
      final token = await _getToken();
      await _adminController.deleteUser(token: token, userId: userId);
      if (!mounted) return;
      setState(() {
        users.removeAt(index);
      });
      _showSnackBar('Account "$name" deleted successfully.', Colors.redAccent);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        Colors.redAccent,
      );
    }
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
          title: const Text(
            'Delete Account',
            style: TextStyle(
              color: darkCharcoal,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure?',
            style: TextStyle(color: slateGrey, fontSize: 14),
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

  // =============================== MAIN BUILD ================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showConcertFormDialog(),
              backgroundColor: primaryPink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Concert',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabSwitcher(),
            Expanded(
              child: _selectedTab == 0
                  ? (_isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: primaryPink,
                          ),
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
                        ))
                  : (_isLoadingConcerts
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: primaryPink,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildConcertTitleSection(),
                              const SizedBox(height: 16),
                              _buildConcertSearchBar(),
                              const SizedBox(height: 20),
                              _buildConcertCardsList(),
                            ],
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  // ========================== WIDGET COMPONENTS ==============================
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

  /// แถบสลับโหมด Users / Concerts (ไม่มีไอคอน)
  Widget _buildTabSwitcher() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _tabChip(
            index: 0,
            label: 'Users (${users.length})',
          ),
          const SizedBox(width: 10),
          _tabChip(
            index: 1,
            label: 'Concerts (${concerts.length})',
          ),
        ],
      ),
    );
  }

  Widget _tabChip({
    required int index,
    required String label,
  }) {
    final bool selected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primaryPink : lightBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? primaryPink : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // -------------------- CONCERT MANAGEMENT UI --------------------
  Widget _buildConcertTitleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Concert Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkCharcoal,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Add, edit, or remove concerts available across the platform.',
          style: TextStyle(color: slateGrey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildConcertSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: concertSearchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search concert title, artist, or venue...',
          hintStyle: TextStyle(color: slateGrey, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: primaryPink),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildConcertCardsList() {
    final list = filteredConcerts;

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
            'No concerts found. Tap "+ Add Concert" to create one.',
            style: TextStyle(color: slateGrey, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final concert = list[index];
        final String posterUrl = (concert['poster_url'] ?? '').toString();
        final String artist = (concert['artist'] ?? '').toString();
        final String category = (concert['category'] ?? '').toString();
        final String formattedDate =
            _formatShowDateTime(concert['show_datetime']);

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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60,
                  height: 60,
                  color: softPink,
                  child: posterUrl.isNotEmpty
                      ? Image.network(
                          posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.music_note,
                            color: primaryPink,
                            size: 28,
                          ),
                        )
                      : const Icon(
                          Icons.music_note,
                          color: primaryPink,
                          size: 28,
                        ),
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
                            (concert['title'] ?? 'Untitled Concert').toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: darkCharcoal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (category.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: softPink,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                color: primaryPink,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (artist.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Artist: $artist',
                        style: const TextStyle(
                          color: darkCharcoal,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: primaryPink,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            (concert['venue'] ?? 'N/A').toString(),
                            style: const TextStyle(
                              color: slateGrey,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: slateGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate.isEmpty ? 'N/A' : formattedDate,
                          style: const TextStyle(
                            color: slateGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: primaryPink),
                tooltip: 'Edit Concert',
                onPressed: () =>
                    _showConcertFormDialog(existingConcert: concert),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Delete Concert',
                onPressed: () => _showDeleteConcertDialog(concert),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------- USER MANAGEMENT UI --------------------
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
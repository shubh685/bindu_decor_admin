import 'dart:convert';

import 'package:bindu_decor_admin/Admin_Auth.dart';
import 'package:bindu_decor_admin/Api/Operations.dart';
import 'package:bindu_decor_admin/Blogs.dart';
import 'package:bindu_decor_admin/products.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Api/Auth_Api.dart';
import 'clients.dart';
import 'projects.dart';
import 'Helper_class.dart';
import 'Safe_Net_img.dart';

// ==========================================
// LUXURY THEME COLORS & STYLES
// ==========================================
class AdminTheme {
  static const Color primaryDark = Color(0xFF0F2C23);
  static const Color primaryAccent = Color(0xFFD4AF37);
  static const Color secondaryAccent = Color(0xFFC5A059);
  static const Color bgCanvas = Color(0xFFF8F9FA);
  static const Color cardBg = Colors.white;
}

// ==========================================
// UNIFIED MEDIA DATA MODEL
// ==========================================
class MediaItem {
  final String? url;
  final Uint8List? bytes;
  final String? fileName;

  const MediaItem({this.url, this.bytes, this.fileName});

  bool get isWebUrl =>
      url != null &&
          (url!.startsWith('http://') || url!.startsWith('https://'));

  bool get isAsset => url != null && url!.startsWith('assets/');
  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
}

class AppDataStore {
  static final List<ClientItems> clientLogos = [];
  static final List<ProjectItem> projects = [];
  static final List<DecorProductItem> products = [];
  static List<BlogItem> get blogs => BlogDataStore.blogs;
}

// ==========================================
// IMAGE RENDERER & NORMALIZATION
// ==========================================
// ==========================================
// IMAGE RENDERER & NORMALIZATION
// ==========================================
String normalizeToAbsoluteImageUrl(String rawOrPartial) {
  final raw = (rawOrPartial ?? '').trim();
  if (raw.isEmpty) return '';

  // If it's a data URI, return as is
  if (raw.startsWith('data:image/')) {
    return raw;
  }

  // If it's already an absolute image.php URL, return as is
  if (raw.contains('/image.php?path=')) {
    debugPrint('✅ Already absolute image.php URL: $raw');
    return raw;
  }

  // If it's already an absolute URL (any http/https), return as is
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    debugPrint('✅ Already absolute HTTP(S) URL: $raw');
    return raw;
  }

  // If it's a relative path, build the image.php URL
  if (!raw.startsWith('/')) {
    final imageUrl = '${OperationsApi.baseUrl}image.php?path=${Uri.encodeComponent(raw)}';
    debugPrint('📸 Built image.php URL from relative path: $imageUrl');
    return imageUrl;
  }

  // Final fallback
  debugPrint('⚠️ Could not resolve image URL: $raw');
  return '';
}

// In AdminDashboard.dart, update the buildUniversalImage function

Widget buildUniversalImage(
    MediaItem media, {
      BoxFit fit = BoxFit.cover,
      double? width,
      double? height,
    }) {
  // 1) Local bytes (file picker / camera)
  if (media.hasBytes) {
    return Image.memory(
      media.bytes!,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (c, e, s) {
        debugPrint('❌ ERROR loading memory image: $e');
        return _imageFallback();
      },
    );
  }

  final raw = (media.url ?? '').trim();
  if (raw.isEmpty) {
    return _imageFallback();
  }

  // 2) Asset
  if (raw.startsWith('assets/')) {
    return Image.asset(
      raw,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (c, e, s) {
        debugPrint('❌ ERROR loading asset: $raw -> $e');
        return _imageFallback();
      },
    );
  }

  // 3) Data URI
  if (raw.startsWith('data:image/')) {
    try {
      return Image.memory(
        base64Decode(raw.split(',').last),
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (c, e, s) {
          return _imageFallback();
        },
      );
    } catch (_) {
      return _imageFallback();
    }
  }

  // 4) Direct URL - use SafeNetworkImage
  debugPrint('📸 Loading image: $raw');
  return SafeNetworkImage(
    url: raw,
    width: width,
    height: height,
    fit: fit,
  );
}

Widget _imageFallback() {
  return Container(
    color: Colors.grey.shade200,
    child: Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text('Image not found', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    ),
  );
}

// MAIN ADMIN DASHBOARD
// ==========================================
// MAIN ADMIN DASHBOARD
// ==========================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Updated length to 5 to accommodate the Blog tab
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all data including blogs in parallel
      await Future.wait([
        _loadProjects(),
        _loadProducts(),
        _loadClients(),
        _loadBlogs(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBlogs() async {
    try {
      final response = await http.get(Uri.parse('https://yellow-woodpecker-430323.hostingersite.com/bindu_web/blogs.php'
          'http://192.168.1.48/bindu_decor/bogs.php'
          'https://yellow-woodpecker-430323.hostingersite.com/bindu_admin_web/blogs.php'));
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success' && resData['data'] != null) {
          final List list = resData['data'];
          if (mounted) {
            BlogDataStore.blogs.clear();
            BlogDataStore.blogs.addAll(list.map((item) => BlogItem.fromJson(item)).toList());
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading blogs in AdminDashboard: $e");
    }
  }

  Future<void> _loadProjects() async {
    final projects = await OperationsApi.fetchProjects();
    if (mounted) {
      AppDataStore.projects.clear();
      AppDataStore.projects.addAll(projects);
      print('Loaded ${projects.length} projects');
    }
  }

  Future<void> _loadProducts() async {
    final products = await OperationsApi.fetchProducts();
    if (mounted) {
      AppDataStore.products.clear();
      AppDataStore.products.addAll(products);
      print('Loaded ${products.length} products');
    }
  }

  Future<void> _loadClients() async {
    final clients = await OperationsApi.fetchClients();
    if (mounted) {
      AppDataStore.clientLogos.clear();
      AppDataStore.clientLogos.addAll(clients);
      print('Loaded ${clients.length} clients');
    }
  }

  void _refreshDashboard() {
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgCanvas,
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black26,
        backgroundColor: AdminTheme.primaryDark,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AdminTheme.primaryAccent, width: 1.5),
              ),
              child: const Icon(Icons.shield_outlined, color: AdminTheme.primaryAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Admin Management Portal",
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.aleo(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.8,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AdminTheme.primaryAccent,
          indicatorWeight: 3,
          labelColor: AdminTheme.primaryAccent,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: "Overview"),
            Tab(icon: Icon(Icons.apartment_rounded), text: "Projects"),
            Tab(icon: Icon(Icons.category_rounded), text: "Products"),
            Tab(icon: Icon(Icons.people_alt_rounded), text: "Clients"),
            Tab(icon: Icon(Icons.library_add_check_sharp), text: "Blog"),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                // Refresh all data
                _loadAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Refreshing data...")),
                );
              },
              tooltip: "Refresh",
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: AdminTheme.primaryAccent.withOpacity(0.4)),
                ),
                child: const Icon(Icons.refresh_rounded, size: 18, color: AdminTheme.primaryAccent),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                _showAccountPopup(context);
              },
              child: Container(
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(CupertinoIcons.person_crop_circle, size: 25, color: AdminTheme.primaryDark),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AdminTheme.primaryAccent),
            SizedBox(height: 16),
            Text("Loading data...", style: TextStyle(color: AdminTheme.primaryDark)),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          OverviewDomainManager(onNavigateToTab: (index) => _tabController.animateTo(index)),
          ProjectDomainManager(onDataChanged: _refreshDashboard),
          ProductDomainManager(onDataChanged: _refreshDashboard),
          ClientDomainManager(onDataChanged: _refreshDashboard),
          Blogs(onDataChanged: _refreshDashboard),
        ],
      ),
    );
  }
}

// Helper method to trigger the Change Password Dialog Box
// Helper method to trigger the Luxury Styled Change Password Dialog Box
void _showChangePasswordDialog(BuildContext context, String userEmail) {
  final oldPwdController = TextEditingController();
  final newPwdController = TextEditingController();
  final reconfirmPwdController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool obscureOld = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          // Input field decoration builder matching AdminTheme
          InputDecoration buildInputDecoration(String label, IconData icon, Widget? suffixIcon) {
            return InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade600),
              prefixIcon: Icon(icon, color: AdminTheme.primaryDark, size: 20),
              suffixIcon: suffixIcon,
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFFAF9F6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.primaryAccent, width: 1.5)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
            );
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 10,
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AdminTheme.primaryDark.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: AdminTheme.primaryDark, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Change Password",
                                style: GoogleFonts.aleo(fontWeight: FontWeight.bold, fontSize: 18, color: AdminTheme.primaryDark),
                              ),
                              Text(
                                "Update credentials for $userEmail",
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // Form Inputs
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          // Old Password
                          TextFormField(
                            controller: oldPwdController,
                            obscureText: obscureOld,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AdminTheme.primaryDark),
                            decoration: buildInputDecoration(
                              "Old Password",
                              Icons.key_rounded,
                              IconButton(
                                icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade500, size: 18),
                                onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                              ),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? "Enter old password" : null,
                          ),
                          const SizedBox(height: 14),

                          // New Password
                          TextFormField(
                            controller: newPwdController,
                            obscureText: obscureNew,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AdminTheme.primaryDark),
                            decoration: buildInputDecoration(
                              "New Password",
                              Icons.lock_outline_rounded,
                              IconButton(
                                icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade500, size: 18),
                                onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Enter new password";
                              if (val.length < 6) return "Password must be at least 6 characters";
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Reconfirm Password
                          TextFormField(
                            controller: reconfirmPwdController,
                            obscureText: obscureConfirm,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AdminTheme.primaryDark),
                            decoration: buildInputDecoration(
                              "Reconfirm New Password",
                              Icons.check_circle_outline_rounded,
                              IconButton(
                                icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade500, size: 18),
                                onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                              ),
                            ),
                            validator: (val) {
                              if (val != newPwdController.text) return "Passwords do not match";
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              "CANCEL",
                              style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.primaryDark,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                              if (formKey.currentState!.validate()) {
                                setDialogState(() => isLoading = true);

                                // Calls static method Api.changePassword
                                final res = await Api.changePassword(
                                  email: userEmail,
                                  oldPassword: oldPwdController.text,
                                  newPassword: newPwdController.text,
                                );

                                setDialogState(() => isLoading = false);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['message'] ?? 'Password update status unknown'),
                                      backgroundColor: res['status'] == true ? Colors.green.shade700 : Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              }
                            },
                            child: isLoading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: AdminTheme.primaryAccent, strokeWidth: 2),
                            )
                                : Text(
                              "UPDATE",
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// Updated _accView displaying dynamic data from Users table (via SharedPreferences)
Widget _accView(BuildContext context) {
  return FutureBuilder<SharedPreferences>(
    future: SharedPreferences.getInstance(),
    builder: (context, snapshot) {
      final prefs = snapshot.data;
      final String userName = prefs?.getString('user_name') ?? 'Admin User';
      final String userEmail = prefs?.getString('user_email') ?? 'admin@example.com';

      return Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AdminTheme.primaryDark,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AdminTheme.primaryAccent.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Info", style: GoogleFonts.aleo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),

              // Dynamic User Name
              Row(
                children: [
                  const Icon(Icons.person_outline, color: AdminTheme.primaryAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userName,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Dynamic User Email
              Row(
                children: [
                  const Icon(Icons.email_outlined, color: AdminTheme.primaryAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userEmail,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Change Password Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showChangePasswordDialog(context, userEmail);
                  },
                  icon: const Icon(Icons.password, size: 18, color: Colors.black87),
                  label: const Text("Change Password"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AdminTheme.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 1. Show confirmation dialog before logging out
                    final confirmLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(
                          "Confirm Logout",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: AdminTheme.primaryDark,
                          ),
                        ),
                        content: Text(
                          "Are you sure you want to end your current session?",
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              "CANCEL",
                              style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminAuth())),
                            child: Text("LOGOUT", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                    );

                    // 2. Perform logout if confirmed
                    if (confirmLogout == true) {
                      final prefs = await SharedPreferences.getInstance();

                      // Clear all stored credentials and session flags
                      await prefs.clear();
                      // Note: Use prefs.remove('isLoggedIn') if you only want to delete specific keys

                      if (!context.mounted) return;

                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryAccent,
                    foregroundColor: AdminTheme.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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


void _showAccountPopup(BuildContext context) {
  final overlay = Overlay.of(context);

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          // Close popup when clicking anywhere outside
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                overlayEntry.remove();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          Positioned(
            top: 70,
            right: 15,
            child: GestureDetector(
              onTap: () {},
              child: _accView(context),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(overlayEntry);
}
// ==========================================
// OVERVIEW DOMAIN MANAGER (SUMMARY & COUNTS)
// ==========================================
// ==========================================
// OVERVIEW DOMAIN MANAGER (SUMMARY & COUNTS)
// ==========================================


class OverviewDomainManager extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const OverviewDomainManager({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final int projectCount = AppDataStore.projects.length;
    final int productCount = AppDataStore.products.length;
    final int clientCount = AppDataStore.clientLogos.length;
    final int blogCount = AppDataStore.blogs.length; // Live count from BlogDataStore

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("System Summary Overview", style: GoogleFonts.aleo(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
                  const SizedBox(height: 4),
                  Text("Live metrics and control dashboard", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overview Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 750) {
                return Column(
                  children: [
                    _buildCountCard("Projects", projectCount, Icons.apartment_rounded, const Color(0xFF1E88E5), () => onNavigateToTab(1)),
                    const SizedBox(height: 12),
                    _buildCountCard("Products", productCount, Icons.category_rounded, const Color(0xFFFB8C00), () => onNavigateToTab(2)),
                    const SizedBox(height: 12),
                    _buildCountCard("Clients", clientCount, Icons.people_alt_rounded, const Color(0xFF43A047), () => onNavigateToTab(3)),
                    const SizedBox(height: 12),
                    _buildCountCard("Blogs", blogCount, Icons.library_add_check_sharp, const Color(0xFF8E24AA), () => onNavigateToTab(4)),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _buildCountCard("Projects", projectCount, Icons.apartment_rounded, const Color(0xFF1E88E5), () => onNavigateToTab(1))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCountCard("Products", productCount, Icons.category_rounded, const Color(0xFFFB8C00), () => onNavigateToTab(2))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCountCard("Clients", clientCount, Icons.people_alt_rounded, const Color(0xFF43A047), () => onNavigateToTab(3))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCountCard("Blogs", blogCount, Icons.library_add_check_sharp, const Color(0xFF8E24AA), () => onNavigateToTab(4))),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Recent Projects Section
          _buildSummarySection(
            title: "Recent Projects",
            itemCount: projectCount,
            onViewAll: () => onNavigateToTab(1),
            child: projectCount == 0
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("No projects available.")),
            )
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projectCount > 3 ? 3 : projectCount,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final item = AppDataStore.projects[idx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: buildUniversalImage(
                        MediaItem(url: item.imageUrls.isNotEmpty ? item.imageUrls.first : ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(item.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("${item.location} • ${item.pricing}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Recent Products Section
          _buildSummarySection(
            title: "Recent Products",
            itemCount: productCount,
            onViewAll: () => onNavigateToTab(2),
            child: productCount == 0
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("No products available.")),
            )
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: productCount > 3 ? 3 : productCount,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final item = AppDataStore.products[idx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: buildUniversalImage(
                        MediaItem(url: item.imageUrls.isNotEmpty ? item.imageUrls.first : ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(item.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.category, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Recent Blogs Section
          // ==========================================
          _buildSummarySection(
            title: "Recent Blogs",
            itemCount: blogCount,
            onViewAll: () => onNavigateToTab(4),
            child: blogCount == 0
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("No blogs available.")),
            )
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: blogCount > 3 ? 3 : blogCount,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final item = AppDataStore.blogs[idx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: buildUniversalImage(
                        item.photos.isNotEmpty
                            ? MediaItem(url: item.photos.first)
                            : const MediaItem(url: ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "${item.subject} • ${item.status}",
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard(String label, int count, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count.toString(), style: GoogleFonts.alexandria(fontSize: 26, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
                Text(label, style: GoogleFonts.aleo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection({required String title, required int itemCount, required VoidCallback onViewAll, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$title ($itemCount)", style: GoogleFonts.aleo(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
                TextButton(
                  onPressed: onViewAll,
                  child: Text("Manage All", style: GoogleFonts.plusJakartaSans(color: AdminTheme.secondaryAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

// ==========================================
// SHARED MEDIA PICKER COMPONENT
// ==========================================
class MediaPickerWidget extends StatelessWidget {
  final List<MediaItem> mediaList;
  final TextEditingController webUrlController;
  final VoidCallback onAddWebUrl;
  final Function(List<MediaItem>) onMediaAdded;
  final Function(int) onRemoveMedia;

  const MediaPickerWidget({
    super.key,
    required this.mediaList,
    required this.webUrlController,
    required this.onAddWebUrl,
    required this.onMediaAdded,
    required this.onRemoveMedia,
  });

  bool get _shouldShowCameraButton {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<bool> _requestPermission(Permission permission, BuildContext context) async {
    if (kIsWeb) return true;

    final status = await permission.status;
    if (status.isGranted) return true;

    final result = await permission.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Permission permanently denied. Please enable it in Settings."),
          action: SnackBarAction(
            label: "SETTINGS",
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
    return false;
  }

  Future<void> _pickFiles(BuildContext context) async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      bool granted = await _requestPermission(Permission.photos, context);
      if (!granted) return;
    }

    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      List<MediaItem> items = [];
      for (var f in result.files) {
        Uint8List? fileBytes = f.bytes;

        if (fileBytes != null && fileBytes.isNotEmpty) {
          items.add(
            MediaItem(
              bytes: fileBytes,
              fileName: f.name,
            ),
          );
        }
      }

      if (items.isNotEmpty) {
        onMediaAdded(items);
      }
    }
  }

  Future<void> _pickCamera(BuildContext context) async {
    bool granted = await _requestPermission(Permission.camera, context);
    if (!granted && !kIsWeb) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        onMediaAdded([
          MediaItem(
            bytes: bytes,
            fileName: photo.name,
          ),
        ]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to capture image: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Media Attachment (Optional)", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: webUrlController,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Paste image address...",
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade400),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFFAF9F6),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.primaryAccent, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAddWebUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.secondaryAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Add Link", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickFiles(context),
                icon: const Icon(Icons.folder_open_rounded, size: 18, color: AdminTheme.primaryDark),
                label: Text("Browse Local Files", style: GoogleFonts.plusJakartaSans(color: AdminTheme.primaryDark, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AdminTheme.primaryDark.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_shouldShowCameraButton) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickCamera(context),
                  icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AdminTheme.primaryDark),
                  label: Text("Camera", style: GoogleFonts.plusJakartaSans(color: AdminTheme.primaryDark, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AdminTheme.primaryDark.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (mediaList.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mediaList.length,
              itemBuilder: (context, idx) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: buildUniversalImage(mediaList[idx]),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => onRemoveMedia(idx),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.close_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ]
      ],
    );
  }
}
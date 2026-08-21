import 'package:bindu_decor_admin/Api/Operations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Api/Auth_Api.dart';
import 'Helper_Class.dart';

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

  const MediaItem({this.url, this.bytes});

  bool get isWebUrl => url != null && (url!.startsWith('http://') || url!.startsWith('https://'));
  bool get isAsset => url != null && url!.startsWith('assets/');
  bool get hasBytes => bytes != null;
}

// ==========================================
// CENTRALIZED DYNAMIC APP DATA STORE
// ==========================================
class AppDataStore {
  static final List<ClientItems> clientLogos = [
    const ClientItems(imgUrl: "assets/photos/img1.png"),
    const ClientItems(imgUrl: "assets/photos/img2.png"),
  ];

  static final List<ProjectItem> projects = [];

  static final List<DecorProductItem> products = [
    const DecorProductItem(
      title: "Premium Luxury Wallpaper",
      category: "Wallpapers",
      imageUrls: [
        "https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800"
      ],
      description: "Elegant textured wallpapers for home spaces.",
    ),
  ];
}

// ==========================================
// CROSS-PLATFORM SAFE IMAGE RENDERER
// ==========================================
Widget buildUniversalImage(MediaItem media, {BoxFit fit = BoxFit.cover}) {
  if (media.hasBytes) {
    return Image.memory(
      media.bytes!,
      fit: fit,
      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  final path = media.url ?? '';
  if (path.isEmpty) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 32)),
    );
  }

  if (media.isWebUrl) {
    return Image.network(
      path,
      fit: fit,
      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  if (media.isAsset) {
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  return const Icon(Icons.image, color: Colors.grey);
}

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshDashboard() {
    setState(() {});
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
            Text("Admin Management Portal", style: GoogleFonts.aleo(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.0, color: Colors.white)),
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
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {},
              tooltip: "Logout",
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: AdminTheme.primaryAccent.withOpacity(0.4)),
                ),
                child: const Icon(Icons.logout_rounded, size: 18, color: AdminTheme.primaryAccent),
              ),
            ),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewDomainManager(onNavigateToTab: (index) => _tabController.animateTo(index)),
          ProjectDomainManager(onDataChanged: _refreshDashboard),
          ProductDomainManager(onDataChanged: _refreshDashboard),
          ClientDomainManager(onDataChanged: _refreshDashboard),
        ],
      ),
    );
  }
}

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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("System Summary Overview", style: GoogleFonts.aleo(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
                  const SizedBox(height: 4),
                  Text("Live metrics and control dashboard", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade600,)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 650) {
                return Column(
                  children: [
                    _buildCountCard("Projects", projectCount, Icons.apartment_rounded, const Color(0xFF1E88E5), () => onNavigateToTab(1)),
                    const SizedBox(height: 12),
                    _buildCountCard("Products", productCount, Icons.category_rounded, const Color(0xFFFB8C00), () => onNavigateToTab(2)),
                    const SizedBox(height: 12),
                    _buildCountCard("Clients", clientCount, Icons.people_alt_rounded, const Color(0xFF43A047), () => onNavigateToTab(3)),
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
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          _buildSummarySection(
            title: "Recent Projects",
            itemCount: projectCount,
            onViewAll: () => onNavigateToTab(1),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projectCount > 3 ? 3 : projectCount,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final item = AppDataStore.projects[idx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminTheme.primaryDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: AdminTheme.primaryDark),
                  ),
                  title: Text(item.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("${item.location} • ${item.pricing}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildSummarySection(
            title: "Recent Products",
            itemCount: productCount,
            onViewAll: () => onNavigateToTab(2),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: productCount > 3 ? 3 : productCount,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final item = AppDataStore.products[idx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminTheme.secondaryAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.category_rounded, color: AdminTheme.secondaryAccent),
                  ),
                  title: Text(item.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.category, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
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
                Text(count.toString(), style: GoogleFonts.alexandria(fontSize: 26, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark),),
                Text(label, style: GoogleFonts.aleo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),),
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
                Text("$title ($itemCount)", style: GoogleFonts.aleo(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark),),
                TextButton(
                  onPressed: onViewAll,
                  child: Text("Manage All", style: GoogleFonts.plusJakartaSans(color: AdminTheme.secondaryAccent, fontWeight: FontWeight.bold, fontSize: 12),),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          itemCount == 0
              ? Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                "No records available.",
                style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          )
              : child,
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
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    }
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
    Permission storagePermission = Permission.photos;

    bool granted = await _requestPermission(storagePermission, context);
    if (!granted && !kIsWeb) return;

    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      final List<MediaItem> items = result.files
          .where((f) => f.bytes != null)
          .map((f) => MediaItem(bytes: f.bytes))
          .toList();
      onMediaAdded(items);
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
        onMediaAdded([MediaItem(bytes: bytes)]);
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
        Text(
          "Media Attachment (Optional)",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AdminTheme.primaryDark,
          ),
        ),
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

// ==========================================
// 1. PROJECT DOMAIN MANAGEMENT SCREEN
// ==========================================
class ProjectDomainManager extends StatefulWidget {
  final VoidCallback onDataChanged;

  const ProjectDomainManager({super.key, required this.onDataChanged});

  @override
  State<ProjectDomainManager> createState() => _ProjectDomainManagerState();
}

class _ProjectDomainManagerState extends State<ProjectDomainManager> {
  final _title = TextEditingController();
  final _subTitle = TextEditingController();
  final _location = TextEditingController();
  final _pricing = TextEditingController();
  final _bhk = TextEditingController();
  final _size = TextEditingController();
  final _description = TextEditingController();
  final _urlController = TextEditingController();

  bool _isLoading = false;

  // Property Type state & options
  String _selectedPropertyType = 'Apartment';
  final List<String> _propertyTypeOptions = [
    'Apartment',
    'Villa',
    'Bungalow',
    'Penthouse',
    'Duplex',
    'Row House',
    'Commercial'
  ];

  // Interior Scope state & options
  String _selectedScope = 'Full Interior';
  final List<String> _scopeOptions = [
    'Full Interior',
    'Bedroom Interior',
    'Living Room Interior',
    'Children Room Interior',
    'Kitchen Interior',
    'Bathroom Interior',
    'Balcony Interior',
    'Office Interior',
    'Hospital Interior'
  ];

  final List<MediaItem> _mediaItems = [];

  // COMPLETE ADD PROJECT METHOD
  Future<void> _addProject() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Project Title is required!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String externalUrl = "";
      Uint8List? rawBytes;

      if (_mediaItems.isNotEmpty) {
        final selectedMedia = _mediaItems.first;
        if (selectedMedia.hasBytes) {
          rawBytes = selectedMedia.bytes;
        } else if (selectedMedia.url != null && selectedMedia.url!.isNotEmpty) {
          externalUrl = selectedMedia.url!;
        }
      }

      if (externalUrl.isEmpty && rawBytes == null) {
        externalUrl = "https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800";
      }

      // Payload keys precisely match $_POST keys in PHP
      final Map<String, String> fields = {
        "title": _title.text.trim(),
        "sub_title": _subTitle.text.trim().isEmpty ? "Featured Residence" : _subTitle.text.trim(),
        "location": _location.text.trim().isEmpty ? "Mumbai" : _location.text.trim(),
        "pricing": _pricing.text.trim().isEmpty ? "N/A" : _pricing.text.trim(),
        "bhk": _bhk.text.trim().isEmpty ? "3-BHK" : _bhk.text.trim(),
        "scope": _selectedScope,
        "property_type": _selectedPropertyType,
        "size": _size.text.trim().isEmpty ? "2000 sq ft" : _size.text.trim(),
        "description": _description.text.trim().isEmpty ? "No description provided." : _description.text.trim(),
        "image_url": externalUrl,
      };

      final response = await OperationsApi.addProject(
        fields: fields,
        imageBytes: rawBytes,
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        String finalImageUrl = response['image_url'] ?? externalUrl;

        AppDataStore.projects.add(
          ProjectItem.fromMap({
            "id": response['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            "title": fields["title"],
            "sub_title": fields["sub_title"],
            "location": fields["location"],
            "pricing": fields["pricing"],
            "bhk": fields["bhk"],
            "scope": fields["scope"],
            "property_type": fields["property_type"],
            "size": fields["size"],
            "description": fields["description"],
            "image_url": finalImageUrl,
          }),
        );

        _mediaItems.clear();
        _title.clear();
        _subTitle.clear();
        _location.clear();
        _pricing.clear();
        _bhk.clear();
        _selectedPropertyType = 'Apartment';
        _selectedScope = 'Full Interior';
        _size.clear();
        _description.clear();

        widget.onDataChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New Project published successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to publish project: ${response['message']}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection exception: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteProject(String id, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Project", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '${AppDataStore.projects[index].title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              bool success = await OperationsApi.deleteProject(id);
              if (success && mounted) {
                setState(() {
                  AppDataStore.projects.removeAt(index);
                });
                widget.onDataChanged();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project deleted!")));
              }
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.primaryDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFFAF9F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.primaryAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add New Interior Project", style: GoogleFonts.aleo(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
                const SizedBox(height: 16),
                _buildTextField(controller: _title, label: "Project Title *"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _subTitle, label: "Subtitle")),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Property Type", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.primaryDark)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedPropertyType,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AdminTheme.primaryDark),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFFFAF9F6),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.primaryAccent, width: 1.5)),
                            ),
                            items: _propertyTypeOptions.map((pt) => DropdownMenuItem(value: pt, child: Text(pt))).toList(),
                            onChanged: (val) => setState(() => _selectedPropertyType = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _location, label: "Location")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller: _pricing, label: "Pricing")),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _bhk, label: "BHK Config")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller: _size, label: "Property Size")),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Interior Scope", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.primaryDark)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedScope,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AdminTheme.primaryDark),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFFAF9F6),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.primaryAccent, width: 1.5)),
                      ),
                      items: _scopeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedScope = val!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(controller: _description, label: "Description", maxLines: 2),
                const SizedBox(height: 16),
                MediaPickerWidget(
                  mediaList: _mediaItems,
                  webUrlController: _urlController,
                  onAddWebUrl: () {
                    if (_urlController.text.trim().isNotEmpty) {
                      setState(() {
                        _mediaItems.add(MediaItem(url: _urlController.text.trim()));
                        _urlController.clear();
                      });
                    }
                  },
                  onMediaAdded: (items) => setState(() => _mediaItems.addAll(items)),
                  onRemoveMedia: (idx) => setState(() => _mediaItems.removeAt(idx)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : Text("PUBLISH PROJECT", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Active Projects Summary (${AppDataStore.projects.length})", style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
                const Divider(height: 20),
                AppDataStore.projects.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text("No projects available.", style: GoogleFonts.plusJakartaSans(color: Colors.grey))),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: AppDataStore.projects.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = AppDataStore.projects[idx];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: item.imageUrls.isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(item.imageUrls.first),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: item.imageUrls.isEmpty
                            ? const Icon(
                          Icons.apartment_rounded,
                          color: AdminTheme.primaryDark,
                        )
                            : null,
                      ),
                      title: Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "${item.propertyType} • ${item.location} • ${item.pricing}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _deleteProject(
                          item.id.toString(),
                          idx,
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 2. PRODUCT DOMAIN MANAGEMENT SCREEN
// ==========================================
class ProductDomainManager extends StatefulWidget {
  final VoidCallback onDataChanged;

  const ProductDomainManager({super.key, required this.onDataChanged});

  @override
  State<ProductDomainManager> createState() => _ProductDomainManagerState();
}

class _ProductDomainManagerState extends State<ProductDomainManager> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _urlController = TextEditingController();

  String _selectedCategory = 'Wallpapers';
  final List<String> _categories = [
    'Wallpapers', 'Floorings', 'Carpets', 'Blinds', 'Glass Films', 'Artificial Turfs',
    'Gym Floorings', 'Awnings', 'Mosquito Nets', 'Upholstery', 'Curtains', 'Stretch Ceiling'
  ];
  final List<MediaItem> _mediaItems = [];

  void _addProduct() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Title is required!")));
      return;
    }

    final imageUrls = _mediaItems
        .map((m) => m.url ?? "")
        .where((u) => u.isNotEmpty)
        .toList();

    setState(() {
      AppDataStore.products.add(
        DecorProductItem(
          title: _title.text.trim(),
          category: _selectedCategory,
          imageUrls: imageUrls.isEmpty ? ["https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800"] : imageUrls,
          description: _description.text.trim().isEmpty ? "High-quality decor item." : _description.text.trim(),
        ),
      );
      _mediaItems.clear();
      _title.clear();
      _description.clear();
    });

    widget.onDataChanged();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New Product added successfully!")));
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Product", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '${AppDataStore.products[index].title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              setState(() {
                AppDataStore.products.removeAt(index);
              });
              widget.onDataChanged();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product deleted!")));
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.primaryDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFFAF9F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.primaryAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add New Product Catalog Entry", style: GoogleFonts.aleo(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
                const SizedBox(height: 16),
                _buildTextField(controller: _title, label: "Product Title *"),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Category Selection", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.primaryDark)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AdminTheme.primaryDark),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFFAF9F6),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.primaryAccent, width: 1.5)),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(controller: _description, label: "Description", maxLines: 2),
                const SizedBox(height: 16),
                MediaPickerWidget(
                  mediaList: _mediaItems,
                  webUrlController: _urlController,
                  onAddWebUrl: () {
                    if (_urlController.text.trim().isNotEmpty) {
                      setState(() {
                        _mediaItems.add(MediaItem(url: _urlController.text.trim()));
                        _urlController.clear();
                      });
                    }
                  },
                  onMediaAdded: (items) => setState(() => _mediaItems.addAll(items)),
                  onRemoveMedia: (idx) => setState(() => _mediaItems.removeAt(idx)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("PUBLISH PRODUCT", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Active Products Summary (${AppDataStore.products.length})", style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
                const Divider(height: 20),
                AppDataStore.products.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text("No products available.", style: GoogleFonts.plusJakartaSans(color: Colors.grey))),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: AppDataStore.products.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = AppDataStore.products[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: item.imageUrls.isNotEmpty
                              ? DecorationImage(image: NetworkImage(item.imageUrls.first), fit: BoxFit.cover)
                              : null,
                        ),
                        child: item.imageUrls.isEmpty ? const Icon(Icons.category_rounded, color: AdminTheme.primaryDark) : null,
                      ),
                      title: Text(item.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(item.category, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () => _deleteProduct(idx),
                      ),
                    );
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 3. CLIENT DOMAIN MANAGEMENT SCREEN
// ==========================================
class ClientDomainManager extends StatefulWidget {
  final VoidCallback onDataChanged;

  const ClientDomainManager({super.key, required this.onDataChanged});

  @override
  State<ClientDomainManager> createState() => _ClientDomainManagerState();
}

class _ClientDomainManagerState extends State<ClientDomainManager> {
  final _urlController = TextEditingController();
  final List<MediaItem> _mediaItems = [];

  void _addClients() {
    if (_mediaItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide at least one client image/link!")));
      return;
    }

    setState(() {
      for (var media in _mediaItems) {
        if (media.url != null && media.url!.isNotEmpty) {
          AppDataStore.clientLogos.add(ClientItems(imgUrl: media.url!));
        } else {
          AppDataStore.clientLogos.add(const ClientItems(imgUrl: "assets/photos/img1.png"));
        }
      }
      _mediaItems.clear();
    });

    widget.onDataChanged();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Client entries updated!")));
  }

  void _deleteClient(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Client Logo", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this client logo?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              setState(() {
                AppDataStore.clientLogos.removeAt(index);
              });
              widget.onDataChanged();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Client logo deleted!")));
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add Client Logos", style: GoogleFonts.aleo(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
                const SizedBox(height: 16),
                MediaPickerWidget(
                  mediaList: _mediaItems,
                  webUrlController: _urlController,
                  onAddWebUrl: () {
                    if (_urlController.text.trim().isNotEmpty) {
                      setState(() {
                        _mediaItems.add(MediaItem(url: _urlController.text.trim()));
                        _urlController.clear();
                      });
                    }
                  },
                  onMediaAdded: (items) => setState(() => _mediaItems.addAll(items)),
                  onRemoveMedia: (idx) => setState(() => _mediaItems.removeAt(idx)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addClients,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("SAVE CLIENT LOGOS", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Active Client Logos (${AppDataStore.clientLogos.length})", style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark)),
                const Divider(height: 20),
                AppDataStore.clientLogos.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text("No client logos available.", style: GoogleFonts.plusJakartaSans(color: Colors.grey))),
                )
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: AppDataStore.clientLogos.length,
                  itemBuilder: (context, idx) {
                    final item = AppDataStore.clientLogos[idx];
                    return Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: buildUniversalImage(MediaItem(url: item.imgUrl)),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _deleteClient(idx),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.redAccent,
                              child: Icon(Icons.delete_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
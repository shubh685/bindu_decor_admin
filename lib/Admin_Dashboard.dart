import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Api/App_Api.dart';
import 'Helper_Class.dart';

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

  static final List<ProjectItem> projects = [
    const ProjectItem(
      title: "Modern Apartment Design in Mumbai",
      subTitle: "Villa Velloze",
      location: "Mumbai",
      tags: ["Modern"],
      pricing: "10 - 15 Lakhs",
      bhk: "3-BHK",
      scope: "Living Room",
      propertyType: "Apartment",
      size: "2000 sq ft",
      description: "A tastefully designed villa featuring contemporary architecture.",
      imageUrls: [
        "https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800"
      ],
    ),
  ];

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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt('user_id');

    try {
      if (userId != null) {
        await Api.logout(userId: userId);
      }
    } catch (e) {
      // Even if API fails, clear local login.
    }

    await prefs.clear();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
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
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFF0F382C),
        foregroundColor: Colors.white,
        title: Text("Admin Management Portal", style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 22)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFC5A059),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Overview"),
            Tab(icon: Icon(Icons.apartment), text: "Projects"),
            Tab(icon: Icon(Icons.category), text: "Products"),
            Tab(icon: Icon(Icons.people), text: "Clients"),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: logout,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white
                ),
                child: Icon(Icons.logout, size: 20, color: Colors.black),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("System Summary Overview", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F382C))),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCountCard("Projects", projectCount, Icons.apartment, Colors.blue, () => onNavigateToTab(1)),
              const SizedBox(width: 12),
              _buildCountCard("Products", productCount, Icons.category, Colors.orange, () => onNavigateToTab(2)),
              const SizedBox(width: 12),
              _buildCountCard("Clients", clientCount, Icons.people, Colors.green, () => onNavigateToTab(3)),
            ],
          ),
          const SizedBox(height: 24),
          _buildSummarySection(
            title: "Recent Projects",
            itemCount: projectCount,
            onViewAll: () => onNavigateToTab(1),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projectCount > 3 ? 3 : projectCount,
              itemBuilder: (context, idx) {
                final item = AppDataStore.projects[idx];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.apartment, color: Color(0xFF0F382C)),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${item.location} • ${item.pricing}"),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSummarySection(
            title: "Recent Products",
            itemCount: productCount,
            onViewAll: () => onNavigateToTab(2),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: productCount > 3 ? 3 : productCount,
              itemBuilder: (context, idx) {
                final item = AppDataStore.products[idx];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.category, color: Color(0xFFC5A059)),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard(String label, int count, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 8),
                Text(count.toString(), style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection({required String title, required int itemCount, required VoidCallback onViewAll, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$title ($itemCount)", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(onPressed: onViewAll, child: const Text("Manage")),
              ],
            ),
            const Divider(),
            itemCount == 0 ? const Padding(padding: EdgeInsets.all(8.0), child: Text("No records available.")) : child,
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SHARED MEDIA PICKER COMPONENT (WITH PERMISSIONS)
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

  /// Check whether camera option should be hidden (Hidden on Desktop Web)
  bool get _shouldShowCameraButton {
    if (kIsWeb) {
      // Show camera button on mobile web browsers, hide on desktop web
      return defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
    }
    // Show camera button on mobile native apps (Android/iOS)
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Handles runtime permissions cross-platform
  Future<bool> _requestPermission(Permission permission, BuildContext context) async {
    // Web platform handles permissions natively via browser popups
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

  /// Pick images from local gallery / media store
  Future<void> _pickFiles(BuildContext context) async {
    Permission storagePermission = Permission.photos;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // For Android API levels support
      storagePermission = Permission.photos;
    }

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

  /// Pick image from camera (Works on Mobile Native & Mobile Web)
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F382C),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: webUrlController,
                decoration: InputDecoration(
                  hintText: "Paste image address (Pinterest, Unsplash, Google)...",
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAddWebUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A059),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: const Text("Add Link"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickFiles(context),
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text("Browse Local Files"),
              ),
            ),
            // Dynamically show camera button only on mobile web and mobile apps
            if (_shouldShowCameraButton) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickCamera(context),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text("Camera"),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: buildUniversalImage(mediaList[idx]),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => onRemoveMedia(idx),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 10, color: Colors.white),
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
  final _scope = TextEditingController();
  final _size = TextEditingController();
  final _description = TextEditingController();
  final _urlController = TextEditingController();

  final List<MediaItem> _mediaItems = [];

  void _addProject() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project Title is required!")));
      return;
    }

    final imageUrls = _mediaItems
        .map((m) => m.url ?? "")
        .where((u) => u.isNotEmpty)
        .toList();

    setState(() {
      AppDataStore.projects.add(
        ProjectItem(
          title: _title.text.trim(),
          subTitle: _subTitle.text.trim().isEmpty ? "Featured Residence" : _subTitle.text.trim(),
          location: _location.text.trim().isEmpty ? "Mumbai" : _location.text.trim(),
          tags: const ["Modern", "Exclusive"],
          pricing: _pricing.text.trim().isEmpty ? "N/A" : _pricing.text.trim(),
          bhk: _bhk.text.trim().isEmpty ? "3-BHK" : _bhk.text.trim(),
          scope: _scope.text.trim().isEmpty ? "Full Interior" : _scope.text.trim(),
          propertyType: "Apartment",
          size: _size.text.trim().isEmpty ? "2000 sq ft" : _size.text.trim(),
          description: _description.text.trim().isEmpty ? "No description provided." : _description.text.trim(),
          imageUrls: imageUrls.isEmpty ? ["https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800"] : imageUrls,
        ),
      );
      _mediaItems.clear();
      _title.clear();
      _subTitle.clear();
      _location.clear();
      _pricing.clear();
      _bhk.clear();
      _scope.clear();
      _size.clear();
      _description.clear();
    });

    widget.onDataChanged();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New Project added successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Add New Interior Project", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F382C))),
                  const SizedBox(height: 12),
                  TextField(controller: _title, decoration: const InputDecoration(labelText: "Project Title *", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _subTitle, decoration: const InputDecoration(labelText: "Subtitle", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _location, decoration: const InputDecoration(labelText: "Location", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _pricing, decoration: const InputDecoration(labelText: "Pricing", border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _bhk, decoration: const InputDecoration(labelText: "BHK Config", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _addProject,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F382C), foregroundColor: Colors.white),
                      child: const Text("PUBLISH PROJECT"),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Active Projects Summary (${AppDataStore.projects.length})", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: AppDataStore.projects.length,
                    itemBuilder: (context, idx) {
                      final item = AppDataStore.projects[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: item.imageUrls.isNotEmpty ? NetworkImage(item.imageUrls.first) : null,
                          child: item.imageUrls.isEmpty ? const Icon(Icons.apartment) : null,
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${item.location} • ${item.pricing}"),
                      );
                    },
                  )
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Add New Product Catalog Entry", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F382C))),
                  const SizedBox(height: 12),
                  TextField(controller: _title, decoration: const InputDecoration(labelText: "Product Title *", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: "Category Selection", border: OutlineInputBorder()),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _addProduct,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F382C), foregroundColor: Colors.white),
                      child: const Text("PUBLISH PRODUCT"),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Active Products Summary (${AppDataStore.products.length})", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: AppDataStore.products.length,
                    itemBuilder: (context, idx) {
                      final item = AppDataStore.products[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: item.imageUrls.isNotEmpty ? NetworkImage(item.imageUrls.first) : null,
                          child: item.imageUrls.isEmpty ? const Icon(Icons.category) : null,
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item.category),
                      );
                    },
                  )
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Add Client Logos", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F382C))),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _addClients,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F382C), foregroundColor: Colors.white),
                      child: const Text("SAVE CLIENT LOGOS"),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Active Client Logos (${AppDataStore.clientLogos.length})", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: AppDataStore.clientLogos.length,
                    itemBuilder: (context, idx) {
                      final item = AppDataStore.clientLogos[idx];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: buildUniversalImage(MediaItem(url: item.imgUrl)),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

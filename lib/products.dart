// ==========================================
// 2. PRODUCT DOMAIN MANAGEMENT SCREEN
// ==========================================
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'AdminDashboard.dart';
import 'Api/Operations.dart';
import 'Helper_class.dart';

class ProductDomainManager extends StatefulWidget {
  final VoidCallback onDataChanged;

  const ProductDomainManager({super.key, required this.onDataChanged});

  @override
  State<ProductDomainManager> createState() => _ProductDomainManagerState();
}

class _ProductDomainManagerState extends State<ProductDomainManager> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _materialController = TextEditingController(text: "Premium Grade Material");
  final _printTypeController = TextEditingController(text: "High Definition Digital Print / Finish");
  final _urlController = TextEditingController();

  bool _isLoading = false;

  String _selectedCategory = 'Wallpapers';
  final List<String> _categories = [
    'Wallpapers', 'Floorings', 'Carpets', 'Blinds', 'Glass Films', 'Artificial Turfs',
    'Gym Floorings', 'Awnings', 'Mosquito Nets', 'Upholstery', 'Curtains', 'Stretch Ceiling'
  ];
  final List<MediaItem> _mediaItems = [];

  Future<void> _addProduct() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Title is required!")),
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

      final Map<String, String> fields = {
        "title": _title.text.trim(),
        "category": _selectedCategory,
        "description": _description.text.trim().isEmpty ? "High-quality decor item." : _description.text.trim(),
        "material": _materialController.text.trim().isEmpty ? "Premium Grade Material" : _materialController.text.trim(),
        "print_type": _printTypeController.text.trim().isEmpty ? "High Definition Digital Print / Finish" : _printTypeController.text.trim(),
        "image_url": externalUrl,
      };

      final response = await OperationsApi.addProduct(
        fields: fields,
        imageBytes: rawBytes,
        imageFileName:
        _mediaItems.isNotEmpty ? _mediaItems.first.fileName : null,
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        final String finalImageUrl =
        (response['image_url'] ??
            response['imageUrl'] ??
            externalUrl)
            .toString()
            .trim();

        AppDataStore.products.add(
          DecorProductItem(
            id: response['id']?.toString() ?? '',
            title: fields["title"]!,
            category: fields["category"]!,
            imageUrls: finalImageUrl.isNotEmpty ? [finalImageUrl] : [],
            description: fields["description"]!,
            material: fields["material"],
            printType: fields["print_type"],
          ),
        );

        _title.clear();
        _description.clear();
        _materialController.text = "Premium Grade Material";
        _printTypeController.text = "High Definition Digital Print / Finish";
        _mediaItems.clear();
        _urlController.clear();

        widget.onDataChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New product published successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to publish product: ${response['message']}")),
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

  void _deleteProduct(String id, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Product", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '${AppDataStore.products[index].title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              bool success = await OperationsApi.deleteProduct(id);
              if (success && mounted) {
                setState(() {
                  AppDataStore.products.removeAt(index);
                });
                widget.onDataChanged();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product deleted!")));
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _materialController, label: "Material Specification")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller: _printTypeController, label: "Print / Finish Type")),
                  ],
                ),
                const SizedBox(height: 16),
                MediaPickerWidget(
                  mediaList: _mediaItems,
                  webUrlController: _urlController,
                  onAddWebUrl: () {
                    if (_urlController.text.trim().isNotEmpty) {
                      setState(() {
                        _mediaItems.add(
                          MediaItem(url: _urlController.text.trim()),
                        );
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
                    onPressed: _isLoading ? null : _addProduct,
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
                        : Text("PUBLISH PRODUCT", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
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
                    final String displayUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: buildUniversalImage(MediaItem(url: displayUrl)),
                        ),
                      ),
                      title: Text(item.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text("${item.category} • ${item.material}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () => _deleteProduct(item.id, idx),
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
import 'dart:convert';
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
  final _newCategoryController = TextEditingController();

  bool _isLoading = false;
  DecorProductItem? _editingProduct;

  late String _selectedCategory;
  List<String> _categories = ['Create New Category'];
  final List<MediaItem> _mediaItems = [];

  @override
  void initState() {
    super.initState();
    _loadCategoriesFromDatabase();
  }

  void _loadCategoriesFromDatabase() {
    final Set<String> categorySet = {
      'Wallpapers', 'Floorings', 'Carpets', 'Blinds', 'Glass Films', 'Artificial Turfs',
      'Gym Floorings', 'Awnings', 'Mosquito Nets', 'Upholstery', 'Curtains', 'Stretch Ceiling'
    };

    for (var p in AppDataStore.products) {
      if (p.category.trim().isNotEmpty) {
        categorySet.add(p.category.trim());
      }
    }

    setState(() {
      _categories = ['Create New Category', ...categorySet.toList()..sort()];
      _selectedCategory = _categories.length > 1 ? _categories[1] : 'Create New Category';
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _materialController.dispose();
    _printTypeController.dispose();
    _urlController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _title.clear();
    _description.clear();
    _materialController.text = "Premium Grade Material";
    _printTypeController.text = "High Definition Digital Print / Finish";
    _mediaItems.clear();
    _urlController.clear();
    _newCategoryController.clear();
    setState(() {
      _editingProduct = null;
      _selectedCategory = _categories.length > 1 ? _categories[1] : 'Create New Category';
    });
  }

  void _editProduct(DecorProductItem item) {
    setState(() {
      _editingProduct = item;
      _title.text = item.title;
      if (!_categories.contains(item.category)) {
        _categories.add(item.category);
      }
      _selectedCategory = item.category;
      _description.text = item.description ?? '';
      _materialController.text = item.material ?? "Premium Grade Material";
      _printTypeController.text = item.printType ?? "High Definition Digital Print / Finish";
      _mediaItems.clear();
      for (var url in item.imageUrls) {
        _mediaItems.add(MediaItem(url: url));
      }
    });
  }

  void _addNewCategory() {
    final newCategory = _newCategoryController.text.trim();
    if (newCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a category name!")),
      );
      return;
    }

    setState(() {
      if (!_categories.contains(newCategory)) {
        _categories.add(newCategory);
      }
      _selectedCategory = newCategory;
      _newCategoryController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Category '$newCategory' selected for this product!")),
    );
  }

  Future<void> _saveProduct() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Title is required!")),
      );
      return;
    }

    if (_selectedCategory == 'Create New Category') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or add a valid category!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> externalUrls = [];
      List<Uint8List> fileBytesList = [];

      for (var media in _mediaItems) {
        if (media.hasBytes && media.bytes != null) {
          fileBytesList.add(media.bytes!);
        } else if (media.url != null && media.url!.trim().isNotEmpty) {
          externalUrls.add(media.url!.trim());
        }
      }

      final Map<String, String> fields = {
        "title": _title.text.trim(),
        "category": _selectedCategory,
        "description": _description.text.trim().isEmpty ? "High-quality decor item." : _description.text.trim(),
        "material": _materialController.text.trim().isEmpty ? "Premium Grade Material" : _materialController.text.trim(),
        "print_type": _printTypeController.text.trim().isEmpty ? "High Definition Digital Print / Finish" : _printTypeController.text.trim(),
        "external_urls": jsonEncode(externalUrls),
      };

      if (_editingProduct != null) {
        fields["id"] = _editingProduct!.id;
      }

      final response = _editingProduct == null
          ? await OperationsApi.addProduct(
        fields: fields,
        imageBytes: fileBytesList.isNotEmpty ? fileBytesList.first : null,
        imageFileName: _mediaItems.isNotEmpty ? _mediaItems.first.fileName : null,
      )
          : await OperationsApi.updateProduct(
        fields: fields,
        imageBytes: fileBytesList.isNotEmpty ? fileBytesList.first : null,
        imageFileName: _mediaItems.isNotEmpty ? _mediaItems.first.fileName : null,
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        List<String> finalUrls = [];
        if (response['image_urls'] is List) {
          finalUrls = List<String>.from(response['image_urls']);
        } else if (response['image_url'] != null) {
          finalUrls = [response['image_url'].toString()];
        } else {
          finalUrls = externalUrls;
        }

        if (_editingProduct == null) {
          AppDataStore.products.add(
            DecorProductItem(
              id: response['id']?.toString() ?? '',
              title: fields["title"]!,
              category: fields["category"]!,
              imageUrls: finalUrls,
              description: fields["description"]!,
              material: fields["material"],
              printType: fields["print_type"],
            ),
          );
        } else {
          final idx = AppDataStore.products.indexWhere((p) => p.id == _editingProduct!.id);
          if (idx != -1) {
            AppDataStore.products[idx] = DecorProductItem(
              id: _editingProduct!.id,
              title: fields["title"]!,
              category: fields["category"]!,
              imageUrls: finalUrls,
              description: fields["description"]!,
              material: fields["material"],
              printType: fields["print_type"],
            );
          }
        }

        _loadCategoriesFromDatabase();
        _resetForm();
        widget.onDataChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingProduct == null ? "New product published successfully!" : "Product updated successfully!"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save product: ${response['message']}")),
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
                  _loadCategoriesFromDatabase();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingProduct != null ? "Edit Product Entry" : "Add New Product Catalog Entry",
                      style: GoogleFonts.aleo(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark),
                    ),
                    if (_editingProduct != null)
                      TextButton.icon(
                        onPressed: _resetForm,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("New Entry"),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(controller: _title, label: "Product Title *"),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Category Selection", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.primaryDark)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _categories.contains(_selectedCategory) ? _selectedCategory : _categories.first,
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
                    if (_selectedCategory == 'Create New Category') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newCategoryController,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: "Enter new category name",
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
                            onPressed: _addNewCategory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.primaryAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            child: const Text("ADD"),
                          ),
                        ],
                      ),
                    ],
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
                    onPressed: _isLoading ? null : _saveProduct,
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
                        : Text(
                      _editingProduct != null ? "UPDATE PRODUCT" : "PUBLISH PRODUCT",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                    ),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AdminTheme.primaryDark),
                            onPressed: () => _editProduct(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _deleteProduct(item.id, idx),
                          ),
                        ],
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
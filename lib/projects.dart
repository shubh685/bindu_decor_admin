import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'AdminDashboard.dart';
import 'Helper_class.dart';
import 'Api/Operations.dart';

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
  ProjectItem? _editingProject;

  String _selectedPropertyType = 'Apartment';
  final List<String> _propertyTypeOptions = ['Apartment', 'Villa', 'Bungalow', 'Penthouse', 'Duplex', 'Row House', 'Commercial'];

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

  void _resetForm() {
    _title.clear();
    _subTitle.clear();
    _location.clear();
    _pricing.clear();
    _bhk.clear();
    _size.clear();
    _description.clear();
    _urlController.clear();
    _mediaItems.clear();
    setState(() {
      _editingProject = null;
      _selectedPropertyType = 'Apartment';
      _selectedScope = 'Full Interior';
    });
  }

  void _editProject(ProjectItem item) {
    setState(() {
      _editingProject = item;
      _title.text = item.title;
      _subTitle.text = item.subTitle;
      _location.text = item.location;
      _pricing.text = item.pricing;
      _bhk.text = item.bhk;
      _size.text = item.size;
      _description.text = item.description;
      _selectedPropertyType = item.propertyType.isEmpty ? 'Apartment' : item.propertyType;
      _selectedScope = item.scope.isEmpty ? 'Full Interior' : item.scope;

      _mediaItems.clear();
      for (var url in item.imageUrls) {
        _mediaItems.add(MediaItem(url: url));
      }
    });
  }

  Future<void> _saveProject() async {
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
      List<String> externalUrls = [];
      List<Uint8List> fileBytesList = [];
      List<String> fileNamesList = [];

      for (var media in _mediaItems) {
        if (media.hasBytes && media.bytes != null) {
          fileBytesList.add(media.bytes!);
          fileNamesList.add(media.fileName ?? 'project_image.jpg');
        } else if (media.url != null && media.url!.trim().isNotEmpty) {
          externalUrls.add(media.url!.trim());
        }
      }

      if (externalUrls.isEmpty && fileBytesList.isEmpty) {
        externalUrls.add("https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800");
      }

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
        "image_urls": jsonEncode(externalUrls),
      };

      if (_editingProject != null) {
        fields["id"] = _editingProject!.id;
      }

      for (int i = 0; i < externalUrls.length; i++) {
        fields["image_urls[$i]"] = externalUrls[i];
      }

      final response = _editingProject == null
          ? await OperationsApi.addProject(
        fields: fields,
        imageBytesList: fileBytesList,
        fileNamesList: fileNamesList,
      )
          : await OperationsApi.updateProject(
        fields: fields,
        imageBytesList: fileBytesList,
        fileNamesList: fileNamesList,
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

        final project = ProjectItem.fromMap({
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
          "image_urls": finalUrls,
        });

        if (_editingProject == null) {
          AppDataStore.projects.add(project);
        } else {
          final idx = AppDataStore.projects.indexWhere((p) => p.id == _editingProject!.id);
          if (idx != -1) {
            AppDataStore.projects[idx] = project;
          }
        }

        _resetForm();
        widget.onDataChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingProject == null ? "New Project published successfully!" : "Project updated successfully!",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save project: ${response['message']}")),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingProject != null ? "Edit Interior Project" : "Add New Interior Project",
                      style: GoogleFonts.aleo(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.primaryDark),
                    ),
                    if (_editingProject != null)
                      TextButton.icon(
                        onPressed: _resetForm,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Cancel Edit"),
                      ),
                  ],
                ),
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
                    onPressed: _isLoading ? null : _saveProject,
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
                      _editingProject != null ? "UPDATE PROJECT" : "PUBLISH PROJECT",
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
                      title: Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "${item.propertyType} • ${item.location} • ${item.imageUrls.length} image(s)",
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AdminTheme.primaryDark),
                            onPressed: () => _editProject(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _deleteProject(item.id, idx),
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
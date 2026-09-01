import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import 'AdminDashboard.dart';
import 'Helper_class.dart';

class BlogDataStore {
  static final List<BlogItem> blogs = [];
}

class Blogs extends StatefulWidget {
  final VoidCallback onDataChanged;

  const Blogs({super.key, required this.onDataChanged});

  @override
  State<Blogs> createState() => _BlogsState();
}

class _BlogsState extends State<Blogs> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  final String _apiEndpoint = "http://192.168.1.48/bindu_decor/blogs.php";

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _webUrlController = TextEditingController();

  List<MediaItem> _selectedPhotos = [];
  BlogItem? _editingBlog;
  bool _isLoading = false;
  bool _isSaving = false;

  Timer? _timer;
  final ValueNotifier<DateTime> _liveTimeNotifier = ValueNotifier<DateTime>(DateTime.now());

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    if (BlogDataStore.blogs.isEmpty) {
      _fetchBlogsFromApi();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _liveTimeNotifier.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _liveTimeNotifier.dispose();
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _webUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchBlogsFromApi({bool forceRefresh = false}) async {
    if (_isLoading) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(_apiEndpoint));
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success' && resData['data'] != null) {
          final List list = resData['data'];
          if (mounted) {
            setState(() {
              BlogDataStore.blogs.clear();
              BlogDataStore.blogs.addAll(
                list.map((item) => BlogItem.fromJson(item)).toList(),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching blogs: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _subjectController.clear();
    _descriptionController.clear();
    _authorController.clear();
    _webUrlController.clear();
    setState(() {
      _selectedPhotos = [];
      _editingBlog = null;
    });
  }

  Future<void> _saveBlog(String status) async {
    if (_isSaving) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one blog image.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse(_apiEndpoint);
      final request = http.MultipartRequest('POST', uri);

      request.fields['title'] = _titleController.text.trim();
      request.fields['subject'] = _subjectController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['author_name'] = _authorController.text.trim();
      request.fields['status'] = status;

      if (_editingBlog != null) {
        request.fields['id'] = _editingBlog!.id;
        request.fields['_method'] = 'PUT';
      }

      int uploadIndex = 0;

      for (final media in _selectedPhotos) {
        if (media.hasBytes && media.bytes != null) {
          final fileName = media.fileName?.isNotEmpty == true
              ? media.fileName!
              : 'blog_image_$uploadIndex.jpg';

          request.files.add(
            http.MultipartFile.fromBytes(
              'photos[]',
              media.bytes!,
              filename: fileName,
            ),
          );
          uploadIndex++;
        } else if (media.url != null && media.url!.trim().isNotEmpty) {
          request.fields['photos[]'] = media.url!.trim();
          uploadIndex++;
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);

        if (resData['status'] == 'success') {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resData['message'] ??
                    (_editingBlog != null
                        ? 'Blog updated successfully'
                        : 'Blog published successfully'),
              ),
            ),
          );

          _resetForm();
          await _fetchBlogsFromApi(forceRefresh: true);
          widget.onDataChanged();
        } else {
          throw Exception(resData['message'] ?? 'Blog operation failed');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to save blog: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteBlog(String id) async {
    try {
      final response = await http.delete(Uri.parse("$_apiEndpoint?id=$id"));
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Blog deleted successfully')),
          );
        }
        await _fetchBlogsFromApi(forceRefresh: true);
        widget.onDataChanged();
      }
    } catch (e) {
      debugPrint("API Delete Exception: $e");
    }
  }

  void _editBlog(BlogItem blog) {
    setState(() {
      _editingBlog = blog;
      _titleController.text = blog.title;
      _subjectController.text = blog.subject;
      _descriptionController.text = blog.description;
      _authorController.text = blog.authorName;
      _selectedPhotos = blog.photos.map((p) => MediaItem(url: p)).toList();
    });
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      final List<MediaItem> newItems = [];
      for (var img in images) {
        final bytes = await img.readAsBytes();
        newItems.add(MediaItem(
          bytes: bytes,
          fileName: img.name,
        ));
      }

      setState(() {
        _selectedPhotos.addAll(newItems);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final draftBlogs = BlogDataStore.blogs.where((b) => b.status != 'Published').toList();
    final publishedBlogs = BlogDataStore.blogs.where((b) => b.status == 'Published').toList();

    return Scaffold(
      backgroundColor: AdminTheme.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed horizontal layout overflow here
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingBlog != null ? "Edit Blog Post" : "Create New Blog",
                        style: GoogleFonts.aleo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Publish articles.",
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _isLoading ? null : () => _fetchBlogsFromApi(forceRefresh: true),
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded),
                      color: AdminTheme.primaryDark,
                      tooltip: "Refresh List",
                    ),
                    if (_editingBlog != null)
                      ElevatedButton.icon(
                        onPressed: _resetForm,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("New Blog"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.primaryDark,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<DateTime>(
                      valueListenable: _liveTimeNotifier,
                      builder: (context, time, _) {
                        final formattedDate = DateFormat('dd MMM yyyy, hh:mm:ss a').format(time);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AdminTheme.primaryDark.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AdminTheme.primaryDark.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_filled_rounded,
                                size: 16,
                                color: AdminTheme.primaryDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Date & Time: $formattedDate",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AdminTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 600;
                        return Flex(
                          direction: isMobile ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildTextField(
                                controller: _titleController,
                                label: "Blog Title (Main Subject)",
                                hint: "e.g., Scaling Flutter Admin Apps",
                                validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
                              ),
                            ),
                            SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 12 : 0),
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildTextField(
                                controller: _subjectController,
                                label: "Blog Subject",
                                hint: "e.g., Software Development Journey",
                                validator: (val) => val == null || val.trim().isEmpty ? "Subject is required" : null,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _authorController,
                      label: "Author Name",
                      hint: "e.g., Author Name",
                      validator: (val) => val == null || val.trim().isEmpty ? "Author name is required" : null,
                    ),
                    const SizedBox(height: 14),

                    _buildMediaPicker(),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _descriptionController,
                      label: "Blog Description",
                      hint: "Write detailed content here...",
                      maxLines: 4,
                      validator: (val) => val == null || val.trim().isEmpty ? "Description is required" : null,
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : () => _saveBlog('Draft'),
                          icon: _isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.drafts_outlined, size: 18),
                          label: const Text("Save as Draft"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AdminTheme.primaryDark,
                            side: const BorderSide(color: AdminTheme.primaryDark),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _saveBlog('Published'),
                          icon: _isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.publish_rounded, size: 18),
                          label: Text(_editingBlog != null ? "Update & Publish" : "Publish Blog"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primaryAccent,
                            foregroundColor: AdminTheme.primaryDark,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            if (draftBlogs.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Colors.amber.shade900, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Drafted Blogs (${draftBlogs.length})",
                    style: GoogleFonts.aleo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: draftBlogs.length,
                itemBuilder: (context, index) {
                  return _buildSummaryCard(draftBlogs[index]);
                },
              ),
              const SizedBox(height: 24),
            ],

            Text(
              "Published Blogs (${publishedBlogs.length})",
              style: GoogleFonts.aleo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 14),

            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryAccent))
                : publishedBlogs.isEmpty
                ? Container(
              padding: const EdgeInsets.all(30),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  "No published blogs yet.",
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: publishedBlogs.length,
              itemBuilder: (context, index) {
                return _buildSummaryCard(publishedBlogs[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AdminTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade400),
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

  Widget _buildMediaPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Blog Images (${_selectedPhotos.length})",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AdminTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 10),

        if (_selectedPhotos.isNotEmpty)
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: buildUniversalImage(
                          _selectedPhotos[index],
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPhotos.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image, size: 18),
              label: const Text("Pick Images"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: AdminTheme.primaryDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _webUrlController,
                      decoration: InputDecoration(
                        hintText: "Enter image URL",
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminTheme.primaryAccent)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (_webUrlController.text.trim().isNotEmpty) {
                        setState(() {
                          _selectedPhotos.add(MediaItem(url: _webUrlController.text.trim()));
                          _webUrlController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add_circle, color: AdminTheme.primaryAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BlogItem blog) {
    final isPublished = blog.status == 'Published';
    final PageController carouselController = PageController();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: blog.photos.isNotEmpty
                  ? PageView.builder(
                controller: carouselController,
                itemCount: blog.photos.length,
                itemBuilder: (context, idx) {
                  return buildUniversalImage(
                    MediaItem(url: blog.photos[idx]),
                    fit: BoxFit.cover,
                  );
                },
              )
                  : const Icon(Icons.article_outlined, color: Colors.grey, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        blog.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AdminTheme.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPublished ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isPublished ? Colors.green.shade300 : Colors.amber.shade300,
                        ),
                      ),
                      child: Text(
                        blog.status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPublished ? Colors.green.shade800 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "By ${blog.authorName.split(RegExp(r'https?://')).first.trim()} • ${blog.photos.length} image(s)",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AdminTheme.primaryDark),
                onPressed: () => _editBlog(blog),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => _deleteBlog(blog.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
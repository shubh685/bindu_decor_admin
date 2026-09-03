import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
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

  final String _apiEndpoint = "https://yellow-woodpecker-430323.hostingersite.com/api/bindu_admin_web";

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _webUrlController = TextEditingController();

  // Quill Editor Controller & FocusNode
  late quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _toolbarScrollController = ScrollController();

  // Font Selection State (MS Word Style)
  String _selectedFontFamily = 'Plus Jakarta Sans';
  double _selectedFontSize = 14.0;

  final Map<String, TextStyle Function({TextStyle? textStyle})> _googleFontMap = {
    'Plus Jakarta Sans': GoogleFonts.plusJakartaSans,
    'Cormorant Garamond': GoogleFonts.cormorantGaramond,
    'Roboto': GoogleFonts.roboto,
    'Open Sans': GoogleFonts.openSans,
    'Lato': GoogleFonts.lato,
    'Montserrat': GoogleFonts.montserrat,
    'Poppins': GoogleFonts.poppins,
    'Playfair Display': GoogleFonts.playfairDisplay,
    'Lora': GoogleFonts.lora,
    'Oswald': GoogleFonts.oswald,
    'Raleway': GoogleFonts.raleway,
    'Merriweather': GoogleFonts.merriweather,
  };

  final List<double> _fontSizeOptions = [10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 36.0];

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
    _initQuillController("");

    if (BlogDataStore.blogs.isEmpty) {
      _fetchBlogsFromApi();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _liveTimeNotifier.value = DateTime.now();
    });
  }

  void _initQuillController(String content) {
    if (content.trim().startsWith('[')) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(content));
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
        return;
      } catch (_) {}
    }

    // Fallback for plain text format
    final doc = quill.Document();
    if (content.isNotEmpty) {
      doc.insert(0, content);
    }
    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _liveTimeNotifier.dispose();
    _titleController.dispose();
    _subjectController.dispose();
    _authorController.dispose();
    _webUrlController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _toolbarScrollController.dispose();
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
    _authorController.clear();
    _webUrlController.clear();
    setState(() {
      _initQuillController("");
      _selectedPhotos = [];
      _editingBlog = null;
    });
  }

  String _getQuillContent() {
    final delta = _quillController.document.toDelta();
    return jsonEncode(delta.toJson());
  }

  String _getQuillPlainText() {
    return _quillController.document.toPlainText().trim();
  }

  Future<void> _saveBlog(String status) async {
    if (_isSaving) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final descriptionText = _getQuillPlainText();
    if (descriptionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description cannot be empty.')),
      );
      return;
    }

    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one blog image.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse(_apiEndpoint);
      final request = http.MultipartRequest('POST', uri);

      request.fields['title'] = _titleController.text.trim();
      request.fields['subject'] = _subjectController.text.trim();
      request.fields['description'] = _getQuillContent(); // JSON delta payload
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
      _authorController.text = blog.authorName;
      _initQuillController(blog.description);
      _selectedPhotos = blog.photos.map((p) => MediaItem(url: p)).toList();
    });
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 80);

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

  // Opens History Panel showing Drafted and Published Blogs
  void _showHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final draftBlogs = BlogDataStore.blogs.where((b) => b.status != 'Published').toList();
              final publishedBlogs = BlogDataStore.blogs.where((b) => b.status == 'Published').toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, color: Color(0xFF0073AA), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Blog History & Archives",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF23282D),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.grey),
                            onPressed: () async {
                              await _fetchBlogsFromApi(forceRefresh: true);
                              setModalState(() {});
                            },
                            tooltip: "Sync History",
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildHistorySectionHeader("Drafted Posts", draftBlogs.length, Colors.amber.shade800),
                        const SizedBox(height: 8),
                        if (draftBlogs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No draft posts found.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          )
                        else
                          ...draftBlogs.map((b) => _buildHistoryCardItem(b, () {
                            Navigator.pop(context);
                            _editBlog(b);
                          })),
                        const SizedBox(height: 20),
                        _buildHistorySectionHeader("Published Posts", publishedBlogs.length, Colors.green.shade700),
                        const SizedBox(height: 8),
                        if (publishedBlogs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No published posts found.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          )
                        else
                          ...publishedBlogs.map((b) => _buildHistoryCardItem(b, () {
                            Navigator.pop(context);
                            _editBlog(b);
                          })),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistorySectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          "$title ($count)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
      ],
    );
  }

  Widget _buildHistoryCardItem(BlogItem blog, VoidCallback onEdit) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 46,
            height: 46,
            color: Colors.grey.shade200,
            child: blog.photos.isNotEmpty
                ? buildUniversalImage(MediaItem(url: blog.photos.first), fit: BoxFit.cover)
                : const Icon(Icons.article, size: 24, color: Colors.grey),
          ),
        ),
        title: Text(
          blog.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          "By ${blog.authorName} • Subject: ${blog.subject}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note, color: Color(0xFF0073AA)),
              onPressed: onEdit,
              tooltip: "Edit Post",
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () async {
                await _deleteBlog(blog.id);
                setState(() {});
              },
              tooltip: "Delete Post",
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getFormattedTextStyle() {
    final fontBuilder = _googleFontMap[_selectedFontFamily] ?? GoogleFonts.plusJakartaSans;
    return fontBuilder(
      textStyle: TextStyle(
        fontSize: _selectedFontSize,
        color: const Color(0xFF23282D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final draftBlogs = BlogDataStore.blogs.where((b) => b.status != 'Published').toList();
    final publishedBlogs = BlogDataStore.blogs.where((b) => b.status == 'Published').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Title and Right Action (History Icon)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _editingBlog != null ? "Edit Post" : "Add New Post",
                    style: GoogleFonts.openSans(
                      fontSize: 23,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF23282D),
                    ),
                  ),
                  // History Icon Button replacing Refresh and Screen Options
                  Container(
                    padding: EdgeInsets.only(left: 8, right: 8, top: 7.5, bottom: 5),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: InkWell(
                      onTap: () {
                        _showHistoryModal(context);
                      },
                      child: Row(
                        children: [
                            Icon(Icons.history, size: 20, color: Colors.grey), SizedBox(width: 10),
                            Text("Blog History", style: GoogleFonts.plusJakartaSans(fontSize: 15.8, fontWeight: FontWeight.bold, color: Colors.blue))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Responsive Workspace Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktop = constraints.maxWidth > 900;
                  return Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Title & Quill Rich Text Editor Panel
                      Expanded(
                        flex: isDesktop ? 3 : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Post Title Box
                            TextFormField(
                              controller: _titleController,
                              style: _getFormattedTextStyle().copyWith(fontSize: 18, fontWeight: FontWeight.normal),
                              validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
                              decoration: InputDecoration(
                                hintText: "Add title (e.g., 1. Plain Khakhra Title)",
                                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(2),
                                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(2),
                                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Media Picker Trigger
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickImages,
                                  icon: const Icon(Icons.perm_media, size: 16, color: Color(0xFF555555)),
                                  label: const Text("Add Media", style: TextStyle(color: Color(0xFF555555), fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF7F7F7),
                                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 2 & 3. Custom Classic Toolbar + MS Word Font Controls + Quill Text Editor
                            Localizations(
                              locale: const Locale('en', 'US'),
                              delegates: const [
                                quill.FlutterQuillLocalizations.delegate,
                                GlobalMaterialLocalizations.delegate,
                                GlobalWidgetsLocalizations.delegate,
                              ],
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFFCCCCCC)),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Column(
                                  children: [
                                    // MS Word-style Toolbar with Font Family & Font Size Dropdowns
                                    Container(
                                      color: const Color(0xFFF5F5F5),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Scrollbar(
                                        controller: _toolbarScrollController,
                                        thumbVisibility: true,
                                        trackVisibility: true,
                                        thickness: 6.0,
                                        radius: const Radius.circular(3),
                                        child: SingleChildScrollView(
                                          controller: _toolbarScrollController,
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            children: [
                                              // MS Word Font Family Dropdown
                                              Container(
                                                height: 32,
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(color: Colors.grey.shade400),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    value: _selectedFontFamily,
                                                    isDense: true,
                                                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                                    onChanged: (String? newFont) {
                                                      if (newFont != null) {
                                                        setState(() {
                                                          _selectedFontFamily = newFont;
                                                        });
                                                      }
                                                    },
                                                    items: _googleFontMap.keys.map<DropdownMenuItem<String>>((String font) {
                                                      final fontStyleFunc = _googleFontMap[font]!;
                                                      return DropdownMenuItem<String>(
                                                        value: font,
                                                        child: Text(
                                                          font,
                                                          style: fontStyleFunc(textStyle: const TextStyle(fontSize: 13)),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),

                                              // MS Word Font Size Dropdown
                                              Container(
                                                height: 32,
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(color: Colors.grey.shade400),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<double>(
                                                    value: _selectedFontSize,
                                                    isDense: true,
                                                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                                    onChanged: (double? newSize) {
                                                      if (newSize != null) {
                                                        setState(() {
                                                          _selectedFontSize = newSize;
                                                        });
                                                      }
                                                    },
                                                    items: _fontSizeOptions.map<DropdownMenuItem<double>>((double size) {
                                                      return DropdownMenuItem<double>(
                                                        value: size,
                                                        child: Text("${size.toInt()} pt"),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const SizedBox(height: 20, child: VerticalDivider(width: 1, color: Colors.grey)),

                                              // Quill Default Formatting Controls
                                              quill.QuillSimpleToolbar(
                                                controller: _quillController,
                                                config: const quill.QuillSimpleToolbarConfig(
                                                  showFontFamily: false,
                                                  showFontSize: false,
                                                  showColorButton: false,
                                                  showBackgroundColorButton: false,
                                                  showSearchButton: false,
                                                  showSubscript: false,
                                                  showSuperscript: false,
                                                  showCodeBlock: false,
                                                  showInlineCode: false,
                                                  showStrikeThrough: false,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 1, color: Color(0xFFCCCCCC)),

                                    // Quill Canvas Editor Area with Selected GoogleFont Style Applied
                                    Container(
                                      height: 300,
                                      padding: const EdgeInsets.all(12),
                                      child: DefaultTextStyle(
                                        style: _getFormattedTextStyle(),
                                        child: quill.QuillEditor(
                                          controller: _quillController,
                                          focusNode: _editorFocusNode,
                                          scrollController: _editorScrollController,
                                          config: quill.QuillEditorConfig(
                                            placeholder: 'Write your description, e.g., details about Plain Khakhra...',
                                            padding: EdgeInsets.zero,
                                            autoFocus: false,
                                            expands: true,
                                            customStyles: quill.DefaultStyles(
                                              paragraph: quill.DefaultTextBlockStyle(
                                                _getFormattedTextStyle(),
                                                const quill.HorizontalSpacing(0, 0),
                                                const quill.VerticalSpacing(0, 0),
                                                const quill.VerticalSpacing(0, 0),
                                                null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Footer Word Count Bar
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      color: const Color(0xFFF5F5F5),
                                      child: AnimatedBuilder(
                                        animation: _quillController,
                                        builder: (context, _) {
                                          final text = _getQuillPlainText();
                                          final count = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Word count: $count",
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                                              ),
                                              Text(
                                                "Font: $_selectedFontFamily (${_selectedFontSize.toInt()}pt)",
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isDesktop) const SizedBox(width: 20) else const SizedBox(height: 20),

                      // RIGHT COLUMN: Sidebar Panes
                      Expanded(
                        flex: isDesktop ? 1 : 0,
                        child: Column(
                          children: [
                            // Publish Box
                            _buildSidebarBox(
                              title: "Publish",
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton(
                                        onPressed: _isSaving ? null : () => _saveBlog('Draft'),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF7F7F7),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                                        ),
                                        child: const Text("Save Draft", style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
                                      ),
                                      OutlinedButton(
                                        onPressed: _editingBlog != null ? _resetForm : null,
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF7F7F7),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                                        ),
                                        child: const Text("Reset Form", style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.key, size: 16, color: Color(0xFF666666)),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Status: ${_editingBlog?.status ?? 'Draft'}",
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ValueListenableBuilder<DateTime>(
                                    valueListenable: _liveTimeNotifier,
                                    builder: (context, time, _) {
                                      final formattedDate = DateFormat('MMM dd, yyyy @ HH:mm').format(time);
                                      return Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF666666)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              "Publish: $formattedDate",
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const Divider(height: 20),
                                  Container(
                                    color: const Color(0xFFF5F5F5),
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (_editingBlog != null)
                                          GestureDetector(
                                            onTap: () => _deleteBlog(_editingBlog!.id),
                                            child: const Text("Move to Trash", style: TextStyle(color: Colors.red, fontSize: 12, decoration: TextDecoration.underline)),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        ElevatedButton(
                                          onPressed: _isSaving ? null : () => _saveBlog('Published'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0073AA),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                          ),
                                          child: Text(
                                            _editingBlog != null ? "Update" : "Publish",
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Post Details Box
                            _buildSidebarBox(
                              title: "Post Details",
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _subjectController,
                                    validator: (val) => val == null || val.trim().isEmpty ? "Subject is required" : null,
                                    decoration: const InputDecoration(
                                      labelText: "Category / Subject",
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _authorController,
                                    validator: (val) => val == null || val.trim().isEmpty ? "Author is required" : null,
                                    decoration: const InputDecoration(
                                      labelText: "Author Name",
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Image Sidebar Box
                            _buildSidebarBox(
                              title: "Featured Images",
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_selectedPhotos.isNotEmpty)
                                    SizedBox(
                                      height: 90,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _selectedPhotos.length,
                                        itemBuilder: (context, idx) {
                                          return Stack(
                                            children: [
                                              Container(
                                                width: 80,
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                                                child: buildUniversalImage(_selectedPhotos[idx], fit: BoxFit.cover),
                                              ),
                                              Positioned(
                                                top: 2,
                                                right: 10,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedPhotos.removeAt(idx);
                                                    });
                                                  },
                                                  child: const CircleAvatar(
                                                    radius: 10,
                                                    backgroundColor: Colors.red,
                                                    child: Icon(Icons.close, size: 12, color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _webUrlController,
                                          style: const TextStyle(fontSize: 12),
                                          decoration: const InputDecoration(
                                            hintText: "Add Image URL",
                                            isDense: true,
                                            contentPadding: EdgeInsets.all(8),
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_link, color: Color(0xFF0073AA)),
                                        onPressed: () {
                                          if (_webUrlController.text.trim().isNotEmpty) {
                                            setState(() {
                                              _selectedPhotos.add(MediaItem(url: _webUrlController.text.trim()));
                                              _webUrlController.clear();
                                            });
                                          }
                                        },
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: _pickImages,
                                    child: const Text(
                                      "Set featured image",
                                      style: TextStyle(color: Color(0xFF0073AA), fontSize: 13, decoration: TextDecoration.underline),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarBox({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCCCCCC)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF23282D)),
                ),
                const Icon(Icons.keyboard_arrow_up, size: 18, color: Color(0xFF666666)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: child,
          ),
        ],
      ),
    );
  }
}
// ==========================================
// 3. CLIENT DOMAIN MANAGEMENT SCREEN
// ==========================================
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'AdminDashboard.dart';
import 'Api/Operations.dart';
import 'Helper_class.dart';

class ClientDomainManager extends StatefulWidget {
  final VoidCallback onDataChanged;

  const ClientDomainManager({super.key, required this.onDataChanged});

  @override
  State<ClientDomainManager> createState() => _ClientDomainManagerState();
}

class _ClientDomainManagerState extends State<ClientDomainManager> {
  final _urlController = TextEditingController();
  final List<MediaItem> _mediaItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Debug: Print current client logos on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugPrintClientLogos();
    });
  }

  void _debugPrintClientLogos() {
    debugPrint('📋 Current Client Logos: ${AppDataStore.clientLogos.length}');
    for (var client in AppDataStore.clientLogos) {
      debugPrint('  🖼️ ID: ${client.id}, URL: ${client.safeImageUrl}');
    }
  }

  Future<void> _addClients() async {
    if (_mediaItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please attach an image file or provide an image link!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      for (var media in _mediaItems) {
        final Uint8List? imageBytes = media.bytes;

        final response = await OperationsApi.addClient(
          imageUrl: media.url ?? '',
          imageBytes: imageBytes,
          imageFileName: media.fileName ?? '',
        );

        debugPrint('📤 Add Client Response: $response');

        if (response['status'] == 'success') {
          // Get the uploaded image URL from response
          String uploadedUrl = '';

          // Try to get from data first
          if (response['data'] != null) {
            if (response['data']['img_path'] != null && response['data']['img_path'].toString().isNotEmpty) {
              uploadedUrl = response['data']['img_path'].toString();
            } else if (response['data']['img_url'] != null && response['data']['img_url'].toString().isNotEmpty) {
              uploadedUrl = response['data']['img_url'].toString();
            }
          }

          // If not found in data, try top level
          if (uploadedUrl.isEmpty) {
            uploadedUrl = response['img_url']?.toString() ??
                response['image_url']?.toString() ??
                media.url ?? '';
          }

          debugPrint('🖼️ Uploaded URL: $uploadedUrl');

          String resolvedUrl = OperationsApi.resolveImageUrl(uploadedUrl);
          debugPrint('✅ Resolved URL: $resolvedUrl');

          String id = response['id']?.toString() ??
              response['data']?['id']?.toString() ??
              '${DateTime.now().millisecondsSinceEpoch}';

          setState(() {
            // Check for duplicates
            bool exists = AppDataStore.clientLogos.any((item) => item.id == id);
            if (!exists) {
              AppDataStore.clientLogos.add(
                ClientItems(
                  id: id,
                  imgUrl: resolvedUrl,
                  imageUrl: resolvedUrl,
                  imageUrlFull: resolvedUrl,
                ),
              );
            }
          });

          _debugPrintClientLogos();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message']?.toString() ?? "Failed to save logo")),
            );
          }
        }
      }
      widget.onDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Client logo(s) updated successfully!")),
        );
        setState(() {
          _mediaItems.clear();
          _urlController.clear();
        });
      }
    } catch (e) {
      debugPrint('❌ Error saving clients: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving clients: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteClient(String id, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Client Logo", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this client logo?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              bool success = await OperationsApi.deleteClient(id);
              if (success && mounted) {
                setState(() {
                  AppDataStore.clientLogos.removeAt(index);
                });
                widget.onDataChanged();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Client logo deleted!")));
                _debugPrintClientLogos();
              }
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
                    onPressed: _isLoading ? null : _addClients,
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
                        : Text("SAVE CLIENT LOGOS", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
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
                            child: _buildClientImage(item.safeImageUrl),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _deleteClient(item.id, idx),
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

  Widget _buildClientImage(String rawUrl) {
    if (rawUrl.trim().isEmpty) {
      return _buildPlaceholder();
    }

    // Resolve the URL using OperationsApi
    final String imageUrl = OperationsApi.resolveImageUrl(rawUrl);
    debugPrint('🖼️ Loading image from: $imageUrl');

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image load error for: $imageUrl');
        debugPrint('❌ Error: $error');

        // Try alternative URL without image.php as fallback
        String altUrl = _tryAlternativeUrl(rawUrl);
        if (altUrl != imageUrl) {
          debugPrint('🔄 Trying alternative URL: $altUrl');
          return Image.network(
            altUrl,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => _buildPlaceholder(),
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return _buildLoadingPlaceholder();
            },
          );
        }

        return _buildPlaceholder();
      },
    );
  }

  String _tryAlternativeUrl(String rawUrl) {
    // Try direct URL without image.php
    String cleanPath = rawUrl.trim();

    // If it's already a full URL with image.php, try to extract the path
    if (cleanPath.contains('image.php')) {
      try {
        var uri = Uri.parse(cleanPath);
        var pathParam = uri.queryParameters['path'];
        if (pathParam != null && pathParam.isNotEmpty) {
          String baseUrl = OperationsApi.baseUrl.endsWith('/')
              ? OperationsApi.baseUrl.substring(0, OperationsApi.baseUrl.length - 1)
              : OperationsApi.baseUrl;
          return '$baseUrl/uploads/$pathParam';
        }
      } catch (e) {}
    }

    return rawUrl;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              'Image Not Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AdminTheme.primaryDark,
          ),
        ),
      ),
    );
  }
}
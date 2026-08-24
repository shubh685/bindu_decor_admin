
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
          imageUrl: media.url,
          imageBytes: imageBytes,
          imageFileName: media.fileName,
        );

        if (response['status'] == 'success') {
          final uploadedUrl = response['img_url'] ?? response['image_url'] ?? media.url ?? '';

          setState(() {
            AppDataStore.clientLogos.add(
              ClientItems(
                id: response['id']?.toString() ?? '',
                imgUrl: uploadedUrl,
              ),
            );
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? "Failed to save logo")),
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
                            child: buildUniversalImage(MediaItem(url: item.imgUrl)),
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
}
import 'package:flutter/material.dart';

class SafeNetworkImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  // Active LAN IP / Host of your backend server
  static const String baseUrl = 'http://192.168.1.6/bindu_decor/';

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  bool _hasError = false;
  String? _errorText;
  int _retryToken = 0;

  String _resolveUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    // Direct HTTP/HTTPS external image URLs or base64 data URIs
    if (Uri.parse(trimmed).hasScheme || trimmed.startsWith('data:image/')) {
      return trimmed;
    }

    // Format relative paths to absolute URLs using baseUrl
    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '${SafeNetworkImage.baseUrl}$cleanPath';
  }

  @override
  void didUpdateWidget(covariant SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _hasError = false;
      _errorText = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveUrl(widget.url);

    if (resolvedUrl.isEmpty) {
      return _imageFallback('No image URL');
    }
    if (_hasError) {
      return _imageFallback(_errorText ?? 'Image not found');
    }

    final key = ValueKey('$resolvedUrl#$_retryToken');

    return Image.network(
      resolvedUrl,
      key: key,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _loadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Network image error for "$resolvedUrl": $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorText = error.toString();
            });
          }
        });
        return _loadingPlaceholder();
      },
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _imageFallback(String reason) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28),
              const SizedBox(height: 6),
              Text(
                'Image not found',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  setState(() {
                    _hasError = false;
                    _errorText = null;
                    _retryToken++;
                  });
                },
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
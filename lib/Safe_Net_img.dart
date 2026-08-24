// Safe_Net_img.dart
import 'package:flutter/material.dart';

class SafeNetworkImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

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

  @override
  void didUpdateWidget(covariant SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      // New URL - give it a fresh chance instead of keeping old error state
      _hasError = false;
      _errorText = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) {
      return _imageFallback('No image URL');
    }
    if (_hasError) {
      return _imageFallback(_errorText ?? 'Image not found');
    }

    // _retryToken busts Flutter's internal image cache on manual retry
    final key = ValueKey('${widget.url}#$_retryToken');

    return Image.network(
      widget.url,
      key: key,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _loadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        // Print the FULL real error so root causes (SocketException,
        // HandshakeException, 404, CORS, etc.) are visible in the console.
        debugPrint('❌ Network image error for "${widget.url}": $error');
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
    );
  }
}
// ==========================================
// SAFE NETWORK IMAGE
// ==========================================
// Drop-in replacement for Image.network(url) that:
//  - Shows a clear placeholder while loading
//  - Retries once automatically on failure (helps with transient
//    connection blips on flaky local Wi-Fi)
//  - Prints a detailed, useful error (not just "statusCode: 0")
//  - Lets you manually retry by tapping the broken-image icon
//
// Usage:
//   SafeNetworkImage(url: client.primaryImageUrl, height: 80, width: 80)

import 'package:flutter/material.dart';

class SafeNetworkImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  int _retryCount = 0;
  int _cacheBuster = 0;

  // Appends a cache-busting query param so a manual retry actually
  // re-hits the network instead of returning a cached failure.
  String get _effectiveUrl {
    if (widget.url.isEmpty) return widget.url;
    final sep = widget.url.contains('?') ? '&' : '?';
    return _cacheBuster == 0
        ? widget.url
        : '${widget.url}${sep}retry=$_cacheBuster';
  }

  void _retry() {
    setState(() {
      _retryCount++;
      _cacheBuster = DateTime.now().millisecondsSinceEpoch;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) {
      return _buildPlaceholder(icon: Icons.image_not_supported_outlined);
    }

    Widget image = Image.network(
      _effectiveUrl,
      key: ValueKey('${widget.url}_$_cacheBuster'),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _buildPlaceholder(loading: true);
      },
      errorBuilder: (context, error, stackTrace) {
        // This is the useful diagnostic — check your console for it.
        debugPrint(
          'SafeNetworkImage load error for "${widget.url}" '
              '(attempt ${_retryCount + 1}): $error',
        );

        // Auto-retry once, in case it was a transient network blip.
        if (_retryCount == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _retry());
          return _buildPlaceholder(loading: true);
        }

        // After the auto-retry also fails, show a tappable error state.
        return GestureDetector(
          onTap: _retry,
          child: _buildPlaceholder(
            icon: Icons.refresh,
            isError: true,
          ),
        );
      },
    );

    if (widget.borderRadius != null) {
      image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder({
    IconData icon = Icons.image_outlined,
    bool loading = false,
    bool isError = false,
  }) {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isError ? Colors.red.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: widget.borderRadius,
      ),
      child: loading
          ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Icon(
        icon,
        color: isError ? Colors.redAccent : Colors.grey.shade400,
        size: (widget.width ?? 40) * 0.4,
      ),
    );
  }
}
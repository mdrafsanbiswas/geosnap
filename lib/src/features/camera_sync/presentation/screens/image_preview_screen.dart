import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({
    required this.filePaths,
    this.initialIndex = 0,
    this.title = 'Image Preview',
    super.key,
  });

  final List<String> filePaths;
  final int initialIndex;
  final String title;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _safeIndex(widget.initialIndex, widget.filePaths.length);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filePaths.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('No image available.')),
      );
    }

    final currentPath = widget.filePaths[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.filePaths.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: Image.file(
                        File(widget.filePaths[index]),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white60,
                              size: 42,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Unable to load this image.',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_currentIndex + 1} / ${widget.filePaths.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.basename(currentPath),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _safeIndex(int requested, int length) {
    if (length <= 0) {
      return 0;
    }
    if (requested < 0) {
      return 0;
    }
    if (requested >= length) {
      return length - 1;
    }
    return requested;
  }
}

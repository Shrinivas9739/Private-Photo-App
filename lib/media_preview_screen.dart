import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewScreen extends StatefulWidget {
  final List<Map<String, String>> mediaList;
  final int initialIndex;

  const MediaPreviewScreen({
    super.key,
    required this.mediaList,
    required this.initialIndex,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadMedia(_currentIndex);
  }

  void _loadMedia(int index) {
    _controller?.dispose();

    if (widget.mediaList[index]["type"] == "video") {
      _controller = VideoPlayerController.file(
        File(widget.mediaList[index]["path"]!),
      )..initialize().then((_) {
          setState(() {});
          _controller!.play();
        });
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _loadMedia(index);
        },
        itemCount: widget.mediaList.length,
        itemBuilder: (context, index) {
          final media = widget.mediaList[index];

          if (media["type"] == "photo") {
            return InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.file(
                File(media["path"]!),
                fit: BoxFit.contain,
              ),
            );
          } else if (media["type"] == "video" &&
              _controller != null &&
              _controller!.value.isInitialized) {
            return AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton:
          widget.mediaList[_currentIndex]["type"] == "video" && _controller != null
              ? FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _controller!.value.isPlaying
                          ? _controller!.pause()
                          : _controller!.play();
                    });
                  },
                  child: Icon(
                    _controller!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                )
              : null,
    );
  }
}

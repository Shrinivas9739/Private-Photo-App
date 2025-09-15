import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:private_photo/trash_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

import 'db_helper.dart';
import 'permission_helper.dart';
import 'media_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBHelper _dbHelper = DBHelper();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _mediaList = [];

  // Created this to move data from media to trash
  List<int> _selectedMediaIds = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final media = await _dbHelper.getAllMedia();
    setState(() {
      _mediaList = media;
    });
  }

  Future<File?> _saveFilePermanently(XFile xFile) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final newPath = path.join(
        appDocDir.path,
        '${DateTime.now().microsecondsSinceEpoch}_${xFile.name}',
      );
      final newFile = await File(xFile.path).copy(newPath);
      return newFile;
    } catch (e) {
      print('Error saving file permanently: $e');
      return null;
    }
  }

  Future<void> _addMedia({
    required bool isCamera,
    required bool isVideo,
  }) async {
    // Request permissions
    bool granted = await PermissionHelper.requestPermissions();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions are required to continue')),
      );
      return;
    }

    if (isVideo) {
      if (isCamera) {
        // Single video from camera
        final XFile? file = await _picker.pickVideo(source: ImageSource.camera);
        if (file != null) {
          final permanentFile = await _saveFilePermanently(file);
          if (permanentFile != null) {
            await _dbHelper.insertMedia(permanentFile.path, "video");
          }
          _loadMedia();
        }
      } else {
        // Import multiple videos from gallery
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: true,
        );

        if (result != null) {
          for (final file in result.files) {
            if (file.path != null) {
              final permanentFile = await _saveFilePermanently(
                XFile(file.path!),
              );
              if (permanentFile != null) {
                await _dbHelper.insertMedia(permanentFile.path, "video");
              }
            }
          }
          _loadMedia();
        }
      }
    } else {
      if (isCamera) {
        // Single photo
        final XFile? file = await _picker.pickImage(source: ImageSource.camera);
        if (file != null) {
          final permanentFile = await _saveFilePermanently(file);
          if (permanentFile != null) {
            await _dbHelper.insertMedia(permanentFile.path, "photo");
          }
          _loadMedia();
        }
      } else {
        // Import multiple photos
        final List<XFile> files = await _picker.pickMultiImage();
        if (files.isNotEmpty) {
          for (final file in files) {
            final permanentFile = await _saveFilePermanently(file);
            if (permanentFile != null) {
              await _dbHelper.insertMedia(permanentFile.path, "photo");
            }
          }
          _loadMedia();
        }
      }
    }
  }

  Widget _buildMediaItem(Map<String, dynamic> media) {
    final File file = File(media['path']);

    if (media['type'] == "photo") {
      return Image.file(file, fit: BoxFit.cover);
    } else {
      // Showing video thumbnail
      return FutureBuilder(
        future: VideoThumbnail.thumbnailFile(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 200,
          quality: 75,
        ),
        builder: (ctx, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(snapshot.data!), fit: BoxFit.cover),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedMediaIds.contains(id)) {
        _selectedMediaIds.remove(id);
        if (_selectedMediaIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMediaIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _confirmMoveToTrash() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Move To Trash?"),
        content: Text(
          "Do you want to move ${_selectedMediaIds.length} item(s) to Trash?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (var id in _selectedMediaIds) {
                final media = _mediaList.firstWhere((m) => m['id'] == id);
                await _dbHelper.moveToTrash(media['path'], media['type']);
                await _dbHelper.deleteMedia(id);
              }
              _loadMedia();
              setState(() {
                _isSelectionMode = false;
                _selectedMediaIds.clear();
              });
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Import Photo"),
              onTap: () {
                Navigator.pop(ctx);
                _addMedia(isCamera: false, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text("Import Video"),
              onTap: () {
                Navigator.pop(ctx);
                _addMedia(isCamera: false, isVideo: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(ctx);
                _addMedia(isCamera: true, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text("Record Video"),
              onTap: () {
                Navigator.pop(ctx);
                _addMedia(isCamera: true, isVideo: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int photoCount = _mediaList.where((m) => m['type'] == 'photo').length;
    int videoCount = _mediaList.where((m) => m['type'] == 'video').length;
    int totalCount = _mediaList.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TrashScreen()),
            ).then((_) {
              _loadMedia();
            });
          },
          icon: const Icon(Icons.delete),
        ),
        centerTitle: true,
        title: _isSelectionMode
            ? Text("${_selectedMediaIds.length} selected")
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("My Vault"),
                  Text(
                    "Total : $totalCount -> Photos: $photoCount | Videos: $videoCount",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: _confirmMoveToTrash,
                ),
              ]
            : [],
      ),
      body: _mediaList.isEmpty
          ? Center(
              child: IconButton(
                onPressed: _showAddOptions,
                icon: const Icon(
                  Icons.add_circle,
                  size: 80,
                  color: Colors.deepPurple,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _mediaList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (ctx, i) {
                final media = _mediaList[i];
                final isSelected = _selectedMediaIds.contains(media['id']); 

                return GestureDetector(
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(media['id']);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MediaPreviewScreen(
                            mediaList: _mediaList
                                .map(
                                  (m) => {
                                    "path": m['path'] as String,
                                    "type": m['type'] as String,
                                  },
                                )
                                .toList(),
                            initialIndex: i,
                          ),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    _isSelectionMode = true;
                    _toggleSelection(media['id']);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaItem(media),
                      if (isSelected)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: _mediaList.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              onPressed: _showAddOptions,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

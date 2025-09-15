import 'dart:io';
import 'package:flutter/material.dart';
import 'db_helper.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _trashList = [];

  // ✅ Multi data selection
  bool _isSelectionMode = false;
  final Set<int> _selectedMediaIds = {};

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    final db = await _dbHelper.db;
    final data = await db.query('trash', orderBy: "id DESC");
    setState(() {
      _trashList = data;
    });
  }

  Future<void> _restoreItems() async {
    for (var id in _selectedMediaIds) {
      final item = _trashList.firstWhere((e) => e['id'] == id);
      await _dbHelper.insertMedia(item['path'], item['type']);
      final db = await _dbHelper.db;
      await db.delete('trash', where: 'id = ?', whereArgs: [id]);
    }
    _exitSelectionMode();
    _loadTrash();
    Navigator.pop(context, true);
  }

  Future<void> _deletePermanently() async {
    final db = await _dbHelper.db;
    for (var id in _selectedMediaIds) {
      await db.delete('trash', where: 'id = ?', whereArgs: [id]);
    }
    _exitSelectionMode();
    _loadTrash();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedMediaIds.contains(id)) {
        _selectedMediaIds.remove(id);
        if (_selectedMediaIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedMediaIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMediaIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text("${_selectedMediaIds.length} selected")
            : const Text("Trash"),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: _restoreItems,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: _deletePermanently,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                ),
              ]
            : [],
      ),
      body: _trashList.isEmpty
          ? const Center(child: Text("Trash is empty"))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _trashList.length,
              itemBuilder: (context, index) {
                final item = _trashList[index];
                final isSelected = _selectedMediaIds.contains(item['id']);
                return GestureDetector(
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(item['id']);
                    } else {
                      _toggleSelection(item['id']);
                    }
                  },
                  onLongPress: () => _toggleSelection(item['id']),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(item['path']),
                        fit: BoxFit.cover,
                      ),
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
    );
  }
}

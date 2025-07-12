import 'package:flutter/material.dart';
import 'package:thuc_tap/models/note_model.dart';
import 'package:thuc_tap/services/note_service.dart';
import 'package:thuc_tap/screens/audio_player_widget.dart';
import 'package:thuc_tap/screens/delete_note_dialog.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditNotePage extends StatefulWidget {
  final NoteModel note;
  final String token;

  const EditNotePage({super.key, required this.note, required this.token});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  String selectedLabel = '';
  final List<String> availableLabels = ['Học tập', 'Công việc', 'Cá nhân', 'Khác'];
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _newAudioPath;
  late List<MediaFile> _visibleMediaFiles;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();
    selectedLabel = widget.note.tags.isNotEmpty ? widget.note.tags.first : '';

    _visibleMediaFiles = widget.note.mediaFiles.where((m) => !m.isDeleted).toList(); // ✅ danh sách media hiển thị
    _initializeRecorder();
  }


  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final requested = await Permission.microphone.request();
      if (!requested.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Vui lòng cấp quyền microphone')),
        );
        return;
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (!await Permission.microphone.isGranted) {
      await [
        Permission.microphone,
        Permission.audio,
      ].request();
      return;
    }

    if (!_isRecording) {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/note_record_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(
        toFile: filePath,
          codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _newAudioPath = filePath;
      });
    } else {
      await _recorder.stopRecorder();
      setState(() => _isRecording = false);

      if (_newAudioPath != null) {
        final audioFile = File(_newAudioPath!);
        final size = await audioFile.length();

        if (size == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Ghi âm thất bại: Không có dữ liệu')),
          );
          return;
        }

        final uploadResult = await NoteService.uploadAudioFile(
          token: widget.token,
          noteId: widget.note.id,
          filePath: _newAudioPath!,
        );

        if (uploadResult != null) {
          final filePathFromServer = uploadResult['filePath'];
          setState(() {
            widget.note.mediaFiles.add(MediaFile(filePath: filePathFromServer, fileType: 'audio'));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã ghi âm và lưu thành công')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lưu file ghi âm thất bại')),
          );
        }
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      await _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    final uploadResult = await NoteService.uploadImageFile(
      token: widget.token,
      noteId: widget.note.id,
      filePath: imageFile.path,
    );

    if (uploadResult != null) {
      final filePathFromServer = uploadResult['filePath'];
      setState(() {
        final newImage = MediaFile(filePath: filePathFromServer, fileType: 'image', isDeleted: false);
        widget.note.mediaFiles.add(newImage);
        _visibleMediaFiles.add(newImage);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📷 Ảnh đã được tải lên thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lỗi khi tải ảnh lên')),
      );
    }
  }

  Future<void> _updateNote() async {
    final success = await NoteService.updateNote(
      token: widget.token,
      noteId: widget.note.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: selectedLabel.isNotEmpty ? [selectedLabel] : [],
    );
    if (success) Navigator.pop(context, true);
  }

  Future<void> _deleteNote() async {
    final confirm = await DeleteNoteDialog.show(context);
    if (confirm == true) {
      final success = await NoteService.deleteNote(
        token: widget.token,
        noteId: widget.note.id,
      );
      if (success) Navigator.pop(context, true);
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteImage(MediaFile imageFile) async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá ảnh'),
        content: const Text('Bạn có chắc muốn xoá ảnh này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await NoteService.deleteMediaFile(
        token: widget.token,
        filePath: imageFile.filePath,
      );

      if (success) {
        setState(() {
          _visibleMediaFiles.removeWhere((m) => m.filePath == imageFile.filePath);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Ảnh đã được xoá')),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Xoá ảnh thất bại')),
        );
      }
    }
  }

  Future<void> _deleteAudio(MediaFile audioFile) async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá ghi âm'),
        content: const Text('Bạn có chắc muốn xoá file ghi âm này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await NoteService.deleteMediaFile(
        token: widget.token,
        filePath: audioFile.filePath,
      );

      if (success) {
        setState(() {
          _visibleMediaFiles.removeWhere((m) => m.filePath == audioFile.filePath);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Ghi âm đã được xoá')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Xoá ghi âm thất bại')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputContainer(
                      child: TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        decoration: const InputDecoration(hintText: 'Tiêu đề ghi chú...', border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputContainer(
                      child: Row(
                        children: [
                          const Text('Nhãn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _showLabelPicker,
                            child: Row(
                              children: [
                                if (selectedLabel.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(selectedLabel, style: TextStyle(fontSize: 12, color: Colors.green[700])),
                                  ),
                                const SizedBox(width: 8),
                                Icon(Icons.local_offer_outlined, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 4),
                                Text('Chọn nhãn', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputContainer(
                      height: 400,
                      child: TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(hintText: 'Nội dung ghi chú...', border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_visibleMediaFiles.any((file) => file.fileType == 'image'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ảnh đính kèm', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _visibleMediaFiles
                                .where((file) => file.fileType == 'image')
                                .map((imageFile) {
                              final imageUrl = '${NoteService.baseUrl}${imageFile.filePath}';
                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showFullImage(imageUrl),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _deleteImage(imageFile),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  )
                                ],
                              );
                            }).toList(),
                          ),

                        ],
                      ),
                    if (_visibleMediaFiles.any((file) => file.fileType == 'audio'))
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ghi âm đính kèm', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            ..._visibleMediaFiles
                                .where((file) => file.fileType == 'audio')
                                .map((audio) {
                              final audioUrl = '${NoteService.baseUrl}${audio.filePath}';
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8, right: 40),
                                    child: AudioPlayerWidget(audioUrl: audioUrl),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _deleteAudio(audio),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  )
                                ],
                              );
                            }),
                          ],
                        ),
                      )

                  ],
                ),
              ),
            ),
            _buildToolbar()
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(color: Color(0xFF81C784)),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
          const Expanded(
            child: Text('Chỉnh sửa ghi chú', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          IconButton(onPressed: _deleteNote, icon: const Icon(Icons.delete_outline, color: Colors.red)),
          TextButton(
            onPressed: _updateNote,
            child: const Text('Lưu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(Icons.camera_alt_outlined, 'Camera', onTap: _pickImageFromCamera),
          _buildToolbarButton(Icons.upload_outlined, 'Upload', onTap: _pickImageFromGallery),
          _buildToolbarButton(_isRecording ? Icons.stop : Icons.mic_outlined, _isRecording ? 'Stop' : 'Ghi âm', onTap: _toggleRecording),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String tooltip, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _showFeatureDialog(tooltip),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.green[400],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child, double? height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  void _showLabelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chọn nhãn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...availableLabels.map((label) => ListTile(
                title: Text(label),
                onTap: () {
                  setState(() => selectedLabel = label);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(feature),
        content: Text('Tính năng "$feature" sẽ được phát triển trong tương lai.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }
}

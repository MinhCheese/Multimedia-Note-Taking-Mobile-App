import 'package:flutter/material.dart';
import 'package:thuc_tap/services/note_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AddNotePage extends StatefulWidget {
  final String token;

  const AddNotePage({super.key, required this.token});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final List<String> _selectedImagePaths = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String selectedLabel = '';
  List<String> availableLabels = ['Học tập', 'Công việc', 'Cá nhân', 'Khác'];

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _audioPath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _speech = stt.SpeechToText();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    if (!await Permission.microphone.isGranted) {
      await Permission.microphone.request();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (!await Permission.microphone.isGranted) {
      await Permission.microphone.request();
      return;
    }

    if (!_isRecording) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/note_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS,);

      setState(() {
        _isRecording = true;
        _audioPath = path;
      });
    } else {
      await _recorder.stopRecorder();
      setState(() => _isRecording = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImagePaths.add(pickedFile.path);
      });
    }
  }

  void _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
      );
      return;
    }
    if (selectedLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ Vui lòng chọn nhãn cho ghi chú')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    final success = await NoteService.createNote(
      token: widget.token,
      userId: userId,
      title: title,
      content: content,
      tags: selectedLabel.isNotEmpty ? [selectedLabel] : [],
    );

    if (success) {
      final noteId = await NoteService.getLatestNoteId(userId, widget.token);
      if (noteId != null) {
        // ✅ Upload audio nếu có
        if (_audioPath != null) {
          await NoteService.uploadAudioFile(
            token: widget.token,
            noteId: noteId,
            filePath: _audioPath!,
          );
        }

        // ✅ Upload tất cả ảnh nếu có
        for (String imagePath in _selectedImagePaths) {
          await NoteService.uploadImageFile(
            token: widget.token,
            noteId: noteId,
            filePath: imagePath,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📒 Ghi chú đã được lưu')),
        );
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lưu ghi chú thất bại')),
      );
    }
  }

  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteImage(String path) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá ảnh'),
        content: Image.file(File(path)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _selectedImagePaths.remove(path);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Đã xoá ảnh')),
      );
    }
  }


  void _showLabelPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableLabels.map((label) {
            return ListTile(
              title: Text(label),
              onTap: () {
                setState(() => selectedLabel = label);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  Future<void> _confirmDeleteAudio() async {
    final confirm = await showDialog(
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

    if (confirm == true) {
      final file = File(_audioPath!);
      if (await file.exists()) await file.delete();

      setState(() => _audioPath = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Đã xoá ghi âm')),
      );
    }
  }


  Widget _buildToolbarButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.green[400],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('🟡 onStatus: $val'),
      onError: (val) => print('🔴 onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          if (val.hasConfidenceRating && val.confidence > 0 && val.finalResult) {
            setState(() {
              _contentController.text += ' ${val.recognizedWords}';
            });
          }
        },
        localeId: 'vi_VN',
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF81C784),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Tạo ghi chú mới',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: _saveNote,
                    child: const Text('Lưu', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
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
                                    child: Text(selectedLabel),
                                  ),
                                const SizedBox(width: 8),
                                Icon(Icons.local_offer_outlined, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text('Chọn nhãn', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputContainer(
                      height: 300,
                      child: TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Nội dung ghi chú...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImagePaths.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedImagePaths.map((path) {
                          return Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showFullImage(path),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(path),
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
                                  onTap: () => _confirmDeleteImage(path),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    if (_audioPath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ghi âm đính kèm', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.audiotrack, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _audioPath!.split('/').last,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _confirmDeleteAudio(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                  ],
                ),
              ),
            ),

            // Bottom Toolbar
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToolbarButton(
                    icon: Icons.camera_alt_outlined,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildToolbarButton(
                    icon: Icons.photo_outlined,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  _buildToolbarButton(
                    icon: _isRecording ? Icons.stop : Icons.mic_outlined,
                    onTap: _toggleRecording,
                  ),
                  _buildToolbarButton(
                    icon: _isListening ? Icons.hearing_disabled : Icons.hearing,
                    onTap: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: child,
    );
  }
}

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
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path/path.dart' as path;
import 'package:thuc_tap/services/media_service.dart';
import 'package:intl/intl.dart';
import 'package:thuc_tap/services/notification_service.dart';

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

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastRecognized = '';
  DateTime? _reminderTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _reminderTime = widget.note.reminderAt;
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();
    selectedLabel = widget.note.tags.isNotEmpty ? widget.note.tags.first : '';

    _visibleMediaFiles = widget.note.mediaFiles.where((m) => !m.isDeleted).toList();
    _initializeRecorder();
    _speech = stt.SpeechToText();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _reminderTime ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(minutes: 1)),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;

    setState(() {
      _reminderTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final requested = await Permission.microphone.request();
      if (!requested.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Vui lòng cấp quyền microphone')),
          );
        }
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
      final fileName = await _askFileName();
      if (fileName == null || fileName.trim().isEmpty) return;

      final sanitizedFileName = fileName.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = path.join(dir.path, '$sanitizedFileName.aac');

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

        final displayName = path.basenameWithoutExtension(_newAudioPath!);

        final uploadResult = await NoteService.uploadAudioFile(
          token: widget.token,
          noteId: widget.note.id,
          filePath: _newAudioPath!,
          displayName: displayName,
        );

        if (uploadResult != null) {
          final filePathFromServer = uploadResult['filePath'];
          setState(() {
            widget.note.mediaFiles.add(MediaFile(
              filePath: filePathFromServer,
              fileType: 'audio',
              displayName: displayName,
            ));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎙️ Ghi âm và lưu thành công')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Lưu file ghi âm thất bại')),
          );
        }
      }
    }
  }

  // ========================================================
  // PHẦN CHỈ TẢI ẢNH (Không dính dáng tới OCR nữa)
  // ========================================================
  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      await _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      await _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final uploadResult = await NoteService.uploadImageFile(
      token: widget.token,
      noteId: widget.note.id,
      filePath: imageFile.path,
    );

    if (mounted) Navigator.pop(context); // Tắt loading

    if (uploadResult != null) {
      final filePathFromServer = uploadResult['filePath'];
      setState(() {
        final newImage = MediaFile(filePath: filePathFromServer, fileType: 'image', isDeleted: false);
        widget.note.mediaFiles.add(newImage);
        _visibleMediaFiles.add(newImage);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📷 Ảnh đính kèm đã được lưu')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lỗi khi tải ảnh lên')),
      );
    }
  }

  // ========================================================
  // PHẦN NÚT OCR CHUYÊN DỤNG MỚI
  // ========================================================
  Future<void> _performOCR() async {
    // 1. Cho người dùng chọn chụp mới hay lấy từ thư viện
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn nguồn ảnh'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Máy ảnh'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Thư viện'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;

    // 2. Gửi cho Python AI đọc
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 15),
            Text(
                "AI đang quét văn bản...",
                style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 14)
            ),
          ],
        ),
      ),
    );

    final recognizedText = await NoteService.predictHandwriting(pickedFile.path);

    if (mounted) Navigator.pop(context); // Tắt loading AI

    if (recognizedText != null && recognizedText.trim().isNotEmpty) {
      setState(() {
        // Chèn vào chỗ con trỏ đang đứng hoặc nối vào cuối
        _contentController.text += "\n\n$recognizedText";
        _contentController.selection = TextSelection.fromPosition(TextPosition(offset: _contentController.text.length));
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã quét và chèn chữ thành công!')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ AI không tìm thấy chữ trong ảnh.')));
      }
    }
  }

  // ========================================================

  Future<void> _updateNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await NoteService.updateNote(
      token: widget.token,
      noteId: widget.note.id,
      title: title,
      content: content,
      tags: selectedLabel.isNotEmpty ? [selectedLabel] : [],
      reminderAt: _reminderTime,
    );

    if (mounted) Navigator.pop(context);

    if (success) {
      try {
        final notificationId = widget.note.id.hashCode;

        if (_reminderTime != null) {
          await NotificationService.scheduleNotification(
            id: notificationId,
            title: title.isEmpty ? 'Nhắc nhở' : title,
            body: content.isNotEmpty ? content : 'Đến giờ hẹn cho ghi chú này!',
            scheduledTime: _reminderTime!,
          );
        } else {
          await NotificationService.cancelNotification(notificationId);
        }
      } catch (e) {
        print("Lỗi cập nhật thông báo: $e");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã cập nhật ghi chú')));
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Cập nhật thất bại')));
      }
    }
  }

  Future<void> _deleteNote() async {
    final confirm = await DeleteNoteDialog.show(context);
    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await NoteService.deleteNote(
      token: widget.token,
      noteId: widget.note.id,
    );

    if (mounted) Navigator.pop(context);

    if (success) {
      try {
        await NotificationService.cancelNotification(widget.note.id.hashCode);
      } catch (e) {
        print("Lỗi hủy thông báo: $e");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Đã xoá ghi chú')));
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Xoá thất bại')));
      }
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
          widget.note.mediaFiles.removeWhere((m) => m.filePath == imageFile.filePath);
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

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          if (val.finalResult && val.recognizedWords != _lastRecognized) {
            setState(() {
              _lastRecognized = val.recognizedWords;
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

  Future<String?> _askFileName() async {
    String? fileName;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Đặt tên cho file ghi âm'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Tên file...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
            TextButton(
              onPressed: () {
                fileName = controller.text.trim();
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return fileName;
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
                    if (_reminderTime != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.alarm, color: Colors.deepOrange, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hạn chót: ${DateFormat('HH:mm - dd/MM/yyyy').format(_reminderTime!)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getRemainingTime(_reminderTime!),
                                    style: TextStyle(
                                        color: _reminderTime!.isBefore(DateTime.now()) ? Colors.red : Colors.green,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _reminderTime = null;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // NÚT OCR "MỜ" NẰM TRÊN KHUNG NỘI DUNG
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _performOCR,
                        icon: const Icon(Icons.document_scanner_outlined, color: Colors.black54, size: 18),
                        label: const Text('Quét chữ từ ảnh', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

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
                                    margin: const EdgeInsets.only(bottom: 12, right: 40),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if ((audio.displayName ?? '').trim().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    audio.displayName!,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        AudioPlayerWidget(audioUrl: audioUrl),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _deleteAudio(audio),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
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
          _buildToolbarButton(
              Icons.alarm,
              'Đặt lịch',
              onTap: _pickDateTime
          ),
          _buildToolbarButton(Icons.camera_alt_outlined, 'Camera', onTap: _pickImageFromCamera),
          _buildToolbarButton(Icons.upload_outlined, 'Upload', onTap: _pickImageFromGallery),
          _buildToolbarButton(_isRecording ? Icons.stop : Icons.mic_outlined, _isRecording ? 'Stop' : 'Ghi âm', onTap: _toggleRecording),
          _buildToolbarButton(
            _isListening ? Icons.hearing_disabled : Icons.hearing,
            _isListening ? 'Dừng' : 'Nói',
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

  String _getRemainingTime(DateTime target) {
    final now = DateTime.now();
    final difference = target.difference(now);

    if (difference.isNegative) {
      return 'Đã quá hạn';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return 'Còn $days ngày $hours giờ nữa';
    } else if (hours > 0) {
      return 'Còn $hours giờ $minutes phút nữa';
    } else {
      return 'Còn $minutes phút nữa';
    }
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
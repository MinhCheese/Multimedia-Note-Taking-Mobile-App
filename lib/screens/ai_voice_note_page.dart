import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:thuc_tap/services/note_service.dart';
import 'package:thuc_tap/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AIVoiceNotePage extends StatefulWidget {
  final String token;

  const AIVoiceNotePage({super.key, required this.token});

  @override
  State<AIVoiceNotePage> createState() => _AIVoiceNotePageState();
}

class _AIVoiceNotePageState extends State<AIVoiceNotePage>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  String _inputText = "";

  bool _isProcessingAI = false;
  Map<String, dynamic>? _parsedData;

  late AnimationController _animationController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ========================================================
  // TAB 1: LOGIC GIỌNG NÓI
  // ========================================================
  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _inputText = "Đang nghe...";
          _parsedData = null;
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _inputText = val.recognizedWords;
            });
          },
          localeId: 'vi_VN',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();

      if (_inputText.isNotEmpty && _inputText != "Đang nghe...") {
        _processAI(_inputText);
      }
    }
  }

  // ========================================================
  // TAB 2: LOGIC OCR (Truyền thẳng Camera hoặc Gallery)
  // ========================================================
  Future<void> _performOCR(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() {
      _isProcessingAI = true;
      _parsedData = null;
    });

    try {
      final recognizedText = await NoteService.predictHandwriting(pickedFile.path);

      if (recognizedText != null && recognizedText.trim().isNotEmpty) {
        // Ảnh đọc xong đẩy thẳng vào AI xử lý
        await _processAI(recognizedText);
      } else {
        _showError('AI không tìm thấy văn bản trong ảnh.');
        setState(() => _isProcessingAI = false);
      }
    } catch (e) {
      _showError('Lỗi quét ảnh: $e');
      setState(() => _isProcessingAI = false);
    }
  }

  // ========================================================
  // BƯỚC CHUNG: GỌI SERVER PYTHON PHÂN TÍCH
  // ========================================================
  Future<void> _processAI(String text) async {
    setState(() => _isProcessingAI = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.29:5000/parse-voice-note'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({"text": text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          setState(() {
            _parsedData = data['parsed_data'];
          });
        } else {
          _showError('AI không thể xử lý dữ liệu này.');
        }
      } else {
        _showError('Không thể kết nối đến Server AI.');
      }
    } catch (e) {
      _showError('Lỗi hệ thống: $e');
    } finally {
      setState(() => _isProcessingAI = false);
    }
  }

  // ========================================================
  // BƯỚC CHUNG: LƯU GHI CHÚ
  // ========================================================
  Future<void> _saveNote() async {
    if (_parsedData == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      DateTime? reminder;
      if (_parsedData!['reminderAt'] != null) {
        reminder = DateTime.parse(_parsedData!['reminderAt']);
      }

      final success = await NoteService.createNote(
        token: widget.token,
        userId: userId!,
        title: _parsedData!['title'],
        content: _parsedData!['content'],
        tags: _parsedData!['tags'] != null && _parsedData!['tags'].isNotEmpty
            ? [_parsedData!['tags'][0]]
            : ['Khác'],
        reminderAt: reminder,
      );

      if (mounted) Navigator.pop(context);

      if (success) {
        if (reminder != null) {
          final noteId = await NoteService.getLatestNoteId(userId, widget.token);
          if (noteId != null) {
            await NotificationService.scheduleNotification(
              id: noteId.toString().hashCode,
              title: _parsedData!['title'],
              body: _parsedData!['content'],
              scheduledTime: reminder,
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✨ Ghi chú AI đã được tạo thành công!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        _showError('Lưu ghi chú thất bại.');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError('Lỗi khi lưu: $e');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ========================================================
  // GIAO DIỆN CHÍNH (SỬ DỤNG TAB)
  // ========================================================
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Số lượng Tab
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F8F1),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          title: const Text(
            'Trợ lý AI',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(icon: Icon(Icons.mic), text: 'Giọng nói'),
              Tab(icon: Icon(Icons.document_scanner), text: 'Quét ảnh'),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // NỬA TRÊN: KHU VỰC NHẬP LIỆU THEO TAB (Cố định chiều cao)
                SizedBox(
                  height: 250,
                  child: TabBarView(
                    children: [
                      _buildVoiceTab(), // Giao diện Tab 1
                      _buildOCRTab(),   // Giao diện Tab 2
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // NỬA DƯỚI: KHU VỰC HIỂN THỊ KẾT QUẢ CHUNG
                Expanded(
                  child: _isProcessingAI
                      ? _buildLoadingState()
                      : (_parsedData != null
                      ? _buildResultCard()
                      : const SizedBox.shrink()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // CÁC WIDGET PHỤ TRỢ (UI của từng Tab)
  // ========================================================

  // Giao diện Tab 1: Giọng nói
  Widget _buildVoiceTab() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Ví dụ: "Chiều mai 5 rưỡi đi đá banh"',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 25),
        GestureDetector(
          onTap: _listen,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.redAccent.withOpacity(0.7 + (_animationController.value * 0.3))
                      : const Color(0xFF4CAF50),
                  boxShadow: [
                    if (_isListening)
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.5),
                        blurRadius: 25 * _animationController.value,
                        spreadRadius: 15 * _animationController.value,
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              );
            },
          ),
        ),
        const Spacer(),
        _buildInputTextBox(), // Hiển thị chữ đang nói
      ],
    );
  }

  // Giao diện Tab 2: Quét Ảnh OCR (Đã bỏ khung text và căn giữa hoàn hảo)
  Widget _buildOCRTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ép nội dung co lại để nằm giữa Tab
        children: [
          const Text(
            'Chụp ảnh đoạn văn bản để AI phân tích',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOCRButton(
                icon: Icons.camera_alt,
                label: 'Chụp ảnh',
                color: Colors.green.shade600,
                onTap: () => _performOCR(ImageSource.camera),
              ),
              const SizedBox(width: 20),
              _buildOCRButton(
                icon: Icons.photo_library,
                label: 'Thư viện',
                color: Colors.blue.shade600,
                onTap: () => _performOCR(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Nút bấm cho Tab OCR
  Widget _buildOCRButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // Khung hiển thị text dùng cho Giọng nói
  Widget _buildInputTextBox() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 50, maxHeight: 80),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: SingleChildScrollView(
        child: Center(
          child: Text(
            _inputText.isEmpty ? "..." : _inputText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontStyle: _inputText == "Đang nghe..."
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: _inputText == "Đang nghe..."
                  ? Colors.grey
                  : Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  // Hiệu ứng Loading
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.orange, strokeWidth: 4),
          SizedBox(height: 16),
          Text(
            'AI đang phân tích dữ liệu...',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Thẻ (Card) Kết quả
  Widget _buildResultCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome, color: Colors.orange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Dữ liệu trích xuất',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          _parsedData!['tags']?[0] ?? 'Khác',
                          style: TextStyle(color: Colors.green.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      )
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                  ),
                  _buildPreviewRow(Icons.title_rounded, 'Tiêu đề', _parsedData!['title']),
                  const SizedBox(height: 20),
                  if (_parsedData!['reminderAt'] != null) ...[
                    _buildPreviewRow(
                        Icons.alarm_rounded,
                        'Giờ hẹn',
                        DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.parse(_parsedData!['reminderAt']))),
                    const SizedBox(height: 20),
                  ],
                  _buildPreviewRow(Icons.subject_rounded, 'Nội dung', _parsedData!['content']),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade500,
              elevation: 4,
              shadowColor: Colors.orange.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _saveNote,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Xác nhận & Lưu Ghi Chú',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.grey.shade600),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
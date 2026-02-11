import 'package:flutter/material.dart';
import 'package:thuc_tap/models/note_model.dart';
import 'package:thuc_tap/screens/file_manegers_page.dart';
import 'package:thuc_tap/screens/setting_page.dart';
import 'package:thuc_tap/services/note_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thuc_tap/screens/add_note_page.dart';
import 'package:thuc_tap/screens/edit_note_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = 'Tất cả';
  List<NoteModel> notes = [];
  bool isLoading = true;


  final List<String> filters = ['Tất cả', 'Sắp tới', 'Học tập', 'Công việc', 'Cá nhân', 'Khác'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final fetchedNotes = await NoteService.fetchNotesByUser(userId);

      // Sắp xếp: Ưu tiên ghi chú có lịch hẹn lên đầu
      fetchedNotes.sort((a, b) {
        if (a.reminderAt != null && b.reminderAt != null) {
          return a.reminderAt!.compareTo(b.reminderAt!);
        } else if (a.reminderAt != null) {
          return -1; // a có lịch, a lên đầu
        } else if (b.reminderAt != null) {
          return 1; // b có lịch, b lên đầu
        }
        return b.createdAt.compareTo(a.createdAt); // Còn lại sắp xếp theo ngày tạo mới nhất
      });

      setState(() {
        notes = fetchedNotes;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print(' Lỗi khi load ghi chú: $e');
    }
  }


  List<NoteModel> get _filteredNotes {
    final keyword = _searchController.text.trim().toLowerCase();

    return notes.where((note) {

      final matchesKeyword = keyword.isEmpty ||
          note.title.toLowerCase().contains(keyword) ||
          note.content.toLowerCase().contains(keyword);


      bool matchesFilter = false;
      if (selectedFilter == 'Tất cả') {
        matchesFilter = true;
      } else if (selectedFilter == 'Sắp tới') {

        matchesFilter = note.reminderAt != null;
      } else {

        matchesFilter = note.tags.contains(selectedFilter);
      }

      return matchesKeyword && matchesFilter;
    }).toList();
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

    if (days > 0) return 'Còn $days ngày nữa';
    if (hours > 0) return 'Còn $hours giờ nữa';
    return 'Còn $minutes phút';
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
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(color: Color(0xFF81C784)),
              child: Row(
                children: [
                  const Text('Notes App', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context)=>FileManagerPage()));},
                    icon: const Icon(Icons.folder_outlined, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context)=>const SettingPage()));},
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle, color: Colors.white)),
                ],
              ),
            ),

            // Search & Filter
            Container(
              color: const Color(0xFFE8F5E8),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Tags (Sắp tới giờ nằm trong này)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        final isSelected = filter == selectedFilter;

                        // Tùy chỉnh màu sắc đặc biệt cho chip "Sắp tới" nếu muốn
                        final isSpecial = filter == 'Sắp tới';

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSpecial) ...[
                                  Icon(Icons.access_time_filled, size: 16, color: isSelected ? Colors.white : Colors.orange),
                                  const SizedBox(width: 4),
                                ],
                                Text(filter, style: TextStyle(color: isSelected ? Colors.white : (isSpecial ? Colors.orange[800] : Colors.green[700]), fontSize: 12)),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) => setState(() => selectedFilter = filter),
                            backgroundColor: Colors.white,
                            selectedColor: isSpecial ? Colors.orange[400] : Colors.green[400], // Màu cam cho "Sắp tới", Xanh cho cái khác
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                                color: isSpecial ? Colors.orange[300]! : Colors.green[300]!,
                                width: 1
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content List (Không còn TabBarView)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildNoteList(_filteredNotes),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            final shouldRefresh = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddNotePage(token: token)),
            );
            if (shouldRefresh == true) {
              setState(() => isLoading = true);
              await loadNotes();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập lại')));
          }
        },
        backgroundColor: Colors.green[400],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoteList(List<NoteModel> notesSource) {
    if (notesSource.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text('Không tìm thấy ghi chú nào', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notesSource.length,
      itemBuilder: (context, index) {
        final note = notesSource[index];
        final hasReminder = note.reminderAt != null;
        final isExpired = hasReminder && note.reminderAt!.isBefore(DateTime.now());

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');
              if (token != null) {
                final shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditNotePage(note: note, token: token)),
                );
                if (shouldRefresh == true) {
                  setState(() => isLoading = true);
                  await loadNotes();
                }
              }
            },
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8E6B8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hiển thị khung đếm ngược
                      if (hasReminder)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isExpired ? Colors.red[100] : Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isExpired ? Colors.red : Colors.orange),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.alarm, size: 14, color: isExpired ? Colors.red : Colors.deepOrange),
                              const SizedBox(width: 6),
                              Text(
                                _getRemainingTime(note.reminderAt!),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isExpired ? Colors.red : Colors.deepOrange
                                ),
                              ),
                            ],
                          ),
                        ),

                      Text(
                        note.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          note.tags.isNotEmpty ? note.tags.first : 'Chung',
                          style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                // Icons
                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    children: [
                      if (note.mediaFiles.any((file) => file.fileType == 'image'))
                        const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.image, size: 18, color: Colors.black54)),
                      if (note.mediaFiles.any((file) => file.fileType == 'audio'))
                        const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.mic, size: 18, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:thuc_tap/models/note_model.dart';
import 'package:thuc_tap/screens/file_manegers_page.dart';
import 'package:thuc_tap/screens/setting_page.dart';
import 'package:thuc_tap/services/note_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thuc_tap/screens/add_note_page.dart';
import 'package:thuc_tap/screens/edit_note_page.dart';
import 'package:thuc_tap/screens/setting_page.dart';
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

  final List<String> filters = ['Tất cả', 'Học tập', 'Công việc', 'Cá nhân', 'Khác'];

  final Map<String, String> categoryDisplay = {
    'Tất cả': 'all',
    'Học tập': 'study',
    'Công việc': 'work',
    'Cá nhân': 'personal',
    'Khác': 'other',
  };

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
        throw Exception('User chưa đăng nhập!');
      }

      final fetchedNotes = await NoteService.fetchNotesByUser(userId);

      print('✅ Số ghi chú tải về: ${fetchedNotes.length}');

      setState(() {
        notes = fetchedNotes;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Lỗi khi load ghi chú: $e');
    }
  }



  List<NoteModel> get filteredNotes {
    final keyword = _searchController.text.trim().toLowerCase();

    return notes.where((note) {
      // Kiểm tra từ khoá: nếu từ khoá rỗng thì cho pass, ngược lại phải chứa trong title hoặc content
      final matchesKeyword = keyword.isEmpty ||
          note.title.toLowerCase().contains(keyword) ||
          note.content.toLowerCase().contains(keyword);

      // Kiểm tra tag: nếu filter là 'Tất cả' thì cho tất cả pass, nếu không thì phải có tag đó
      final matchesTag = selectedFilter == 'Tất cả' ||
          note.tags.contains(selectedFilter);

      return matchesKeyword && matchesTag;
    }).toList();
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
              decoration: const BoxDecoration(
                color: Color(0xFF81C784),
              ),
              child: Row(
                children: [
                  const Text(
                    'Notes App',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context)=>FileManagerPage()));},
                    icon: const Icon(Icons.folder_outlined, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context)=>const SettingPage()));},
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.account_circle, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm ghi chú...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filter Tags
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filters.length,
                        itemBuilder: (context, index) {
                          final filter = filters[index];
                          final isSelected = filter == selectedFilter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.green[700],
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  selectedFilter = filter;
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: Colors.green[400],
                              checkmarkColor: Colors.white,
                              side: BorderSide(
                                color: Colors.green[300]!,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes List
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                          child: GestureDetector(
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final token = prefs.getString('token');

                              if (token != null) {
                                final shouldRefresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditNotePage(note: note, token: token),
                                  ),
                                );

                                if (shouldRefresh == true) {
                                  setState(() => isLoading = true);
                                  await loadNotes();


                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã xoá ghi chú')),
                                  );
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
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        note.content,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          note.tags.isNotEmpty ? note.tags.first : '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Icon nằm ở góc trên phải
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (note.content.trim().isNotEmpty)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(Icons.description, size: 18, color: Colors.black54),
                                        ),
                                      if (note.mediaFiles.any((file) => file.fileType == 'image'))
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(Icons.image, size: 18, color: Colors.black54),
                                        ),
                                      if (note.mediaFiles.any((file) => file.fileType == 'audio'))
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(Icons.mic, size: 18, color: Colors.black54),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                          ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
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
              MaterialPageRoute(
                builder: (context) => AddNotePage(token: token),
              ),
            );

            if (shouldRefresh == true) {
              setState(() {
                isLoading = true;
              });
              await loadNotes(); 
            }

          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy token, vui lòng đăng nhập lại')),
            );
          }
        },
        backgroundColor: Colors.green[400],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }



  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

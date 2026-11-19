import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabiyyah_shared/arabiyyah_shared.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ArabiyyahSiswaApp());
}

class ArabiyyahSiswaApp extends StatefulWidget {
  const ArabiyyahSiswaApp({super.key});

  @override
  State<ArabiyyahSiswaApp> createState() => _ArabiyyahSiswaAppState();
}

class _ArabiyyahSiswaAppState extends State<ArabiyyahSiswaApp> {
  String? _studentEmail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentEmail = prefs.getString('student_email');
      _loading = false;
    });
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_email', email.trim());
    setState(() => _studentEmail = email.trim());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arabiyyah Siswa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_studentEmail == null || _studentEmail!.isEmpty)
              ? StudentLoginScreen(onSubmitted: _saveEmail)
              : StudentLessonsScreen(studentEmail: _studentEmail!),
    );
  }
}

class StudentLoginScreen extends StatefulWidget {
  final Future<void> Function(String email) onSubmitted;
  const StudentLoginScreen({super.key, required this.onSubmitted});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masuk Arabiyyah Siswa')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Masukkan email Anda untuk memulai belajar bahasa Arab',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Alamat Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_emailCtrl.text.trim().contains('@')) {
                  widget.onSubmitted(_emailCtrl.text.trim());
                }
              },
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentLessonsScreen extends StatefulWidget {
  final String studentEmail;
  const StudentLessonsScreen({super.key, required this.studentEmail});

  @override
  State<StudentLessonsScreen> createState() => _StudentLessonsScreenState();
}

class _StudentLessonsScreenState extends State<StudentLessonsScreen> {
  final LessonRepository _repo = LessonRepository();
  List<LessonModel> _cached = [];

  @override
  void initState() {
    super.initState();
    _repo.getCachedLessons().then((c) {
      if (mounted && c.isNotEmpty) setState(() => _cached = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arabiyyah Siswa')),
      body: StreamBuilder<List<LessonModel>>(
        stream: _repo.watchPublishedLessons(),
        builder: (context, snapshot) {
          final lessons = snapshot.data ?? _cached;
          if (lessons.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (lessons.isEmpty) {
            return const Center(child: Text('Belum ada materi yang dipublikasikan.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '\${lesson.type == LessonType.conversation ? "Percakapan A/B" : "Materi Standar"} • \${lesson.items.length} item',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LessonDetailScreen(
                        lesson: lesson,
                        studentEmail: widget.studentEmail,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LessonDetailScreen extends StatefulWidget {
  final LessonModel lesson;
  final String studentEmail;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.studentEmail,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final AudioPlaybackService _audio = AudioPlaybackService();
  final Set<String> _completedIds = {};
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _audio.init();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('progress_\${widget.studentEmail}_\${widget.lesson.id}') ?? [];
    if (mounted) setState(() => _completedIds.addAll(saved));
  }

  Future<void> _toggleComplete(String itemId) async {
    setState(() {
      if (_completedIds.contains(itemId)) {
        _completedIds.remove(itemId);
      } else {
        _completedIds.add(itemId);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'progress_\${widget.studentEmail}_\${widget.lesson.id}',
      _completedIds.toList(),
    );
  }

  @override
  void dispose() {
    _audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.lesson.items;
    final doneCount = items.where((e) => _completedIds.contains(e.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        actions: [
          IconButton(
            tooltip: 'Mode Pelan 0.7x',
            icon: Icon(
              Icons.slow_motion_video,
              color: _audio.isSlowMode ? Colors.amberAccent : Colors.white,
            ),
            onPressed: () async {
              await _audio.setSlowMode(!_audio.isSlowMode);
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.emeraldContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progres: \$doneCount / \${items.length} selesai'),
                FilledButton.icon(
                  onPressed: items.isEmpty
                      ? null
                      : () => _audio.playAll(
                            items
                                .map((e) => (arabicText: e.arabic, audioUrl: e.audioUrl))
                                .toList(),
                            onIndexChanged: (idx) {
                              if (mounted) setState(() => _activeIndex = idx);
                            },
                          ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Putar Semua'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isDone = _completedIds.contains(item.id);
                final isActive = _activeIndex == index;
                final isSpeakerB = widget.lesson.type == LessonType.conversation && item.speaker == 'B';

                return Align(
                  alignment: widget.lesson.type == LessonType.conversation
                      ? (isSpeakerB ? Alignment.centerRight : Alignment.centerLeft)
                      : Alignment.center,
                  child: Card(
                    color: isActive ? AppTheme.emeraldContainer : Colors.white,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.lesson.type == LessonType.conversation && item.speaker.isNotEmpty)
                            Text(
                              'Pembicara \${item.speaker}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Image.network(item.imageUrl!, height: 150, fit: BoxFit.cover),
                            ),
                          Text(
                            item.arabic,
                            textDirection: TextDirection.rtl,
                            style: AppTheme.arabicTextStyle(),
                          ),
                          Text(item.transliteration, style: AppTheme.transliterationStyle()),
                          if (item.meaning.isNotEmpty) Text(item.meaning),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'Putar Audio',
                                icon: const Icon(Icons.volume_up),
                                onPressed: () => _audio.playItem(
                                  arabicText: item.arabic,
                                  audioUrl: item.audioUrl,
                                ),
                              ),
                              Checkbox(
                                value: isDone,
                                onChanged: (_) => _toggleComplete(item.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

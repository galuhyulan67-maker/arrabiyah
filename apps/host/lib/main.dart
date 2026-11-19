import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:arabiyyah_shared/arabiyyah_shared.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ArabiyyahHostApp());
}

class ArabiyyahHostApp extends StatelessWidget {
  const ArabiyyahHostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arabiyyah Host',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HostLessonsScreen(),
    );
  }
}

class HostLessonsScreen extends StatefulWidget {
  const HostLessonsScreen({super.key});

  @override
  State<HostLessonsScreen> createState() => _HostLessonsScreenState();
}

class _HostLessonsScreenState extends State<HostLessonsScreen> {
  final LessonRepository _repo = LessonRepository();
  final AudioPlaybackService _audio = AudioPlaybackService();

  @override
  void initState() {
    super.initState();
    _audio.init();
  }

  void _openLessonEditor({LessonModel? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    LessonType selectedType = existing?.type ?? LessonType.standard;
    final List<LessonItem> items = List<LessonItem>.from(existing?.items ?? []);

    final speakerCtrl = TextEditingController(text: 'A');
    final arabicCtrl = TextEditingController();
    final transCtrl = TextEditingController();
    final meaningCtrl = TextEditingController();
    final audioUrlCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Buat Materi Baru' : 'Edit Materi',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Judul Materi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LessonType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipe Materi', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: LessonType.standard, child: Text('Materi Standar')),
                    DropdownMenuItem(value: LessonType.conversation, child: Text('Percakapan A/B')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedType = v);
                  },
                ),
                const Divider(height: 24),
                const Text('Tambah Butir Teks / Dialog', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (selectedType == LessonType.conversation)
                  DropdownButtonFormField<String>(
                    value: speakerCtrl.text == 'B' ? 'B' : 'A',
                    decoration: const InputDecoration(labelText: 'Pembicara', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('Pembicara A')),
                      DropdownMenuItem(value: 'B', child: Text('Pembicara B')),
                    ],
                    onChanged: (v) => speakerCtrl.text = v ?? 'A',
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: arabicCtrl,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabicTextStyle(fontSize: 22),
                  decoration: const InputDecoration(labelText: 'Teks Arab Berharakat', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: transCtrl,
                  decoration: const InputDecoration(labelText: 'Transliterasi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: meaningCtrl,
                  decoration: const InputDecoration(labelText: 'Arti / Terjemahan', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: imageUrlCtrl,
                  decoration: const InputDecoration(labelText: 'URL Gambar (opsional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: audioUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL Audio (kosongkan untuk TTS ar-SA)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    if (arabicCtrl.text.trim().isEmpty) return;
                    setModalState(() {
                      items.add(LessonItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        speaker: selectedType == LessonType.conversation ? speakerCtrl.text : '',
                        arabic: arabicCtrl.text.trim(),
                        transliteration: transCtrl.text.trim(),
                        meaning: meaningCtrl.text.trim(),
                        imageUrl: imageUrlCtrl.text.trim().isEmpty ? null : imageUrlCtrl.text.trim(),
                        audioUrl: audioUrlCtrl.text.trim().isEmpty ? null : audioUrlCtrl.text.trim(),
                      ));
                      arabicCtrl.clear();
                      transCtrl.clear();
                      meaningCtrl.clear();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text('Tambahkan ke Daftar (\${items.length} item)'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final model = LessonModel(
                      id: existing?.id ?? '',
                      title: titleCtrl.text.trim(),
                      type: selectedType,
                      isPublished: existing?.isPublished ?? false,
                      items: items,
                      updatedAt: DateTime.now(),
                    );
                    await _repo.saveLesson(model);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Simpan Materi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arabiyyah Host')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLessonEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Materi'),
      ),
      body: StreamBuilder<List<LessonModel>>(
        stream: _repo.watchAllLessons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lessons = snapshot.data ?? [];
          if (lessons.isEmpty) {
            return const Center(child: Text('Belum ada materi. Tekan + Materi untuk membuat.'));
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
                    '\${lesson.type == LessonType.conversation ? "Percakapan A/B" : "Standar"} • \${lesson.items.length} item • \${lesson.isPublished ? "Published" : "Draft"}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: lesson.isPublished ? 'Unpublish' : 'Publish',
                        icon: Icon(
                          lesson.isPublished ? Icons.visibility : Icons.visibility_off,
                          color: lesson.isPublished ? AppTheme.emeraldPrimary : Colors.grey,
                        ),
                        onPressed: () => _repo.setPublished(lesson.id, !lesson.isPublished),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openLessonEditor(existing: lesson),
                      ),
                      IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _repo.deleteLesson(lesson.id),
                      ),
                    ],
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

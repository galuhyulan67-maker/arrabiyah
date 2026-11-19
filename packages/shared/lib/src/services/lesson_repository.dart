import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_model.dart';

class LessonRepository {
  static const String collectionName = 'lessons';
  static const String _cacheKey = 'cached_published_lessons_v1';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  LessonRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Stream<List<LessonModel>> watchAllLessons() {
    return _firestore
        .collection(collectionName)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LessonModel.fromDoc(d.id, d.data())).toList());
  }

  Stream<List<LessonModel>> watchPublishedLessons() {
    return _firestore
        .collection(collectionName)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => LessonModel.fromDoc(d.id, d.data())).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      cacheLessons(list);
      return list;
    });
  }

  Future<void> cacheLessons(List<LessonModel> lessons) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(lessons.map((e) => {'id': e.id, ...e.toMap()}).toList());
    await prefs.setString(_cacheKey, encoded);
  }

  Future<List<LessonModel>> getCachedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((m) => LessonModel.fromDoc(m['id']?.toString() ?? '', Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> saveLesson(LessonModel lesson) async {
    final docRef = lesson.id.isEmpty
        ? _firestore.collection(collectionName).doc()
        : _firestore.collection(collectionName).doc(lesson.id);
    await docRef.set(lesson.toMap(), SetOptions(merge: true));
  }

  Future<void> setPublished(String lessonId, bool isPublished) async {
    await _firestore.collection(collectionName).doc(lessonId).update({
      'isPublished': isPublished,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteLesson(String lessonId) async {
    await _firestore.collection(collectionName).doc(lessonId).delete();
  }

  Future<String> uploadLessonImage(File file, String fileName) async {
    final ref = _storage.ref().child('lesson_images/$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadLessonAudio(File file, String fileName) async {
    final ref = _storage.ref().child('lesson_audio/$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}

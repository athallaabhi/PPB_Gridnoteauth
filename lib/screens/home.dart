import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore.dart';
import 'login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final titleTextController = TextEditingController();
  final contentTextController = TextEditingController();
  final tglTextController = TextEditingController();
  final labelTextController = TextEditingController();
  DateTime? selectedTgl;

  final FirestoreService firestoreService = FirestoreService();

  @override
  void dispose() {
    titleTextController.dispose();
    contentTextController.dispose();
    tglTextController.dispose();
    labelTextController.dispose();
    super.dispose();
  }

  void logout(context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void openNoteBox({
    String? docId,
    String? existingTitle,
    String? existingContent,
    DateTime? existingTgl,
    String? existingLabel,
  }) async {
    if (docId != null) {
      titleTextController.text = existingTitle ?? '';
      contentTextController.text = existingContent ?? '';
      selectedTgl = existingTgl;
      tglTextController.text =
          existingTgl == null ? '' : formatDate(existingTgl);
      labelTextController.text = existingLabel ?? '';
    } else {
      selectedTgl = null;
      tglTextController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? 'Create new Note' : 'Edit Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  controller: titleTextController,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Content'),
                  controller: contentTextController,
                ),
                const SizedBox(height: 10),
                TextField(
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Tgl'),
                  controller: tglTextController,
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedTgl ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      selectedTgl = pickedDate;
                      tglTextController.text = formatDate(pickedDate);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Label'),
                  controller: labelTextController,
                ),
              ],
            ),
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                if (docId == null) {
                  firestoreService.addNote(
                    titleTextController.text,
                    contentTextController.text,
                    selectedTgl ?? DateTime.now(),
                    labelTextController.text,
                  );
                } else {
                  firestoreService.updateNote(
                    docId,
                    titleTextController.text,
                    contentTextController.text,
                    selectedTgl ?? DateTime.now(),
                    labelTextController.text,
                  );
                }
                titleTextController.clear();
                contentTextController.clear();
                tglTextController.clear();
                labelTextController.clear();
                selectedTgl = null;

                Navigator.pop(context);
              },
              child: Text(docId == null ? 'Create' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Notes'),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => logout(context),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: openNoteBox,
              child: const Icon(Icons.add),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getNotes(),
              builder: (context, noteSnapshot) {
                if (noteSnapshot.hasData) {
                  List notesList = noteSnapshot.data!.docs;

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: notesList.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = notesList[index];
                      String docId = document.id;

                      Map<String, dynamic> data =
                          document.data() as Map<String, dynamic>;
                      String noteTitle = data['title'];
                      String noteContent = data['content'];
                      DateTime noteTglDate =
                          (data['tgl'] as Timestamp).toDate();
                      String noteTgl = formatDate(noteTglDate);
                      String noteLabel = data['label'];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                noteTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                noteContent,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text('Tgl: $noteTgl'),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  noteLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      openNoteBox(
                                        docId: docId,
                                        existingTitle: noteTitle,
                                        existingContent: noteContent,
                                        existingTgl: noteTglDate,
                                        existingLabel: noteLabel,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      firestoreService.deleteNote(docId);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('No data'));
                }
              },
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

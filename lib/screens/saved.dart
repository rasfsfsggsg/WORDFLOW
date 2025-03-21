import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wordflow/screens/view.dart';



class SavedScreen extends StatefulWidget {
  final String userId;
  const SavedScreen({super.key, required this.userId});

  @override
  _SavedScreenState createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref("transcripts");

  List<Map<String, dynamic>> savedTranscripts = [];
  Map<String, List<Map<String, dynamic>>> groupedTranscripts = {};
  bool isLoading = true;
  String searchQuery = ""; // 🔍 Search query
  Set<String> expandedDates = {}; // 📂 Store expanded sections

  @override
  void initState() {
    super.initState();
    _fetchSavedTranscripts();
  }

  Future<void> _fetchSavedTranscripts() async {
    try {
      final event = await databaseRef.child(widget.userId).once();
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        savedTranscripts = data.entries.map((entry) {
          return {
            "key": entry.key,
            ...Map<String, dynamic>.from(entry.value),
          };
        }).toList();

        // 🛠 SORT by timestamp (LATEST FIRST) ✅
        savedTranscripts.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

        _groupTranscriptsByDate();
      } else {
        savedTranscripts = [];
        groupedTranscripts = {};
      }
    } catch (error) {
      Fluttertoast.showToast(msg: "Error loading data: $error", gravity: ToastGravity.BOTTOM);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _groupTranscriptsByDate() {
    groupedTranscripts.clear();

    for (var transcript in savedTranscripts) {
      String date = _formatDate(transcript["timestamp"]);
      if (!groupedTranscripts.containsKey(date)) {
        groupedTranscripts[date] = [];
      }
      groupedTranscripts[date]!.add(transcript);
    }

    // 🛠 Sort groupedTranscripts by date (LATEST FIRST) ✅
    groupedTranscripts = Map.fromEntries(
        groupedTranscripts.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key))
    );

    setState(() {});
  }


  // 📆 Format date
  String _formatDate(String? timestamp) {
    if (timestamp == null) return "Unknown Date";
    DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat("dd MMMM yyyy").format(dateTime); // Example: 05 March 2025
  }

  // ⏰ Format date & time
  String _formatDateTime(String? timestamp) {
    if (timestamp == null) return "Unknown Date & Time";
    DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat("dd MMMM yyyy, hh:mm a").format(dateTime); // Example: 05 March 2025, 10:30 AM
  }

  // ✏ Edit Transcript Name
  void _editTranscriptName(String key, String oldName) {
    TextEditingController controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Transcript Name"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "New Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  databaseRef.child(widget.userId).child(key).update({"fileName": newName}).then((_) {
                    Fluttertoast.showToast(msg: "Name Updated");
                    _fetchSavedTranscripts();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // 🗑 Delete Transcript
  void _deleteTranscript(String key) {
    databaseRef.child(widget.userId).child(key).remove().then((_) {
      Fluttertoast.showToast(msg: "Transcript Deleted", gravity: ToastGravity.BOTTOM);
      _fetchSavedTranscripts();
    }).catchError((error) {
      Fluttertoast.showToast(msg: "Error deleting: $error", gravity: ToastGravity.BOTTOM);
    });
  }

  // 📤 Share Transcript
  void _shareTranscript(String fileName, String originalText, String translatedText) {
    String shareContent = "**$fileName**\n\nOriginal: $originalText\n\nTranslated: $translatedText";
    Share.share(shareContent);
  }

  // 👀 Open Read Screen (✔ Updated)
  void _openReadScreen(String fileName, String originalText, String translatedText) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadScreen(
          fileName: fileName,
          originalText: originalText,
          translatedText: translatedText,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Saved Transcripts"),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // 🔙 Arrow का रंग सफेद
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), // 📝 Title सफेद
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 👈 Home Screen पर वापस जाने के लिए
          },
        ),
      ),







      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search by name or date...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupedTranscripts.isEmpty
                ? const Center(child: Text("No saved transcripts", style: TextStyle(fontSize: 18, color: Colors.black54)))
                : ListView(
              children: groupedTranscripts.entries.map((entry) {
                String date = entry.key;
                List<Map<String, dynamic>> transcripts = entry.value.where((transcript) {
                  return transcript["fileName"].toLowerCase().contains(searchQuery) ||
                      _formatDate(transcript["timestamp"]).toLowerCase().contains(searchQuery);
                }).toList();

                if (transcripts.isEmpty) return const SizedBox();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text("📅 $date - ${transcripts.length} Speech${transcripts.length > 1 ? 'es' : ''}"),
                      trailing: Icon(expandedDates.contains(date) ? Icons.expand_less : Icons.expand_more),
                      onTap: () {
                        setState(() {
                          if (expandedDates.contains(date)) {
                            expandedDates.remove(date);
                          } else {
                            expandedDates.add(date);
                          }
                        });
                      },
                    ),
                    if (expandedDates.contains(date))
                      ...transcripts.map((transcript) {
                        return Card(
                          child: ListTile(
                            title: Text(transcript["fileName"] ?? "Unnamed Note"),
                            subtitle: Text(_formatDateTime(transcript["timestamp"])), // 🕒 Show time
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye, color: Colors.green),
                                  onPressed: () => _openReadScreen(
                                    transcript["fileName"] ?? "Unnamed",
                                    transcript["originalText"],
                                    transcript["translatedText"],
                                  ),
                                ),

                                IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _editTranscriptName(transcript["key"], transcript["fileName"] ?? "Unnamed")),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTranscript(transcript["key"])),
                                IconButton(icon: const Icon(Icons.share, color: Colors.blue), onPressed: () => _shareTranscript(transcript["fileName"] ?? "Unnamed", transcript["originalText"], transcript["translatedText"])),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'login_screen.dart';
import 'saved.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen(this.user, {super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final databaseRef = FirebaseDatabase.instance.ref("transcripts");
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _spokenText = "";
  String _translatedText = "";
  bool _isListening = false;
  String _sourceLang = "English";
  String _targetLang = "Hindi";
  final _spokenController = TextEditingController();
  final _translatedController = TextEditingController();
  OnDeviceTranslator? _translator;
  bool _saveOriginal = true;
  bool _saveTranslated = true;
  bool _showSaveShare = false;

  final Map<String, TranslateLanguage> _languageMap = {
    "English": TranslateLanguage.english,
    "Hindi": TranslateLanguage.hindi,
    "Kannada": TranslateLanguage.kannada,
    "Bengali": TranslateLanguage.bengali,
    "Tamil": TranslateLanguage.tamil,
    "Telugu": TranslateLanguage.telugu,
    "Marathi": TranslateLanguage.marathi,
    "Gujarati": TranslateLanguage.gujarati,



  };

  String _getLocaleFromLanguage(String language) {
    switch (language) {
      case "English":
        return "en_US";
      case "Hindi":
        return "hi_IN";
      case "Kannada":
        return "kn_IN";
      case "Tamil":
        return "ta_IN";
      case "Telugu":
        return "te_IN";

      case "Marathi":
        return "mr_IN";
      case "Gujarati":
        return "gu_IN";
      case "Bengali":
        return "bn_IN";

      default:
        return "en_US"; // डिफ़ॉल्ट भाषा
    }
  }







  @override
  void initState() {
    super.initState();
    _setTranslator();
    _initSpeech();
  }

  void _setTranslator() {
    if (_sourceLang != _targetLang) {  // ✅ केवल तब सेट करें जब अनुवाद आवश्यक हो
      setState(() {
        _translator = OnDeviceTranslator(
          sourceLanguage: _languageMap[_sourceLang]!,
          targetLanguage: _languageMap[_targetLang]!,
        );
      });
    } else {
      setState(() {
        _translator = null; // ✅ यदि अनुवाद की जरूरत नहीं, तो null सेट करें
      });
    }
  }


  void _initSpeech() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {});
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    setState(() => _isListening = true);

    _speech.listen(
      onResult: (result) async {
        String recognizedWords = result.recognizedWords.trim();

        // ✅ पहले और अभी बोले गए टेक्स्ट को मिलाकर डुप्लिकेट हटाएं
        Set<String> uniqueWords = {..._spokenText.split(" "), ...recognizedWords.split(" ")};
        _spokenText = uniqueWords.join(" ").trim(); // ✅ केवल यूनिक शब्द जोड़ें

        setState(() {
          _spokenController.text = _spokenText;
        });

        // ✅ यदि अनुवाद आवश्यक है (स्रोत और लक्ष्य भाषा अलग हैं)
        if (_sourceLang != _targetLang && _translator != null) {
          try {
            final translatedWords = await _translator!.translateText(recognizedWords);

            // ✅ पहले के अनुवादित टेक्स्ट में नए टेक्स्ट को जोड़ें और डुप्लिकेट हटाएं
            Set<String> uniqueTranslatedWords = {..._translatedText.split(" "), ...translatedWords.split(" ")};
            _translatedText = uniqueTranslatedWords.join(" ").trim();

            setState(() {
              _translatedController.text = _translatedText;
              _showSaveShare = true;
            });
          } catch (e) {
            setState(() => _translatedText = "Translation Error: $e");
          }
        } else {
          // ✅ यदि अनुवाद की आवश्यकता नहीं है, तो केवल यूनिक शब्द जोड़ें
          setState(() {
            _translatedText = _spokenText;
            _translatedController.text = _translatedText;
            _showSaveShare = true;
          });
        }

        if (!_speech.isListening) {
          _stopListening();
        }
      },

      localeId: _getLocaleFromLanguage(_sourceLang), // ✅ सही भाषा सेट करें
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 5),
      partialResults: false,
      listenMode: stt.ListenMode.dictation,
    );
  }




  void _stopListening() {
    if (_isListening) {
      _speech.stop().then((_) {
        setState(() => _isListening = false); // ✅ UI अपडेट होगा और माइक एनिमेशन बंद होगा
      });
    }
  }







  void _clearText() {
    setState(() {
      _spokenText = "";
      _translatedText = "";
      _spokenController.clear();
      _translatedController.clear();
      _showSaveShare = false;
    });
  }

  void _saveTranscript() {
    if (!_saveOriginal && !_saveTranslated) {
      Fluttertoast.showToast(
          msg: "Please select text to save!", gravity: ToastGravity.BOTTOM);
      return;
    }

    databaseRef.child(widget.user.uid).push().set({
      "fileName": "Transcript ${DateTime
          .now()
          .millisecondsSinceEpoch}", // Adding a default file name
      "originalText": _saveOriginal ? _spokenText : "",
      "translatedText": _saveTranslated ? _translatedText : "",
      "timestamp": DateTime.now().toIso8601String(),


    }).then((_) {
      Fluttertoast.showToast(
          msg: "Transcript Saved!", gravity: ToastGravity.BOTTOM);
    }).catchError((error) {
      Fluttertoast.showToast(
          msg: "Error saving transcript: $error", gravity: ToastGravity.BOTTOM);
    });
  }

  void _shareTranscript() {
    String textToShare = "";
    if (_saveOriginal) textToShare += "Original: $_spokenText\n";
    if (_saveTranslated) textToShare += "Translated: $_translatedText";

    if (textToShare
        .trim()
        .isEmpty) {
      Fluttertoast.showToast(
          msg: "Please select text to share!", gravity: ToastGravity.BOTTOM);
      return;
    }

    Share.share(textToShare);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
                backgroundImage: NetworkImage(widget.user.photoURL ?? ""),
                radius: 20),
            const SizedBox(width: 10),
            Text(widget.user.displayName ?? "User",
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              GoogleSignIn().signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Live Translation",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _sourceLang,
                    items: _languageMap.keys.map((String lang) =>
                        DropdownMenuItem(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (newLang) {
                      setState(() {
                        _sourceLang = newLang!;
                        _setTranslator();
                      });
                    },
                  ),
                ),
                const Icon(Icons.arrow_forward),
                Expanded(
                  child: DropdownButton<String>(
                    value: _targetLang,
                    items: _languageMap.keys.map((String lang) =>
                        DropdownMenuItem(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (newLang) {
                      setState(() {
                        _targetLang = newLang!;
                        _setTranslator();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _textBox(_spokenController, "Recognized Speech", Icons.edit),

            const SizedBox(height: 10),


            Column(
              children: [
                const Text(
                  "Tap to speak and translate",
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                ),
                const SizedBox(height: 5), // Space between text and mic button

                // Listening text (Visible only when _isListening is true)
                if (_isListening)
                  const Text(
                    "listening and translating...",
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),

                const SizedBox(height: 5), // Space between text and mic button

                AvatarGlow(
                  animate: _isListening, // Glow animation starts when listening
                  glowColor: Colors.red,
                  child: GestureDetector(
                    onTap: _toggleListening,
                    child: FloatingActionButton(
                      onPressed: null,
                      backgroundColor: _isListening ? Colors.red : Colors.green,
                      // Green before tap, red after tap
                      child: const Icon(
                          Icons.mic, size: 36, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )

            ,
            const SizedBox(height: 10),


            const SizedBox(height: 10),
            _textBox(_translatedController, "Translated Text", Icons.edit),

            if (_showSaveShare) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(onPressed: _clearText,
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear")),

              CheckboxListTile(title: const Text("Save Original"),
                  value: _saveOriginal,
                  onChanged: (val) => setState(() => _saveOriginal = val!)),
              CheckboxListTile(title: const Text("Save Translated"),
                  value: _saveTranslated,
                  onChanged: (val) => setState(() => _saveTranslated = val!)),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(onPressed: _saveTranscript,
                      icon: const Icon(Icons.save),
                      label: const Text("Save")),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(onPressed: _shareTranscript,
                      icon: const Icon(Icons.share),
                      label: const Text("Share")),
                ],
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SavedScreen(userId: widget.user.uid), // Pass user ID
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text("Saved Speech"),
            ),

          ],
        ),
      ),
    );
  }


  Widget _textBox(TextEditingController controller, String hint,
      IconData icon) {
    final ScrollController _scrollController = ScrollController();

    controller.addListener(() {
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    return Container(
      height: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        reverse: true,
        child: TextField(
          controller: controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            suffixIcon: Icon(icon),
          ),
        ),
      ),
    );
  }
}
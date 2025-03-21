import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReadScreen extends StatefulWidget {
  final String fileName, originalText, translatedText;

  const ReadScreen({
    super.key,
    required this.fileName,
    required this.originalText,
    required this.translatedText,
  });

  @override
  _ReadScreenState createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  bool isLoading = false; // 🌀 Progress Indicator Flag
  String currentSpeakingText = "";
  Timer? speechTimer;
  int elapsedTime = 0;

  // 🌍 Available Languages Mapping
  final Map<String, String> languageMap = {
    "English": "en-US",
    "Hindi": "hi-IN",
    "Kannada": "kn-IN",
    "Bengali": "bn-IN",
    "Tamil": "ta-IN",
    "Telugu": "te-IN",
    "Marathi": "mr-IN",
    "Gujarati": "gu-IN",
  };

  // 🕵️‍♂️ Function to Detect Language
  String detectLanguage(String text) {
    if (text.contains(RegExp(r'[\u0900-\u097F]'))) return "Hindi";
    if (text.contains(RegExp(r'[\u0C80-\u0CFF]'))) return "Kannada";
    if (text.contains(RegExp(r'[\u0980-\u09FF]'))) return "Bengali";
    if (text.contains(RegExp(r'[\u0B80-\u0BFF]'))) return "Tamil";
    if (text.contains(RegExp(r'[\u0C00-\u0C7F]'))) return "Telugu";
    if (text.contains(RegExp(r'[\u0D00-\u0D7F]'))) return "Marathi";
    if (text.contains(RegExp(r'[\u0A80-\u0AFF]'))) return "Gujarati";
    return "English";
  }

  // 🎙 Speak or Stop Function
  Future<void> toggleSpeech(String text, String language) async {
    if (isSpeaking && text == currentSpeakingText) {
      await flutterTts.stop();
      stopSpeechAnimation();
    } else {
      setState(() {
        isLoading = true; // 🌀 Show Progress Bar
      });

      // 🔍 Simulate Language Detection Delay
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        isLoading = false; // Hide Progress Bar
      });

      await flutterTts.setLanguage(language);
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.4); // 👈 Slow speed
      startSpeechAnimation(text);
      await flutterTts.speak(text);
    }
  }

  // ⏳ Start Speech Animation + Timer
  void startSpeechAnimation(String text) {
    setState(() {
      isSpeaking = true;
      currentSpeakingText = text;
      elapsedTime = 0;
    });

    speechTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedTime++;
      });
    });
  }

  // 🛑 Stop Speech Animation + Timer
  void stopSpeechAnimation() {
    setState(() {
      isSpeaking = false;
      currentSpeakingText = "";
      elapsedTime = 0;
    });

    speechTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 Detect Languages
    String originalLang = detectLanguage(widget.originalText);
    String translatedLang = detectLanguage(widget.translatedText);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📜 Original Text Section
              Text(
                "📜 Original Text ($originalLang)",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  widget.originalText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),

              // 🏁 Progress Indicator
              if (isLoading)
                const Center(child: CircularProgressIndicator()),

              Text(
                "🎧 Please tap on mic to hear in $originalLang",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 10),

              Center(
                child: GestureDetector(
                  onTap: () {
                    toggleSpeech(widget.originalText, languageMap[originalLang] ?? "en-US");
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSpeaking && currentSpeakingText == widget.originalText ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSpeaking && currentSpeakingText == widget.originalText ? Icons.volume_off : Icons.volume_up,
                      size: 40, // 👈 Bigger icon
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🌍 Translated Text Section
              Text(
                "🌍 Translated Text ($translatedLang)",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  widget.translatedText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),

              // 🏁 Progress Indicator
              if (isLoading)
                const Center(child: CircularProgressIndicator()),

              Text(
                "🎧 Please tap on mic to hear in $translatedLang",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 10),

              Center(
                child: GestureDetector(
                  onTap: () {
                    toggleSpeech(widget.translatedText, languageMap[translatedLang] ?? "en-US");
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSpeaking && currentSpeakingText == widget.translatedText ? Colors.red : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSpeaking && currentSpeakingText == widget.translatedText ? Icons.volume_off  : Icons.volume_up,
                      size: 40, // 👈 Bigger icon
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

}

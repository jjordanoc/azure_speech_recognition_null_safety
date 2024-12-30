import 'package:azure_speech_recognition_null_safety/azure_speech_recognition_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';

class SimpleRecognitionScreen extends StatefulWidget {
  @override
  _SimpleRecognitionScreenState createState() =>
      _SimpleRecognitionScreenState();
}

class _SimpleRecognitionScreenState extends State<SimpleRecognitionScreen>
    with SingleTickerProviderStateMixin {
  String _centerText = 'Unknown';
  late AzureSpeechRecognition _speechAzure;
  String subKey = dotenv.get("AZURE_KEY");
  String region = dotenv.get('AZURE_REGION');
  String lang = "en-US";
  String timeout = "2000";
  bool isRecording = false;
  late AnimationController controller;

  void activateSpeechRecognizer() {
    // MANDATORY INITIALIZATION
    AzureSpeechRecognition.initialize(subKey, region,
        lang: lang, timeout: timeout);

    _speechAzure.setFinalTranscription((text) {
      // do what you want with your final transcription
      debugPrint("Setting final transcript");
      setState(() {
        _centerText = text;
        isRecording = false;
      });
    });

    _speechAzure.setRecognitionResultHandler((text) {
      debugPrint("Received partial result in recognizer: $text");
    });

    _speechAzure.setRecognitionStartedHandler(() {
      // called at the start of recognition (it could also not be used)
      debugPrint("Recognition started");
      setState(() {
        isRecording = true;
      });
    });
  }

  @override
  void initState() {
    _speechAzure = AzureSpeechRecognition();
    controller =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat();
    activateSpeechRecognizer();
    super.initState();
  }

  Future _recognizeVoice() async {
    try {
      AzureSpeechRecognition
          .simpleVoiceRecognition(); //await platform.invokeMethod('azureVoice');
      print("Started recognition with subKey: $subKey");
    } on Exception catch (e) {
      print("Failed to get text '$e'.");
    }
  }
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Is recording: $isRecording'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 40,
            ),
            Center(
              child: AnimatedBuilder(
                child: FlutterLogo(size: 200),
                animation: controller,
                builder: (_, child) {
                  return Transform.rotate(
                    angle: controller.value * 2 * pi,
                    child: child,
                  );
                },
              ),
            ),
            SizedBox(height: 40,),
            Text('Recognized text : $_centerText\n'),
            FloatingActionButton(
              onPressed: !isRecording ? _recognizeVoice : null,
              child: Icon(Icons.mic),
            ),
          ],
        ),
      ),
    );
  }
}

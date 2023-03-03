import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:azure_speech_recognition_null_safety/azure_speech_recognition_null_safety.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _centerText = 'Unknown';
  late AzureSpeechRecognition _speechAzure;
  String subKey = "300d3aa8af5c42f9914ae59997043825";
  String region = "eastus";
  String lang = "en-US";
  bool isRecording = false;

  void activateSpeechRecognizer() {
    // MANDATORY INITIALIZATION
    AzureSpeechRecognition.initialize(subKey, region, lang: lang);

    _speechAzure.setFinalTranscription((text) {
      // do what you want with your final transcription
      debugPrint("Setting final transcript");
      setState(() {
        _centerText = text;
        isRecording = false;
      });
    });

    _speechAzure.setRecognitionStartedHandler(() {
      // called at the start of recognition (it could also not be used)
      debugPrint("Recognition started");
      isRecording = true;
    });
  }

  void onLayoutDone(Duration timeStamp) async {
    await Permission.microphone.request();
    setState(() {});
  }

  @override
  void initState() {
    _speechAzure = new AzureSpeechRecognition();

    activateSpeechRecognizer();

    super.initState();

    WidgetsBinding.instance?.addPostFrameCallback(onLayoutDone);
  }

  Future _recognizeVoice() async {
    try {
      AzureSpeechRecognition
          .simpleVoiceRecognition(); //await platform.invokeMethod('azureVoice');
    } on PlatformException catch (e) {
      print("Failed to get text '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Text('TEXT RECOGNIZED : $_centerText\n'),
              FloatingActionButton(
                onPressed: () {
                  if (!isRecording) _recognizeVoice();
                },
                child: Icon(Icons.mic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

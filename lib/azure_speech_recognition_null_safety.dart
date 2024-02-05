import 'dart:async';

import 'package:flutter/services.dart';

typedef void StringResultHandler(String text);

class AzureSpeechRecognition {
  static const MethodChannel _channel =
  const MethodChannel('azure_speech_recognition');

  static final AzureSpeechRecognition _azureSpeechRecognition =
  new AzureSpeechRecognition._internal();

  factory AzureSpeechRecognition() => _azureSpeechRecognition;

  AzureSpeechRecognition._internal() {
    _channel.setMethodCallHandler(_platformCallHandler);
  }

  static String? _subKey;
  static String? _region;
  static String _lang = "en-EN";
  static String _timeout = "1000";

  /// default intitializer for almost every type except for the intent recognizer.
  /// Default language -> English
  AzureSpeechRecognition.initialize(String subKey, String region,
      {String? lang, String? timeout}) {
    _subKey = subKey;
    _region = region;
    if (lang != null) _lang = lang;
    if (timeout != null) {
      if (int.parse(timeout) >= 100 && int.parse(timeout) <= 5000) {
        _timeout = timeout;
      } else {
        throw "Segmentation silence timeout must be an integer in the range 100 to 5000. See https://learn.microsoft.com/en-us/azure/cognitive-services/speech-service/how-to-recognize-speech?pivots=programming-language-csharp#change-how-silence-is-handled for more information.";
      }
    }
    exceptionHandler = null;
    recognitionResultHandler = null;
    finalTranscriptionHandler = null;
    assessmentResultHandler = null;
    recognitionStartedHandler = null;
    startRecognitionHandler = null;
    recognitionStoppedHandler = null;
  }

  StringResultHandler? exceptionHandler;
  StringResultHandler? recognitionResultHandler;
  StringResultHandler? finalTranscriptionHandler;
  StringResultHandler? assessmentResultHandler;
  VoidCallback? recognitionStartedHandler;
  VoidCallback? startRecognitionHandler;
  VoidCallback? recognitionStoppedHandler;

  Future _platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case "speech.onRecognitionStarted":
        recognitionStartedHandler!();
        break;
      case "speech.onSpeech":
        recognitionResultHandler!(call.arguments);
        break;
      case "speech.onFinalResponse":
        finalTranscriptionHandler!(call.arguments);
        break;
      case "speech.onAssessmentResult":
        assessmentResultHandler!(call.arguments);
        break;
      case "speech.onStartAvailable":
        startRecognitionHandler!();
        break;
      case "speech.onRecognitionStopped":
        recognitionStoppedHandler!();
        break;
      case "speech.onException":
        exceptionHandler!(call.arguments);
        break;
      default:
        print("Error: method called not found");
    }
  }

  /// called each time a result is obtained from the async call
  void setRecognitionResultHandler(StringResultHandler handler) =>
      recognitionResultHandler = handler;

  /// final transcription is passed here
  void setFinalTranscription(StringResultHandler handler) =>
      finalTranscriptionHandler = handler;

  void setAssessmentResult(StringResultHandler handler) =>
      assessmentResultHandler = handler;

  /// called when an exception occur
  void onExceptionHandler(StringResultHandler handler) =>
      exceptionHandler = handler;

  /// called when the recognition is started
  void setRecognitionStartedHandler(VoidCallback handler) =>
      recognitionStartedHandler = handler;

  /// only for continuosly
  void setStartHandler(VoidCallback handler) =>
      startRecognitionHandler = handler;

  /// only for continuosly
  void setRecognitionStoppedHandler(VoidCallback handler) =>
      recognitionStoppedHandler = handler;

  // Performs speech recognition until a silence is detected
  static void simpleVoiceRecognition() {
    if ((_subKey != null && _region != null)) {
      _channel.invokeMethod('simpleVoice', {
        'language': _lang,
        'subscriptionKey': _subKey,
        'region': _region,
        'timeout': _timeout
      });
    } else {
      throw "Error: SpeechRecognitionParameters not initialized correctly";
    }
  }

  /// Performs speech recognition until a silence is detected (with speech assessment)
  static void simpleVoiceRecognitionWithAssessment({String? referenceText,
    String? phonemeAlphabet,
    String? granularity,
    bool? enableMiscue, int? nBestPhonemeCount,}) {
    if ((_subKey != null && _region != null)) {
      _channel.invokeMethod('simpleVoiceWithAssessment', {
        'language': _lang,
        'subscriptionKey': _subKey,
        'region': _region,
        'timeout': _timeout,
        'granularity': granularity,
        'enableMiscue': enableMiscue,
        'referenceText': referenceText,
        'phonemeAlphabet': phonemeAlphabet,
        'nBestPhonemeCount': nBestPhonemeCount,
      });
    } else {
      throw "Error: SpeechRecognitionParameters not initialized correctly";
    }
  }


  /// When called for the first time, starts performing continuous recognition
  /// When called a second time, it stops the previously started recognition
  /// It essentially toggles between "recording" and "not recording" states
  static void continuousRecording() {
    if (_subKey != null && _region != null) {
      _channel.invokeMethod('continuousStream',
          {'language': _lang, 'subscriptionKey': _subKey, 'region': _region});
    } else {
      throw "Error: SpeechRecognitionParameters not initialized correctly";
    }
  }

  /// When called for the first time, starts performing continuous recognition (with speech assessment)
  /// When called a second time, it stops the previously started recognition (with speech assessment)
  /// It essentially toggles between "recording" and "not recording" states
  static void continuousRecordingWithAssessment({String? referenceText,
    String? phonemeAlphabet,
    String? granularity,
    bool? enableMiscue, int? nBestPhonemeCount,}) {
    if ((_subKey != null && _region != null)) {
      _channel.invokeMethod('continuousStreamWithAssessment', {
        'language': _lang,
        'subscriptionKey': _subKey,
        'region': _region,
        'granularity': granularity,
        'enableMiscue': enableMiscue,
        'referenceText': referenceText,
        'phonemeAlphabet': phonemeAlphabet,
        'nBestPhonemeCount': nBestPhonemeCount,
      });
    } else {
      throw "Error: SpeechRecognitionParameters not initialized correctly";
    }
  }


  /// When continuously recording, returns true, otherwise it returns false
  static Future<bool> isContinuousRecognitionOn() {
    return _channel.invokeMethod<bool>('isContinuousRecognitionOn').then<bool>((
        bool? value) => value ?? false);
  }

  static Future<void> stopContinuousRecognition() async {
    await _channel.invokeMethod('stopContinuousStream');
  }
}

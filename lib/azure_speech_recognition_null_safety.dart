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

  static String? _languageUnderstandingSubscriptionKey;
  static String? _languageUnderstandingServiceRegion;
  static String? _languageUnderstandingAppId;

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
  }

  /// initializer for intent purpose
  /// Default language -> English
  AzureSpeechRecognition.initializeLanguageUnderstading(
      String subKey, String region, String appId,
      {lang}) {
    _languageUnderstandingSubscriptionKey = subKey;
    _languageUnderstandingServiceRegion = region;
    _languageUnderstandingAppId = appId;
    if (lang != null) _lang = lang;
  }

  StringResultHandler? exceptionHandler;
  StringResultHandler? recognitionResultHandler;
  StringResultHandler? finalTranscriptionHandler;
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

  /// Simple voice Recognition, the result will be sent only at the end.
  /// Return the text obtained or the error catched

  static simpleVoiceRecognition() {
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

  /// Speech recognition that return text while still recognizing
  /// Return the text obtained or the error catched

  static micStream() {
    if ((_subKey != null && _region != null)) {
      _channel.invokeMethod('micStream',
          {'language': _lang, 'subscriptionKey': _subKey, 'region': _region});
    } else {
      throw "Error: SpeechRecognitionParameters not initialized correctly";
    }
  }

  /// Speech recognition that doesnt stop recording text until you stopped it by calling again this function
  /// Return the text obtained or the error catched

  static continuousRecording() {
    if (_subKey != null && _region != null) {
      _channel.invokeMethod('continuousStream',
          {'language': _lang, 'subscriptionKey': _subKey, 'region': _region});
    } else {
      throw "Error: SpeechRecognitionParameters not initialized correctly";
    }
  }

  static dictationMode() {
    if (_subKey != null && _region != null) {
      _channel.invokeMethod('dictationMode',
          {'language': _lang, 'subscriptionKey': _subKey, 'region': _region});
    } else {
      throw "Error: SpeechRecognitionParameters not initialized correctly";
    }
  }

  /// Intent recognition
  /// Return the intent obtained or the error catched

  static intentRecognizer() {
    if (_languageUnderstandingSubscriptionKey != null &&
        _languageUnderstandingServiceRegion != null &&
        _languageUnderstandingAppId != null) {
      _channel.invokeMethod('intentRecognizer', {
        'language': _lang,
        'subscriptionKey': _languageUnderstandingSubscriptionKey,
        'appId': _languageUnderstandingAppId,
        'region': _languageUnderstandingServiceRegion
      });
    } else {
      throw "Error: LanguageUnderstading not initialized correctly";
    }
  }

  /// Speech recognition with Keywords
  /// [kwsModelName] name of the file in the asset folder that contains the keywords
  /// Return the speech obtained or the error catched

  static speechRecognizerWithKeyword(String kwsModelName) {
    if (_subKey != null && _region != null) {
      _channel.invokeMethod('keywordRecognizer', {
        'language': _lang,
        'subscriptionKey': _subKey,
        'region': _region,
        'kwsModel': kwsModelName
      });
    } else {
      throw "Error: SpeechRecognitionParameters not initialized correctly";
    }
  }
}

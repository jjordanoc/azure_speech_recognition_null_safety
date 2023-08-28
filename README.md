# Azure Speech Recognition for Flutter

See original project by cristianbregant: https://github.com/cristianbregant/azure_speech_recognition

## Getting Started

This project is a starting point for using the Azure Speech Recognition Services in Flutter.

Currently, the library supports both the Android and the iOS platform.

__Important__: To use this plugin you must have already created an account on the cognitive service page.

## Installation

To install the package use the latest version:

```dart
azure_speech_recognition_null_safety: ^<insert_latest_version_here>
```

## Usage

```dart
import 'package:azure_speech_recognition_null_safety/azure_speech_recognition_null_safety.dart';
```

## Initializer
The language default setting is "en-EN" but you could use what you want (if it is supported). 
The segmentation silence timeout default is 1000 ms. (It must be an integer in the range 100 to 5000)
```dart
AzureSpeechRecognition.initialize("your_subscription_key", "your_server_region", lang: "it-IT", timeout: "3000");
```

## Types of recognition

### Simple voice recognition

Performs speech recognition until silence is detected.

- Returns the final transcription in the `setFinalTranscription` call (only calls the method once, when it has detected silence).

- Returns partial results that are prone to change in the `setRecognitionResultHandler` call (is called multiple times, every time a new partial transcription is received).

```dart
AzureSpeechRecognition.simpleVoiceRecognition();
```

### Continuous voice recognition

Calling the method toggles the speech recognition on or off.

__Warning__: You must always stop the recognition manually to avoid memory leaks.

- Continuosly returns the finalized transcriptions through a call to `setFinalTranscription` (calls it every time a final transcription is received, and won't stop calling it until the recognition is manually stopped).

- Continuosly returns the partial transcriptions through a call to `setRecognitionResultHandler` (calls it every time a final transcription is received, and won't stop calling it until the recognition is manually stopped).

```dart
AzureSpeechRecognition.continuousRecording();
```

## Example program

See the `example/` folder for a complete Flutter application.

```dart

AzureSpeechRecognition _speechAzure;

void activateSpeechRecognizer(){
    // MANDATORY INITIALIZATION
  AzureSpeechRecognition.initialize("your_subscription_key", "your_server_region", lang: "it-IT", timeout: "3000");
  
  _speechAzure.setFinalTranscription((text) {
    // do what you want with your final transcription
  });

  _speechAzure.setRecognitionStartedHandler(() {
   // called at the start of recognition (it could also not be used)
  });

}

  @override
  void initState() {
    
    _speechAzure = new AzureSpeechRecognition();

    activateSpeechRecognizer();

    super.initState();
  }


  // This is the function you'll call to start the recognition
  Future recognizeVoice() async {
    try {
      AzureSpeechRecognition.simpleVoiceRecognition();
    } on PlatformException catch (e) {
      print("Failed start the recognition: '${e.message}'.");
    }
  }
```
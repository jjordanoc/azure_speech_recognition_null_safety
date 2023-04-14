# AzureSpeechRecognition

See original project by cristianbregant: https://github.com/cristianbregant/azure_speech_recognition

## Getting Started

This project is a starting point for using the Azure Speech Recognition Services.

To use this plugin you must have already created an account on the cognitive service page.

## Installation

To install the package use the latest version:

```dart
azure_speech_recognition: ^0.8.5
```

## Usage

```dart
import 'package:azure_speech_recognition_null_safety/azure_speech_recognition_null_safety.dart';
```

## Initialize
There are 2 type of initializer:
### Simple initializer
It should be used in any case other than the IntentRecognition.
The language default setting is "en-EN" but you could use what you want (if it is supported). 
The segmentation silence timeout default is 1000 ms. (It must be an integer in the range 100 to 5000)
```dart
AzureSpeechRecognition.initialize("your_subscription_key", "your_server_region",lang: "it-IT", timeout: "3000");
```

### Intent initializer
It should be used only in IntentRecognition.
The language default setting is "en-EN" but you could use what you want (if it is supported). 
```dart
AzureSpeechRecognition.initializeLanguageUnderstading("your_language_subscription_key", "your_language_server_region", "your_language_appId",lang:"it-IT");
```

## Types of recognitions 

### Simple voice recognition (Android and iOS supported)
The response is given at the end of the recognition.

```dart

AzureSpeechRecognition _speechAzure;
String subKey = "your_key";
String region = "your_server_region";
String lang = "it-IT";

void activateSpeechRecognizer(){
    // MANDATORY INITIALIZATION
  AzureSpeechRecognition.initialize(subKey, region,lang: lang);
  
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



Future recognizeVoice() async {
    try {
      AzureSpeechRecognition.simpleVoiceRecognition();
    } on PlatformException catch (e) {
      print("Failed start the recognition: '${e.message}'.");
    }
  }
```

### Voice recognition with microphone streaming
It returns in the recognitionResultHandler the temporary phrases that it understand and at the end the final response is returned by the setFinalTranscription method.

```dart

void activateSpeechRecognizer(){
    // MANDATORY INITIALIZATION
  AzureSpeechRecognition.initialize(subKey, region,lang: lang);
  
  _speechAzure.setFinalTranscription((text) {
    // do what you want with your final transcription
  });

  _speechAzure.setRecognitionResultHandler((text) {
    // do what you want with your partial transcription (this one is called every time a word is recognized)
    // if you have a string that is displayed you could call here setState() to updated with the partial result
  });

  _speechAzure.setRecognitionStartedHandler(() {
   // called at the start of recognition (it could also not be used)
  });

}


Future recognizeVoiceMicStreaming() async {
    try {
      AzureSpeechRecognition.micStream();
    } on PlatformException catch (e) {
      print("Failed start the recognition: '${e.message}'.");
    }
  }
```

### Voice recognition continuously : CURRENTLY NOT WORKING
It returns in the recognitionResultHandler the temporary phrases that it understand and at when the function is called again the final response is returned by the setFinalTranscription method.

### Voice intent recognition
It returns in the recognitionResultHandler the temporary phrases that it understand and at the end the final response is returned by the setFinalTranscription method.

```dart

void activateSpeechRecognizer(){
    // MANDATORY INITIALIZATION
  AzureSpeechRecognition.initializeLanguageUnderstading(subKey, region, appId, lang: lang);
  
  _speechAzure.setFinalTranscription((text) {
    // do what you want with your final transcription
  });

  _speechAzure.setRecognitionResultHandler((text) {
    // do what you want with your partial transcription (this one is called every time a word is recognized)
    // if you have a string that is displayed you could call here setState() to updated with the partial result
  });

  _speechAzure.setRecognitionStartedHandler(() {
   // called at the start of recognition (it could also not be used)
  });

}


Future speechIntentRecognizer() async {
    try {
      AzureSpeechRecognition.intentRecognizer();
    } on PlatformException catch (e) {
      print("Failed start the recognition: '${e.message}'.");
    }
  }
```

### Voice recognition with keyword : CURRENTLY NOT WORKING
This method require the keywords file to be put in the asset folder.
The mandatory parameter is the name of that file.
It returns in the recognitionResultHandler the temporary phrases that it understand and at the end the final response is returned by the setFinalTranscription method.




## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.


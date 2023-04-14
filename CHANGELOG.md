## 0.8.5
- Fix: final response now returns the empty string whenever result.getReason() is different from ResultReason.RecognizedSpeech on Android.

## 0.8.4
- Added iOS support for simple microphone recognition.

## 0.8.3
- Added null safety.
- Added (optional) segmentation silence timeout for simple voice recognition.

## 0.8.2

- BugFix
- Support continuous recognition

## 0.8.0

# Breaking changes:
New method to initialize the speech recognition plugin.
See readme to know more about.

# New release :
- Support for asynchronous recognition for the simple voice.
- Support for microphone streaming for having text while dictating
- New method to initialize the AzureSpeechRecognition



## 0.0.1

# First release:
- it supports only Android.
- it supports only the voice recognition with the result at the end of the speech.


TODO: 
- add support to IOS.
- add support to microphone stream

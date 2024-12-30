## 0.9.6
- Fix: Update gradle for compatibility with Android Studio Ladybug 2024.2.1.

## 0.9.5
- Feat: Added method to stop continuous recognition independently.

## 0.9.4
- Feat: Added NBestPhoneme count parameter to improve assessments.

## 0.9.3
- Feat: Added speech assessment feature for continuous recognition.

## 0.9.2
- Feat: Added speech assessment feature for simple recognition.

## 0.9.0
- Feat: Added task cancellation, which allows cancelling all active Simple Recognition tasks.

## 0.8.9
- Fix: Use asynchronous recognition on iOS to avoid blocking main isolate.

## 0.8.8
- Fix: Added 0.8.7 features to Android.

## 0.8.7
- Feat: Partial results are now transmitted through calls to the appropriate handlers.
- Refactor: Removed poorly documented methods.
- __Important__: If your application depends on any of these methods consider staying on version 0.8.6.

## 0.8.6
- Feat: Added continuous speech recognition in iOS.

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
New method to initialize the speech recognition plugin.
See readme to know more about.

- Support for asynchronous recognition for the simple voice.
- Support for microphone streaming for having text while dictating
- New method to initialize the AzureSpeechRecognition

## 0.0.1
- it supports only Android.
- it supports only the voice recognition with the result at the end of the speech.

import Flutter
import UIKit
import MicrosoftCognitiveServicesSpeech

public class SwiftAzureSpeechRecognitionPlugin: NSObject, FlutterPlugin {
  var azureChannel: FlutterMethodChannel
  var continuousListeningStarted: Bool = false
  private var speechRecognizer: SPXSpeechRecognizer?
  var text = ""
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "azure_speech_recognition", binaryMessenger: registrar.messenger())
    let instance: SwiftAzureSpeechRecognitionPlugin = SwiftAzureSpeechRecognitionPlugin(azureChannel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    init(azureChannel: FlutterMethodChannel) {
        self.azureChannel = azureChannel
    }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? Dictionary<String, String>
    if (call.method == "simpleVoice") {
        let speechSubscriptionKey = args?["subscriptionKey"] ?? ""
        let serviceRegion = args?["region"] ?? ""
        let lang = args?["language"] ?? ""
        let timeoutMs = args?["timeout"] ?? ""
        print("Called simpleVoice \(speechSubscriptionKey) \(serviceRegion) \(lang) \(timeoutMs)")
        simpleSpeechRecognition(speechSubscriptionKey: speechSubscriptionKey, serviceRegion: serviceRegion, lang: lang, timeoutMs: timeoutMs)
    } else if(call.method == "micStream"){
    let speechSubscriptionKey = args?["subscriptionKey"] ?? ""
            let serviceRegion = args?["region"] ?? ""
            let lang = args?["language"] ?? ""
            let timeoutMs = args?["timeout"] ?? ""
            print("Called simpleVoice \(speechSubscriptionKey) \(serviceRegion) \(lang) \(timeoutMs)")
        micStreamSpeechRecognition(speechSubscriptionKey: speechSubscriptionKey, serviceRegion: serviceRegion, lang: lang, timeoutMs: timeoutMs)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  public func simpleSpeechRecognition(speechSubscriptionKey : String, serviceRegion : String, lang: String, timeoutMs: String) {
      var speechConfig: SPXSpeechConfiguration?
              do {
                  try speechConfig = SPXSpeechConfiguration(subscription: speechSubscriptionKey, region: serviceRegion)
                  speechConfig!.enableDictation();
              } catch {
                  print("error \(error) happened")
                  speechConfig = nil
              }
              speechConfig?.speechRecognitionLanguage = lang
      speechConfig?.setPropertyTo(timeoutMs, by: SPXPropertyId.speechSegmentationSilenceTimeoutMs)

              let audioConfig = SPXAudioConfiguration()

              let reco = try! SPXSpeechRecognizer(speechConfiguration: speechConfig!, audioConfiguration: audioConfig)

//               reco.addRecognizingEventHandler() {reco, evt in

//                   print("intermediate recognition result: \(evt.result.text ?? "(no result)")")

//               }

              print("Listening...")

              let result = try! reco.recognizeOnce()
              print("recognition result: \(result.text ?? "(no result)"), reason: \(result.reason.rawValue)")

              if result.reason != SPXResultReason.recognizedSpeech {
                  let cancellationDetails = try! SPXCancellationDetails(fromCanceledRecognitionResult: result)
                  print("cancelled: \(result.reason), \(cancellationDetails.errorDetails)")
                  print("Did you set the speech resource key and region values?")
                  azureChannel.invokeMethod("speech.onFinalResponse", arguments: "")
              } else {
                  azureChannel.invokeMethod("speech.onFinalResponse", arguments: result.text)
              }
      
  }
  public func micStreamSpeechRecognition(speechSubscriptionKey : String, serviceRegion : String, lang: String, timeoutMs: String) {
        if continuousListeningStarted == true {
           do {
                try speechRecognizer?.stopContinuousRecognition()
           } catch {

           }
           continuousListeningStarted = false
           return
        }
        var speechConfig: SPXSpeechConfiguration?
        do {
            try speechConfig = SPXSpeechConfiguration(subscription: speechSubscriptionKey, region: serviceRegion)
            speechConfig!.enableDictation()
        } catch {
            print("error \(error) happened")
            speechConfig = nil
        }
        //speechConfig?.speechRecognitionLanguage = lang
        //speechConfig?.setPropertyTo(timeoutMs, by: SPXPropertyId.speechSegmentationSilenceTimeoutMs)
        let audioConfig = SPXAudioConfiguration()
        speechRecognizer = try! SPXSpeechRecognizer(speechConfiguration: speechConfig!, audioConfiguration: audioConfig)
        speechRecognizer?.addRecognizedEventHandler() { reco, evt in
             if self.text.isEmpty == false {
             self.text += " "
             }
             self.text += evt.result.text ?? ""
             self.azureChannel.invokeMethod("speech.onSpeech",arguments:evt.result.text ?? "")
             print("sentence recognition result: \(evt.result.text ?? "(no result)")")
//              self.azureChannel.invokeMethod("speech.onFinalResponse", arguments: self.text ?? "")
        }
        speechRecognizer?.addSessionStoppedEventHandler() {reco, evt in
                print("Received session stopped event. SessionId: \(evt.sessionId)")
                self.azureChannel.invokeMethod("speech.onFinalResponse", arguments: self.text)
                self.text = ""
                self.azureChannel.invokeMethod("speech.onRecognitionStopped",arguments:nil);
                self.speechRecognizer = nil
        }
        self.azureChannel.invokeMethod("speech.onRecognitionStarted",arguments:nil)

        print("Listening...")
        continuousListeningStarted = true
        do {
            try? speechRecognizer?.startContinuousRecognition()
        } catch {
        }
    }
}

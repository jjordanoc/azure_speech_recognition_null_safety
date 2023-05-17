import Flutter
import UIKit
import MicrosoftCognitiveServicesSpeech

public class SwiftAzureSpeechRecognitionPlugin: NSObject, FlutterPlugin {
    var azureChannel: FlutterMethodChannel
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
        print("Called simpleVoice")
        simpleSpeechRecognition(speechSubscriptionKey: speechSubscriptionKey, serviceRegion: serviceRegion, lang: lang, timeoutMs: timeoutMs)
    }
    else {
      result(FlutterMethodNotImplemented)
    }
  }

  public func simpleSpeechRecognition(speechSubscriptionKey : String, serviceRegion : String, lang: String, timeoutMs: String) {
      var speechConfig: SPXSpeechConfiguration?
              do {
                  try speechConfig = SPXSpeechConfiguration(subscription: speechSubscriptionKey, region: serviceRegion)
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
              }
      else {
          azureChannel.invokeMethod("speech.onFinalResponse", arguments: result.text)
      }
      
  }
}

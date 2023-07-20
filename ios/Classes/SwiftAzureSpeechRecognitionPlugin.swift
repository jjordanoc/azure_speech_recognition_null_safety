import Flutter
import UIKit
import MicrosoftCognitiveServicesSpeech
import AVFoundation
public class SwiftAzureSpeechRecognitionPlugin: NSObject, FlutterPlugin {
    var azureChannel: FlutterMethodChannel
    var continousListeningStarted: Bool = false
    var continousSpeechRecognizer: SPXSpeechRecognizer? = nil
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
        else if (call.method == "continuousStream") {
            let speechSubscriptionKey = args?["subscriptionKey"] ?? ""
            let serviceRegion = args?["region"] ?? ""
            let lang = args?["language"] ?? ""
            print("Called continuousStream")
            continuousStream(speechSubscriptionKey: speechSubscriptionKey, serviceRegion: serviceRegion, lang: lang)
        }
        else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func simpleSpeechRecognition(speechSubscriptionKey : String, serviceRegion : String, lang: String, timeoutMs: String) {
        var speechConfig: SPXSpeechConfiguration?
        do {
            // Request access to the microphone
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            print("Request access to the microphone")
            
            // Initialize speech recognizer and specify correct subscription key and service region
            try speechConfig = SPXSpeechConfiguration(subscription: speechSubscriptionKey, region: serviceRegion)
        } catch {
            print("error \(error) happened")
            speechConfig = nil
        }
        speechConfig?.speechRecognitionLanguage = lang
        speechConfig?.setPropertyTo(timeoutMs, by: SPXPropertyId.speechSegmentationSilenceTimeoutMs)
        
        let audioConfig = SPXAudioConfiguration()
        
        let reco = try! SPXSpeechRecognizer(speechConfiguration: speechConfig!, audioConfiguration: audioConfig)
        reco.addRecognizingEventHandler() {reco, evt in
            print("intermediate recognition result: \(evt.result.text ?? "(no result)")")
        }
        print("Listening...")
        let result = try! reco.recognizeOnce()
        print("recognition result: \(result.text ?? "(no result)"), reason: \(result.reason.rawValue)")
        print("reason \(result.reason)")
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
    
    public func continuousStream(speechSubscriptionKey : String, serviceRegion : String, lang: String) {
        if (continousListeningStarted) {
            print("Stopping continous recognition")
            do {
                var cancelTask = try continousSpeechRecognizer!.stopContinuousRecognition()
                
                azureChannel.invokeMethod("speech.onRecognitionStopped", arguments: nil)
                continousSpeechRecognizer = nil
                continousListeningStarted = false
            }
            catch {
                print("Error occurred stopping continous recognition")
            }
        }
        else {
            print("Starting continous recognition")
            do {
                // Request access to the microphone
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
                print("Request access to the microphone")
            }
            catch {
                print("An unexpected error occurred")
            }
            
            // Initialize speech recognizer and specify correct subscription key and service region
            let speechConfig = try! SPXSpeechConfiguration(subscription: speechSubscriptionKey, region: serviceRegion)
            
            speechConfig.speechRecognitionLanguage = lang
            
            let audioConfig = SPXAudioConfiguration()
            
            continousSpeechRecognizer = try! SPXSpeechRecognizer(speechConfiguration: speechConfig, audioConfiguration: audioConfig)
            continousSpeechRecognizer!.addRecognizingEventHandler() {reco, evt in
                print("intermediate recognition result: \(evt.result.text ?? "(no result)")")
            }
            continousSpeechRecognizer!.addRecognizedEventHandler({reco, evt in
                let res = evt.result.text
                print("final result \(res!)")
                self.azureChannel.invokeMethod("speech.onFinalResponse", arguments: res)
            })
            print("Listening...")
            try! continousSpeechRecognizer!.startContinuousRecognition()
            continousListeningStarted = true
        }
    }
}

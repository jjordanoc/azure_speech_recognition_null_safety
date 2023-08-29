import Flutter
import UIKit
import MicrosoftCognitiveServicesSpeech
import AVFoundation

@available(iOS 13.0, *)
struct SimpleRecognitionTask {
    var task: Task<Void, Never>
    var isCanceled: Bool
}

@available(iOS 13.0, *)
public class SwiftAzureSpeechRecognitionPlugin: NSObject, FlutterPlugin {
    var azureChannel: FlutterMethodChannel
    var continousListeningStarted: Bool = false
    var continousSpeechRecognizer: SPXSpeechRecognizer? = nil
    var simpleRecognitionTasks: Dictionary<String, SimpleRecognitionTask> = [:]
   
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
        else if (call.method == "cancelActiveSimpleRecognitionTasks") {
            cancelActiveSimpleRecognitionTasks();
        }
        else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func cancelActiveSimpleRecognitionTasks() {
        print("Cancelling any active tasks")
        for taskId in simpleRecognitionTasks.keys {
            print("Cancelling task \(taskId)")
            simpleRecognitionTasks[taskId]?.task.cancel()
            simpleRecognitionTasks[taskId]?.isCanceled = true
        }
    }
    
    public func simpleSpeechRecognition(speechSubscriptionKey : String, serviceRegion : String, lang: String, timeoutMs: String) {
        print("Created new recognition task")
        let taskId = UUID().uuidString;
        let task = Task {
            print("Started recognition with task ID \(taskId)")
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
                if (self.simpleRecognitionTasks[taskId]?.isCanceled ?? false) { // Discard intermediate results if the task was cancelled
                    print("Ignoring partial result. TaskID: \(taskId)")
                }
                else {
                    print("Intermediate result: \(evt.result.text ?? "(no result)")\nTaskID: \(taskId)")
                    self.azureChannel.invokeMethod("speech.onSpeech", arguments: evt.result.text)
                }
            }
            
            let result = try! reco.recognizeOnce()
            if (Task.isCancelled) {
                print("Ignoring final result. TaskID: \(taskId)")
            } else {
                print("Final result: \(result.text ?? "(no result)")\nReason: \(result.reason.rawValue)\nTaskID: \(taskId)")
                if result.reason != SPXResultReason.recognizedSpeech {
                    let cancellationDetails = try! SPXCancellationDetails(fromCanceledRecognitionResult: result)
                    print("Cancelled: \(cancellationDetails.description), \(cancellationDetails.errorDetails)\nTaskID: \(taskId)")
                    print("Did you set the speech resource key and region values?")
                    self.azureChannel.invokeMethod("speech.onFinalResponse", arguments: "")
                }
                else {
                    self.azureChannel.invokeMethod("speech.onFinalResponse", arguments: result.text)
                }
                
            }
            self.simpleRecognitionTasks.removeValue(forKey: taskId)
        }
        simpleRecognitionTasks[taskId] = SimpleRecognitionTask(task: task, isCanceled: false)
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
                self.azureChannel.invokeMethod("speech.onSpeech", arguments: evt.result.text)
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

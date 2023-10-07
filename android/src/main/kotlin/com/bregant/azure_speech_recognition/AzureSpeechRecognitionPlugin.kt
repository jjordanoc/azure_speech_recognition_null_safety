package com.bregant.azure_speech_recognition

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import com.microsoft.cognitiveservices.speech.audio.AudioConfig;
import com.microsoft.cognitiveservices.speech.intent.LanguageUnderstandingModel;
import com.microsoft.cognitiveservices.speech.intent.IntentRecognitionResult;
import com.microsoft.cognitiveservices.speech.intent.IntentRecognizer;
import com.bregant.azure_speech_recognition.MicrophoneStream;
import android.app.Activity;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.Callable;
import android.os.Handler;
import android.os.Looper;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
//import androidx.core.app.ActivityCompat;
import java.net.URI;
import android.util.Log;
import android.text.TextUtils;
import com.microsoft.cognitiveservices.speech.*

import java.util.concurrent.Semaphore 


/** AzureSpeechRecognitionPlugin */
public class AzureSpeechRecognitionPlugin(): FlutterPlugin,Activity(),MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var azureChannel : MethodChannel;
  private var microphoneStream : MicrophoneStream? = null;
  private  lateinit var handler : Handler;
  var continuousListeningStarted : Boolean = false;
  lateinit var  reco : SpeechRecognizer;
  lateinit var  task_global : Future<SpeechRecognitionResult>;
  var enableDictation : Boolean = false;
  private fun createMicrophoneStream() : MicrophoneStream{
    if (microphoneStream != null) {
        microphoneStream!!.close();
        microphoneStream = null;
    }

    microphoneStream = MicrophoneStream();
    return microphoneStream!!;
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    azureChannel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "azure_speech_recognition")
    azureChannel.setMethodCallHandler(this);
    
  }

  init{
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "azure_speech_recognition")

      this.azureChannel = MethodChannel(registrar.messenger(), "azure_speech_recognition");
      this.azureChannel.setMethodCallHandler(this);
    }

    handler = Handler(Looper.getMainLooper());
  }

  /*companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "azure_speech_recognition")
      channel.setMethodCallHandler(AzureSpeechRecognitionPlugin(registrar.activity(),channel))
    }
  }

  init{
    this.azureChannel = channel;
    this.azureChannel.setMethodCallHandler(this);

    handler = Handler(Looper.getMainLooper());
  }*/


  fun getAudioConfig() : AudioConfig {
    return AudioConfig.fromDefaultMicrophoneInput();
  }


  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if(call.method == "simpleVoice"){
      //_result = result;
      var permissionRequestId : Int = 5;
      var speechSubscriptionKey : String = ""+call.argument("subscriptionKey");
      var serviceRegion : String= ""+call.argument("region");
      var lang : String = ""+call.argument("language");
      var timeoutMs : String = ""+call.argument("timeout");

      simpleSpeechRecognition(speechSubscriptionKey,serviceRegion,lang,timeoutMs);
      result.success(true);

    }else if(call.method == "micStream"){
      var permissionRequestId : Int = 5;
      var speechSubscriptionKey : String = ""+call.argument("subscriptionKey");
      var serviceRegion : String= ""+call.argument("region");
      var lang : String = ""+call.argument("language");


      micStreamRecognition(speechSubscriptionKey,serviceRegion,lang);
      result.success(true);

    }else if(call.method == "continuousStream"){
      var permissionRequestId : Int = 5;
      var speechSubscriptionKey : String = ""+call.argument("subscriptionKey");
      var serviceRegion : String= ""+call.argument("region");
      var lang : String =  ""+call.argument("language");


      micStreamContinuosly(speechSubscriptionKey,serviceRegion,lang);
      result.success(true);

    }else if(call.method == "dictationMode"){
      var permissionRequestId : Int = 5;
      var speechSubscriptionKey : String = ""+call.argument("subscriptionKey");
      var serviceRegion : String= ""+call.argument("region");
      var lang : String =  ""+call.argument("language");

      enableDictation = true;
      micStreamContinuosly(speechSubscriptionKey,serviceRegion,lang);
      result.success(true);

    }
    else if(call.method == "intentRecognizer"){
      var permissionRequestId : Int = 5;
      var speechSubscriptionKey : String = ""+call.argument("subscriptionKey");
      var serviceRegion : String= ""+call.argument("region");
      var appId : String= ""+call.argument("appId");
      var lang : String =  ""+call.argument("language");


      recognizeIntent(speechSubscriptionKey,serviceRegion,appId,lang);
      result.success(true);

    }else if(call.method == "keywordRecognizer"){
      var permissionRequestId : Int = 5;
      var speechSubscriptionKey : String = ""+call.argument("subscriptionKey");
      var serviceRegion : String= ""+call.argument("region");
      var lang : String =  ""+call.argument("language");
      var kwsModel : String = ""+call.argument("kwsModel");

      keywordRecognizer(speechSubscriptionKey, serviceRegion, lang, kwsModel);
      result.success(true);

    }
    else if (call.method == "cancelActiveSimpleRecognitionTasks") {
      // ignore
    }
    else{
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    azureChannel.setMethodCallHandler(null)
  }

  fun simpleSpeechRecognition(speechSubscriptionKey:String,serviceRegion:String,lang:String,timeoutMs:String) {
    val logTag : String = "simpleVoice";


    try{
      
      var audioInput : AudioConfig = AudioConfig.fromStreamInput(createMicrophoneStream());

      var config : SpeechConfig = SpeechConfig.fromSubscription(speechSubscriptionKey, serviceRegion); 

      config.speechRecognitionLanguage = lang;
      config.setProperty(PropertyId.Speech_SegmentationSilenceTimeoutMs, timeoutMs);

      var reco : SpeechRecognizer = SpeechRecognizer(config,audioInput);

      var task : Future<SpeechRecognitionResult> = reco.recognizeOnceAsync();

      task_global=task;

      invokeMethod("speech.onRecognitionStarted",null);

      reco.recognizing.addEventListener({ o, speechRecognitionResultEventArgs->
        val s = speechRecognitionResultEventArgs.getResult().getText();
        Log.i(logTag, "Intermediate result received: " + s);
        if(task_global===task){
          invokeMethod("speech.onSpeech",s);
        }
      });

      setOnTaskCompletedListener(task, { result ->
        val s = result.getText()
        Log.i(logTag, "Recognizer returned: " + s)
        if(task_global===task){
          if (result.getReason() == ResultReason.RecognizedSpeech) {
            invokeMethod("speech.onFinalResponse",s);
          }
          else {
            invokeMethod("speech.onFinalResponse","");
          }
        }
        reco.close();
      })

    }catch(exec:Exception){
      Log.i(logTag,"ERROR")
      assert(false);
      invokeMethod("speech.onException", "Exception: "+exec.message);

    }
  }

  // Mic Streaming, it need the additional method implementend to get the data from the async task
  fun micStreamRecognition(speechSubscriptionKey:String,serviceRegion:String,lang:String){
    val logTag : String = "micStream";

    try{
      
      var audioInput : AudioConfig = AudioConfig.fromStreamInput(createMicrophoneStream());


      var config : SpeechConfig = SpeechConfig.fromSubscription(speechSubscriptionKey, serviceRegion); 
      assert(config != null);

      config.speechRecognitionLanguage = lang;

      var reco : SpeechRecognizer = SpeechRecognizer(config,audioInput);

      assert(reco != null);

      invokeMethod("speech.onRecognitionStarted",null);

      reco.recognizing.addEventListener({ o, speechRecognitionResultEventArgs->
        val s = speechRecognitionResultEventArgs.getResult().getText()
        //Log.i(logTag, "Intermediate result received: " + s)
        invokeMethod("speech.onSpeech",s);
      });
      
  
      val task : Future<SpeechRecognitionResult> = reco.recognizeOnceAsync();


      setOnTaskCompletedListener(task, { result ->
        val s = result.getText()
        reco.close()
        //Log.i(logTag, "Recognizer returned: " + s)
        invokeMethod("speech.onFinalResponse",s);
      })

    }catch(exec:Exception){
      assert(false);
      invokeMethod("speech.onException", "Exception: "+exec.message);
    }
  }



  // stream continuosly until you press the button to stop ! STILL NOT WORKING COMPLETELY

  fun micStreamContinuosly(speechSubscriptionKey:String,serviceRegion:String,lang:String){
    val logTag : String = "micStreamContinuos";
    
    
    lateinit var  audioInput : AudioConfig;
    var content :  ArrayList<String> = ArrayList<String>();


    Log.i(logTag, "StatoRiconoscimentoVocale: " + continuousListeningStarted);

    if(continuousListeningStarted){
      if(reco != null){
        val _task1  = reco.stopContinuousRecognitionAsync();

        setOnTaskCompletedListener(_task1, { result ->
          Log.i(logTag, "Continuous recognition stopped.");
          continuousListeningStarted = false;
          invokeMethod("speech.onRecognitionStopped",null);
                reco.close();

        })
      }else{
        continuousListeningStarted = false;
      }
      

      return;
    }
    
    content.clear();

    try{
      
      //audioInput = AudioConfig.fromStreamInput(createMicrophoneStream());


      var config : SpeechConfig = SpeechConfig.fromSubscription(speechSubscriptionKey, serviceRegion); 
      assert(config != null);

      config.speechRecognitionLanguage = lang;

      if(enableDictation){
        Log.i(logTag, "Enabled BF dictation");
        config.enableDictation();
        Log.i(logTag, "Enabled AF dictation");

      }

      reco = SpeechRecognizer(config,getAudioConfig());

      assert(reco != null);


      

      reco.recognizing.addEventListener({ o, speechRecognitionResultEventArgs->
        val s = speechRecognitionResultEventArgs.getResult().getText()
        content.add(s);
        Log.i(logTag, "Intermediate result received: " + s)
        invokeMethod("speech.onSpeech",s);
        content.removeAt(content.size - 1);
      });

      reco.recognized.addEventListener({ o, speechRecognitionResultEventArgs->
        val s = speechRecognitionResultEventArgs.getResult().getText()
        content.add(s);
        Log.i(logTag, "Final result received: " + s)
        invokeMethod("speech.onFinalResponse",s);
      });
      
  
      val _task2 = reco.startContinuousRecognitionAsync();

      setOnTaskCompletedListener(_task2, { result ->
        continuousListeningStarted = true;
        invokeMethod("speech.onRecognitionStarted",null);

        //invokeMethod("speech.onStopAvailable",null);
      })
      

    }catch(exec:Exception){
      assert(false);
      invokeMethod("speech.onException", "Exception: "+exec.message);

    }
  }





  /// Recognize Intent method from microsoft sdk

  fun recognizeIntent(speechSubscriptionKey:String,serviceRegion:String,appId:String,lang:String){
    val logTag : String = "intent";

    var content :  ArrayList<String> = ArrayList<String>();

    content.add("");
    content.add("");

    try{
       
      val audioInput = AudioConfig.fromStreamInput(createMicrophoneStream());


      var config : SpeechConfig = SpeechConfig.fromSubscription(speechSubscriptionKey, serviceRegion); 

      assert(config != null);

      config.speechRecognitionLanguage = lang;

      val reco = IntentRecognizer(config,audioInput);

      var intentModel : LanguageUnderstandingModel = LanguageUnderstandingModel.fromAppId(appId);
      reco.addAllIntents(intentModel);

      reco.recognizing.addEventListener({ o, intentRecognitionResultEventArgs->
        val s = intentRecognitionResultEventArgs.getResult().getText()
        content.set(0,s);
        Log.i(logTag, "Final result received: " + s)
        invokeMethod("speech.onFinalResponse",TextUtils.join(System.lineSeparator(), content));
      });
      
      
      val task : Future<IntentRecognitionResult> = reco.recognizeOnceAsync();

      setOnTaskCompletedListener(task, { result ->
        Log.i(logTag, "Continuous recognition stopped.");

        var s = result.getText();

        if (result.getReason() != ResultReason.RecognizedIntent) {
          var errorDetails = if(result.getReason() == ResultReason.Canceled) CancellationDetails.fromResult(result).getErrorDetails() else "";
          s = "Intent failed with " + result.getReason() + ". Did you enter your Language Understanding subscription?" + System.lineSeparator() + errorDetails;
        } 

        var intentId = result.getIntentId();


        content.set(0,s);
        content.set(1,"[intent: "+intentId+" ]");

        invokeMethod("speech.onSpeech",TextUtils.join(System.lineSeparator(), content));
        println("Stopped");
      })



    }catch(exec:Exception){
      //Log.e("SpeechSDKDemo", "unexpected " + exec.message);
      assert(false);
      invokeMethod("speech.onException", "Exception: "+exec.message);
    }
  }

  fun keywordRecognizer(speechSubscriptionKey:String,serviceRegion:String,lang:String,kwsModelFile:String) {
    val logTag : String = "keyword";
    var continuousListeningStarted : Boolean = false;
    lateinit var reco : SpeechRecognizer;
    lateinit var audioInput : AudioConfig;
    var content :  ArrayList<String> = ArrayList<String>();




    if(continuousListeningStarted) {
      if(reco != null){
        val task : Future<Void> = reco.stopContinuousRecognitionAsync();

        setOnTaskCompletedListener(task, { result ->
          Log.i(logTag, "Continuous recognition stopped.");
          continuousListeningStarted = false;
          azureChannel.invokeMethod("speech.onStartAvailable",null);
        })

      }else{
        continuousListeningStarted = false;
      }

      return;
    }
    
    content.clear();
    try{

      audioInput = AudioConfig.fromStreamInput(createMicrophoneStream());

      var config : SpeechConfig = SpeechConfig.fromSubscription(speechSubscriptionKey, serviceRegion); 

      assert(config != null);

      config.speechRecognitionLanguage = lang;

      reco = SpeechRecognizer(config,audioInput); 

      reco.recognizing.addEventListener({ o, speechRecognitionResultEventArgs->
        val s = speechRecognitionResultEventArgs.getResult().getText()
        content.add(s);
        Log.i(logTag, "Intermediate result received: " + s)
        invokeMethod("speech.onSpeech",TextUtils.join(" ", content));
        content.removeAt(content.size - 1);
      });

      reco.recognizing.addEventListener({ o, speechRecognitionResultEventArgs->
        var s: String;
        if (speechRecognitionResultEventArgs.getResult().getReason() == ResultReason.RecognizedKeyword)
          {
              s = "Keyword: " + speechRecognitionResultEventArgs.getResult().getText();
              Log.i(logTag, "Keyword recognized result received: " + s);
          }
          else
          {
              s = "Recognized: " + speechRecognitionResultEventArgs.getResult().getText();
              Log.i(logTag, "Final result received: " + s);
          }
          content.add(s);
        invokeMethod("speech.onSpeech",s);
      });
      
      var kwsModel = KeywordRecognitionModel.fromFile(copyAssetToCacheAndGetFilePath(kwsModelFile));
      val task : Future<Void> = reco.startKeywordRecognitionAsync(kwsModel);

      
      setOnTaskCompletedListener(task, { result ->
        continuousListeningStarted = true;

        invokeMethod("speech.onStopAvailable",null);
        println("Stopped");
      })


    }catch(exc:Exception){

    }
  } 




   private val s_executorService : ExecutorService = Executors.newCachedThreadPool();



  

   private fun <T> setOnTaskCompletedListener(task:Future<T>, listener: (T) -> Unit){
    s_executorService.submit({ 
      val result = task.get()
      listener(result)
    });
  }


  private interface OnTaskCompletedListener<T> {
    fun onCompleted(taskResult : T);
  }

  private fun setRecognizedText (s : String) {
    azureChannel.invokeMethod("speech.onSpeech",s);
  }

  private fun invokeMethod(method:String, arguments:Any?){

    handler.post{
        azureChannel.invokeMethod(method,arguments); 
    }
  }


  private fun copyAssetToCacheAndGetFilePath(filename : String) : String{
    var cacheFile : File = File(""+getCacheDir() + "/" + filename);
    if (!cacheFile.exists()) {
        try {
            var iS : InputStream = getAssets().open(filename);
            val size : Int = iS.available();
            var buffer : ByteArray = ByteArray(size);
            iS.read(buffer);
            iS.close();
            var fos:FileOutputStream = FileOutputStream(cacheFile);
            fos.write(buffer);
            fos.close();
        }
        catch (e:Exception) {
            throw RuntimeException(e);
        }
    }
    return cacheFile.getPath();
  }
}

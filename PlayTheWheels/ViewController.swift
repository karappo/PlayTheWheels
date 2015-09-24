//
//  ViewController.swift
//  PlayTheWheels
//
//  Created by Naokazu Terada on 2015/08/13.
//  Copyright (c) 2015年 Karappo Inc. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

class ViewController: UIViewController, ESTBeaconManagerDelegate {
  
  // UserDefaults
  let UD = NSUserDefaults.standardUserDefaults()
  let UD_KEY_KONASHI = "konashi"
  let UD_KEY_INSTRUMENT_COLOR_HUE = "instrument_color_hue"
  let UD_KEY_INSTRUMENT_COLOR_SATURATION = "instrument_color_saturation"
  let UD_KEY_EFFECT_COLOR_HUE = "effect_color_hue"
  let UD_KEY_EFFECT_COLOR_SATURATION = "effect_color_saturation"
  let UD_KEY_LED_DIVIDE = "led_divide"
  let UD_KEY_LED_POSITION = "led_position"
  
  @IBOutlet weak var arrow: UIImageView!
  
  // # Konashi Section
  
  @IBOutlet weak var konashiBtn: UIButton!
  
  // # Beacon Section
  
  @IBOutlet weak var beaconDelayLabel: UILabel!
  @IBOutlet weak var beaconDelaySlider: UISlider!
  @IBOutlet weak var beaconReverbLabel: UILabel!
  @IBOutlet weak var beaconReverbSlider: UISlider!
  
  // # Color Section
  
  @IBOutlet weak var colorView: UIView!
  @IBOutlet weak var hueSlider: UISlider!
  @IBOutlet weak var saturationSlider: UISlider!
  @IBOutlet weak var colorView2: UIView!
  @IBOutlet weak var hueSlider2: UISlider!
  @IBOutlet weak var saturationSlider2: UISlider!
  @IBOutlet weak var brightnessLabel: UILabel!
  @IBOutlet weak var divideSlider: UISlider!
  @IBOutlet weak var divideLabel: UILabel!
  @IBOutlet weak var positionSlider: UISlider!
  @IBOutlet weak var positionLabel: UILabel!
  
  var instrumentColor: UIColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
  var effectColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
  
  // # Tone Section
  
  @IBOutlet weak var toneNameBtn: UIButton!
  @IBOutlet weak var tonePlayerTypeLabel: UILabel!
  @IBOutlet weak var toneCountLabel: UILabel!
  enum PlayerType: String {
    case OneShot  = "One Shot"
    case LongShot = "Long Shot"
  }
  var playerType = PlayerType.OneShot
  var toneDirs: [String] = []
  
  // # Effect Section
  
  // EQ
  @IBOutlet weak var eqBypassSwitch: UISwitch!
  @IBOutlet weak var eqFilterTypeBtn: UIButton!
  @IBOutlet weak var eqFrequencySlider: UISlider!
  @IBOutlet weak var eqFrequencyLabel: UILabel!
  @IBOutlet weak var eqBandwidthSlider: UISlider!
  @IBOutlet weak var eqBandwidthLabel: UILabel!
  @IBOutlet weak var eqGainSlider: UISlider!
  @IBOutlet weak var eqGainLabel: UILabel!
  // Delay
  @IBOutlet weak var delaySwitch: UISwitch!
  @IBOutlet weak var delayDryWetSlider: UISlider!
  @IBOutlet weak var delayDelayTimeSlider: UISlider!
  @IBOutlet weak var delayFeedbackSlider: UISlider!
  @IBOutlet weak var delayLowPassCutOffSlider: UISlider!
  @IBOutlet weak var delayDryWetLabel: UILabel!
  @IBOutlet weak var delayDelayTimeLabel: UILabel!
  @IBOutlet weak var delayFeedbackLabel: UILabel!
  @IBOutlet weak var delayLowPassCutOffLabel: UILabel!
  // Reverb
  @IBOutlet weak var reverbSwitch: UISwitch!
  @IBOutlet weak var reverbDryWetSlider: UISlider!
  @IBOutlet weak var reverbDryWetLabel: UILabel!
  @IBOutlet weak var reverbPresetsBtn: UIButton!
  
  // Beacon
  let beaconManager = ESTBeaconManager()
  let beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "B8A63B91-CB83-4701-8093-62084BFA40B4"), identifier: "ranged region")
  let effectBeacons = [
    // major:minor
    "9152:49340": "Distortion",
    "38936:27676": "Delay",
    "30062:7399": "Reverb"
  ]
  
  let FM = NSFileManager.defaultManager()
  
  let MM: CMMotionManager = CMMotionManager()
  let MM_UPDATE_INTERVAL = 0.01 // 更新周期 100Hz
  
  var engine: AVAudioEngine = AVAudioEngine()
  var eq: AVAudioUnitEQ!
  var epParams: AVAudioUnitEQFilterParameters!
  var delay: AVAudioUnitDelay!
  var reverb: AVAudioUnitReverb!
  var mixer: AVAudioMixerNode!
  var longShotPlayers: Array<AVAudioPlayerNode> = []
  var oneShotPlayers: Array<AVAudioPlayerNode> = []
  var audioFiles: Array<AVAudioFile> = []
  var current_index: Int = 0
  let reverbPresetsStrings: Array<String> = [
    "SmallRoom",
    "MediumRoom",
    "LargeRoom",
    "MediumHall",
    "LargeHall",
    "Plate",
    "MediumChamber",
    "LargeChamber",
    "Cathedral",
    "LargeRoom2",
    "MediumHall2",
    "MediumHall3",
    "LargeHall2"
  ]
  let reverbPresetsEnums: Array<AVAudioUnitReverbPreset> = [
    AVAudioUnitReverbPreset.SmallRoom,
    AVAudioUnitReverbPreset.MediumRoom,
    AVAudioUnitReverbPreset.LargeRoom,
    AVAudioUnitReverbPreset.MediumHall,
    AVAudioUnitReverbPreset.LargeHall,
    AVAudioUnitReverbPreset.Plate,
    AVAudioUnitReverbPreset.MediumChamber,
    AVAudioUnitReverbPreset.LargeChamber,
    AVAudioUnitReverbPreset.Cathedral,
    AVAudioUnitReverbPreset.LargeRoom2,
    AVAudioUnitReverbPreset.MediumHall2,
    AVAudioUnitReverbPreset.MediumHall3,
    AVAudioUnitReverbPreset.LargeHall2
  ]
  let eqFilterTypesStrings: Array<String> = [
    "Parametric",
    "LowPass",
    "HighPass",
    "ResonantLowPass",
    "ResonantHighPass",
    "BandPass",
    "BandStop",
    "LowShelf",
    "HighShelf",
    "ResonantLowShelf",
    "ResonantHighShelf"
  ]
  let eqFilterTypesEnums: Array<AVAudioUnitEQFilterType> = [
    AVAudioUnitEQFilterType.Parametric,
    AVAudioUnitEQFilterType.LowPass,
    AVAudioUnitEQFilterType.HighPass,
    AVAudioUnitEQFilterType.ResonantLowPass,
    AVAudioUnitEQFilterType.ResonantHighPass,
    AVAudioUnitEQFilterType.BandPass,
    AVAudioUnitEQFilterType.BandStop,
    AVAudioUnitEQFilterType.LowShelf,
    AVAudioUnitEQFilterType.HighShelf,
    AVAudioUnitEQFilterType.ResonantLowShelf,
    AVAudioUnitEQFilterType.ResonantHighShelf
  ]

  let SLIT_COUNT = 8 // 円周を何分割してplayerPointsにするか
  var prevDeg: Double = 0.0
  var playerPoints: Array<Double> = [] // 分割数に応じて360度を当分した角度を保持しておく配列
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    toneDirs = FM.contentsOfDirectoryAtPath("\(NSBundle.mainBundle().resourcePath!)/tones", error: nil) as! [String]
    
    // Estimote Beacon
    beaconManager.delegate = self
    beaconManager.requestAlwaysAuthorization()
    
    // playerPoints
    let count = Double(SLIT_COUNT)
    for i in 0..<SLIT_COUNT {
      playerPoints += [360.0/count*Double(i)]
    }
    
    // Sound
    
    eq = AVAudioUnitEQ(numberOfBands: 1)
    epParams = eq.bands.first as! AVAudioUnitEQFilterParameters
    setEqFilterTypes(1)
    setEqFrequency(659.255)
    setEqBandwidth(0.05)
    setEqGain(0.0)
    epParams.bypass = eqBypassSwitch.on
    
    delay = AVAudioUnitDelay()
    setDelayWetDry(0)
    setDelayDelayTime(0.4)
    setDelayFeedback(70)
    setDelayLowPassCutOff(700)
    
    reverb = AVAudioUnitReverb()
    setReverbWetDry(0)
    setReverbPresets(4)
    
    setBrightnessMin(0.15)
    
    mixer = AVAudioMixerNode()
    
    engine.attachNode(eq)
    engine.attachNode(delay)
    engine.attachNode(reverb)
    engine.attachNode(mixer)
    
    // AudioPlayerの準備
    // OneShot
    var format: AVAudioFormat = initPlayers(toneDirs.first!)

    engine.connect(mixer, to: eq, format: format)
    engine.connect(eq, to: delay, format: format)
    engine.connect(delay, to: reverb, format: format)
    engine.connect(reverb, to: engine.mainMixerNode, format: format)
    engine.startAndReturnError(nil)
    
    // モーションセンサー
    if MM.deviceMotionAvailable {
      MM.deviceMotionUpdateInterval = MM_UPDATE_INTERVAL
      MM.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
        [weak self] (data: CMDeviceMotion!, error: NSError!) in
        
        let rotation = atan2(data.gravity.x, data.gravity.y) - M_PI
        self?.updateRotation(rotation)
      }
    }
    
    // Color
    hueSlider.setValue(UD.floatForKey(UD_KEY_INSTRUMENT_COLOR_HUE), animated: true)
    saturationSlider.setValue(UD.floatForKey(UD_KEY_INSTRUMENT_COLOR_SATURATION), animated: true)
    hueSlider2.setValue(UD.floatForKey(UD_KEY_EFFECT_COLOR_HUE), animated: true)
    saturationSlider2.setValue(UD.floatForKey(UD_KEY_EFFECT_COLOR_SATURATION), animated: true)
    
    divideSlider.setValue(Float(UD.integerForKey(UD_KEY_LED_DIVIDE)), animated: true)
    changeDivide(divideSlider)
    
    positionSlider.setValue(Float(UD.integerForKey(UD_KEY_LED_POSITION)), animated: true)
    changePosition(positionSlider)
    
    updateInstrumentColor()
    updateEffectColor()
    
    // Konashi関係
    logKonashiStatus()
    
    Konashi.shared().connectedHandler = {
      NSLog("[Konashi] Connected")
    }
    Konashi.shared().disconnectedHandler = {
      NSLog("[Konashi] Disonnected")
      
      // button
      self.konashiBtn.setTitle("Find Konashi", forState: UIControlState.Normal)
    }
    Konashi.shared().readyHandler = {
      NSLog("[Konashi] Ready...")
      self.logKonashiStatus()
      
      let konashiName = Konashi.peripheralName()
      
      self.UD.setObject(konashiName, forKey: self.UD_KEY_KONASHI)
      
      // button
      self.konashiBtn.setTitle(konashiName, forState: UIControlState.Normal)
      
      // Konashi setting
      Konashi.uartMode(KonashiUartMode.Enable, baudrate: KonashiUartBaudrate.Rate9K6)
      Konashi.pinMode(KonashiDigitalIOPin.DigitalIO1, mode: KonashiPinMode.Output)
      Konashi.pinMode(KonashiDigitalIOPin.DigitalIO2, mode: KonashiPinMode.Output)
      
      // LED2を点灯
      Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO1, value: KonashiLevel.High)
      
      self.updateInstrumentColor()
      self.updateEffectColor()
    }
    Konashi.shared().uartRxCompleteHandler = {(data: NSData!) -> Void in
      
      // LED3を消灯
      Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO2, value: KonashiLevel.Low)
      
//      NSLog("[Konashi] UartRx \(data.description)")
    }
    
    // UserDefaultsから前回接続したKonashiを読み、接続を試みる
    if let previously_connected_konashi = UD.stringForKey(UD_KEY_KONASHI) {
      NSLog("[Konashi] Auto connecting to \(previously_connected_konashi)...")
      if Konashi.findWithName(previously_connected_konashi) == KonashiResult.Success {
        NSLog("[Konashi] Auto connect successed!")
      }
      else {
        NSLog("[Konashi] Auto connect failed!")
      }
      
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    beaconManager.startRangingBeaconsInRegion(beaconRegion)
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    beaconManager.stopRangingBeaconsInRegion(beaconRegion)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func logKonashiStatus() {
    NSLog("--------------------------------")
    NSLog("[Konashi] connected: \(Konashi.isConnected())")
    NSLog("[Konashi] ready: \(Konashi.isReady())")
    NSLog("[Konashi] module: \(Konashi.peripheralName())")
    NSLog("--------------------------------")
  }
  // Beacon
  func beaconManager(manager: AnyObject!, didRangeBeacons beacons: [AnyObject]!,
    inRegion region: CLBeaconRegion!) {
      if let _beacons = beacons as? [CLBeacon] {
        var str: String = ""
        for _beacon: CLBeacon in _beacons {
          let beaconKey = "\(_beacon.major):\(_beacon.minor)"
          if let effectName = effectBeacons[beaconKey] as String! {
            let accuracy = Float(Int(_beacon.accuracy * 100.0)) / 100.0 // 小数点第１位まで
            str += "\(effectName): \(accuracy)\n"
            
            // accuracy: 5 - 0 => 0 - 50 に変換
            // TODO やり方変える
//            var dryWet = Float(50 - _beacon.accuracy * 10)
            var dryWet = Float(_beacon.accuracy * 10)
            dryWet = max(min(50, dryWet), 0) // 範囲内に収める
            
            switch effectName {
              case "Delay":
                beaconDelayLabel.text = "\(accuracy)"
                beaconDelaySlider.setValue(accuracy, animated: true)
                if delaySwitch.on {
                  setDelayWetDry(dryWet)
                  delayDryWetSlider.setValue(dryWet, animated: true)
                }
              case "Reverb":
                beaconReverbLabel.text = "\(accuracy)"
                beaconReverbSlider.setValue(accuracy, animated: true)
                if reverbSwitch.on {
                  setReverbWetDry(dryWet)
                  reverbDryWetSlider.setValue(dryWet, animated: true)
                }
              default :
                break
            }
          }
        }
      }
  }
  
  // oldMin～oldMax内のoldValをnewMin〜newMax内の値に変換して返す
  func map(oldVal: Float, oldMin: Float, oldMax: Float, newMin: Float, newMax: Float) -> Float{
    return (((oldVal - oldMin) * (newMax - newMin)) / (oldMax - oldMin)) + newMin
  }
  
  
  @IBAction func tapFind(sender: UIButton) {
    if Konashi.isConnected() {
      var alertController = UIAlertController(title: "Disconnect Konashi", message: "You are disconnecting \(Konashi.peripheralName()). Are you sure?", preferredStyle: .Alert)
      
      let otherAction = UIAlertAction(title: "Disconnect", style: .Default) {
        action in
          NSLog("[Konashi] Disconnect \(Konashi.peripheralName())")
          // LED2を消灯
          Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO1, value: KonashiLevel.Low)
          // 接続解除
          Konashi.disconnect()
      }
      let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) {
        action in
          NSLog("[Konashi] Cancel disconnecting \(Konashi.peripheralName())")
      }
      
      // addActionした順に左から右にボタンが配置されます
      alertController.addAction(otherAction)
      alertController.addAction(cancelAction)
      
      presentViewController(alertController, animated: true, completion: nil)

    }
    else {
      Konashi.find()
    }
    
  }
  
  // Color
  
  @IBAction func changeHue(sender: UISlider) {
    UD.setObject(CGFloat(sender.value), forKey: UD_KEY_INSTRUMENT_COLOR_HUE)
    updateInstrumentColor()
  }
  @IBAction func changeSaturation(sender: UISlider) {
    UD.setObject(CGFloat(sender.value), forKey: UD_KEY_INSTRUMENT_COLOR_SATURATION)
    updateInstrumentColor()
  }
  @IBAction func tapBlack(sender: UIButton) {
    uart("i:000,000,000;\n")
    instrumentColor = UIColor(hue: 0.0, saturation: 0.0, brightness: 0.0, alpha: 1.0)
    colorView.backgroundColor = instrumentColor
  }
  
  @IBAction func changeHue2(sender: UISlider) {
    UD.setObject(CGFloat(sender.value), forKey: UD_KEY_EFFECT_COLOR_HUE)
    updateEffectColor()
  }
  @IBAction func changeSaturation2(sender: UISlider) {
    UD.setObject(CGFloat(sender.value), forKey: UD_KEY_EFFECT_COLOR_SATURATION)
    updateEffectColor()
  }
  @IBAction func tapBlack2(sender: UIButton) {
    uart("e:000,000,000;\n")
    effectColor = UIColor(hue: 0.0, saturation: 0.0, brightness: 0.0, alpha: 1.0)
    colorView2.backgroundColor = effectColor
  }
  
  @IBAction func changeBrightnessMin(sender: UISlider) {
    setBrightnessMin(sender.value)
  }
  func setBrightnessMin(val: Float) {
    brightnessLabel.text = "\(val)"
    uart("b:\(val);")
  }
  
  @IBAction func changeDivide(sender: UISlider) {
    let val = Int(sender.value)
    UD.setObject(val, forKey: UD_KEY_LED_DIVIDE)
    divideLabel.text = "\(val)"
    uart("d:\(val);")
  }
  @IBAction func changePosition(sender: UISlider) {
    let val = Int(sender.value)
    UD.setObject(val, forKey: UD_KEY_LED_POSITION)
    positionLabel.text = "\(val)"
    uart("p:\(Float(val)/100);")
  }
  
  
  func updateInstrumentColor() {
    let hue = CGFloat(UD.floatForKey(UD_KEY_INSTRUMENT_COLOR_HUE))
    let saturation = CGFloat(UD.floatForKey(UD_KEY_INSTRUMENT_COLOR_SATURATION))
    instrumentColor = UIColor(hue: hue, saturation: saturation, brightness: 1.0, alpha: 1.0)
    colorView.backgroundColor = instrumentColor
    
    let r = NSString(format: "%03d", Int(instrumentColor.getRed()))
    let g = NSString(format: "%03d", Int(instrumentColor.getGreen()))
    let b = NSString(format: "%03d", Int(instrumentColor.getBlue()))
    uart("i:\(r).\(g).\(b);")
  }
  func updateEffectColor() {
    let hue = CGFloat(UD.floatForKey(UD_KEY_EFFECT_COLOR_HUE))
    let saturation = CGFloat(UD.floatForKey(UD_KEY_EFFECT_COLOR_SATURATION))
    effectColor = UIColor(hue: hue, saturation: saturation, brightness: 1.0, alpha: 1.0)
    colorView2.backgroundColor = effectColor

    let r = NSString(format: "%03d", Int(effectColor.getRed()))
    let g = NSString(format: "%03d", Int(effectColor.getGreen()))
    let b = NSString(format: "%03d", Int(effectColor.getBlue()))
    uart("e:\(r).\(g).\(b);")
  }
  
  // Tone
  
  @IBAction func tapToneName(sender: UIButton) {
    let initial: Int = find(toneDirs, toneNameBtn.titleLabel!.text!)!
    ActionSheetStringPicker.showPickerWithTitle("Tone", rows: toneDirs, initialSelection: initial, doneBlock: {
      picker, value, index in
        let key: String = "\(index)"
        self.initPlayers(key)
        return
    }, cancelBlock: { ActionStringCancelBlock in return }, origin: sender)
  }
  
  // AVAudioPlayerNode の生成やAudioFileの設定
  // その他のノードの初期化のために、最初のAudioFileのAVAudioFormatを返す
  func initPlayers(toneDir: String) -> AVAudioFormat!{
    
    toneNameBtn.setTitle(toneDir, forState: UIControlState.Normal)
    
    var format: AVAudioFormat! = nil
    if 1<audioFiles.count {
      audioFiles.removeAll(keepCapacity: false)
    }
    
    // stop and remove players
    for player in oneShotPlayers {
      if player.playing {
        player.stop()
        engine.disconnectNodeInput(player)
      }
    }
    for player in longShotPlayers {
      if player.playing {
        player.stop()
        engine.disconnectNodeInput(player)
      }
    }
    // remove players
    oneShotPlayers.removeAll(keepCapacity: false)
    longShotPlayers.removeAll(keepCapacity: false)
    
    // ------------
    
    let items = FM.contentsOfDirectoryAtPath("\(NSBundle.mainBundle().resourcePath!)/tones/\(toneDir)", error: nil)
    
    let itemsCount = items!.count
    toneCountLabel.text = "\(itemsCount)"
    if 0 < itemsCount {
      
      // 左用の音かどうか判定（Lで終わっていたら左）
      var regex = NSRegularExpression(pattern: "L$", options: NSRegularExpressionOptions.allZeros, error: nil)
      let isLeft: Bool = regex?.firstMatchInString(toneDir, options: NSMatchingOptions.allZeros, range: NSMakeRange(0, count(toneDir))) != nil
      
      // switch player type
      
      if itemsCount == 2 {
        setTonePlayerType(PlayerType.LongShot)
        
        let _tones = isLeft ? ["02","01"] : ["01","02"]
        
        for (index, file) in enumerate(_tones) {
          let filePath: String = NSBundle.mainBundle().pathForResource("tones/\(toneDir)/\(file)", ofType: "wav")!
          let fileURL: NSURL = NSURL(fileURLWithPath: filePath)!
          let audioFile = AVAudioFile(forReading: fileURL, error: nil)
          let audioFileBuffer = AVAudioPCMBuffer(PCMFormat: audioFile.processingFormat, frameCapacity: UInt32(audioFile.length))
          audioFile.readIntoBuffer(audioFileBuffer, error: nil)
          
          let player = AVAudioPlayerNode()
          engine.attachNode(player)
          engine.connect(player, to: mixer, format: audioFile.processingFormat)
          player.volume = 0.0
          player.play()
          player.scheduleBuffer(audioFileBuffer, atTime: nil, options:.Loops, completionHandler: nil)
          
          longShotPlayers += [player]
          
          if format == nil {
            format = audioFile.processingFormat
          }
        }
      }
      else {
        setTonePlayerType(PlayerType.OneShot)
        
        for i in 1..<itemsCount+1 {
          let num = NSString(format: "%02d", isLeft ? itemsCount+1 - i : i) // 左車輪の音だったら反転し、２桁で0埋め
          let url = NSBundle.mainBundle().pathForResource("tones/\(toneDir)/\(num)", ofType: "wav")!
          let audioFile = AVAudioFile(forReading: NSURL(fileURLWithPath: url), error: nil)
          audioFiles += [audioFile]
          
          let player = AVAudioPlayerNode()
          engine.attachNode(player)
          engine.connect(player, to: mixer, format: audioFile.processingFormat)
          player.volume = 9.0
          
          oneShotPlayers += [player]
          
          if format == nil {
            format = audioFile.processingFormat
          }
        }
      }
    }
    return format
  }
  
  func setTonePlayerType(type: PlayerType) {
    playerType = type
    tonePlayerTypeLabel.text = type.rawValue
  }
  
  // EQ
  @IBAction func changeEqBypass(sender: UISwitch) {
    epParams.bypass = sender.on
  }
  @IBAction func tapFilterType(sender: UIButton) {
    let initial: Int = find(self.eqFilterTypesStrings, eqFilterTypeBtn.titleLabel!.text!)!
    ActionSheetStringPicker.showPickerWithTitle("EQ FilterType", rows: eqFilterTypesStrings, initialSelection: initial, doneBlock: {
      picker, value, index in
      self.setEqFilterTypes(value)
      return
      }, cancelBlock: { ActionStringCancelBlock in return }, origin: sender)
  }
  func setEqFilterTypes(index: Int) {
    epParams.filterType = eqFilterTypesEnums[index]
    eqFilterTypeBtn.setTitle(eqFilterTypesStrings[index], forState: UIControlState.Normal)
  }
  @IBAction func changeEqFrequency(sender: UISlider) {
    setEqFrequency(sender.value)
  }
  func setEqFrequency(val: Float) {
    epParams.frequency = val
    eqFrequencyLabel.text = "\(val)"
  }
  @IBAction func changeEqBandwidth(sender: UISlider) {
    setEqBandwidth(sender.value)
  }
  func setEqBandwidth(val: Float) {
    epParams.bandwidth = val
    eqBandwidthLabel.text = "\(val)"
  }
  @IBAction func changeEqGain(sender: UISlider) {
    setEqGain(sender.value)
  }
  func setEqGain(val: Float) {
    epParams.gain = val
    eqGainLabel.text = "\(val)"
  }
  
  // Delay
  @IBAction func changeDelayWetDry(sender: UISlider) {
    setDelayWetDry(sender.value)
  }
  func setDelayWetDry(val: Float) {
    delay.wetDryMix = val
    delayDryWetLabel.text = "\(val)"
  }
  @IBAction func changeDelayDelayTime(sender: UISlider) {
    setDelayDelayTime(sender.value)
  }
  func setDelayDelayTime(val: Float) {
    delay.delayTime = NSTimeInterval(val)
    delayDelayTimeLabel.text = "\(val)"
  }
  @IBAction func changeDelayFeedback(sender: UISlider) {
    setDelayFeedback(sender.value)
  }
  func setDelayFeedback(val: Float) {
    delay.feedback = val
    delayFeedbackLabel.text = "\(val)"
  }
  @IBAction func changeDelayLowPassCutOff(sender: UISlider) {
    setDelayLowPassCutOff(sender.value)
  }
  func setDelayLowPassCutOff(val: Float) {
    delay.lowPassCutoff = val
    delayLowPassCutOffLabel.text = "\(val)"
  }
  
  // Reverb
  @IBAction func changeReverbWetDry(sender: UISlider) {
    setReverbWetDry(sender.value)
  }
  func setReverbWetDry(val: Float) {
    reverb.wetDryMix = val
    reverbDryWetLabel.text = "\(val)"
  }
  @IBAction func tapReverbPresets(sender: UIButton) {
    ActionSheetStringPicker.showPickerWithTitle("Reverb presets", rows: reverbPresetsStrings, initialSelection: find(self.reverbPresetsStrings, reverbPresetsBtn.titleLabel!.text!)!, doneBlock: {
      picker, value, index in
        self.setReverbPresets(value)
        return
    }, cancelBlock: { ActionStringCancelBlock in return }, origin: sender)
  }
  func setReverbPresets(index: Int) {
    reverb.loadFactoryPreset(reverbPresetsEnums[index])
    reverbPresetsBtn.setTitle(reverbPresetsStrings[index], forState: UIControlState.Normal)
  }
  
  // シリアル通信で送信
  func uart(key: String, value: String){
    if Konashi.isConnected() {
      let command = "\(key)=\(value);"
      NSLog(command)
      // LED3を点灯
      Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO2, value: KonashiLevel.High)
      let res = Konashi.uartWriteString(command)
      if res == KonashiResult.Success {
        NSLog("[Konashi] KonashiResultSuccess")
      }
      else {
        NSLog("[Konashi] KonashiResultFailure")
      }
    }
  }
  func uart(str: String){
    if Konashi.isConnected() {
      NSLog(str)
      // LED3を点灯
      Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO2, value: KonashiLevel.High)
      let res = Konashi.uartWriteString(str)
      if res == KonashiResult.Success {
        NSLog("[Konashi] KonashiResultSuccess")
      }
      else {
        NSLog("[Konashi] KonashiResultFailure")
      }
    }
  }
  
  func updateRotation(radian: Double) {
    
    let currentDeg = self.radiansToDegrees(radian)
//    let variation = Float(prevDeg - current_deg)
    let _variation = variation(prevDeg, current: currentDeg)
    
    arrow.transform = CGAffineTransformMakeRotation(CGFloat(radian))
    
    switch playerType {
    case PlayerType.OneShot:
      // OneShot
      let passed_slit = slitIndexInRange(prevDeg, current: currentDeg)
      
      if 0 < passed_slit.count {
        
        let audioIndexes = Array(0..<audioFiles.count)
        var passed_players: Array<Int> = []
        
        for i in current_index..<current_index+passed_slit.count {
          passed_players += [audioIndexes.get(i)!]
        }
        let _idx = current_index + passed_slit.count*(0<_variation ? 1 : -1)
        current_index = audioFiles.relativeIndex(_idx)
        
        
        for index in passed_players {
          // Sound
          let audioFile: AVAudioFile = audioFiles[index] as AVAudioFile
          let player: AVAudioPlayerNode = oneShotPlayers[index] as AVAudioPlayerNode
          if player.playing {
            player.stop()
          }
          
          // playerにオーディオファイルを設定　※ 再生直前にセットしないと再生されない？
          player.scheduleFile(audioFile, atTime: nil, completionHandler: nil)
          
          // 再生開始
          player.play()
          
          // Konashi通信
          uart("s:;")
        }
      }
    case PlayerType.LongShot:
      // LongShot
      // 変化量
      // TODO 実際の車輪のスピードの範囲とうまくマッピングする
      if 0 < _variation {
        longShotPlayers[0].volume = 0
        longShotPlayers[1].volume = abs(_variation)
      }
      else {
        longShotPlayers[0].volume = abs(_variation)
        longShotPlayers[1].volume = 0
      }
      // TODO Konashi通信
    default:
      NSLog("Error")
    }
    
    prevDeg = currentDeg
  }
  
  func radiansToDegrees(value: Double) -> Double {
    return value * 180.0 / M_PI + 180.0
  }
  
  // 0 <= value < 360 の範囲に値を収める
  private func restrict(value: Double) -> Double {
    var deg = value
    if deg < 0.0 {
      deg += 360
    }
    else if 360 < deg {
      deg -= 360*(floor(deg/360))
    }
    return deg
  }
  
  // 引数で与えた角度の中に含まれるスリットのindexを配列にして返す
  private func slitIndexInRange(prev: Double, current: Double) -> Array<Int> {
    if prev == current {
      return []
    }
    
    let _prev = restrict(prev)
    let _current = restrict(current)
    let _min = min(_prev, _current)
    let _max = max(_prev, _current)
    var result: Array<Int> = [] // range内にあるslit
    var rest: Array<Int> = [] // range外にあるslit
    
    for i in 0..<SLIT_COUNT {
      let slit = playerPoints[i]
      if _min <= slit && slit <= _max {
        result += [i]
      }
      else {
        rest += [i]
      }
    }
    
    // 回転が早く通過slitが多い場合は、どちら向きか判定しにくいので、数の少ない方を返す
    return ((rest.count < result.count) ? rest : result)
  }
  
  // 変化量を計算（359°->2°などに変化した時に正しく回転方向を算出）
  // [left wheel]  forward: plus, back: minus
  // [right wheel] forward: minus, back: plus
  private func variation(prev: Double, current: Double) -> Float {
    let diff = abs(prev - current)
    
    if 180 < diff {
      if 180 < prev {
        return Float((360 - prev) + current)
      }
      else {
        return Float((360.0 - current) + prev)
      }
    }
    return Float(prev - current)
  }
}

internal extension Array {
  
  //  If the index is out of bounds it's assumed relative
  func relativeIndex (index: Int) -> Int {
    var _index = (index % count)
    
    if _index < 0 {
      _index = count + _index
    }
    
    return _index
  }
  
  func get (index: Int) -> Element? {
    let _index = relativeIndex(index)
    return _index < count ? self[_index] : nil
  }
}

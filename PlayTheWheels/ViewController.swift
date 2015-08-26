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

  @IBOutlet weak var arrow: UIImageView!
  @IBOutlet weak var led1: UIView!
  @IBOutlet weak var led2: UIView!
  @IBOutlet weak var led3: UIView!
  @IBOutlet weak var led4: UIView!
  @IBOutlet weak var led5: UIView!
  @IBOutlet weak var led6: UIView!
  @IBOutlet weak var led7: UIView!
  @IBOutlet weak var led8: UIView!
  
  // # Beacon Section
  
  @IBOutlet weak var beaconDistortionLabel: UILabel!
  @IBOutlet weak var beaconDistortionSlider: UISlider!
  @IBOutlet weak var beaconDelayLabel: UILabel!
  @IBOutlet weak var beaconDelaySlider: UISlider!
  @IBOutlet weak var beaconReverbLabel: UILabel!
  @IBOutlet weak var beaconReverbSlider: UISlider!
  
  // # Tone Section
  
  @IBOutlet weak var toneNameBtn: UIButton!
  let tones = [
    // [label]: [directory]
    "Blue Ballad - L": "Blue Ballad/hi",
    "Blue Ballad - R": "Blue Ballad/low",
    "Pianokind - L": "Pianokind/hi",
    "Pianokind - R": "Pianokind/low",
    "Soufeed 1 - L": "Soufeed 1/hi",
    "Soufeed 1 - R": "Soufeed 1/low"
  ]
  var toneDir: String!
  
  // # Effect Section
  
  // Distortion
  @IBOutlet weak var distortionSwitch: UISwitch!
  @IBOutlet weak var distortionDryWetSlider: UISlider!
  @IBOutlet weak var distortionPreGainSlider: UISlider!
  @IBOutlet weak var distortionDryWetLabel: UILabel!
  @IBOutlet weak var distortionPresetsBtn: UIButton!
  @IBOutlet weak var distortionPreGainLabel: UILabel!
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
  
  let MM: CMMotionManager = CMMotionManager()
  let MM_UPDATE_INTERVAL = 0.01 // 更新周期 100Hz
  
  var engine: AVAudioEngine!
  var reverb: AVAudioUnitReverb!
  var distortion: AVAudioUnitDistortion!
  var delay: AVAudioUnitDelay!
  var mixer: AVAudioMixerNode!
  var players: Array<AVAudioPlayerNode> = []
  var audioFiles: Array<AVAudioFile> = []
  let distortionPresetsStrings: Array<String> = [
    "DrumsBitBrush",
    "DrumsBufferBeats",
    "DrumsLoFi",
    "MultiBrokenSpeaker",
    "MultiCellphoneConcert",
    "MultiDecimated1",
    "MultiDecimated2",
    "MultiDecimated3",
    "MultiDecimated4",
    "MultiDistortedFunk",
    "MultiDistortedCubed",
    "MultiDistortedSquared",
    "MultiEcho1",
    "MultiEcho2",
    "MultiEchoTight1",
    "MultiEchoTight2",
    "MultiEverythingIsBroken",
    "SpeechAlienChatter",
    "SpeechCosmicInterference",
    "SpeechGoldenPi",
    "SpeechRadioTower",
    "SpeechWaves"
  ]
  
  let distortionPresetsEnums: Array<AVAudioUnitDistortionPreset> = [
    AVAudioUnitDistortionPreset.DrumsBitBrush,
    AVAudioUnitDistortionPreset.DrumsBufferBeats,
    AVAudioUnitDistortionPreset.DrumsLoFi,
    AVAudioUnitDistortionPreset.MultiBrokenSpeaker,
    AVAudioUnitDistortionPreset.MultiCellphoneConcert,
    AVAudioUnitDistortionPreset.MultiDecimated1,
    AVAudioUnitDistortionPreset.MultiDecimated2,
    AVAudioUnitDistortionPreset.MultiDecimated3,
    AVAudioUnitDistortionPreset.MultiDecimated4,
    AVAudioUnitDistortionPreset.MultiDistortedFunk,
    AVAudioUnitDistortionPreset.MultiDistortedCubed,
    AVAudioUnitDistortionPreset.MultiDistortedSquared,
    AVAudioUnitDistortionPreset.MultiEcho1,
    AVAudioUnitDistortionPreset.MultiEcho2,
    AVAudioUnitDistortionPreset.MultiEchoTight1,
    AVAudioUnitDistortionPreset.MultiEchoTight2,
    AVAudioUnitDistortionPreset.MultiEverythingIsBroken,
    AVAudioUnitDistortionPreset.SpeechAlienChatter,
    AVAudioUnitDistortionPreset.SpeechCosmicInterference,
    AVAudioUnitDistortionPreset.SpeechGoldenPi,
    AVAudioUnitDistortionPreset.SpeechRadioTower,
    AVAudioUnitDistortionPreset.SpeechWaves
  ]
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

  let SLIT_COUNT = 8
  var leds: Array<UIView> = []
  var prevDeg: Double = 0.0
  var slitDegs: Array<Double> = [] // 分割数に応じて360度を当分した角度を保持しておく配列
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Estimote Beacon
    beaconManager.delegate = self
    beaconManager.requestAlwaysAuthorization()
    
    // 画面上のLEDの準備
    let count = Double(SLIT_COUNT)
    for i in 0..<SLIT_COUNT {
      slitDegs += [360.0/count*Double(i)]
    }
    leds = [
      led1,
      led2,
      led3,
      led4,
      led5,
      led6,
      led7,
      led8
    ]
    
    engine = AVAudioEngine()
    
    distortion = AVAudioUnitDistortion()
    setDistortionWetDry(0)
    setDistortionPresets(2)
    setDistortionPreGain(-30)
    
    delay = AVAudioUnitDelay()
    setDelayWetDry(0)
    setDelayDelayTime(0.2)
    setDelayFeedback(-55)
    setDelayLowPassCutOff(1500)
    
    reverb = AVAudioUnitReverb()
    setReverbWetDry(0)
    setReverbPresets(4)
    
    mixer = AVAudioMixerNode()
    
    engine.attachNode(distortion)
    engine.attachNode(delay)
    engine.attachNode(reverb)
    engine.attachNode(mixer)
    
    // AudioPlayerの準備
    var format: AVAudioFormat = setAudioFile("Blue Ballad - R")
    for i in 0..<SLIT_COUNT {
      
      let player = AVAudioPlayerNode()
      player.volume = 9.0
      engine.attachNode(player)
      
      engine.connect(player, to: mixer, format: format)
      
      players += [player]
    }
    
    engine.connect(mixer, to: distortion, format: format)
    engine.connect(distortion, to: delay, format: format)
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
    
    // Konashi関係
    NSLog("[Konashi] isConnected:\(Konashi.isConnected())")
    
    Konashi.shared().connectedHandler = {
      NSLog("[Konashi] Connected")
    }
    Konashi.shared().disconnectedHandler = {
      NSLog("[Konashi] Disonnected")
    }
    Konashi.shared().readyHandler = {
      NSLog("[Konashi] Ready...")
      
      Konashi.uartMode(KonashiUartMode.Enable, baudrate: KonashiUartBaudrate.Rate9K6)

      // LED2を点灯させる
      Konashi.pinMode(KonashiDigitalIOPin.DigitalIO1, mode: KonashiPinMode.Output)
      Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO1, value: KonashiLevel.High)
    }
    Konashi.shared().uartRxCompleteHandler = {(data: NSData!) -> Void in
      NSLog("[Konashi] UartRx \(data.description)")
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
            var dryWet = Float(50 - _beacon.accuracy * 10)
            dryWet = max(min(50, dryWet), 0) // 範囲内に収める
            
            switch effectName {
              case "Distortion":
                beaconDistortionLabel.text = "\(accuracy)"
                beaconDistortionSlider.setValue(accuracy, animated: true)
                if distortionSwitch.on {
                  setDistortionWetDry(dryWet)
                  distortionDryWetSlider.setValue(dryWet, animated: true)
                }
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
    Konashi.find()
  }
  
  @IBAction func tapR(sender: UIButton) {
    uart("255.000.000\n")
  }
  @IBAction func tapG(sender: UIButton) {
    uart("000.255.000\n")
  }
  @IBAction func tapB(sender: UIButton) {
    uart("000.000.255\n")
  }
  
  // Tone
  
  @IBAction func tapToneName(sender: UIButton) {
    let keys: Array = Array(tones.keys)
    let initial: Int = find(keys, toneNameBtn.titleLabel!.text!)!
    ActionSheetStringPicker.showPickerWithTitle("Tone", rows: keys, initialSelection: initial, doneBlock: {
      picker, value, index in
        let key: String = "\(index)"
        self.setAudioFile(key)
        return
    }, cancelBlock: { ActionStringCancelBlock in return }, origin: sender)
  }
  
  func setAudioFile(key: String) -> AVAudioFormat!{
    var format: AVAudioFormat! = nil
    audioFiles = []
    
    self.toneNameBtn.setTitle(key, forState: UIControlState.Normal)
    
    toneDir = tones[key]
    
    for i in 0..<SLIT_COUNT {
      let audioFile = AVAudioFile(forReading: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("tones/\(toneDir!)/\(i)", ofType: "wav")!), error: nil)
      audioFiles += [audioFile]
      if format == nil {
        format = audioFile.processingFormat
      }
    }
    return format
  }
  
  
  // Distortion
  @IBAction func changeDistortionWetDry(sender: UISlider) {
    setDistortionWetDry(sender.value)
  }
  func setDistortionWetDry(val: Float) {
    distortion.wetDryMix = val
    distortionDryWetLabel.text = "\(val)"
  }
  @IBAction func tapDistortionPresets(sender: UIButton) {
    let initial: Int = find(self.distortionPresetsStrings, distortionPresetsBtn.titleLabel!.text!)!
    ActionSheetStringPicker.showPickerWithTitle("Distortion presets", rows: distortionPresetsStrings, initialSelection: initial, doneBlock: {
      picker, value, index in
        self.setDistortionPresets(value)
        return
      }, cancelBlock: { ActionStringCancelBlock in return }, origin: sender)
  }
  func setDistortionPresets(index: Int) {
    distortion.loadFactoryPreset(distortionPresetsEnums[index])
    distortionPresetsBtn.setTitle(distortionPresetsStrings[index], forState: UIControlState.Normal)
  }
  @IBAction func changeDistortionPreGain(sender: UISlider) {
    setDistortionPreGain(sender.value)
  }
  func setDistortionPreGain(val: Float) {
    distortion.preGain = val
    distortionPreGainLabel.text = "\(val)"
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
  func uart(str: String){
    if Konashi.isConnected() {
      let res = Konashi.uartWriteString(str)
      if res == KonashiResult.Success {
//        NSLog("[Konashi] KonashiResultSuccess")
      }
      else {
        NSLog("[Konashi] KonashiResultFailure")
      }
    }
  }
  
  func updateRotation(radian: Double) {
    let current_deg = self.radiansToDegrees(radian)
    let passed_index = self.getSlitIndexInRange(self.prevDeg, current: current_deg)
    if 0 < passed_index.count {
      for slit_index in passed_index {
        // スクリーンのLED
        let led = leds[slit_index]
        activate(led)
        
        // Sound
        let audioFile: AVAudioFile = audioFiles[slit_index] as AVAudioFile
        let player: AVAudioPlayerNode = players[slit_index] as AVAudioPlayerNode
        if player.playing {
          player.stop()
        }
        
        // playerにオーディオファイルを設定
        player.scheduleFile(audioFile, atTime: nil, completionHandler: nil)
        
        // 再生開始
        player.play()
        
        // Konashi通信
        
        // slit位置に応じて色を決定
        let h = CGFloat(Float(slit_index)/Float(SLIT_COUNT))
        let slitColor: UIColor = UIColor(hue: h, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        // RGB値を3桁ゼロ埋めで取得
        let r = NSString(format: "%03d", Int(slitColor.getRed()))
        let g = NSString(format: "%03d", Int(slitColor.getGreen()))
        let b = NSString(format: "%03d", Int(slitColor.getBlue()))
        
        uart("\(r).\(g).\(b)\n")
      }
    }
    prevDeg = current_deg
    
    arrow.transform = CGAffineTransformMakeRotation(CGFloat(radian))
  }
  
  // LEDを点灯させる（少ししたら自動で消灯）
  func activate(led: UIView) {
    led.alpha = 1
    var dic: NSDictionary = NSDictionary(dictionary: ["led": led])
    NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "onTimer:", userInfo: dic, repeats: false)
  }
  func onTimer(timer : NSTimer) {
    let led = timer.userInfo!.objectForKey("led") as! UIView
    led.alpha = 0.3
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
  private func getSlitIndexInRange(prev: Double, current: Double) -> Array<Int> {
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
      let slit = slitDegs[i]
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
}


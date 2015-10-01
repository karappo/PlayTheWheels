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
  
  var devices = NSMutableDictionary()
  var colors = NSMutableDictionary()
  
  
  @IBOutlet weak var arrow: UIImageView!
  
  // # Konashi Section
  
  @IBOutlet weak var konashiBtn: UIButton!
  var konashiBtnDefaultLabel = "Find Konashi"
  var manualDisconnection: Bool = false // Disconnectされた際に手動で切断されたのかどうかを判定するためのフラグ
  var connectionCheckTimer: NSTimer!
  var lastSendedCommand: NSString!
  @IBOutlet weak var uuidLabel: UILabel!
  
  // # Beacon Section
  
  @IBOutlet weak var beaconSliderBlueberry1: UISlider!
  @IBOutlet weak var beaconSliderBlueberry2: UISlider!
  @IBOutlet weak var beaconSliderIce1: UISlider!
  @IBOutlet weak var beaconSliderIce2: UISlider!
  @IBOutlet weak var beaconSliderMint1: UISlider!
  @IBOutlet weak var beaconSliderMint2: UISlider!
  @IBOutlet weak var beaconSwitchBlueberry1: UISwitch!
  @IBOutlet weak var beaconSwitchBlueberry2: UISwitch!
  @IBOutlet weak var beaconSwitchIce1: UISwitch!
  @IBOutlet weak var beaconSwitchIce2: UISwitch!
  @IBOutlet weak var beaconSwitchMint1: UISwitch!
  @IBOutlet weak var beaconSwitchMint2: UISwitch!
  
  
  // # Color Section
  
  @IBOutlet weak var colorView: UIView!
  @IBOutlet weak var hueSlider: UISlider!
  @IBOutlet weak var hueLabel: UILabel!
  @IBOutlet weak var saturationSlider: UISlider!
  @IBOutlet weak var saturationLabel: UILabel!
  @IBOutlet weak var colorView2: UIView!
  @IBOutlet weak var hueSlider2: UISlider!
  @IBOutlet weak var hueLabel2: UILabel!
  @IBOutlet weak var saturationSlider2: UISlider!
  @IBOutlet weak var saturationLabel2: UILabel!
  @IBOutlet weak var brightnessLabel: UILabel!
  @IBOutlet weak var brightnessSlider: UISlider!
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
  
  // Delay
  @IBOutlet weak var delayDryWetSlider: UISlider!
  @IBOutlet weak var delayDelayTimeSlider: UISlider!
  @IBOutlet weak var delayFeedbackSlider: UISlider!
  @IBOutlet weak var delayLowPassCutOffSlider: UISlider!
  @IBOutlet weak var delayDryWetLabel: UILabel!
  @IBOutlet weak var delayDelayTimeLabel: UILabel!
  @IBOutlet weak var delayFeedbackLabel: UILabel!
  @IBOutlet weak var delayLowPassCutOffLabel: UILabel!
  
  // Beacon
  let beaconManager = ESTBeaconManager()
  let beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "B8A63B91-CB83-4701-8093-62084BFA40B4"), identifier: "ranged region")
  let effectBeacons = [
    // "major:minor":"key"
    "9152:49340" :"blueberry1",
    "21461:51571":"blueberry2",
    "30062:7399" :"ice1",
    "13066:17889":"ice2",
    "38936:27676":"mint1",
    "4274:29174" :"mint2"
  ]
  var beaconUIs:[String: [AnyObject]]!
  
  let FM = NSFileManager.defaultManager()
  
  let MM: CMMotionManager = CMMotionManager()
  let MM_UPDATE_INTERVAL = 0.01 // 更新周期 100Hz
  
  var engine: AVAudioEngine = AVAudioEngine()
  var delay: AVAudioUnitDelay!
  var mixer: AVAudioMixerNode!
  var players: Array<AVAudioPlayerNode> = []
  var layeredPlayers: Array<AVAudioPlayerNode> = []
  var layeredPlayerVol: Float = 0.0
  var audioFiles: Array<AVAudioFile> = []
  var current_index: Int = 0

  let SLIT_COUNT = 8 // 円周を何分割してplayerPointsにするか
  var prevDeg: Double = 0.0
  var playerPoints: Array<Double> = [] // 分割数に応じて360度を当分した角度を保持しておく配列
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // initialize
    // ==========
    
    // "{IPHONE-UUIDString}":["tone":"{TONE-NAME}","konashi":"{KONASHI-ID}",["color":["hue":{val},"saturation":{val}]]]
    // [注意] defaults = [["DAE4E972-9F4D-4EDB-B511-019B0214944F":["tone":"A-L"],..],...] みたいな書き方をするとindexingが止まらなくなる 参考：http://qiita.com/osamu1203/items/270fc716883d86d8f3b7
    devices["DAE4E972-9F4D-4EDB-B511-019B0214944F"] = ["tone":"A-L", "konashi":"konashi2-f01d0f"]
    devices["137FF2D6-7F9D-4729-A001-A0F070BB1E3C"] = ["tone":"A-R", "konashi":"konashi2-f01c9e"]
    devices["B43C8AB7-78EB-4E38-A95E-AA709DD11958"] = ["tone":"B-L", "konashi":"konashi2-f01c3d"]
    devices["159360AB-EC18-4331-87E7-157E309AA974"] = ["tone":"B-R", "konashi":"konashi2-f01cc9"]
    devices["7E04FA65-3F4A-41DF-8B95-E7C7AA04B40A"] = ["tone":"C-L", "konashi":"konashi2-f01c12"]
    devices["2EE83A45-E6D1-4237-A053-1476530207E3"] = ["tone":"C-R", "konashi":"konashi2-f01c40"]
    devices["9BC12444-044F-4272-81B8-583431124105"] = ["tone":"D-L", "konashi":"konashi2-f01cf9"]
    devices["3C3E8B86-4F97-4962-90A4-1D0CCC6EF6DD"] = ["tone":"D-R", "konashi":"konashi2-f01bf3"]
    devices["8FB88F20-8DDF-4589-A14B-B49CF6E9993B"] = ["tone":"E-L", "konashi":"konashi2-f01bf5"]
    devices["FD44A541-97F1-42AB-845B-CABB42A6599D"] = ["tone":"E-R", "konashi":"konashi2-f01c78"]
    devices["C1AF90DE-4B33-422D-B382-A4CFC1AD5555"] = ["tone":"F-L", "konashi":"konashi2-f01d54"]
    devices["E7D0E520-80F6-4270-9FB4-57B2E8D15A99"] = ["tone":"F-R", "konashi":"konashi2-f01d7a"]
    
    colors["A"] = ["hue":0.412, "saturation":1.0]
    colors["B"] = ["hue":0.678, "saturation":1.0]
    colors["C"] = ["hue":0.893, "saturation":0.966]
    colors["D"] = ["hue":0.0,   "saturation":1.0]
    colors["E"] = ["hue":0.070, "saturation":1.0]
    colors["F"] = ["hue":0.190, "saturation":1.0]
    
    toneDirs = FM.contentsOfDirectoryAtPath("\(NSBundle.mainBundle().resourcePath!)/tones", error: nil) as! [String]
    
    // Estimote Beacon
    beaconManager.delegate = self
    beaconManager.requestAlwaysAuthorization()
    beaconUIs = [
      "blueberry1":[beaconSwitchBlueberry1, beaconSliderBlueberry1],
      "blueberry2":[beaconSwitchBlueberry2, beaconSliderBlueberry2],
      "ice1":[beaconSwitchIce1, beaconSliderIce1],
      "ice2":[beaconSwitchIce2, beaconSliderIce2],
      "mint1":[beaconSwitchMint1, beaconSliderMint1],
      "mint2":[beaconSwitchMint2, beaconSliderMint2]
    ]
    
    // playerPoints
    for i in 0..<SLIT_COUNT {
      playerPoints += [360.0/Double(SLIT_COUNT)*Double(i)]
    }
    
    
    // load settings
    // =============
    
    let uuid = UIDevice.currentDevice().identifierForVendor.UUIDString
    NSLog("uuid:\(uuid)")
    uuidLabel.text = "uuid:\(uuid)"
    
    let device: AnyObject? = devices[uuid] // default value of indivisual device
    
    if device != nil {
      if let konashi = device!["konashi"] as? String {
        konashiBtnDefaultLabel = "Find Konashi (\(konashi))"
        konashiBtn.setTitle(konashiBtnDefaultLabel, forState: UIControlState.Normal)
      }
    }
    
    
    
    // Sound
    
    // Delay
    delay = AVAudioUnitDelay()
    setDelayWetDry(0) // 可変 0-80
    setDelayDelayTime(0.295) // 不変
    setDelayFeedback(0) // 可変 0-90
    setDelayLowPassCutOff(700) // 不変
    
    setBrightnessMin(0.15)
    
    mixer = AVAudioMixerNode()
    
    engine.attachNode(delay)
    engine.attachNode(mixer)
    
    // AudioPlayerの準備
    // OneShot
    var toneDir: AnyObject = toneDirs.first!
    if device != nil {
      toneDir = device!["tone"] ?? toneDirs.first! // 先に_default["tone"]のを代入試み、なかったらtoneDirs.first
    }
    
    var format: AVAudioFormat = initPlayers(toneDir as! String)

    engine.connect(mixer, to: delay, format: format)
    engine.connect(delay, to: engine.mainMixerNode, format: format)
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
    loadInstrumentColor(toneDir as! NSString)
    
    hueSlider2.setValue(0.66, animated: true)
    saturationSlider2.setValue(1.0, animated: true)
    
    divideSlider.setValue(Float(UD.integerForKey(UD_KEY_LED_DIVIDE)), animated: true)
    changeDivide(divideSlider)
    
    positionSlider.setValue(Float(UD.integerForKey(UD_KEY_LED_POSITION)), animated: true)
    changePosition(positionSlider)
    
    sendInstrumentColor()
    sendEffectColor()
    setBrightnessMin(self.brightnessSlider.value)
    
    // Konashi関係
    logKonashiStatus()
    
    Konashi.shared().connectedHandler = {
      NSLog("[Konashi] Connected!")
    }
    Konashi.shared().disconnectedHandler = {
      NSLog("[Konashi] Disconnected")
      
      // button
      self.konashiBtn.setTitle(self.konashiBtnDefaultLabel, forState: UIControlState.Normal)
      
//      // 勝手に切断された場合にリトライする
//      if self.manualDisconnection == false {
//        // UserDefaultsから前回接続したKonashiを読み、接続を試みる
//        if let previously_connected_konashi = self.UD.stringForKey(self.UD_KEY_KONASHI) {
//          NSLog("[Konashi] Retry connecting to \(previously_connected_konashi) (previus connection) ...")
//          self.findKonashiWithName(previously_connected_konashi)
//        }
//      }
//      self.manualDisconnection = false
    }
    Konashi.shared().readyHandler = {
      NSLog("[Konashi] Ready...")
      
      // stop timer
      if self.connectionCheckTimer != nil && self.connectionCheckTimer.valid {
        NSLog("[Konashi] Stop connection check")
        self.connectionCheckTimer.invalidate()
      }
      
      self.logKonashiStatus()
      
      let konashiName = Konashi.peripheralName()
      
      self.UD.setObject(konashiName, forKey: self.UD_KEY_KONASHI)
      
      
      // button
      self.konashiBtn.setTitle("[Connected] \(konashiName)", forState: UIControlState.Normal)
      
      // Konashi setting
      Konashi.uartMode(KonashiUartMode.Enable, baudrate: KonashiUartBaudrate.Rate9K6)
      Konashi.pinMode(KonashiDigitalIOPin.DigitalIO1, mode: KonashiPinMode.Output)
      
      // LED2を点灯
      Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO1, value: KonashiLevel.High)
      
      self.sendPlayerType()
      self.sendInstrumentColor()
      self.sendEffectColor()
      self.setBrightnessMin(self.brightnessSlider.value)
    }
//    Konashi.shared().uartRxCompleteHandler = {(data: NSData!) -> Void in
//      NSLog("[Konashi] UartRx \(data.description)")
//    }
    
    if device != nil {
      if let default_konashi = device!["konashi"] as? String {
        NSLog("[Konashi] Auto connecting to \(default_konashi) (default) ...")
        findKonashiWithName(default_konashi)
      }
    }
  }
  
  func findKonashiWithName(konashiName: String) -> KonashiResult {
    let res = Konashi.findWithName(konashiName)
    if res == KonashiResult.Success {
      // 呼び出しが正しく行われただけで、接続されたわけではない
//      NSLog("[Konashi] Konashi.findWithName called and success")
//      if connectionCheckTimer == nil || connectionCheckTimer.valid == false {
//        NSLog("[Konashi] Start connection check")
//        // 接続出来たかどうかの監視を開始
//        connectionCheckTimer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: "checkConnection", userInfo: ["konashi": konashiName], repeats: true)
//      }
    }
    else {
      NSLog("[Konashi] Konashi.findWithName called and failed...")
    }
    return res
  }
  func checkConnection(){
    NSLog("[Konashi] Retry connecting")
    let userInfo = connectionCheckTimer.userInfo as! Dictionary<String, AnyObject>
    let konashi = userInfo["konashi"] as! String
    findKonashiWithName(konashi)
  }
  
  func sendPlayerType() {
    switch playerType {
    case PlayerType.OneShot:
      uart("t:1;")
    case PlayerType.LongShot:
      uart("t:2;")
    default:
      NSLog("Error")
    }
  }
  
  // toneDirから該当する色を読み込む
  func loadInstrumentColor(toneDirStr: NSString) {
    let alphabet = toneDirStr.substringToIndex(1)
    if let color: AnyObject = colors[alphabet] {
      if let hue = color["hue"] as? Float {
        setHue(hue)
      }
      if let saturation = color["saturation"] as? Float {
        setSaturation(saturation)
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
  func beaconManager(manager: AnyObject!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
      if let _beacons = beacons as? [CLBeacon] {
        
        var accuracy_min: Float? // 最小値を保持しておいて、あとでEffectに適用する
        var nearestBeacon: String?
        for _beacon: CLBeacon in _beacons {
          let beaconKey = "\(_beacon.major):\(_beacon.minor)"
          if let beaconName = effectBeacons[beaconKey] as String! {
            let beaconUI = self.beaconUIs[beaconName]
            let _switch: UISwitch = beaconUI?[0] as! UISwitch
            let _slider: UISlider = beaconUI?[1] as! UISlider
            
            if _switch.on {
              if accuracy_min == nil || Float(_beacon.accuracy) < accuracy_min {
                accuracy_min = Float(_beacon.accuracy)
                nearestBeacon = beaconName
              }
            }
            _slider.setValue(Float(-_beacon.accuracy), animated: true)
          }
        }
        
        if accuracy_min != nil {
          let accuracy = Float(Int(accuracy_min! * 100.0)) / 100.0 // 小数点第１位まで
          let beacon_min: Float = 0.81
          let beacon_max: Float = 0.8
          let drywet    = map(accuracy, in_min:beacon_min, in_max:beacon_max, out_min:0, out_max:60)
          let feedback  = map(accuracy, in_min:beacon_min, in_max:beacon_max, out_min:0, out_max:80)
          let float_val = map(accuracy, in_min:beacon_min, in_max:beacon_max, out_min:0.0, out_max:1.0)
          setDelayFeedback(feedback)
          delayFeedbackSlider.setValue(feedback, animated: true)
          setDelayWetDry(drywet)
          delayDryWetSlider.setValue(drywet, animated: true)
          
          layeredPlayerVol = float_val
          
          uart("E:\(float_val);")
          
//          // for debug --------
////          println(nearestBeacon)
//          print(NSString(format: "%.3f ", accuracy))
//          let percent = Int(map(accuracy, in_min:beacon_min, in_max:beacon_max, out_min:0, out_max:100))
//          let arr = Array(count: percent, repeatedValue: "*")
//          
//          if 0<arr.count {
//            if 100<=percent {
//              print(join("", arr))
//              println()
//            }
//            else {
//              println(join("", arr))
//            }
//            
//          }
//          else {
//            println()
//          }
//          // / for debug --------
        }
      }
  }
  
  // in_min～in_max内のxをout_min〜out_max内の値に変換して返す
  private func map(x: Float, in_min: Float, in_max: Float, out_min: Float, out_max: Float) -> Float{
    // restrict 'x' in 'in' range
    let x_in_range = in_min < in_max ? max(min(x, in_max), in_min) : max(min(x, in_min), in_max)
    return (x_in_range - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  }
  
  
  @IBAction func tapFind(sender: UIButton) {
    if Konashi.isConnected() {
      var alertController = UIAlertController(title: "Disconnect Konashi", message: "You are disconnecting \(Konashi.peripheralName()). Are you sure?", preferredStyle: .Alert)
      
      let otherAction = UIAlertAction(title: "Disconnect", style: .Default) {
        action in
        
          // LED2を消灯
          Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO1, value: KonashiLevel.Low)
        
          // LEDが消灯するのに時間が必要なので遅延させる
          NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "disconnectKonashi", userInfo: nil, repeats: false)
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
  
  func disconnectKonashi() {
    NSLog("[Konashi] Disconnect \(Konashi.peripheralName())")
    // 接続解除
    self.manualDisconnection = true
    Konashi.disconnect()
  }
  
  // Color
  
  @IBAction func changeHue(sender: UISlider) {
    setHue(sender.value)
  }
  private func setHue(val: Float) {
    hueLabel.text = "\(val)"
    hueSlider.setValue(val, animated: true)
    UD.setObject(CGFloat(val), forKey: UD_KEY_INSTRUMENT_COLOR_HUE)
    sendInstrumentColor()
  }
  
  @IBAction func changeSaturation(sender: UISlider) {
    setSaturation(sender.value)
  }
  private func setSaturation(val: Float) {
    saturationLabel.text = "\(val)"
    saturationSlider.setValue(val, animated: true)
    UD.setObject(CGFloat(val), forKey: UD_KEY_INSTRUMENT_COLOR_SATURATION)
    sendInstrumentColor()
  }
  
  @IBAction func tapBlack(sender: UIButton) {
    uart("i:000,000,000;\n")
    instrumentColor = UIColor(hue: 0.0, saturation: 0.0, brightness: 0.0, alpha: 1.0)
    colorView.backgroundColor = instrumentColor
  }
  
  @IBAction func changeHue2(sender: UISlider) {
    setHue2(sender.value)
  }
  func setHue2(val: Float) {
    hueLabel2.text = "\(val)"
    hueSlider2.setValue(val, animated: true)
    UD.setObject(CGFloat(val), forKey: UD_KEY_EFFECT_COLOR_HUE)
    sendEffectColor()
  }
  
  @IBAction func changeSaturation2(sender: UISlider) {
    setSaturation2(sender.value)
  }
  func setSaturation2(val: Float) {
    saturationLabel2.text = "\(val)"
    saturationSlider2.setValue(val, animated: true)
    UD.setObject(CGFloat(val), forKey: UD_KEY_EFFECT_COLOR_SATURATION)
    sendEffectColor()
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
    uart("t:0;d:\(val);")
  }
  @IBAction func changePosition(sender: UISlider) {
    let val = Int(sender.value)
    UD.setObject(val, forKey: UD_KEY_LED_POSITION)
    positionLabel.text = "\(val)"
    uart("t:0;p:\(Float(val)/100);")
  }
  
  
  func sendInstrumentColor() {
    let hue = CGFloat(hueSlider.value)
    let saturation = CGFloat(saturationSlider.value)
    instrumentColor = UIColor(hue: hue, saturation: saturation, brightness: 1.0, alpha: 1.0)
    colorView.backgroundColor = instrumentColor
    
    let r = NSString(format: "%03d", Int(instrumentColor.getRed()))
    let g = NSString(format: "%03d", Int(instrumentColor.getGreen()))
    let b = NSString(format: "%03d", Int(instrumentColor.getBlue()))
    uart("i:\(r).\(g).\(b);")
  }
  func sendEffectColor() {
    let hue = CGFloat(hueSlider2.value)
    let saturation = CGFloat(saturationSlider2.value)
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
    
    // cleanup players
    for player in players {
      if player.playing {
        player.stop()
      }
      engine.disconnectNodeInput(player)
    }
    players.removeAll(keepCapacity: false)
    
    
    // ------------
    
    var items = FM.contentsOfDirectoryAtPath("\(NSBundle.mainBundle().resourcePath!)/tones/\(toneDir)", error: nil) as! [String]
    
    // wavファイル以外は無視
    items = items.filter { (name: String) -> Bool in
      var regex = NSRegularExpression(pattern: ".wav$", options: NSRegularExpressionOptions.allZeros, error: nil)
      return regex?.firstMatchInString(name, options: NSMatchingOptions.allZeros, range: NSMakeRange(0, count(name))) != nil
    }
    
    let itemsCount = items.count
    toneCountLabel.text = "\(itemsCount)"
    if 0 < itemsCount {
      
      // 左用の音かどうか判定（Lで終わっていたら左）
      var regex = NSRegularExpression(pattern: "L$", options: NSRegularExpressionOptions.allZeros, error: nil)
      let isLeft: Bool = regex?.firstMatchInString(toneDir, options: NSMatchingOptions.allZeros, range: NSMakeRange(0, count(toneDir))) != nil
      let _tones = isLeft ? ["02","01"] : ["01","02"]
      
      // switch player type
      
      if itemsCount == 2 {
        setTonePlayerType(PlayerType.LongShot)
        
        for (index, file) in enumerate(_tones) {
          var filePath: String = NSBundle.mainBundle().pathForResource("tones/\(toneDir)/\(file)", ofType: "wav")!
          var fileURL: NSURL = NSURL(fileURLWithPath: filePath)!
          var audioFile = AVAudioFile(forReading: fileURL, error: nil)
          var audioFileBuffer = AVAudioPCMBuffer(PCMFormat: audioFile.processingFormat, frameCapacity: UInt32(audioFile.length))
          audioFile.readIntoBuffer(audioFileBuffer, error: nil)
          var player = AVAudioPlayerNode()
          engine.attachNode(player)
          engine.connect(player, to: mixer, format: audioFile.processingFormat)
          player.volume = 0.0
          player.scheduleBuffer(audioFileBuffer, atTime: nil, options:.Loops, completionHandler: nil)
          players += [player]
          
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
          
          players += [player]
          
          if format == nil {
            format = audioFile.processingFormat
          }
        }
      }
      
      // set layeredPlayer
      for (index, file) in enumerate(_tones) {
        let layeredTones = FM.contentsOfDirectoryAtPath("\(NSBundle.mainBundle().resourcePath!)/tones/\(toneDir)/layered", error: nil)
        if 0 < layeredTones!.count {
          let filePath = NSBundle.mainBundle().pathForResource("tones/\(toneDir)/layered/\(file)", ofType: "wav")!
          let fileURL = NSURL(fileURLWithPath: filePath)!
          let audioFile = AVAudioFile(forReading: fileURL, error: nil)
          let audioFileBuffer = AVAudioPCMBuffer(PCMFormat: audioFile.processingFormat, frameCapacity: UInt32(audioFile.length))
          audioFile.readIntoBuffer(audioFileBuffer, error: nil)
          let player = AVAudioPlayerNode()
          engine.attachNode(player)
          engine.connect(player, to: mixer, format: audioFile.processingFormat)
          player.volume = 0.0
          player.scheduleBuffer(audioFileBuffer, atTime: nil, options:.Loops, completionHandler: nil)
          layeredPlayers += [player]
        }
      }
    }
    
    sendPlayerType()
    
    // Color
    loadInstrumentColor(toneDir as NSString)
    
    return format
  }
  
  func setTonePlayerType(type: PlayerType) {
    playerType = type
    tonePlayerTypeLabel.text = type.rawValue
  }
  
  // Effect
  // ======
  
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
  
  // シリアル通信で送信
  func uart(str: String){
    if Konashi.isConnected() {
      // 連続して送信してしまわないように制限をかける
      // TODO "コマンド毎"の連続送信時間で制限をかけるようにしたい
      let cmd = (str as NSString).substringToIndex(1)
      if (cmd == "B" || cmd == "e" || cmd == "i" || cmd == "b") && ElapsedTimeCounter.instance.getMillisec() < 10 {
        println("ignore command (not send to Konashi) \(str)")
      }
      else {
        if Konashi.uartWriteString(str) == KonashiResult.Failure {
          NSLog("[Konashi] uartWriteString error")
        }
      }
    }
  }
  
  func updateRotation(radian: Double) {
    
    let currentDeg = radiansToDegrees(radian)
//    let variation = Float(prevDeg - current_deg)
    let _variation = variation(prevDeg, current: currentDeg)
    
    arrow.transform = CGAffineTransformMakeRotation(CGFloat(radian))
    
    // 変化量
    // 実際の車輪のスピードの範囲とうまくマッピングする
    // 実際にクルマイスに乗って試したところ前進で_variationは最大で5くらいだった
    let vol = 9.0 * min(abs(_variation)/5,1)
    
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
          let player: AVAudioPlayerNode = players[index] as AVAudioPlayerNode
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
      
      for player in players {
        if !player.playing {
          player.play()
        }
      }
      for player in layeredPlayers {
        if !player.playing {
          player.play()
        }
      }
      
      if 0 < _variation {
        players[0].volume = 0
        players[1].volume = vol
      }
      else {
        players[0].volume = vol
        players[1].volume = 0
      }
      
      // Konashi通信
      let brightness = map(vol, in_min:0.0, in_max:9.0, out_min:0.2, out_max:1.0)
      uart("B:\(brightness);")
      
    default:
      NSLog("Error")
    }
    
    // layered players
    if 0 < _variation {
      layeredPlayers[0].volume = 0
      layeredPlayers[1].volume = vol*layeredPlayerVol
    }
    else {
      layeredPlayers[0].volume = vol*layeredPlayerVol
      layeredPlayers[1].volume = 0
    }
    
    prevDeg = currentDeg
  }
  
  func radiansToDegrees(value: Double) -> Double {
    return value * 180.0 / M_PI + 360.0
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


//
// http://qiita.com/KeitaMoromizato/items/59cb25925642822c6ec9
// 経過時間を調べる
class ElapsedTimeCounter {
  class var instance: ElapsedTimeCounter {
    struct Static {
      static let instance = ElapsedTimeCounter()
    }
    return Static.instance
  }
  
  private var lastDate: NSDate?
  
  func getMillisec() -> Int? {
    let now = NSDate()
    if let date = lastDate {
      let elapsed = now.timeIntervalSinceDate(date)
      lastDate = now
      
      return Int(elapsed * 1000.0)
    }
    
    lastDate = now
    return nil
  }
}

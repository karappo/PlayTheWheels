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
  let UD = UserDefaults.standard
  let UD_KEY_KONASHI = "konashi"
  let UD_KEY_INSTRUMENT_COLOR_HUE = "instrument_color_hue"
  let UD_KEY_INSTRUMENT_COLOR_SATURATION = "instrument_color_saturation"
  let UD_KEY_EFFECT_COLOR_HUE = "effect_color_hue"
  let UD_KEY_EFFECT_COLOR_SATURATION = "effect_color_saturation"
  let UD_KEY_LED_DIVIDE = "led_divide"
  let UD_KEY_LED_POSITION = "led_position"
  
  var devices = NSMutableDictionary()
  var colors = NSMutableDictionary()
  
  var commandLastCalls = NSMutableDictionary() // commandの最後に送信された時刻を記録
  
  @IBOutlet weak var arrow: UIImageView!
  
  // # Konashi Section
  
  @IBOutlet weak var konashiBtn: UIButton!
  var konashiBtnDefaultLabel = "Find Konashi"
  var manualDisconnection: Bool = false // Disconnectされた際に手動で切断されたのかどうかを判定するためのフラグ
  var connectionCheckTimer: Timer!
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
  let beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: "B8A63B91-CB83-4701-8093-62084BFA40B4")!, identifier: "ranged region")
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
  
  let FM = FileManager.default
  
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
    
    initialize()
    
    // load settings
    // =============
    
    let uuid = UIDevice.current.identifierForVendor!.uuidString
    NSLog("uuid:\(uuid)")
    uuidLabel.text = "uuid:\(uuid)"
    
    let device: NSMutableDictionary
    if devices[uuid] != nil {
      device = devices[uuid] as! NSMutableDictionary
    }
    else {
      NSLog("Not found device configuration")
      device = devices[devices.allKeys.first!] as! NSMutableDictionary
    }
    
    if let konashi = device.value(forKey: "konashi") as? String {
      konashiBtnDefaultLabel = "Find Konashi (\(konashi))"
      konashiBtn.setTitle(konashiBtnDefaultLabel, for: UIControlState())
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
    
    engine.attach(delay)
    engine.attach(mixer)
    
    // AudioPlayerの準備
    // OneShot
    var toneDir: String = toneDirs.first!
    toneDir = device.value(forKey: "tone") as! String
    
    let format: AVAudioFormat = initPlayers(toneDir as String)

    engine.connect(mixer, to: delay, format: format)
    engine.connect(delay, to: engine.mainMixerNode, format: format)
    do {
      try engine.start()
    }
    catch {
      NSLog("AVAudioEngine start error")
    }
    
    // モーションセンサー
    if MM.isDeviceMotionAvailable {
      MM.deviceMotionUpdateInterval = MM_UPDATE_INTERVAL
      MM.startDeviceMotionUpdates(to: OperationQueue()) { deviceMotion, error in
        let rotation = atan2(deviceMotion!.gravity.x, deviceMotion!.gravity.y) - .pi
        self.updateRotation(rotation)
      }
    }
    
    // Color
    loadInstrumentColor(toneDir as NSString)
    
    hueSlider2.setValue(0.66, animated: true)
    saturationSlider2.setValue(1.0, animated: true)
    
    divideSlider.setValue(Float(UD.integer(forKey: UD_KEY_LED_DIVIDE)), animated: true)
    changeDivide(divideSlider)
    
    positionSlider.setValue(Float(UD.integer(forKey: UD_KEY_LED_POSITION)), animated: true)
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
      self.konashiBtn.setTitle(self.konashiBtnDefaultLabel, for: [])
      
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
      if self.connectionCheckTimer != nil && self.connectionCheckTimer.isValid {
        NSLog("[Konashi] Stop connection check")
        self.connectionCheckTimer.invalidate()
      }
      
      self.logKonashiStatus()
      
      let konashiName: String = Konashi.peripheralName()
      
      self.UD.set(konashiName, forKey: self.UD_KEY_KONASHI)
      
      
      // button
      self.konashiBtn.setTitle("[Connected] \(konashiName)", for: [])
      
      // Konashi setting
      Konashi.uartMode(KonashiUartMode.enable, baudrate: KonashiUartBaudrate.rate9K6)
      Konashi.pinMode(KonashiDigitalIOPin.digitalIO1, mode: KonashiPinMode.output)
      
      // LED2を点灯
      Konashi.digitalWrite(KonashiDigitalIOPin.digitalIO1, value: KonashiLevel.high)
      
      self.sendPlayerType()
      self.sendEffectColor()
      self.sendInstrumentColor()
      self.setBrightnessMin(self.brightnessSlider.value)
    }
//    Konashi.shared().uartRxCompleteHandler = {(data: NSData!) -> Void in
//      NSLog("[Konashi] UartRx \(data.description)")
//    }
    
    if let default_konashi = device.value(forKey: "konashi") as? String {
      NSLog("[Konashi] Auto connecting to \(default_konashi) (default) ...")
      findKonashiWithName(default_konashi)
    }
  }
  
  func initialize() {
    
    // "{IPHONE-UUIDString}":["tone":"{TONE-NAME}","konashi":"{KONASHI-ID}",["color":["hue":{val},"saturation":{val}]]]
    // [注意] defaults = [["DAE4E972-9F4D-4EDB-B511-019B0214944F":["tone":"A-L"],..],...] みたいな書き方をするとindexingが止まらなくなる 参考：http://qiita.com/osamu1203/items/270fc716883d86d8f3b7
    
    devices["DAE4E972-9F4D-4EDB-B511-019B0214944F"] = ["tone":"A-L", "konashi":"konashi2-f01d0f"] as NSMutableDictionary
    devices["137FF2D6-7F9D-4729-A001-A0F070BB1E3C"] = ["tone":"A-R", "konashi":"konashi2-f01c9e"] as NSMutableDictionary
    devices["B43C8AB7-78EB-4E38-A95E-AA709DD11958"] = ["tone":"B-L", "konashi":"konashi2-f01c3d"] as NSMutableDictionary
    devices["159360AB-EC18-4331-87E7-157E309AA974"] = ["tone":"B-R", "konashi":"konashi2-f01cc9"] as NSMutableDictionary
    devices["7E04FA65-3F4A-41DF-8B95-E7C7AA04B40A"] = ["tone":"C-L", "konashi":"konashi2-f01c12"] as NSMutableDictionary
    devices["2EE83A45-E6D1-4237-A053-1476530207E3"] = ["tone":"C-R", "konashi":"konashi2-f01c40"] as NSMutableDictionary
    devices["9BC12444-044F-4272-81B8-583431124105"] = ["tone":"D-L", "konashi":"konashi2-f01cf9"] as NSMutableDictionary
    devices["3C3E8B86-4F97-4962-90A4-1D0CCC6EF6DD"] = ["tone":"D-R", "konashi":"konashi2-f01bf3"] as NSMutableDictionary
    devices["8FB88F20-8DDF-4589-A14B-B49CF6E9993B"] = ["tone":"E-L", "konashi":"konashi2-f01bf5"] as NSMutableDictionary
    devices["FD44A541-97F1-42AB-845B-CABB42A6599D"] = ["tone":"E-R", "konashi":"konashi2-f01c78"] as NSMutableDictionary
    devices["C1AF90DE-4B33-422D-B382-A4CFC1AD5555"] = ["tone":"F-L", "konashi":"konashi2-f01d54"] as NSMutableDictionary
    devices["E7D0E520-80F6-4270-9FB4-57B2E8D15A99"] = ["tone":"F-R", "konashi":"konashi2-f01d7a"] as NSMutableDictionary
    
    colors["A"] = ["hue":0.412, "saturation":1.0]
    colors["B"] = ["hue":0.678, "saturation":1.0]
    colors["C"] = ["hue":0.893, "saturation":0.966]
    colors["D"] = ["hue":0.0,   "saturation":1.0]
    colors["E"] = ["hue":0.070, "saturation":1.0]
    colors["F"] = ["hue":0.190, "saturation":1.0]
    
    do {
      toneDirs = try FM.contentsOfDirectory(atPath: "\(Bundle.main.resourcePath!)/tones")
      toneDirs.remove(at: toneDirs.index(of: "README.md")!)
    }
    catch {
      // do nothing
      NSLog("Cannot load toneDirs !")
    }
    
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
  }
  
  func findKonashiWithName(_ konashiName: String) {
    let res = Konashi.find(withName: konashiName)
    if res == KonashiResult.success {
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
    }
  }
  
  // toneDirから該当する色を読み込む
  func loadInstrumentColor(_ toneDirStr: NSString) {
    let alphabet = toneDirStr.substring(to: 1)
    if let color: NSMutableArray = colors.value(forKey: alphabet) as? NSMutableArray {
      setHue(color.value(forKey: "hue") as! Float)
      setSaturation(color.value(forKey: "saturation") as! Float)
    }
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    beaconManager.startRangingBeacons(in: beaconRegion)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    beaconManager.stopRangingBeacons(in: beaconRegion)
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
  func beaconManager(_ manager: AnyObject!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
      if let _beacons = beacons as? [CLBeacon] {
        
        var accuracy_min: Float? // 最小値を保持しておいて、あとでEffectに適用する
        // var nearestBeacon: String?
        for _beacon: CLBeacon in _beacons {
          let beaconKey = "\(_beacon.major):\(_beacon.minor)"
          if let beaconName = effectBeacons[beaconKey] as String! {
            let beaconUI = self.beaconUIs[beaconName]
            let _switch: UISwitch = beaconUI?[0] as! UISwitch
            let _slider: UISlider = beaconUI?[1] as! UISlider
            
            if _switch.isOn {
              if accuracy_min == nil || Float(_beacon.accuracy) < accuracy_min! {
                accuracy_min = Float(_beacon.accuracy)
                // nearestBeacon = beaconName
              }
            }
            _slider.setValue(Float(-_beacon.accuracy), animated: true)
          }
        }
        
        if accuracy_min != nil {
          let accuracy = Float(Int(accuracy_min! * 100.0)) / 100.0 // 小数点第１位まで
          let beacon_min: Float = 1.3
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
          
          // for debug --------
//          NSLog(nearestBeacon)
          NSLog(NSString(format: "%.3f ", accuracy) as String)
          let percent = Int(map(accuracy, in_min:beacon_min, in_max:beacon_max, out_min:0, out_max:100))
          let arr = Array(repeating: "*", count: percent)
          
          if 0<arr.count {
            if 100<=percent {
              NSLog(arr.joined(separator: ""))
              NSLog("")
            }
            else {
              NSLog(arr.joined(separator: ""))
            }
            
          }
          else {
            NSLog("")
          }
          // / for debug --------
        }
      }
  }
  
  // in_min～in_max内のxをout_min〜out_max内の値に変換して返す
  fileprivate func map(_ x: Float, in_min: Float, in_max: Float, out_min: Float, out_max: Float) -> Float{
    // restrict 'x' in 'in' range
    let x_in_range = in_min < in_max ? max(min(x, in_max), in_min) : max(min(x, in_min), in_max)
    return (x_in_range - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  }
  
  
  @IBAction func tapFind(_ sender: UIButton) {
    if Konashi.isConnected() {
      let alertController = UIAlertController(title: "Disconnect Konashi", message: "You are disconnecting \(Konashi.peripheralName()). Are you sure?", preferredStyle: .alert)
      
      let otherAction = UIAlertAction(title: "Disconnect", style: .default) {
        action in
        
          // LED2を消灯
          Konashi.digitalWrite(KonashiDigitalIOPin.digitalIO1, value: KonashiLevel.low)
        
          // LEDが消灯するのに時間が必要なので遅延させる
          Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.disconnectKonashi), userInfo: nil, repeats: false)
      }
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
        action in
          NSLog("[Konashi] Cancel disconnecting \(Konashi.peripheralName())")
      }
      
      // addActionした順に左から右にボタンが配置されます
      alertController.addAction(otherAction)
      alertController.addAction(cancelAction)
      
      present(alertController, animated: true, completion: nil)

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
  
  @IBAction func changeHue(_ sender: UISlider) {
    setHue(sender.value)
  }
  fileprivate func setHue(_ val: Float) {
    hueLabel.text = "\(val)"
    hueSlider.setValue(val, animated: true)
    UD.set(CGFloat(val), forKey: UD_KEY_INSTRUMENT_COLOR_HUE)
    sendInstrumentColor()
  }
  
  @IBAction func changeSaturation(_ sender: UISlider) {
    setSaturation(sender.value)
  }
  fileprivate func setSaturation(_ val: Float) {
    saturationLabel.text = "\(val)"
    saturationSlider.setValue(val, animated: true)
    UD.set(CGFloat(val), forKey: UD_KEY_INSTRUMENT_COLOR_SATURATION)
    sendInstrumentColor()
  }
  
  @IBAction func tapBlack(_ sender: UIButton) {
    uart("i:000,000,000;\n")
    instrumentColor = UIColor(hue: 0.0, saturation: 0.0, brightness: 0.0, alpha: 1.0)
    colorView.backgroundColor = instrumentColor
  }
  
  @IBAction func changeHue2(_ sender: UISlider) {
    setHue2(sender.value)
  }
  func setHue2(_ val: Float) {
    hueLabel2.text = "\(val)"
    hueSlider2.setValue(val, animated: true)
    UD.set(CGFloat(val), forKey: UD_KEY_EFFECT_COLOR_HUE)
    sendEffectColor()
  }
  
  @IBAction func changeSaturation2(_ sender: UISlider) {
    setSaturation2(sender.value)
  }
  func setSaturation2(_ val: Float) {
    saturationLabel2.text = "\(val)"
    saturationSlider2.setValue(val, animated: true)
    UD.set(CGFloat(val), forKey: UD_KEY_EFFECT_COLOR_SATURATION)
    sendEffectColor()
  }
  
  @IBAction func tapBlack2(_ sender: UIButton) {
    uart("e:000,000,000;\n")
    effectColor = UIColor(hue: 0.0, saturation: 0.0, brightness: 0.0, alpha: 1.0)
    colorView2.backgroundColor = effectColor
  }
  
  @IBAction func changeBrightnessMin(_ sender: UISlider) {
    setBrightnessMin(sender.value)
  }
  func setBrightnessMin(_ val: Float) {
    brightnessLabel.text = "\(val)"
    uart("b:\(val);")
  }
  
  @IBAction func changeDivide(_ sender: UISlider) {
    let val = Int(sender.value)
    UD.set(val, forKey: UD_KEY_LED_DIVIDE)
    divideLabel.text = "\(val)"
    uart("t:0;d:\(val);")
  }
  @IBAction func changePosition(_ sender: UISlider) {
    let val = Int(sender.value)
    UD.set(val, forKey: UD_KEY_LED_POSITION)
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
  
  @IBAction func tapToneName(_ sender: UIButton) {
    let initial: Int = toneDirs.index(of: toneNameBtn.titleLabel!.text!)!
    ActionSheetStringPicker.show(withTitle: "Tone", rows: toneDirs, initialSelection: initial, doneBlock: {
      picker, value, index in
      let key: String = index as! String
      self.initPlayers(key)
      return
    }, cancel: { ActionStringCancelBlock in return }, origin: sender)
  }
  
  // AVAudioPlayerNode の生成やAudioFileの設定
  // その他のノードの初期化のために、最初のAudioFileのAVAudioFormatを返す
  @discardableResult
  func initPlayers(_ toneDir: String) -> AVAudioFormat!{
    
    toneNameBtn.setTitle(toneDir, for: UIControlState())
    
    var format: AVAudioFormat! = nil
    if 1<audioFiles.count {
      audioFiles.removeAll(keepingCapacity: false)
    }
    
    // cleanup players
    for player in players {
      if player.isPlaying {
        player.stop()
      }
      engine.disconnectNodeInput(player)
    }
    players.removeAll(keepingCapacity: false)
    
    
    // ------------
    
    var items: [String] = [];
    do {
      items = try FM.contentsOfDirectory(atPath: "\(Bundle.main.resourcePath!)/tones/\(toneDir)")
    }
    catch {
      NSLog("Cannot load items !")
    }
    
    // wavファイル以外は無視
    items = items.filter { (name: String) -> Bool in
      let regex = try! NSRegularExpression(pattern: ".wav$", options: [])
      return regex.firstMatch(in: name, options: [], range: NSMakeRange(0, name.utf8.count)) != nil
    }
    
    let itemsCount = items.count
    toneCountLabel.text = "\(itemsCount)"
    if 0 < itemsCount {
      
      // 左用の音かどうか判定（Lで終わっていたら左）
      let regex = try! NSRegularExpression(pattern: "L$", options: [])
      let isLeft: Bool = regex.firstMatch(in: toneDir, options: [], range: NSMakeRange(0, toneDir.utf8.count)) != nil
      let _tones = isLeft ? ["02","01"] : ["01","02"]
      
      // switch player type
      
      if itemsCount == 2 {
        setTonePlayerType(PlayerType.LongShot)
        
        for (_, file) in _tones.enumerated() {
          let filePath: String = Bundle.main.path(forResource: "tones/\(toneDir)/\(file)", ofType: "wav")!
          let fileURL: URL = URL(fileURLWithPath: filePath)
          do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: UInt32(audioFile.length))
            do {
              try audioFile.read(into: audioFileBuffer)
              let player = AVAudioPlayerNode()
              engine.attach(player)
              engine.connect(player, to: mixer, format: audioFile.processingFormat)
              player.volume = 0.0
              player.scheduleBuffer(audioFileBuffer, at: nil, options:.loops, completionHandler: nil)
              players += [player]
              
              if format == nil {
                format = audioFile.processingFormat
              }
            }
            catch {
              NSLog("Cannot AVAudioFile read")
            }
          }
          catch {
            NSLog("Cannot load audioFile !")
          }
        }
      }
      else {
        setTonePlayerType(PlayerType.OneShot)
        
        for i in 1..<itemsCount+1 {
          let num = NSString(format: "%02d", isLeft ? itemsCount+1 - i : i) // 左車輪の音だったら反転し、２桁で0埋め
          let url = Bundle.main.path(forResource: "tones/\(toneDir)/\(num)", ofType: "wav")!
          do {
            let audioFile = try AVAudioFile(forReading: URL(fileURLWithPath: url))
            audioFiles += [audioFile]
            
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mixer, format: audioFile.processingFormat)
            player.volume = 9.0
            
            players += [player]
            
            if format == nil {
              format = audioFile.processingFormat
            }
          }
          catch {
            NSLog("Cannot init AVAudioFile")
          }
        }
      }
      
      // set layeredPlayer
      for (_, file) in _tones.enumerated() {
        var layeredTones: [String] = [];
        do {
          layeredTones = try FM.contentsOfDirectory(atPath: "\(Bundle.main.resourcePath!)/tones/\(toneDir)/layered")
        }
        catch {
          // do nothing
          NSLog("Cannot load layeredTones !")
        }
        
        if 0 < layeredTones.count {
          let filePath = Bundle.main.path(forResource: "tones/\(toneDir)/layered/\(file)", ofType: "wav")!
          let fileURL = URL(fileURLWithPath: filePath)
          do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: UInt32(audioFile.length))
            do {
              try audioFile.read(into: audioFileBuffer)
              let player = AVAudioPlayerNode()
              engine.attach(player)
              engine.connect(player, to: mixer, format: audioFile.processingFormat)
              player.volume = 0.0
              player.scheduleBuffer(audioFileBuffer, at: nil, options:.loops, completionHandler: nil)
              layeredPlayers += [player]
            }
            catch {
              NSLog("Cannot AVAudioFile read")
            }
          }
          catch{
            NSLog("Cannot init AVAudioFile")
          }
        }
      }
    }
    
    sendPlayerType()
    
    // Color
    loadInstrumentColor(toneDir as NSString)
    
    return format
  }
  
  func setTonePlayerType(_ type: PlayerType) {
    playerType = type
    tonePlayerTypeLabel.text = type.rawValue
  }
  
  // Effect
  // ======
  
  // Delay
  @IBAction func changeDelayWetDry(_ sender: UISlider) {
    setDelayWetDry(sender.value)
  }
  func setDelayWetDry(_ val: Float) {
    delay.wetDryMix = val
    delayDryWetLabel.text = "\(val)"
  }
  @IBAction func changeDelayDelayTime(_ sender: UISlider) {
    setDelayDelayTime(sender.value)
  }
  func setDelayDelayTime(_ val: Float) {
    delay.delayTime = TimeInterval(val)
    delayDelayTimeLabel.text = "\(val)"
  }
  @IBAction func changeDelayFeedback(_ sender: UISlider) {
    setDelayFeedback(sender.value)
  }
  func setDelayFeedback(_ val: Float) {
    delay.feedback = val
    delayFeedbackLabel.text = "\(val)"
  }
  @IBAction func changeDelayLowPassCutOff(_ sender: UISlider) {
    setDelayLowPassCutOff(sender.value)
  }
  func setDelayLowPassCutOff(_ val: Float) {
    delay.lowPassCutoff = val
    delayLowPassCutOffLabel.text = "\(val)"
  }
  
  // シリアル通信で送信
  func uart(_ str: String){
    if Konashi.isConnected() {
      // コマンド毎の連続送信時間で制限をかける（Bコマンドなどが大量に送られるとKonashiとの接続が切れる）
      let cmd = (str as NSString).substring(to: 1)
      if let lastCall = commandLastCalls[cmd] as? Date {
        let elapsed = Float(Date().timeIntervalSince(lastCall))
        if 0.01 < elapsed {
          if Konashi.uartWrite(str) == KonashiResult.success {
            commandLastCalls[cmd] = Date()
          }
        }
      }
      else {
        if Konashi.uartWrite(str) == KonashiResult.success {
          commandLastCalls[cmd] = Date()
        }
      }
    }
  }
  
  
  func updateRotation(_ radian: Double) {
    
    let currentDeg = radiansToDegrees(radian)
    let variation = getVariation(prevDeg, current: currentDeg)
    
    arrow.transform = CGAffineTransform(rotationAngle: CGFloat(radian))
    
    // 変化量
    // 実際の車輪のスピードの範囲とうまくマッピングする
    // 実際にクルマイスに乗って試したところ前進でvariationは最大で5くらいだった
    let vol = 9.0 * min(abs(variation)/5,1)
    
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
        let _idx = current_index + passed_slit.count*(0<variation ? 1 : -1)
        current_index = audioFiles.relativeIndex(_idx)
        
        
        for index in passed_players {
          // Sound
          let audioFile: AVAudioFile = audioFiles[index] as AVAudioFile
          let player: AVAudioPlayerNode = players[index] as AVAudioPlayerNode
          if player.isPlaying {
            player.stop()
          }
          
          // playerにオーディオファイルを設定　※ 再生直前にセットしないと再生されない？
          player.scheduleFile(audioFile, at: nil, completionHandler: nil)
          
          // 再生開始
          player.play()
          
          // Konashi通信
          uart("s:;")
        }
      }
    case PlayerType.LongShot:
      // LongShot
      
      for player in players {
        if !player.isPlaying {
          player.play()
        }
      }
      for player in layeredPlayers {
        if !player.isPlaying {
          player.play()
        }
      }
      
      if(players.count == 2) {
        if 0 < variation {
          players[0].volume = 0
          players[1].volume = vol
        }
        else {
          players[0].volume = vol
          players[1].volume = 0
        }
      }
      
      // Konashi通信
      let brightness = map(vol, in_min:0.0, in_max:9.0, out_min:0.2, out_max:1.0)
      uart("B:\(brightness);")
    }
    
    // layered players
    if 0 < variation {
      layeredPlayers[0].volume = 0
      layeredPlayers[1].volume = vol*layeredPlayerVol
    }
    else {
      layeredPlayers[0].volume = vol*layeredPlayerVol
      layeredPlayers[1].volume = 0
    }
    
    prevDeg = currentDeg
  }
  
  func radiansToDegrees(_ value: Double) -> Double {
    return value * 180.0 / .pi + 360.0
  }
  
  // 0 <= value < 360 の範囲に値を収める
  fileprivate func restrict(_ value: Double) -> Double {
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
  fileprivate func slitIndexInRange(_ prev: Double, current: Double) -> Array<Int> {
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
  fileprivate func getVariation(_ prev: Double, current: Double) -> Float {
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
  func relativeIndex (_ index: Int) -> Int {
    var _index = (index % count)
    
    if _index < 0 {
      _index = count + _index
    }
    
    return _index
  }
  
  func get (_ index: Int) -> Element? {
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
  
  fileprivate var lastDate: Date?
  
  func getMillisec() -> Int? {
    let now = Date()
    if let date = lastDate {
      let elapsed = now.timeIntervalSince(date)
      lastDate = now
      
      return Int(elapsed * 1000.0)
    }
    
    lastDate = now
    return nil
  }
}

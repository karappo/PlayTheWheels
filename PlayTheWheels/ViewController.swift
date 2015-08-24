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

class ViewController: UIViewController {

  @IBOutlet weak var arrow: UIImageView!
  @IBOutlet weak var led1: UIView!
  @IBOutlet weak var led2: UIView!
  @IBOutlet weak var led3: UIView!
  @IBOutlet weak var led4: UIView!
  @IBOutlet weak var led5: UIView!
  @IBOutlet weak var led6: UIView!
  @IBOutlet weak var led7: UIView!
  @IBOutlet weak var led8: UIView!
  
  @IBOutlet weak var find: UIButton!
  @IBOutlet weak var sendR: UIButton!
  @IBOutlet weak var sendG: UIButton!
  @IBOutlet weak var sendB: UIButton!
  @IBOutlet weak var reverbSlider: UISlider!
  
  let MM: CMMotionManager = CMMotionManager()
  let MM_UPDATE_INTERVAL = 0.01 // 更新周期 100Hz
  
  var engine: AVAudioEngine!
  var reverb: AVAudioUnitReverb!
  var mixer: AVAudioMixerNode!
  var players: Array<AVAudioPlayerNode> = []
  var audioFiles: Array<AVAudioFile> = []
  
  let SLIT_COUNT = 8
  var leds: Array<UIView> = []
  var prevDeg: Double = 0.0
  var slitDegs: Array<Double> = [] // 分割数に応じて360度を当分した角度を保持しておく配列
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
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
    reverb = AVAudioUnitReverb()
    reverb.loadFactoryPreset(.LargeHall2)
    reverb.wetDryMix = 0
    
    mixer = AVAudioMixerNode()
    
    engine.attachNode(reverb)
    engine.attachNode(mixer)
    
    // AudioPlayerの準備
    var format: AVAudioFormat! = nil
    for i in 0..<SLIT_COUNT {
      
      let player = AVAudioPlayerNode()
      let audioFile = AVAudioFile(forReading: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Blue Ballad - Pattern 2 - 96 - \(i)", ofType: "wav")!), error: nil)
      audioFiles += [audioFile]
      
      engine.attachNode(player)
      
      if format == nil {
        format = audioFile.processingFormat
      }
      
      engine.connect(player, to: mixer, format: format)
      
      players += [player]
    }
    
    engine.connect(mixer, to: reverb, format: format)
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
    find.addTarget(self, action: "tapFind:", forControlEvents: .TouchUpInside)
    sendR.addTarget(self, action: "tapSendR:", forControlEvents: .TouchUpInside)
    sendG.addTarget(self, action: "tapSendG:", forControlEvents: .TouchUpInside)
    sendB.addTarget(self, action: "tapSendB:", forControlEvents: .TouchUpInside)
    reverbSlider.addTarget(self, action: "sliderChanged:", forControlEvents: .ValueChanged)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func tapFind(sender:UIButton!) {
    Konashi.find()
  }
  
  func tapSendR(sender:UIButton!) {
    uart("255.000.000\n")
  }
  func tapSendG(sender:UIButton!) {
    uart("000.255.000\n")
  }
  func tapSendB(sender:UIButton!) {
    uart("000.000.255\n")
  }
  func sliderChanged(sender: UISlider!) {
    reverb.wetDryMix = reverbSlider.value
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


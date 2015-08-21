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

  @IBOutlet weak var label: UILabel!
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
  
  let MM: CMMotionManager = CMMotionManager()
  let MM_UPDATE_INTERVAL = 0.01 // 更新周期 100Hz
  
  var players: Array<AVAudioPlayer> = []
  
  let slits_count = 8
  var leds: Array<UIView> = []
  var prev_deg: Double = 0.0
  var slit_degs: Array<Double> = [] // 分割数に応じて360度を当分した角度を保持しておく配列
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 画面上のLEDの準備
    let count = Double(slits_count)
    for i in 0..<slits_count {
      slit_degs += [360.0/count*Double(i)]
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
    
    // AudioPlayerの準備
    for i in 0..<slits_count {
      let sound_data = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Blue Ballad - Pattern 2 - 96 - \(i)", ofType: "wav")!)
      let player = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
      player.prepareToPlay()
      players += [player]
    }
    
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
    NSLog("Konashi.isConnected:\(Konashi.isConnected())")
    
    Konashi.shared().connectedHandler = {
      NSLog("CONNECTED")
    }
    
    Konashi.shared().readyHandler = {
      NSLog("READY")
      
      Konashi.uartMode(KonashiUartMode.Enable, baudrate: KonashiUartBaudrate.Rate9K6)

      // LED2を点灯させる
      Konashi.pinMode(KonashiDigitalIOPin.DigitalIO1, mode: KonashiPinMode.Output)
      Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO1, value: KonashiLevel.High)
    }
    Konashi.shared().uartRxCompleteHandler = {(data: NSData!) -> Void in
      NSLog("UartRx \(data.description)")
    }
    find.addTarget(self, action: "tapFind:", forControlEvents: .TouchUpInside)
    sendR.addTarget(self, action: "tapSendR:", forControlEvents: .TouchUpInside)
    sendG.addTarget(self, action: "tapSendG:", forControlEvents: .TouchUpInside)
    sendB.addTarget(self, action: "tapSendB:", forControlEvents: .TouchUpInside)
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
  // シリアル通信で送信
  func uart(str: String){
    let res = Konashi.uartWriteString(str)
    if res == KonashiResult.Success {
//      NSLog("KonashiResultSuccess")
    }
    else {
      NSLog("KonashiResultFailure")
    }
  }
  
  func updateRotation(radian: Double) {
    let current_deg = self.radiansToDegrees(radian)
    label.text = "\(floor(current_deg))"
    let passed_index = self.getSlitIndexInRange(self.prev_deg, current: current_deg)
    if 0 < passed_index.count {
      for slit_index in passed_index {
        // スクリーンのLED
        let led = leds[slit_index]
        activate(led)
        
        // Sound
        let player: AVAudioPlayer = players[slit_index]
        player.currentTime = 0
        player.play()
        
        // Konashi通信
        
        // slit位置に応じて色を決定
        let h = CGFloat(Float(slit_index)/Float(slits_count))
        let slitColor: UIColor = UIColor(hue: h, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        // RGB値を3桁ゼロ埋めで取得
        let r = NSString(format: "%03d", Int(slitColor.getRed()))
        let g = NSString(format: "%03d", Int(slitColor.getGreen()))
        let b = NSString(format: "%03d", Int(slitColor.getBlue()))
        
        uart("\(r).\(g).\(b)\n")
      }
    }
    prev_deg = current_deg
    
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
  
  func wheel(position: Int) -> String{
    let MAX_VAL = 60
    if position < 85 {
      return "\((position*3)*MAX_VAL/255).\((255-position*3)*MAX_VAL/255).0"
    }
    else if position < 170 {
      return "\((255-position*3)*MAX_VAL/255)).0.\((position*3)*MAX_VAL/255)"
    }
    else {
      return "0.\((position*3)*MAX_VAL/255).\((255-position*3)*MAX_VAL/255))"
    }
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
    
    for i in 0..<slits_count {
      let slit = slit_degs[i]
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


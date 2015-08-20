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
  var player1: AVAudioPlayer!
  var player2: AVAudioPlayer!
  var player3: AVAudioPlayer!
  var player4: AVAudioPlayer!
  var player5: AVAudioPlayer!
  var player6: AVAudioPlayer!
  var player7: AVAudioPlayer!
  var player8: AVAudioPlayer!
  
  let slits = [
    "sample.mp3",
    "sample.mp3",
    "sample.mp3",
    "sample.mp3",
    "sample.mp3",
    "sample.mp3",
    "sample.mp3",
    "sample.mp3"
  ]
  var leds: Array<UIView> = []
  var prev_deg: Double = 0.0
  var slit_degs: Array<Double> = [] // 分割数に応じて360度を当分した角度を保持しておく配列
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let count = Double(slits.count)
    for i in 0..<slits.count {
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
    
    let sound_data = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("sample", ofType: "mp3")!)
    player1 = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
    player1.prepareToPlay()
    player2 = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
    player2.prepareToPlay()
    player3 = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
    player3.prepareToPlay()
    player4 = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
    player4.prepareToPlay()
    player5 = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
    player5.prepareToPlay()
    player6 = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
    player6.prepareToPlay()
    player7 = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
    player7.prepareToPlay()
    player8 = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
    player8.prepareToPlay()
    players = [
      player1,
      player2,
      player3,
      player4,
      player5,
      player6,
      player7,
      player8
    ]
    
    MM.deviceMotionUpdateInterval = MM_UPDATE_INTERVAL
    
    if MM.deviceMotionAvailable {
      MM.deviceMotionUpdateInterval = MM_UPDATE_INTERVAL
      MM.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
        [weak self] (data: CMDeviceMotion!, error: NSError!) in
        
        let rotation = atan2(data.gravity.x, data.gravity.y) - M_PI
        self?.updateRotation(rotation)
      }
    }
    
    NSLog("Konashi.isConnected:\(Konashi.isConnected())")
    
    Konashi.shared().connectedHandler = {
      NSLog("CONNECTED");
    }
    
    Konashi.shared().readyHandler = {
      NSLog("READY");
      
      Konashi.uartMode(KonashiUartMode.Enable, baudrate: KonashiUartBaudrate.Rate9K6)

      // LED2を点灯させる
//      Konashi.pinMode(KonashiDigitalIOPin.DigitalIO1, mode: KonashiPinMode.Output)
//      Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO1, value: KonashiLevel.High)
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
  func uart(str: String){
    let res = Konashi.uartWriteString(str)
    if res == KonashiResult.Success {
      NSLog("KonashiResultSuccess")
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
        let slit = self.slits[slit_index]
        let led = leds[slit_index]
        activate(led)
        
        let player = players[slit_index]
        player.play()
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
    
    for i in 0..<slits.count {
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


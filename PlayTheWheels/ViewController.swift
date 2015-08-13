//
//  ViewController.swift
//  PlayTheWheels
//
//  Created by Naokazu Terada on 2015/08/13.
//  Copyright (c) 2015年 Karappo Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var find: UIButton!
  @IBOutlet weak var sendR: UIButton!
  @IBOutlet weak var sendG: UIButton!
  @IBOutlet weak var sendB: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSLog("Konashi.isConnected:\(Konashi.isConnected())")
    
    Konashi.shared().connectedHandler = {
      NSLog("CONNECTED");
    }
    
    Konashi.shared().readyHandler = {
      NSLog("READY");
      
//      Konashi.uartBaudrate(KonashiUartBaudrate.Rate9K6)
//      Konashi.uartMode(KonashiUartMode.Enable)
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

}


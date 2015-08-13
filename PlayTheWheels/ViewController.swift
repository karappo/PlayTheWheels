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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    Konashi.shared().readyHandler = {
      // LED2を点灯させる
      Konashi.pinMode(KonashiDigitalIOPin.DigitalIO1, mode: KonashiPinMode.Output)
      Konashi.digitalWrite(KonashiDigitalIOPin.DigitalIO1, value: KonashiLevel.High)
    }
    
    find.addTarget(self, action: "tapFind:", forControlEvents: .TouchUpInside)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func tapFind(sender:UIButton!) {
    Konashi.find()
  }

}


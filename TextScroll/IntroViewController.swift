//
//  IntroViewController.swift
//  TextScroll
//
//  Created by Michelle Feng on 7/11/16.
//  Copyright © 2016 cssummer16. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {
    
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton.layer.cornerRadius = 10
        startButton.clipsToBounds = true
    }
}
//
//  TutorialViewController.swift
//  TextScroll
//
//  Created by cssummer16 on 7/13/16.
//  Copyright © 2016 cssummer16. All rights reserved.
//

import UIKit
import CoreMotion
import QuartzCore

class TutorialViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var blurFilterRight: UIVisualEffectView!
    @IBOutlet weak var blurFilterLeft: UIVisualEffectView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var controlSwitch: UISwitch!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var switchLabel: UILabel!
    
    let maxSize = CGSizeMake(99999, 99999) //max size of the scrollview
    let font = UIFont(name: "Courier", size: 100)!
    
    var finishedTutorial = false
    
    //Tilt configuration settings
    var switchIsOn = false //Gotten from Instructions V.C.
    var tiltMapping = 0 //way that scrolling will react to tilt. 1: linear 0: impatient developer mode
    var nextStep = "showLabel" //Helps button determine which transition to execute
    
    //Blur settings
    let blurFilterSize = CGFloat(250) //set width of blur filter
    var hideBlur = false //set hide/ not hide blur filter
    
    //Variables to set specific boundaries of each part of the textscroll
    var label: UILabel! //holds the text
    var frame: CGRect! //bounds for the text label
    let screenRect: CGRect = UIScreen.mainScreen().bounds
    
    @IBOutlet weak var svWidth: NSLayoutConstraint!
    @IBOutlet weak var svHeight: NSLayoutConstraint!
    
    @IBOutlet weak var blurLeftWidth: NSLayoutConstraint!
    @IBOutlet weak var blurLeftHeight: NSLayoutConstraint!
    
    @IBOutlet weak var blurRightWidth: NSLayoutConstraint!
    @IBOutlet weak var blurRightHeight: NSLayoutConstraint!
    
    //Start on iteration at -1 for acclimation text
    var text: String!
    var iteration:Int=(-1)
    let totalIterations:Int = 1 //set how many text samples to give before submission
    
    //Different types of text
    let textTypes:Array<String>=["Semantics","Syntactic","Lexical"]
    var textVersion:String!
    
    //Randomly picks which version, A or B you will start with
    var versionNumber:Int=Int(arc4random_uniform(2))
    let textVersions:Array<String>=["A","B"]
    
    //The number of texts per text type
    let numberOfTexts:Int=4
    var nextText:String!
    var textType:String!
    
    var doneWithText = false
    
    var textDictionary:Dictionary<String,String>!
    var masterDataDictionary = Dictionary<String, [(Double, Double)]>()
    var data: [(Double, Double)] = []
    
    //Accelerometer setup
    var motionManager: CMMotionManager!
    var queue: NSOperationQueue!
    var accel: Double!
    
    //Misc
    var anim: CAKeyframeAnimation = CAKeyframeAnimation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.layer.cornerRadius = 10
        nextButton.clipsToBounds = true
        
        scrollView.alpha = 0.0
        blurFilterLeft.alpha = 0.0
        blurFilterRight.alpha = 0.0
        switchLabel.hidden = true
        controlSwitch.hidden = true
        
        if !switchIsOn{
            controlSwitch.setOn(false, animated: false)
        }
        
        //Create the text inside the ScrollView
        let screenWidth = screenRect.size.width
        
        text = getNextText()
        let strSize = (text as NSString).boundingRectWithSize(maxSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName : font], context: nil)
        
        //Set up the Scroll View
        svWidth.constant = screenWidth - 100
        svHeight.constant = strSize.height + 10
        scrollView.contentSize = CGSizeMake(strSize.width, strSize.height)
        scrollView.userInteractionEnabled = false
        
        //Set up blur filter
        if hideBlur {
            blurFilterRight.hidden = true
            blurFilterLeft.hidden = true
        } else{
            blurLeftWidth.constant = blurFilterSize
            blurRightWidth.constant = blurFilterSize
            blurLeftHeight.constant = strSize.height + 10
            blurRightHeight.constant = strSize.height + 10
        }
    }
    
    func setupMotion(){
        //Set up accelerometer
        motionManager=CMMotionManager()
        queue=NSOperationQueue()
        
        if motionManager.accelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.02
            motionManager.startAccelerometerUpdatesToQueue(self.queue, withHandler: {accelerometerData, error in
                guard let accelerometerData = accelerometerData else {return}
                
                self.accel = accelerometerData.acceleration.y
                
                //multithreading required for items that don't automatically refresh on the screen after
                //they've been changed
                dispatch_async(dispatch_get_main_queue()) {
                    
                    //Control switch functionality
                    if self.controlSwitch.on {
                        self.accel = accelerometerData.acceleration.y
                    } else {
                        self.accel = -accelerometerData.acceleration.y
                    }
                    
                    //Calculate movement based off accel
                    var i = self.accel/10 //default: super speed for impatient developers
                    if self.tiltMapping == 1 {
                        i = self.accel/Double(self.text.length)
                        if abs(i) < 0.00025 {
                            i = 0.0
                        }
                    }
                    
                    if self.label.layer.timeOffset + i >= 0 && self.label.layer.timeOffset + i <= 1.0{
                        self.label.layer.timeOffset += i
                        
                        if self.nextStep == "tiltRight" && self.label.layer.timeOffset >= 0.9 {
                            self.updateInstructions("Tilt the device right to let the text scroll into view ✓ \n Tilt the device left to scroll backwards  ", fadeIn: 0.3)
                                    self.nextStep = "tiltLeft"
                        }
                        else if self.nextStep == "tiltLeft" && self.label.layer.timeOffset <= 0.7{
                            self.updateInstructions("Tilt the device right to let the text scroll into view ✓ \n Tilt the device left to scroll backwards ✓", fadeIn: 0.3)
                            self.nextButton.hidden = false
                            UIView.animateWithDuration(0.3, delay:1.0, options: .CurveEaseInOut, animations: {
                                self.nextButton.center = CGPointMake(self.nextButton.center.x, self.nextButton.center.y - 20)
                                self.nextButton.alpha = 1.0
                                }, completion: nil)
                            self.nextStep = "showSwitch"
                        }
                        else if self.nextStep == "showSwitch" && self.controlSwitch.on {
                            self.scrollView.addSubview(self.label)
                            self.label.layer.timeOffset = 0.0
                            self.controlSwitch.layer.removeAllAnimations()
                            self.updateInstructions("Tilt the device left to scroll forwards  ", fadeIn: 0.3)
                            UIView.animateWithDuration(0.3, animations: {
                                self.controlSwitch.alpha = 0.5
                            })
                            self.controlSwitch.userInteractionEnabled = false
                            self.nextStep = "reverseTiltRight"
                        }
                        else if self.nextStep == "reverseTiltRight" && self.label.layer.timeOffset >= 0.8 {
                            self.updateInstructions("Tilt the device left to scroll forwards ✓ \n Tilt the device right to scroll backwards  ", fadeIn: 0.3)
                            self.nextStep = "reverseTiltLeft"
                        }
                        else if self.nextStep == "reverseTiltLeft" && self.label.layer.timeOffset <= 0.6 {
                            self.updateInstructions("Tilt the device left to scroll forwards ✓ \n Tilt the device right to scroll backwards ✓", fadeIn: 0.3)
                            self.nextButton.hidden = false
                            UIView.animateWithDuration(0.3, delay:1.0, options: .CurveEaseInOut, animations: {
                                self.nextButton.center = CGPointMake(self.nextButton.center.x, self.nextButton.center.y - 20)
                                self.nextButton.alpha = 1.0
                                }, completion: nil)
                                self.nextStep = "freePlay"
                        }
                    }
                }
            })
        }
    }
    
    func setupText(){
        //Prep for fade-in animation
        scrollView.alpha = 0.0
        blurFilterLeft.alpha = 0.0
        blurFilterRight.alpha = 0.0
        
        let strSize = (text as NSString).boundingRectWithSize(maxSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName : font], context: nil)
        frame = CGRectMake(0, 0, strSize.width + screenRect.size.width, strSize.height) //allot enough width to let text start offscreen
        label = UILabel(frame: frame)
        label.font = font
        label.text = text
        label.textAlignment = .Right
        
        scrollView.addSubview(label)
        
        //Set up the animation
        anim.keyPath = "position.x"
        anim.values = [0, -frame.size.width + scrollView.frame.size.width - blurFilterRight.frame.width]
        anim.keyTimes = [0, 1]
        anim.duration = 1.0
        anim.removedOnCompletion = false
        anim.additive = true
        
        label.layer.addAnimation(anim, forKey: "move")
        label.layer.speed = 0.0 //so it doesn't move by itself
        label.layer.timeOffset = 0.0
        
        //Let updated view appear
        UIView.animateWithDuration(0.3, animations: {
            self.scrollView.alpha = 1.0
            self.blurFilterLeft.alpha = 0.99 //there will be an error in console but it's ok. You're technically
            self.blurFilterRight.alpha = 0.99 //not supposed to tamper for the blurview's alpha but this hasn't broken yet
        })
        nextButton.hidden = true
        doneWithText = false
    }
    
    func getNextText() -> String {
        //Determines which text to use next and returns the string of that text
        if iteration==(-1) {
            textType="Acclimation"
        }
        else {
            textType=textTypes[iteration/numberOfTexts]
        }
        let path=NSBundle.mainBundle().pathForResource(textType,ofType:"plist")
        let myDict=NSDictionary(contentsOfFile: path!)
        textDictionary=myDict as! Dictionary<String,String>
        //Switch version every text
        versionNumber=(versionNumber+1)%2
        textVersion=textVersions[versionNumber]
        
        if iteration==(-1) {nextText="1A"}
        else {
            nextText=String((iteration%numberOfTexts)+1)+textVersion
        }
        iteration += 1
        
        return textDictionary[nextText]!
    }
    
    @IBAction func nextButtonPressed(sender: AnyObject) {
        if nextStep == "showLabel" {
            setupText()
            updateInstructions("This is where the text will appear.", fadeIn: 0.2)
            nextButton.setTitle(" Try it out ", forState: UIControlState.Normal)
            self.nextButton.hidden = false
            self.nextButton.alpha = 0
            UIView.animateWithDuration(0.3, delay:1.0, options: .CurveEaseInOut, animations: {
                self.nextButton.alpha = 1.0
            }, completion: nil)
            nextStep = "tiltRight"
        }
        else if nextStep == "tiltRight" {
            setupMotion()
            updateInstructions("Tilt the device right to let the text scroll into view", fadeIn: 0.2)
            self.nextButton.hidden = true
            self.nextButton.alpha = 0
            nextButton.setTitle(" Next ", forState: UIControlState.Normal)
        }
        else if nextStep == "showSwitch" {
            updateInstructions("Great! Now try the reverse by tapping the switch on the lower right.", fadeIn: 0.2)
            self.nextButton.hidden = true
            self.nextButton.alpha = 0
            self.switchLabel.hidden = false
            self.switchLabel.alpha = 0
            self.controlSwitch.hidden = false
            self.switchLabel.alpha = 0
            label.removeFromSuperview()
            UIView.animateWithDuration(0.3, delay:1.0, options: .CurveEaseInOut, animations: {
                self.switchLabel.alpha = 1.0
                self.controlSwitch.alpha = 1.0
                }, completion: nil)
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = 1
            pulseAnimation.fromValue = 1
            pulseAnimation.toValue = 1.5
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = MAXFLOAT
            controlSwitch.layer.addAnimation(pulseAnimation, forKey: nil)
        }
        else if self.nextStep == "freePlay" {
            self.updateInstructions("Free play! \n Adjust the switch to the tilt configuration that’s most comfortable for you. \n You can still change this setting in the first passage after this tutorial.", fadeIn: 0.3)
            UIView.animateWithDuration(0.2, animations: {
                self.controlSwitch.alpha = 1.0
            })
            controlSwitch.userInteractionEnabled = true
            nextButton.hidden = false
            nextButton.setTitle(" Finish Tutorial ", forState: UIControlState.Normal)
            UIView.animateWithDuration(0.3, delay: 3.0, options: .CurveEaseInOut, animations: {
                self.nextButton.alpha = 1.0
                }, completion: nil)
            nextStep = "finish"
        }
        else if nextStep == "finish" {
            finishedTutorial = true
            performSegueWithIdentifier("toInstructionsViewController", sender: sender)
        }
    }
    
    func updateInstructions(text: String, fadeIn: Double){
        instructionsLabel.alpha = 0
        instructionsLabel.text = text
        UIView.animateWithDuration(fadeIn, animations: {
            self.instructionsLabel.alpha = 1.0
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Passes data to MVC
        if segue.identifier=="toInstructionsViewController" {
            let ivc = segue.destinationViewController as! InstructionsViewController
            ivc.controlSwitchIsOn = controlSwitch.on
            ivc.tiltMapping = tiltMapping
            ivc.finishedTutorial = finishedTutorial
            if finishedTutorial{
                ivc.iteration = 0
            }
        }
    }
}

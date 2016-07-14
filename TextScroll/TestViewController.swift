//
//  ViewController.swift
//  TextScroll
//
//  Created by Michelle Feng on 7/7/16.
//  Copyright © 2016 cssummer16. All rights reserved.
//

import UIKit
import CoreMotion
import QuartzCore

class TestViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var blurFilterRight: UIVisualEffectView!
    @IBOutlet weak var blurFilterLeft: UIVisualEffectView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var controlSwitch: UISwitch!
    @IBOutlet weak var debugLabel: UILabel!
    
    let maxSize = CGSizeMake(99999, 99999) //max size of the scrollview
    let font = UIFont(name: "Courier", size: 100)!
    
    //Tilt configuration settings
    var switchIsOn: Bool! //Gotten from Instructions V.C.
    var debugMode = false //show some helpful stats for debugging the scrollview.
    var tiltMapping = 0 //way that scrolling will react to tilt. 1: linear 0: impatient developer mode
    var finishedTutorial = false //Skips the acclimation test if tutorial was completed
    
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
    let totalIterations:Int = 2 //set how many text samples to give before submission

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
    var stopWatch = StopWatch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(finishedTutorial)
        print(iteration)
        
        nextButton.hidden = true
        nextButton.layer.cornerRadius = 10
        nextButton.clipsToBounds = true
        debugLabel.hidden = true
        stopWatch.start()
        
        if !switchIsOn{
            controlSwitch.setOn(false, animated: false)
        }
        
        //Create the text inside the ScrollView
        let screenWidth = screenRect.size.width
        setupText()
        
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
        
        //Set up moving label and update screen with the dimensions specified above
        setupMotion()
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
                        
                    }
                    else if self.label.layer.timeOffset + i >= 1.0{
                        self.label.layer.timeOffset = 1.0
                        //Make the 'next' button appear, but only do this once
                        if !self.doneWithText {
                            self.nextButton.hidden = false
                            self.nextButton.alpha = 0
                            UIView.animateWithDuration(0.1, animations: {
                                self.nextButton.center = CGPointMake(self.nextButton.center.x, self.nextButton.center.y - 20)
                                self.nextButton.alpha = 1.0
                            })
                        }
                        self.doneWithText = true
                    }
                    //Collect data
                    let timeStamp = self.stopWatch.roundTime(4)
                    let progress = self.label.layer.timeOffset
                    let dataPoint = (timeStamp, progress)
                    self.data.append(dataPoint)
                    
                    //Debug Mode
                    if self.debugMode{
                        self.debugLabel.hidden = false
                        let time = self.stopWatch.timeIntervalToString()!
                        let accel = round(1000 * self.accel)/1000
                        let progress = round(100 * self.label.layer.timeOffset)
                        self.debugLabel.text = "Time: \(time)  Accel: \(accel)  Progress: \(progress)%"
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
        
        if iteration >= 0 && !finishedTutorial {
            label.removeFromSuperview()
            
            controlSwitch.userInteractionEnabled = false
            controlSwitch.alpha = 0.2
        }
            
        else if iteration >= 1{
            masterDataDictionary["'"+nextText+textType+"'"] = data
            data = [] //clear data after entry is recorded
            print(masterDataDictionary)
        }
        
        //Prepare the button to appear as 'finish' for the next round
        if iteration + 1 == totalIterations{
            nextButton.setTitle(" Finish ", forState: UIControlState.Normal)
        }
        
        text = getNextText()
        
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
        if iteration == totalIterations{
            performSegueWithIdentifier("toMetricsViewController", sender: sender)
        }
        else{
            setupText()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Passes data to MVC
        if segue.identifier=="toMetricsViewController" {
            let mvc = segue.destinationViewController as! MetricsViewController
            masterDataDictionary["'"+nextText+textType+"'"] = data
            data = [] //clear data after entry is recorded
            mvc.masterData = self.masterDataDictionary
        }
    }
}


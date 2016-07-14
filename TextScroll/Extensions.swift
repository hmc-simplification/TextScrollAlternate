//
//  Extensions.swift
//  ScrollingLabel
//
//  .fraCreated by Adam Shaw on 6/4/15.
//  Copyright (c) 2015 Adam Shaw. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

extension UITextView {
    /**
     Allows the font size of the textView to be directly accessible
    */
    var fontSize: CGFloat {
        get {
            return self.font!.fontSize
        }
        set(newValue) {
            self.font=UIFont(name: self.font!.fontName, size: newValue)
        }
    }
}

extension UIFont {
    /**
     Gives pointSize a more apt name
    */
    var fontSize: CGFloat {
        return self.pointSize
    }
}

extension Array {
    /**
     Gives length of a list.
     Ex: [1,2,3].length -> 3
    */
    var length:Int {
        return self.count
    }
}

extension String {
    /**
     Finds distinct words within a master string separated by " " or "\n"
     Ex: "Harvey Mudd College".words -> ["Havery", "Mudd", "College"]
    */
    var words:Array<String> {
        let items=self.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        var words:[String]=[]
        for word in items {
            if word.rangeOfCharacterFromSet(NSCharacterSet.letterCharacterSet()) != nil{
                words.append(word)
            }
        }
        return words
    }
    
    /**
     Creates a more usable name for getting the number of words in a string.
     Ex: "Harvey Mudd College".wordCount -> 3
    */
    var wordCount:Int {
        return self.words.count
    }
    
    /**
    Gets the length of the average word in a string.
    Ex: "Harvey Mudd College".averageWordLength -> 5.6666666667
    */
    var averageWordLength: Double {
        let concatenatedWords=self.words.joinWithSeparator("")
        let totalCharLength=concatenatedWords.length
        return Double(totalCharLength)/Double(self.wordCount)
    }
    
    /**
     Gives a more recognizable name for getting the number of characters in a string.
     Ex: "Mudd".length -> 4
    */
    var length:Int {
        return self.characters.count
    }
    
    /**
     Returns the number of complete words before a certain character index.
     Ex: "Harvey Mudd College".findWordsBeforeIndex(13) (the "o" in "College") -> 2
     
     @param index : Index cannot be larger than length of string or negative
    */
    func findWordsBeforeIndex(index:Int) -> Int {
        //check for out of bounds
        guard index <= self.length && index >= 0 else {
            print("index is invalid!")
            return 0
        }
        
        //based off vacawama's solution from Stack Overflow
        let ranges: [NSRange]
        var indeces: [Int] = []
        
        do {
            // Create the regular expression.
            let regex = try NSRegularExpression(pattern: " ", options: [])
            
            // Use the regular expression to get an array of NSTextCheckingResult.
            // Use map to extract the range from each result.
            ranges = regex.matchesInString(self, options: [], range: NSMakeRange(0, index)).map {$0.range}
        }
        catch {
            // There was a problem creating the regular expression
            ranges = []
            indeces = []
            return 0
        }
        
        for range in ranges {
            indeces.append(range.location)
        }
        
        if indeces.length == 0 {
            return 0
        }
        let completeWordsBeforeIndex = self.startIndex.advancedBy(indeces.last!)
        let substring=self.substringToIndex(completeWordsBeforeIndex)
        return substring.wordCount
    }
    
    /**
     Returns string with "drop" number of characters dropped from the end.
     If drop is larger than the size of the string, dropLast returns an empty string.
     Ex: "hello".dropLast(2) -> "hel"
     
     @param drop : (optional) default 1. the number of characters to drop from the end of the string
     */
 
    func dropLast(drop: Int = 1) -> String {
        //check for out of bounds
        guard drop <= self.length || drop >= 0 else {
            print("index is invalid!")
            return ""
        }
        let toIndex = self.length - drop
        return self.substringToIndex(self.startIndex.advancedBy(toIndex))
    }
}

extension UILabel {
    /**
    Debugger tool to find label borders
    */
    func addBorder(color:UIColor) {
        self.layer.cornerRadius=5
        self.layer.masksToBounds=true
        self.layer.borderColor=color.CGColor
        self.layer.borderWidth=4
    }
    
    /**
     Allows fontSize to be readable/writeable
     */
    var fontSize: CGFloat {
        get {
            return self.font.fontSize
        }
        set(newValue) {
            self.font=UIFont(name: self.font.fontName, size: newValue)
        }
    }
    
    /**
     Allows the fontName to be writable/mutate the font itself
     */
    var fontName: String {
        get {
            return self.font.fontName
        }
        set(newName) {
            self.font=UIFont(name: newName, size: self.font.fontSize)
        }
    }
    
}

extension NSTimeInterval {
    /**
     Allows formatting to a certain decimal point
     Ex: myTime.format(2) will return a string w/ the interval rounded to 2nd decimal
     
     @param formatInt : the decimal point to which the NSTimeInterval is to be rounded
     */
    func format(formatInt:Int) -> String {
        
        let floatVersion=Float(self)
        return floatVersion.format(formatInt)
    }
}

extension Float {
    /**
    Truncates the float after a certain decimal point
    Ex: 1.2345.format(2) -> 1.23
     
    @param formatInt : the decimal point to which the float is to be rounded
    */
    func format(formatInt:Int) -> String {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.minimumFractionDigits=formatInt
        numberFormatter.maximumFractionDigits=formatInt
        return numberFormatter.stringFromNumber(self) ?? "\(self)"
    }
}

extension Dictionary {
    /**
    Returns a python-friendly description format
    */
    func printDict() -> String {
        var stringToReturn="{"
        for (key,value) in self {
            stringToReturn+="\(key): \(value), "
        }
        //.dropLast works on its own, but doesn't work here :(
        stringToReturn.dropLast(2)
        //keeping previous code in case I misunderstood its intent....
        //stringToReturn=String(dropLast(dropLast(stringToReturn.characters)))
        stringToReturn+="}"
        return stringToReturn
        //TODO: polish this function if we still need it
    }
}









//
//  JSSAlertView
//  JSSAlertView
//
//  Created by Jay Stakelon on 9/16/14.
//  Copyright (c) 2014 Jay Stakelon / https://github.com/stakes  - all rights reserved.
//
//  Inspired by and modeled after https://github.com/vikmeup/SCLAlertView-Swift
//  by Victor Radchenko: https://github.com/vikmeup
//

import Foundation
import UIKit

class JSSAlertView: UIViewController {
    
    var containerView:UIView!
    var alertBackgroundView:UIView!
    var dismissButton:UIButton!
    var otherButton: UIButton?
    var cancelButton:UIButton!
    var buttonLabel:UILabel!
    var otherButtonLabel: UILabel?
    var cancelButtonLabel:UILabel!
    var titleLabel:UILabel?
    var textView:UILabel!
    var contentView: UIView!
    var separateButtons: Bool!
    weak var rootViewController:UIViewController!
    var iconImage:UIImage!
    var iconImageView:UIImageView!
    var closeAction:(()->Void)!
    var otherAction:(()->Void)?
    var cancelAction:(()->Void)!
    var isAlertOpen:Bool = false
    
    enum FontType {
        case Title, Text, Button
    }
    var titleFont = "HelveticaNeue-Light"
    var textFont = "HelveticaNeue"
    var buttonFont = "HelveticaNeue-Bold"
    
    var defaultColor = UIColorFromHex(0xF2F4F4, alpha: 1)
    
    enum TextColorTheme {
        case Dark, Light
    }
    var darkTextColor = UIColorFromHex(0x000000, alpha: 0.75)
    var lightTextColor = UIColorFromHex(0xffffff, alpha: 0.9)
    
    enum ActionType {
        case Close, Cancel, Other
    }
    
    let baseHeight:CGFloat = 160.0
    var alertWidth:CGFloat = 290.0
    let buttonHeight:CGFloat = 50.0
    let padding:CGFloat = 20.0
    
    var viewWidth:CGFloat?
    var viewHeight:CGFloat?
    
    // Allow alerts to be closed/renamed in a chainable manner
    class JSSAlertViewResponder {
        let alertview: JSSAlertView
        
        init(alertview: JSSAlertView) {
            self.alertview = alertview
        }
        
        func addAction(action: ()->Void) {
            self.alertview.addAction(action)
        }
        
        func addOtherAction(action: ()->Void) {
            self.alertview.addOtherAction(action)
        }
        
        func addCancelAction(action: ()->Void) {
            self.alertview.addCancelAction(action)
        }
        
        func setTitleFont(fontStr: String) {
            self.alertview.setFont(fontStr, type: .Title)
        }
        
        func setTextFont(fontStr: String) {
            self.alertview.setFont(fontStr, type: .Text)
        }
        
        func setButtonFont(fontStr: String) {
            self.alertview.setFont(fontStr, type: .Button)
        }
        
        func setTextTheme(theme: TextColorTheme) {
            self.alertview.setTextTheme(theme)
        }
        
        @objc func close() {
            self.alertview.closeView(false)
        }
    }
    
    func setFont(fontStr: String, type: FontType) {
        switch type {
        case .Title:
            self.titleFont = fontStr
            if let font = UIFont(name: self.titleFont, size: 19) {
                self.titleLabel?.font = font
            } else {
                self.titleLabel?.font = UIFont.systemFontOfSize(19)
            }
        case .Text:
            if self.textView != nil {
                self.textFont = fontStr
                if let font = UIFont(name: self.textFont, size: 16) {
                    self.textView.font = font
                } else {
                    self.textView.font = UIFont.systemFontOfSize(16)
                }
            }
        case .Button:
            self.buttonFont = fontStr
            if let font = UIFont(name: self.buttonFont, size: 16) {
                self.buttonLabel.font = font
            } else {
                self.buttonLabel.font = UIFont.systemFontOfSize(16)
            }
        }
        // relayout to account for size changes
        self.viewDidLayoutSubviews()
    }
    
    func setTextTheme(theme: TextColorTheme) {
        switch theme {
        case .Light:
            recolorText(lightTextColor)
        case .Dark:
            recolorText(darkTextColor)
        }
    }
    
    func recolorText(color: UIColor) {
        titleLabel?.textColor = color
        if textView != nil {
            textView.textColor = color
        }
        buttonLabel.textColor = color
        if cancelButtonLabel != nil {
            cancelButtonLabel.textColor = color
        }
        
        if otherButtonLabel != nil {
            otherButtonLabel!.textColor = color
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let size = self.screenSize()
        self.viewWidth = size.width
        self.viewHeight = size.height
        
        var yPos:CGFloat = 0.0
        let contentWidth:CGFloat = self.alertWidth - (self.padding*2)
        
        // position the icon image view, if there is one
        if self.iconImageView != nil {
            yPos += iconImageView.frame.height
            let centerX = (self.alertWidth-self.iconImageView.frame.width)/2
            self.iconImageView.frame.origin = CGPoint(x: centerX, y: self.padding)
            yPos += padding
        }
        
        // position the title
        if let titleLabel = titleLabel {
            let titleString = titleLabel.text! as NSString
            let titleAttr = [NSFontAttributeName:titleLabel.font]
            let titleSize = CGSize(width: contentWidth, height: 90)
            let titleRect = titleString.boundingRectWithSize(titleSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: titleAttr, context: nil)
            yPos += padding
            self.titleLabel!.frame = CGRect(x: self.padding, y: yPos, width: self.alertWidth - (self.padding*2), height: ceil(titleRect.size.height))
            yPos += ceil(titleRect.size.height)
        }
        
        // position text
        if self.textView != nil {
            let realSize = textView.sizeThatFits(CGSizeMake(contentWidth, 200))
            let textSize = CGSize(width: contentWidth, height: CGFloat(fminf(fmaxf(Float(20.0), Float(realSize.height)), Float(200))))
            self.textView.frame = CGRect(x: self.padding, y: yPos + 5, width: self.alertWidth - (self.padding*2), height: textSize.height + 15)
            yPos += ceil(textView.frame.size.height)
        }
        
        yPos += self.padding
        
        // position content view
        if self.contentView != nil {
            if self.alertWidth - (self.padding*2) > self.contentView.frame.size.width {
                let currentFrame = CGRect(x: contentView.frame.origin.x, y: yPos, width: contentView.frame.size.width, height: contentView.frame.size.height)
                contentView.frame = currentFrame
                contentView.center = CGPointMake(containerView.frame.size.width/2, contentView.center.y)
            } else {
                self.contentView.frame = CGRect(x: self.padding, y: yPos, width: self.alertWidth - (self.padding*2), height: self.contentView.frame.size.height)
            }
            
            yPos += ceil(self.contentView.frame.size.height)
        }
        
        // position the buttons
        var buttonWidth = self.alertWidth
        if self.separateButtons == true {
            self.dismissButton.frame = CGRect(x: 0, y: yPos, width: buttonWidth, height: self.buttonHeight)
            if self.buttonLabel != nil {
                self.buttonLabel.frame = CGRect(x: self.padding, y: (self.buttonHeight/2) - 15, width: buttonWidth - (self.padding*2), height: 30)
            }
            
            yPos += self.dismissButton.frame.size.height + 1
            
            if self.otherButton != nil {
                self.otherButton!.frame = CGRect(x: 0, y: yPos, width: buttonWidth-0.5, height: self.buttonHeight)
                if self.otherButtonLabel != nil {
                    self.otherButtonLabel!.frame = CGRect(x: self.padding, y: (self.buttonHeight/2) - 15, width: buttonWidth - (self.padding*2), height: 30)
                }
                
                yPos += self.otherButton!.frame.size.height + 1
            }
            
            if self.cancelButton != nil {
                self.cancelButton.frame = CGRect(x: 0, y: yPos, width: buttonWidth-0.5, height: self.buttonHeight)
                if self.cancelButtonLabel != nil {
                    self.cancelButtonLabel.frame = CGRect(x: self.padding, y: (self.buttonHeight/2) - 15, width: buttonWidth - (self.padding*2), height: 30)
                }
            }
            
        } else {
            if self.cancelButton != nil {
                buttonWidth = self.alertWidth/2
                self.cancelButton.frame = CGRect(x: 0, y: yPos, width: buttonWidth-0.5, height: self.buttonHeight)
                if self.cancelButtonLabel != nil {
                    self.cancelButtonLabel.frame = CGRect(x: self.padding, y: (self.buttonHeight/2) - 15, width: buttonWidth - (self.padding*2), height: 30)
                }
            }
            
            let buttonX = buttonWidth == self.alertWidth ? 0 : buttonWidth
            self.dismissButton.frame = CGRect(x: buttonX, y: yPos, width: buttonWidth, height: self.buttonHeight)
            if self.buttonLabel != nil {
                self.buttonLabel.frame = CGRect(x: self.padding, y: (self.buttonHeight/2) - 15, width: buttonWidth - (self.padding*2), height: 30)
            }
        }
        
        // set button fonts
        if self.buttonLabel != nil {
            buttonLabel.font = UIFont(name: self.buttonFont, size: 18)
        }
        if self.cancelButtonLabel != nil {
            cancelButtonLabel.font = UIFont(name: self.buttonFont, size: 18)
        }
        if self.otherButtonLabel != nil {
            otherButtonLabel!.font = UIFont(name: self.buttonFont, size: 18)
        }
        
        yPos += self.buttonHeight
        
        // size the background view
        self.alertBackgroundView.frame = CGRect(x: 0, y: 0, width: self.alertWidth, height: yPos)
        
        // size the container that holds everything together
        self.containerView.frame = CGRect(x: (self.viewWidth!-self.alertWidth)/2, y: (self.viewHeight! - yPos)/2, width: self.alertWidth, height: yPos)
    }
    
    
    
    func info(viewController: UIViewController, title: String, text: String?=nil, buttonText: String?=nil, cancelButtonText: String?=nil) -> JSSAlertViewResponder {
        let alertview = self.show(viewController, title: title, text: text, buttonText: buttonText, cancelButtonText: cancelButtonText, color: UIColorFromHex(0x3498db, alpha: 1))
        alertview.setTextTheme(.Light)
        return alertview
    }
    
    func success(viewController: UIViewController, title: String, text: String?=nil, buttonText: String?=nil, cancelButtonText: String?=nil) -> JSSAlertViewResponder {
        return self.show(viewController, title: title, text: text, buttonText: buttonText, cancelButtonText: cancelButtonText, color: UIColorFromHex(0x2ecc71, alpha: 1))
    }
    
    func warning(viewController: UIViewController, title: String, text: String?=nil, buttonText: String?=nil, cancelButtonText: String?=nil) -> JSSAlertViewResponder {
        return self.show(viewController, title: title, text: text, buttonText: buttonText, cancelButtonText: cancelButtonText, color: UIColorFromHex(0xf1c40f, alpha: 1))
    }
    
    func danger(viewController: UIViewController, title: String, text: String?=nil, buttonText: String?=nil, cancelButtonText: String?=nil) -> JSSAlertViewResponder {
        let alertview = self.show(viewController, title: title, text: text, buttonText: buttonText, cancelButtonText: cancelButtonText, color: UIColorFromHex(0xe74c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        return alertview
    }
    
    func show(viewController: UIViewController, title: String?=nil, text: String?=nil, contentView: UIView?=nil, buttonText: String?=nil, otherButtonText: String?=nil, cancelButtonText: String?=nil, color: UIColor?=nil, iconImage: UIImage?=nil, separateButtons: Bool?=false) -> JSSAlertViewResponder {
        
        self.rootViewController = viewController.view.window!.rootViewController
        self.rootViewController.addChildViewController(self)
        self.rootViewController.view.addSubview(view)
        
        self.view.backgroundColor = UIColorFromHex(0x000000, alpha: 0.7)
        
        self.separateButtons = separateButtons
        
        var baseColor:UIColor?
        if let customColor = color {
            baseColor = customColor
        } else {
            baseColor = self.defaultColor
        }
        let textColor = self.darkTextColor
        
        let sz = self.screenSize()
        self.viewWidth = sz.width
        self.viewHeight = sz.height
        
        self.view.frame.size = sz
        
        // Container for the entire alert modal contents
        self.containerView = UIView()
        self.view.addSubview(self.containerView!)
        
        // Background view/main color
        self.alertBackgroundView = UIView()
        alertBackgroundView.backgroundColor = baseColor
        alertBackgroundView.layer.cornerRadius = 4
        alertBackgroundView.layer.masksToBounds = true
        self.containerView.addSubview(alertBackgroundView!)
        
        // Icon
        self.iconImage = iconImage
        if self.iconImage != nil {
            self.iconImageView = UIImageView(image: self.iconImage)
            self.containerView.addSubview(iconImageView)
        }
        
        // Title
        if let title = title {
            self.titleLabel = UILabel()
            titleLabel!.textColor = textColor
            titleLabel!.numberOfLines = 0
            titleLabel!.textAlignment = .Center
            titleLabel!.font = UIFont(name: self.titleFont, size: 19)
            titleLabel!.text = title
            self.containerView.addSubview(titleLabel!)
        }
        
        // View text
        if let text = text {
            self.textView = UILabel()
            textView.textColor = textColor
            textView.textAlignment = .Center
            textView.font = UIFont(name: self.textFont, size: 16)
            textView.backgroundColor = UIColor.clearColor()
            textView.text = text
            textView.numberOfLines = 20
            textView.lineBreakMode = .ByTruncatingTail
            self.containerView.addSubview(textView)
        }
        
        if let contentView = contentView {
            self.contentView = contentView
            self.containerView.addSubview(self.contentView)
        }
        
        // Button
        self.dismissButton = UIButton()
        let buttonColor = UIImage.withColor(UIColorFromHex(0xE7EBF0, alpha: 0.7))
        let buttonHighlightColor = UIImage.withColor(UIColorFromHex(0xE7EBF0, alpha: 0.8))
        dismissButton.setBackgroundImage(buttonColor, forState: .Normal)
        dismissButton.setBackgroundImage(buttonHighlightColor, forState: .Highlighted)
        dismissButton.addTarget(self, action: "buttonTap", forControlEvents: .TouchUpInside)
        alertBackgroundView!.addSubview(dismissButton)
        // Button text
        self.buttonLabel = UILabel()
        buttonLabel.textColor = UIColorFromHex(0x008DFF)
        buttonLabel.numberOfLines = 1
        buttonLabel.textAlignment = .Center
        if let text = buttonText {
            buttonLabel.text = text
        } else {
            buttonLabel.text = "OK"
        }
        dismissButton.addSubview(buttonLabel)
        
        // other cancel button
        if let _ = cancelButtonText {
            self.cancelButton = UIButton()
            let buttonColor = UIImage.withColor(UIColorFromHex(0xE7EBF0, alpha: 0.7))
            let buttonHighlightColor = UIImage.withColor(UIColorFromHex(0xE7EBF0, alpha: 0.8))
            cancelButton.setBackgroundImage(buttonColor, forState: .Normal)
            cancelButton.setBackgroundImage(buttonHighlightColor, forState: .Highlighted)
            cancelButton.addTarget(self, action: "cancelButtonTap", forControlEvents: .TouchUpInside)
            alertBackgroundView!.addSubview(cancelButton)
            // Button text
            self.cancelButtonLabel = UILabel()
            cancelButtonLabel.textColor = UIColorFromHex(0x008DFF)
            cancelButtonLabel.numberOfLines = 1
            cancelButtonLabel.textAlignment = .Center
            if let text = cancelButtonText {
                cancelButtonLabel.text = text
            }
            
            cancelButton.addSubview(cancelButtonLabel)
        }
        
        if let _ = otherButtonText {
            self.otherButton = UIButton()
            let buttonColor = UIImage.withColor(UIColorFromHex(0xE7EBF0, alpha: 0.7))
            let buttonHighlightColor = UIImage.withColor(UIColorFromHex(0xE7EBF0, alpha: 0.8))
            otherButton!.setBackgroundImage(buttonColor, forState: .Normal)
            otherButton!.setBackgroundImage(buttonHighlightColor, forState: .Highlighted)
            otherButton!.addTarget(self, action: "otherButtonTap", forControlEvents: .TouchUpInside)
            alertBackgroundView!.addSubview(otherButton!)
            // Button text
            self.otherButtonLabel = UILabel()
            otherButtonLabel!.textColor = UIColorFromHex(0x008DFF)
            otherButtonLabel!.numberOfLines = 1
            otherButtonLabel!.textAlignment = .Center
            if let text = otherButtonText {
                otherButtonLabel!.text = text
            }
            
            otherButton!.addSubview(otherButtonLabel!)
            cancelButtonLabel.textColor = UIColorFromHex(0xFB5050)
        }
        
        // Animate it in
        self.view.alpha = 0
        UIView.animateWithDuration(0.2, animations: {
            self.view.alpha = 1
        })
        self.containerView.frame.origin.x = self.view.center.x
        self.containerView.center.y = -500
        UIView.animateWithDuration(0.5, delay: 0.05, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            self.containerView.center = self.view.center
            }, completion: { finished in
                
        })
        
        isAlertOpen = true
        return JSSAlertViewResponder(alertview: self)
    }
    
    func addAction(action: ()->Void) {
        self.closeAction = action
    }
    
    func buttonTap() {
        closeView(true, source: .Close);
    }
    
    func addCancelAction(action: ()->Void) {
        self.cancelAction = action
    }
    
    func cancelButtonTap() {
        closeView(true, source: .Cancel);
    }
    
    func addOtherAction(action: ()->Void) {
        self.otherAction = action
    }
    
    func otherButtonTap() {
        closeView(true, source: .Other);
    }
    
    func closeView(withCallback:Bool, source:ActionType = .Close) {
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.containerView.center.y = self.view.center.y + self.viewHeight!
            self.containerView.layoutIfNeeded()
            }, completion: { finished in
                UIView.animateWithDuration(0.1, animations: {
                    self.view.alpha = 0
                    }, completion: { finished in
                        if withCallback {
                            if let action = self.closeAction where source == .Close {
                                action()
                            } else if let action = self.cancelAction where source == .Cancel {
                                action()
                            } else if let action = self.otherAction where source == .Other {
                                action()
                            }
                        }
                        self.removeView()
                })
                
        })
    }
    
    func removeView() {
        isAlertOpen = false
        self.removeFromParentViewController()
        self.view.removeFromSuperview()
    }
    
    
    func screenSize() -> CGSize {
        let screenSize = UIScreen.mainScreen().bounds.size
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) && UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation) {
            return CGSizeMake(screenSize.height, screenSize.width)
        }
        return screenSize
    }
    
}





// Utility methods + extensions

// Extend UIImage with a method to create
// a UIImage from a solid color
//
// See: http://stackoverflow.com/questions/20300766/how-to-change-the-highlighted-color-of-a-uibutton
extension UIImage {
    class func withColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0, 0, 1, 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

// For any hex code 0xXXXXXX and alpha value,
// return a matching UIColor
func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
    let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
    let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
    let blue = CGFloat(rgbValue & 0xFF)/256.0
    
    return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
}

// For any UIColor and brightness value where darker <1
// and lighter (>1) return an altered UIColor.
//
// See: http://a2apps.com.au/lighten-or-darken-a-uicolor/
func adjustBrightness(color:UIColor, amount:CGFloat) -> UIColor {
    var hue:CGFloat = 0
    var saturation:CGFloat = 0
    var brightness:CGFloat = 0
    var alpha:CGFloat = 0
    if color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
        brightness += (amount-1.0)
        brightness = max(min(brightness, 1.0), 0.0)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    return color
}
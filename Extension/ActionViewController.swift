//
//  ActionViewController.swift
//  Extension
//
//  Created by Simon Italia on 1/11/19.
//  Copyright © 2019 SDI Group Inc. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {

    var pageTitle = ""
    var pageURL = ""
    
    @IBOutlet weak var javaScript: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //NotificatonCenter helper method to detect KB state changes so as to not obscure user input behind the iOS KB
        let notificationCenter = NotificationCenter.default
        
        //KB Notificaiton observer methods (x2)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        //Add done bar button item to submit user's custom JS input in extension UITextView
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        //Prepare for the passing of the user's custom JS input in Extension's UITextView to parent / host app
        if let inputItem = extensionContext!.inputItems.first as? NSExtensionItem {
            
            //Call closure with data received from extension, along with any error
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [unowned self] (dict, error) in
                    
                    
                    //Dictionary Data returned from above closure, is then stored in itemDictionary
                    let itemDictionary = dict as! NSDictionary
                    
                    //Pull out JS value stored in special key, "NSExtensionJavaScriptPreprocessingResultsKey" and store that in "javaScriptValues"
                    let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as! NSDictionary
                    print(javaScriptValues)
                    self.pageTitle = javaScriptValues["documentTitle"] as! String
                    self.pageURL = javaScriptValues["documentURL"] as! String
                    
                    //Use "DispatchQueue.main.async" to force call the closure on the main thread, rather than any thread
                    DispatchQueue.main.async {
                        self.title = self.pageTitle
                    }
                }
                
            }// End itemProvider
            
        }//End inputItem
        
    }//End viewDidLoad() method
    
    @objc func adjustForKeyboard(notification: Notification) {
        
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            javaScript.contentInset = UIEdgeInsets.zero
            
        } else {
            
            javaScript.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        javaScript.scrollIndicatorInsets = javaScript.contentInset
        
        let selectedRange = javaScript.selectedRange
        javaScript.scrollRangeToVisible(selectedRange)

        
    } //End adjustForKeyboard() method
    

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        
        //Pass the data from Extension app to host / parent app
        let extensionItem = NSExtensionItem()
        let finalizeArgumentKey: NSDictionary = ["customJavaScript": javaScript.text]
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: finalizeArgumentKey]
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
        extensionItem.attachments = [customJavaScript]
        
        extensionContext!.completeRequest(returningItems: [extensionItem])
        
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}

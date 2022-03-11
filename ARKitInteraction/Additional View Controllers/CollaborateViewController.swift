//
//  CollaborateViewController.swift
//  ARKitInteraction
//
//  Created by Nicholas Vo on 3/9/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import ARKit
import UIKit

protocol DataEnteredDelegate: AnyObject {
    func dummyFunction()
}

class CollaborateViewController: UIViewController, UITextFieldDelegate {
    
    //passing info
    weak var delegate: DataEnteredDelegate?
    
    @IBOutlet weak var userTextField: UITextField!
    @IBOutlet weak var newUserView: UIView!
    @IBOutlet weak var notificationView: UIVisualEffectView!
    @IBOutlet weak var shareButton: UIButton!
    @IBAction func buttonClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)

        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        self.userTextField.delegate = self
        notificationView.isHidden = true
        newUserView.isHidden = true
    }
    
    @IBAction func buttonShared(_ sender: Any) {
        notificationView.isHidden = false
        newUserView.isHidden = false
        UIView.animate(withDuration: 2.2, delay: 0, options: [.beginFromCurrentState], animations: {
            self.notificationView.alpha = 0
        }, completion: nil)
        
        //Passing data
        print("got here")
        NotificationCenter.default.post(name: Notification.Name("NewFunctionName"), object: nil)
        self.delegate?.dummyFunction()
        print("yes")
    }
    
    
    
    

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    
    
    
    
    
}

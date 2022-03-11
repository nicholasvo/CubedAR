//
//  TimelineViewController.swift
//  ARKitInteraction
//
//  Created by Nicholas Vo on 3/8/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import ARKit
import UIKit

class TimelineViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var timelineButton: UIButton!
    @IBAction func buttonClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)

        dismiss(animated: true, completion: nil)
    }
    
    var restartExperienceHandler: () -> Void = {}
    
    // Outlets
    @IBOutlet weak private var versionOne: UIButton!
    @IBOutlet weak private var versionTwo: UIButton!
    @IBOutlet weak private var versionThree: UIButton!
    @IBOutlet weak private var restoreView: UIView!
    @IBOutlet weak private var confirmRestore: UIView!
    @IBOutlet weak private var restoreButton: UIButton!
    @IBOutlet weak private var timeStamp: UILabel!
    
    
    // Actions
    @IBAction private func restartExperience(_ sender: UIButton) {
        restoreView.isHidden = true
        confirmRestore.isHidden = true
        NotificationCenter.default.post(name: Notification.Name("restore"), object: nil)
    }
    
    @IBAction private func action2(_ sender: UIButton) {
        restoreView.isHidden = false
        versionTwo.setImage(UIImage(systemName: "arrowtriangle.right.fill"), for:[])
        versionOne.setImage(UIImage(systemName: "arrowtriangle.right"), for:[])
        // get the current date and time
        let currentDateTime = Date()

        // initialize the date formatter and set the style
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        timeStamp.text = ("\("Edited by You at") \(formatter.string(from: currentDateTime))")
    }
    @IBAction private func action3(_ sender: UIButton) {
        confirmRestore.isHidden = false
        
    }
    @IBAction private func action4(_ sender: UIButton) {
        confirmRestore.isHidden = true
    }
    
    override func viewDidLoad() {
        restoreView.isHidden = true
        confirmRestore.isHidden = true
        versionOne.setImage(UIImage(systemName: "arrowtriangle.right.fill"), for:[])
        
        timeStamp.text = "Edited by You: Current"
    }
}

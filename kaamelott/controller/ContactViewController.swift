//
//  ContactViewController.swift
//  kaamelott
//
//  Created by Tony Ducrocq on 11/04/2017.
//  Copyright © 2017 hubmobile. All rights reserved.
//

import UIKit
import SwiftyMarkdown

class ContactViewController : UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.dataDetectorTypes = UIDataDetectorTypes.all
        if let path = Bundle.main.path(forResource: "README", ofType: "md") {
            if let md = SwiftyMarkdown(url: URL(fileURLWithPath: path)) {
                md.h2.fontName = "AvenirNextCondensed-Bold"
                md.h2.color = UIColor.red
                md.code.fontName = "CourierNewPSMT"
                
                textView.attributedText = md.attributedString()
            }
        } else {
            fatalError("Error loading file")
        }
    }
}

//
//  LoadingViewController.swift
//  kaamelott
//
//  Created by Tony Ducrocq on 06/04/2017.
//  Copyright © 2017 hubmobile. All rights reserved.
//

import UIKit

class LoadingViewController : UIViewController {
    
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressLabel.text = ""
        activityIndicator.startAnimating()
        
        SoundProvider.sounds(soundsResponseHandler: { (sounds, error) in
            self.performSegue(withIdentifier: "main", sender: nil)
        }) { (file, downloaded, count) in
            self.progressLabel.text = "\(downloaded) / \(count)\n\(file) downloaded"
            print("success for download \(file) \(downloaded) / \(count)")
        }
    }
    
}

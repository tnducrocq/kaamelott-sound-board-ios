//
//  LoadingViewController.swift
//  kaamelott
//
//  Created by Tony Ducrocq on 06/04/2017.
//  Copyright © 2017 hubmobile. All rights reserved.
//

import UIKit

class LoadingViewController : UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SoundProvider.sounds { (sounds, error) in
            self.performSegue(withIdentifier: "main", sender: nil)
        }
    }
    
}

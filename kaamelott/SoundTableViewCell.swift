//
//  RestaurantTableViewCell.swift
//  FoodPin
//
//  Created by Simon Ng on 11/7/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class SoundTableViewCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var thumbnailImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

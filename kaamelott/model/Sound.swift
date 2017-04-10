//
//  Sound.swift
//  kaamelott
//
//  Created by Tony Ducrocq on 06/04/2017.
//  Copyright © 2017 hubmobile. All rights reserved.
//

import Foundation
import CoreData

extension SoundMO {
    class func newInstance(character: String, episode: String, file: String, title: String, context: NSManagedObjectContext) -> SoundMO {
        let item = SoundMO(context: context)
        item.character = character
        item.episode = episode
        item.file = file
        item.title = title
        return item
    }
}

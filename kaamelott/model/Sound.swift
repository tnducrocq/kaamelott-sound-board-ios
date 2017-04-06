//
//  Sound.swift
//  kaamelott
//
//  Created by Tony Ducrocq on 06/04/2017.
//  Copyright © 2017 hubmobile. All rights reserved.
//

import Foundation
import EVReflection
import CoreData

class Sound : EVObject {
    var character : String = ""
    var episode : String = ""
    var file : String = ""
    var title : String = ""
    
    func toSoundMO(context: NSManagedObjectContext) -> SoundMO {
        return SoundMO.newInstance(character: character, episode: episode, file: file, title: title, context: context)
    }
}

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


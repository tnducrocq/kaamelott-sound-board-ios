//
//  Sound.swift
//  kaamelott
//
//  Created by Tony Ducrocq on 06/04/2017.
//  Copyright © 2017 hubmobile. All rights reserved.
//

import Foundation
import Alamofire
import EVReflection
import AlamofireJsonToObjects
import Haneke
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

typealias SoundsResponseHandler = (_ response : [Sound]?, _ error:Error?) -> ()

class SoundProvider {

    static var baseApiUrl : String = "https://raw.githubusercontent.com/2ec0b4/kaamelott-soundboard/master/sounds"
    
    
    typealias fetchDataCompletionHandler = ([SoundMO]) -> Void
    static func fetchData(context: NSManagedObjectContext, completion: @escaping fetchDataCompletionHandler) {
        DispatchQueue.global(qos: .background).async {
            let fetchRequest: NSFetchRequest<SoundMO> = SoundMO.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            do {
                try fetchResultController.performFetch()
                if let fetchedObjects = fetchResultController.fetchedObjects {
                    DispatchQueue.main.async {
                        completion(fetchedObjects)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    typealias insertDataCompletionHandler = () -> Void
    static func insertData(completion: insertDataCompletionHandler? = nil) {
        DispatchQueue.global(qos: .background).async {
           
        }
    }
    
    static func sounds(soundsResponseHandler: @escaping SoundsResponseHandler) {
        let url = "\(SoundProvider.baseApiUrl)/sounds.json"
        Alamofire.request(url, method: .get).responseArray { (response: DataResponse<[Sound]>) in
            if let sounds = response.result.value {
                
                let cache = Shared.dataCache
                var filesToDownload = sounds.count
                if filesToDownload == 0 {
                    soundsResponseHandler(response.result.value, response.result.error)
                }
                
                if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                    
                    fetchData(context: appDelegate.persistentContainer.viewContext, completion: { (existingSounds) in
                        
                        let dictionnary = existingSounds.toDictionary { $0.title! }
                        for sound in sounds {
                            if dictionnary.index(forKey: sound.title) == nil {
                                let _ = sound.toSoundMO(context: appDelegate.persistentContainer.viewContext)
                                
                                let url = URL(string: "\(SoundProvider.baseApiUrl)/\(sound.file)")!
                                cache.fetch(URL: url).onSuccess { data in
                                    // Do something with data
                                    print("success for download \(sound.file)")
                                    filesToDownload -= 1
                                    if filesToDownload == 0 {
                                        soundsResponseHandler(response.result.value, response.result.error)
                                    }
                                }
                            } else {
                                filesToDownload -= 1
                                if filesToDownload == 0 {
                                    soundsResponseHandler(response.result.value, response.result.error)
                                }
                            }
                        }
                        
                        appDelegate.saveContext()
                        
                        
                    })
                    
                    
                }
            }
        }
    }
}

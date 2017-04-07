//
//  SoundProvider.swift
//  kaamelott
//
//  Created by Tony Ducrocq on 06/04/2017.
//  Copyright © 2017 hubmobile. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import AlamofireJsonToObjects
import Haneke

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
    
    static func sounds(soundsResponseHandler: @escaping SoundsResponseHandler) {
        let url = "\(SoundProvider.baseApiUrl)/sounds.json"
        Alamofire.request(url, method: .get).responseArray { (response: DataResponse<[Sound]>) in
            if let sounds = response.result.value {
                processSounds(sounds: sounds, soundsResponseHandler: soundsResponseHandler)
            }
        }
    }
    
    private static func processSounds(sounds: [Sound], soundsResponseHandler: @escaping SoundsResponseHandler) {
        let cache = Shared.dataCache
        var filesToDownload : Int = sounds.count
        guard let appDelegate = (UIApplication.shared.delegate as? AppDelegate), filesToDownload > 0 else {
            soundsResponseHandler([], nil)
            return
        }
        
        let context = appDelegate.persistentContainer.newBackgroundContext()
        fetchData(context: context, completion: { (existingSounds) in
            let dictionnary = existingSounds.toDictionary { $0.title! }
            for sound in sounds {
                if dictionnary.index(forKey: sound.title) == nil {
                    let _ = sound.toSoundMO(context: context)
                }
                let url = URL(string: "\(SoundProvider.baseApiUrl)/\(sound.file)")!
                cache.fetch(URL: url).onSuccess { data in
                    // Do something with data
                    print("success for download \(sound.file) \(sounds.count - filesToDownload + 1) / \(sounds.count)")
                    filesToDownload -= 1
                    if filesToDownload == 0 {
                        soundsResponseHandler(sounds, nil)
                    }
                }
            }
            appDelegate.saveContext(context)
        })
    }
}

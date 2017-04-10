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
import Haneke

typealias SoundsResponseHandler = (_ response : [SoundMO]?, _ error:Error?) -> ()
typealias SoundsProgressHandler = (_ fileName: String, _ downloaded : Int, _ count : Int) -> ()
class SoundProvider {
    
    static var baseApiUrl : String = "https://raw.githubusercontent.com/2ec0b4/kaamelott-soundboard/master/sounds"
    
    typealias fetchDataCompletionHandler = (_ sounds: [SoundMO]?, _ error:Error?) -> Void
    static func fetchData(sortKey : String = "titleClean", context: NSManagedObjectContext, completion: @escaping fetchDataCompletionHandler) {
        DispatchQueue.global(qos: .background).async {
            let fetchRequest: NSFetchRequest<SoundMO> = SoundMO.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            do {
                try fetchResultController.performFetch()
                if let fetchedObjects = fetchResultController.fetchedObjects {
                    DispatchQueue.main.async {
                        completion(fetchedObjects, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    static func sounds(soundsResponseHandler: @escaping SoundsResponseHandler, progressHandler: @escaping SoundsProgressHandler) {
        let url = "\(SoundProvider.baseApiUrl)/sounds.json"
        Alamofire.request(url, method: .get).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                let json = data as! [Any]
                DispatchQueue.global(qos: .background).async {
                    sounds(json: json, soundsResponseHandler: { (sounds, error) in
                        DispatchQueue.main.async {
                            soundsResponseHandler(sounds, error)
                        }
                    }, progressHandler: { (file, downloaded, count) in
                        DispatchQueue.main.async {
                            progressHandler(file, downloaded, count)
                        }
                    })
                }
                
            case .failure(let error):
                soundsResponseHandler(nil, error)
            }
        }
    }
    
    private static func sounds(json: [Any], soundsResponseHandler: @escaping SoundsResponseHandler, progressHandler: @escaping SoundsProgressHandler) {
        guard let appDelegate = (UIApplication.shared.delegate as? AppDelegate) else {
            soundsResponseHandler([], nil)
            return
        }
        let context = appDelegate.persistentContainer.newBackgroundContext()
        switch parseSounds(json: json, context: context) {
        case .success(let sounds):
            let cache = Shared.dataCache
            var filesToDownload : Int = sounds.count
            for sound in sounds {
                let file = sound.file!
                let url : URL = URL(string: "\(SoundProvider.baseApiUrl)/\(file)")!
                cache.fetch(URL: url).onSuccess { data in
                    progressHandler(file, sounds.count - filesToDownload + 1, sounds.count)
                    filesToDownload -= 1
                    if filesToDownload == 0 {
                        soundsResponseHandler(sounds, nil)
                    }
                }.onFailure({ (error) in
                    filesToDownload -= 1
                    if filesToDownload == 0 {
                        soundsResponseHandler(sounds, nil)
                    }
                })
            }
        case .failure(let error):
            soundsResponseHandler(nil, error)
        }
        appDelegate.saveContext(context)
    }
    
    private static func parseSounds(json: [Any], context: NSManagedObjectContext) -> Result<[SoundMO]> {
        var sounds : [SoundMO] = []
        for element in json {
            if let obj = element as? [String:String] {
                let fetchRequest: NSFetchRequest<SoundMO> = SoundMO.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "title == %@", obj["title"]!)
                fetchRequest.sortDescriptors = []
                let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
                do {
                    try fetchResultController.performFetch()
                    if let fetchedObjects = fetchResultController.fetchedObjects, !fetchedObjects.isEmpty {
                        sounds.append(fetchedObjects.first!)
                    } else {
                        let sound = SoundMO.newInstance(character: obj["character"]!, episode: obj["episode"]!, file: obj["file"]!, title: obj["title"]!, context: context)
                        sounds.append(sound)
                    }
                } catch {
                    return Result.failure(error)
                }
            } else {
                return Result.failure(JSONParsingError(reason: .invalidDictonnary))
            }
        }
        
        return Result.success(sounds)
    }
}

struct JSONParsingError: Error {
    enum JSONParsingReason {
        case invalidDictonnary
        case invalidArray
    }
    let reason: JSONParsingReason
}

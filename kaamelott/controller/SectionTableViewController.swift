//
//  CharacterTableViewController.swift
//  kaamelott
//
//  Created by Tony Ducrocq on 06/04/2017.
//  Copyright © 2017 hubmobile. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import Haneke

class SectionTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {
    
    var player: AVAudioPlayer?
    var fetchResultController: NSFetchedResultsController<SoundMO>!
    
    var sections : [String] = []
    var searchSections : [String] = []
    var displayedSections : [String] {
        get {
            if searchController.isActive {
                return searchSections
            } else {
                return sections
            }
        }
    }
    var sounds : [String : [SoundMO]] = [:]
    var searchSounds : [String : [SoundMO]] = [:]
    var displayedSounds : [String : [SoundMO]] {
        get {
            if searchController.isActive {
                return searchSounds
            } else {
                return sounds
            }
        }
    }
    
    lazy var searchController: UISearchController = {
        return UISearchController(searchResultsController: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove the title of the back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Enable Self Sizing Cells
        tableView.estimatedRowHeight = 80.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Fetch data from data store
        fetchData {
            self.tableView.reloadData()
        }
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: Notification.Name("SoundAdded"), object: nil)
        
        // Add a search bar
        //searchController = UISearchController(searchResultsController: nil)
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search sounds..."
        searchController.searchBar.tintColor = UIColor.white
        searchController.searchBar.barTintColor = UIColor.kaamelott
    }
    
    typealias fetchDataCompletionHandler = () -> Void
    func fetchData(completion: fetchDataCompletionHandler? = nil) {
        preconditionFailure("must be override")
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return displayedSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = displayedSections[section]
        if let values = displayedSounds[key] {
            return values.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "CharacterCell") as! SectionTableViewCell
        headerCell.backgroundColor = UIColor.kaamelott
        headerCell.characterLabel.text = displayedSections[section]
        headerCell.characterImageView.image = nil
        return headerCell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SoundTableViewCell
        
        let key = displayedSections[indexPath.section]
        guard let values = displayedSounds[key] else {
            return cell
        }
        let sound = values[indexPath.row]
        
        // Configure the cell...
        cell.titleLabel.text = sound.title
        cell.characterLabel.text = sound.character
        cell.episodeLabel.text = sound.episode
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = displayedSections[indexPath.section]
        guard let values = displayedSounds[key] else {
            return
        }
        let sound = values[indexPath.row]
        
        let cache = Shared.dataCache
        let url = URL(string: "\(SoundProvider.baseApiUrl)/\(sound.file!)")!
        
        cache.fetch(URL: url).onSuccess { stream in
            
            let path = NSURL(string: DiskCache.basePath())!.appendingPathComponent("shared-data/original")
            let cached = DiskCache(path: (path?.absoluteString)!).path(forKey: url.absoluteString)
            let file = NSURL(fileURLWithPath: cached)
            
            do {
                self.player = try AVAudioPlayer(contentsOf: file as URL)
                guard let player = self.player else { return }
                
                player.prepareToPlay()
                player.play()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Search Controller
    func filterContent(for searchText: String) {
        searchSounds   = [:]
        searchSections = []
        for section in sections {
            if sounds.index(forKey: section) != nil {
                var values : [SoundMO] = []
                for sound in sounds[section]! {
                    if let character = sound.character, let title = sound.title, let episode = sound.episode {
                        if character.localizedCaseInsensitiveContains(searchText) || title.localizedCaseInsensitiveContains(searchText) || episode.localizedCaseInsensitiveContains(searchText) {
                            values.append(sound)
                        }
                    }
                }
                if !values.isEmpty {
                    searchSounds[section] = values
                    searchSections.append(section)
                }
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContent(for: searchText)
            tableView.reloadData()
        }
    }
}

class CharacterTableViewController: SectionTableViewController {
    
    override func fetchData(completion: fetchDataCompletionHandler? = nil) {
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            SoundProvider.fetchData(sortKey: "titleClean", context: context, completion: { (sounds, error) in
                if let fetchedObjects = sounds {
                    self.sections = []
                    self.sounds = [:]
                    for object in fetchedObjects {
                        let key = object.characterClean!
                        if self.sounds.index(forKey: key) == nil {
                            self.sections.append(key)
                            self.sounds[key] = [object]
                        } else {
                            self.sounds[key]?.append(object)
                        }
                    }
                    self.sections.sort(by: { (s1, s2) -> Bool in
                        return s1.folding(options: .diacriticInsensitive, locale: .current) < s2.folding(options: .diacriticInsensitive, locale: .current)
                    })
                } else if let error = error {
                    print(error)
                }
                completion?()
            })
        }
    }
}

class EpisodeTableViewController: SectionTableViewController {
    
    override func fetchData(completion: fetchDataCompletionHandler? = nil) {
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            SoundProvider.fetchData(sortKey: "titleClean", context: context, completion: { (sounds, error) in
                if let fetchedObjects = sounds {
                    self.sections = []
                    self.sounds = [:]
                    for object in fetchedObjects {
                        let key = object.episode!
                        if self.sounds.index(forKey: key) == nil {
                            self.sections.append(key)
                            self.sounds[key] = [object]
                        } else {
                            self.sounds[key]?.append(object)
                        }
                    }
                    self.sections.sort(by: { (s1, s2) -> Bool in
                        return s1.folding(options: .diacriticInsensitive, locale: .current) < s2.folding(options: .diacriticInsensitive, locale: .current)
                    })
                } else if let error = error {
                    print(error)
                }
                completion?()
            })
        }
    }
}

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

class CharacterTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {
    
    var player: AVAudioPlayer?
    var fetchResultController: NSFetchedResultsController<SoundMO>!
    
    var characters : [String] = []
    var searchCharacters : [String] = []
    var displayedCharacters : [String] {
        get {
            if searchController.isActive {
                return searchCharacters
            } else {
                return characters
            }
        }
    }
    var sounds : [String : [SoundMO]] = [:]
    var searchResults : [String : [SoundMO]] = [:]
    var displayedSounds : [String : [SoundMO]] {
        get {
            if searchController.isActive {
                return searchResults
            } else {
                return sounds
            }
        }
    }
    
    lazy var searchController: UISearchController = {
        return UISearchController(searchResultsController: nil)
    }()
    
    lazy var customRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove the title of the back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Enable Self Sizing Cells
        tableView.estimatedRowHeight = 80.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.addSubview(customRefreshControl)
        
        // Fetch data from data store
        fetchData{
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
    
    func handleRefresh() {
        fetchData {
            self.customRefreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    typealias fetchDataCompletionHandler = () -> Void
    func fetchData(completion: fetchDataCompletionHandler? = nil) {
        DispatchQueue.global(qos: .background).async {
            let fetchRequest: NSFetchRequest<SoundMO> = SoundMO.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "character", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let context = appDelegate.persistentContainer.viewContext
                self.fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
                do {
                    try self.fetchResultController.performFetch()
                    if let fetchedObjects = self.fetchResultController.fetchedObjects {
                        
                        self.characters = []
                        self.sounds = [:]
                        for object in fetchedObjects {
                            if self.sounds.index(forKey: object.character!) == nil {
                                self.characters.append(object.character!)
                                self.sounds[object.character!] = [object]
                            } else {
                                self.sounds[object.character!]?.append(object)
                            }
                        }
                        
                    }
                } catch {
                    print(error)
                }
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return displayedCharacters.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let character = displayedCharacters[section]
        if let values = displayedSounds[character] {
            return values.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "CharacterCell") as! CharacterTableViewCell
        headerCell.backgroundColor = UIColor.kaamelott
        headerCell.characterLabel.text = displayedCharacters[section]
        if let image = charactersImage[displayedCharacters[section]] {
            headerCell.characterImageView.image = UIImage(named : image)
        } else {
            headerCell.characterImageView.image = nil
        }
        return headerCell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SoundTableViewCell
        
        let character = displayedCharacters[indexPath.section]
        guard let values = displayedSounds[character] else {
              return cell
        }
        let sound = values[indexPath.row]
        
        // Configure the cell...
        cell.titleLabel.text = sound.title
        cell.characterLabel.text = sound.character
        //cell.characterImageView.image = UIImage(named: sound.character!.lowercased())
        cell.episodeLabel.text = sound.episode
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let character = displayedCharacters[indexPath.section]
        guard let values = displayedSounds[character] else {
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
        searchResults = [:]
        searchCharacters = []
        for character in characters {
            if sounds.index(forKey: character) != nil {
                var values : [SoundMO] = []
                for sound in sounds[character]! {
                    if let character = sound.character, let title = sound.title, let episode = sound.episode {
                        if character.localizedCaseInsensitiveContains(searchText) || title.localizedCaseInsensitiveContains(searchText) || episode.localizedCaseInsensitiveContains(searchText) {
                            values.append(sound)
                        }
                    }
                }
                if !values.isEmpty {
                    searchResults[character] = values
                    searchCharacters.append(character)
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

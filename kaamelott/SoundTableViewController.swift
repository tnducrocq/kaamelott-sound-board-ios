//
//  SoundTableViewController.swift
//  kaamelott
//
//  Created by Tony Ducrocq on 06/04/2017.
//  Copyright © 2017 hubmobile. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import Haneke

class SoundTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {
    
    var player: AVAudioPlayer?
    var fetchResultController: NSFetchedResultsController<SoundMO>!
    var sounds:[SoundMO] = []
    var searchResults:[SoundMO] = []
    
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
        searchController.searchBar.barTintColor = UIColor(red: 236.0/255.0, green: 236.0/255.0, blue: 236.0/255.0, alpha: 1.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //navigationController?.hidesBarsOnSwipe = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let context = appDelegate.persistentContainer.viewContext
                self.fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
                do {
                    try self.fetchResultController.performFetch()
                    if let fetchedObjects = self.fetchResultController.fetchedObjects {
                        self.sounds = fetchedObjects
                        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive {
            return searchResults.count
        } else {
            return sounds.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SoundTableViewCell
        
        // Determine if we get the sound from search result or the original array
        let sound = (searchController.isActive) ? searchResults[indexPath.row] : sounds[indexPath.row]
        
        // Configure the cell...
        cell.nameLabel.text = sound.title
        //cell.thumbnailImageView.image = UIImage(data: sound.image as! Data)
        cell.locationLabel.text = sound.character
        cell.typeLabel.text = sound.episode
        
        //cell.accessoryType = sound.isVisited ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sound = (searchController.isActive) ? searchResults[indexPath.row] : sounds[indexPath.row]
        
        
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if searchController.isActive {
            return false
        } else {
            return true
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        default:
            tableView.reloadData()
        }
        
        if let fetchedObjects = controller.fetchedObjects {
            sounds = fetchedObjects as! [SoundMO]
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    // MARK: - Search Controller
    
    func filterContent(for searchText: String) {
        searchResults = sounds.filter({ (sound) -> Bool in
            if let character = sound.character, let title = sound.title, let episode = sound.episode {
                let isMatch = character.localizedCaseInsensitiveContains(searchText) || title.localizedCaseInsensitiveContains(searchText) || episode.localizedCaseInsensitiveContains(searchText)
                return isMatch
            }
            
            return false
        })
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContent(for: searchText)
            tableView.reloadData()
        }
    }
}

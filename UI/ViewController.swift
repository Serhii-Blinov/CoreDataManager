//
//  ViewController.swift
//  CoreDataMnager
//
//  Created by Sergey on 11/21/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    @IBOutlet weak var addUserButton: UIButton! {
        didSet {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: addUserButton)
        }
    }
    
    @IBAction func addUserAction(_ sender: Any) {
        CoreDataManager.shared.save ({
            let user = User.createEntity()
            user?.bdate = Date()
            user?.name = String.random(length: 25)
        })
    }
    
    private var _fetchedResultsController: NSFetchedResultsController<User>? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var fetchedResultsController: NSFetchedResultsController<User> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let aFetchedResultsController = User.fetchedResultsController(sort: [NSSortDescriptor(key:"bdate", ascending: false)])
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        try? aFetchedResultsController.performFetch()
        
        return _fetchedResultsController!
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? TableViewCell else { return UITableViewCell() }
        let item = fetchedResultsController.object(at: indexPath)
        cell.titleLabel.text = item.name
        cell.detailLabel.text = item.bdate?.toString()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            context.delete(fetchedResultsController.object(at: indexPath))
            
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func configureCell(_ cell: UITableViewCell, withEvent item: User) {
        guard let cell = cell as? TableViewCell else { return }
        cell.titleLabel.text = item.name
        cell.detailLabel.text = item.bdate?.toString()
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            self.configureCell(self.tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! User)
        case .move:
            self.configureCell(self.tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! User)
            self.tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
}

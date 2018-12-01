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
    
    let fetchedResultsController = User.fetchedResultsController(sort: [NSSortDescriptor(key:"bdate", ascending: false)])
    
    @IBAction func addUserAction(_ sender: Any) {
        CoreDataManager.shared.save ({
            let user = User.createEntity()
            user?.bdate = Date()
            user?.name = String.random(length: 25)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchedResultsController.delegate = self
        try? self.fetchedResultsController.performFetch()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? TableViewCell else { return UITableViewCell() }
        let item = self.fetchedResultsController.object(at: indexPath)
        cell.titleLabel.text = item.name
        cell.detailLabel.text = item.bdate?.toString()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let user = (self.fetchedResultsController.object(at: indexPath))
            user.delete()
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
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
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

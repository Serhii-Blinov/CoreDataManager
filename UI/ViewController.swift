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
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addUserButton)
        }
    }
    
    @IBOutlet weak var removeAllUsersButton: UIButton! {
        didSet {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: removeAllUsersButton)
        }
    }
    
    let fetchedResultsController = User.fetchedResultsController(sort: [NSSortDescriptor(key:"bdate", ascending: false)])
    
    @IBAction func addUserAction(_ sender: Any) {
        CoreDataManager.shared.save(performBlock: {
            let user = User.createEntity()
            user?.bdate = Date()
            user?.name = String(String.random())
        })
    }
    
    @IBAction func removeAllUserAction(_ sender: Any) {
        User.deleteAll()
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
        guard let sections = self.fetchedResultsController.sections else { return 0 }
        let sectionInfo = sections[section]
        
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.className) as? TableViewCell else { return UITableViewCell() }
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
            self.fetchedResultsController.object(at: indexPath).delete()
        }
    }
    
    func configureCell(_ cell: UITableViewCell?, withEvent object: Any) {
        guard let cell = cell as? TableViewCell, let item = object as? User else { return }
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
            guard let path = newIndexPath else { return }
            self.tableView.insertRows(at: [path], with: .fade)
        case .delete:
            guard let path = indexPath else { return }
            self.tableView.deleteRows(at: [path], with: .fade)
        case .update:
            guard let path = indexPath else { return }
            self.configureCell(self.tableView.cellForRow(at: path), withEvent: anObject)
        case .move:
            guard let path = newIndexPath, let oldPath = indexPath else { return }
            self.configureCell(self.tableView.cellForRow(at: path), withEvent: anObject)
            self.tableView.moveRow(at: oldPath, to: path)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
}

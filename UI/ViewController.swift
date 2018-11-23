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
    
    var users = User.all()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = User.deleteAll()
        
        CoreDataManager.shared.save({
            let user = User.createEntity()
            user?.name = String.random()
            user?.bdate = Date()
            
        }) { status in
            self.users = User.all()
            self.tableView.reloadData()
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? TableViewCell else { return UITableViewCell() }
        guard let item = users?[indexPath.row] else { return UITableViewCell() }
        cell.titleLabel.text = item.name
        cell.detailLabel.text = item.dateStamp.toString()
        
        return cell
    }
}

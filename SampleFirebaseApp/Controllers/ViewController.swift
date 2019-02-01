//
//  ViewController.swift
//  SampleFirebaseApp
//  primesoft

import UIKit
import Firebase

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var reference: DatabaseReference!
    @IBOutlet weak var customTableView: UITableView!
    var textField: UITextField?
    var isFromEdit: Bool = false
    var editedName: String?
    var editedIndex: Int?
    var usersList = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /* Retreving user data from Firebase....*/
        self.retrieveUser()
        Fabric.sharedSDK().debug = true
    }
    
    func configurationTextField(textField: UITextField!) {
        if (textField) != nil {
            self.textField = textField!        /*Save reference to the UITextField..*/
            self.textField?.placeholder = "Enter Name"
        }
    }
    
    func openAlertView() {
        let alert = UIAlertController(title: "User Names", message: "Add names", preferredStyle: UIAlertController.Style.alert)
        alert.addTextField(configurationHandler: configurationTextField)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler:{ (UIAlertAction) in
            print("User click Ok button")
            
            if self.isFromEdit == false {
                self.addUsers()
            } else {
                if self.usersList.count > 0 {
                    self.isFromEdit = false
                    let user = self.usersList[self.editedIndex!]
                    self.updateUser(id: user.id, name: (self.textField?.text)!)
                }
            }
            self.customTableView.reloadData()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addButtonAction(_ sender: Any) {
        self.openAlertView()
        Analytics.logEvent("add_button", parameters: nil)
    }
    
    func addUsers(){                           /*  Adding user to Firebase database */
        let key = reference.childByAutoId().key
        let user = ["id":key,"userName":textField?.text!]
        reference.child(key!).setValue(user)
        usersList = [User(id: key!, name: (textField?.text)!)]
    }
    
    func updateUser(id: String, name: String) {   /*  Updating user to Firebase database */
        let user = ["id":id,"userName":name]
        reference.child(id).setValue(user)
    }
    
    func deleteUser(id: String) {      /*  Delete user from Firebase database */
        reference.child(id).setValue(nil)
    }
    
    func retrieveUser(){       /*  Retrieve user from Firebase database */
        
        reference = Database.database().reference().child("users-list")   /* Adding user-list to                         FireDatabase...*/
        
        reference.observe(DataEventType.value, with: {(snapshot) in    /* Retrieving data from Firebase Database...*/
            self.usersList.removeAll()
            if snapshot.childrenCount > 0 {
                for users in snapshot.children.allObjects as![DataSnapshot] {
                    let userObject = users.value as? [String : AnyObject]
                    let userName = userObject?["userName"]
                    let userId = userObject?["id"]
                    let user = User(id: userId as! String, name: userName as! String)
                    self.usersList.append(user)
                }
            }
            self.customTableView.reloadData()
        })
    }
    
    /*  Tableview delegates and Datasource... */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.usersList.count > 0 {
            return self.usersList.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if self.usersList.count > 0 {
            if isFromEdit == true {
                let user = self.usersList[indexPath.row]
                cell.textLabel?.text = user.name
            } else {
                self.isFromEdit = false
                let user = self.usersList[indexPath.row]
                cell.textLabel?.text = user.name
            }
        } else {
            cell.textLabel?.text = " "
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let user = self.usersList[indexPath.row]
        let editAction = UITableViewRowAction(style: .normal, title: "Edit") { (rowAction, indexPath) in
            self.isFromEdit = true
            self.openAlertView()
            self.editedName?.removeAll()
            self.editedIndex = indexPath.row
            self.editedName = user.name
            self.textField?.text = self.editedName
            Analytics.logEvent("edit_button", parameters: nil)
        }
        editAction.backgroundColor = .blue
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
            if self.usersList.count > 0 {
                self.deleteUser(id: user.id)
            } else {
                self.editedIndex = nil
            }
            self.retrieveUser()
            Analytics.logEvent("delete_button", parameters: nil)
        }
        deleteAction.backgroundColor = .red
        self.customTableView.reloadData()
        return [editAction,deleteAction]
    }
    
    @IBAction func didPressCrash(_ sender: Any) {
        print("Crash button pressed..")
        Crashlytics.sharedInstance().setObjectValue("Test value", forKey: "last_UI_action")
        assert(false)
    }
}


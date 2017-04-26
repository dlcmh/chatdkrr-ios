//
//  ViewController.swift
//  chatDKRR
//
//  Created by David Chin on 25/04/2017.
//  Copyright © 2017 David Chin. All rights reserved.
//

import UIKit
import SwiftPhoenixClient

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
//    let socket = Socket(domainAndPort: "localhost:4000", path: "socket", transport: "websocket")
    let socket = Socket(
        domainAndPort: Bundle.main.infoDictionary!["WEBSOCKET_HOST"] as! String,
        path: "socket", transport: "websocket",
        prot: Bundle.main.infoDictionary!["WEBSOCKET_PROTOCOL"] as! String
    )
    let topic = "room:lobby"
    var nameIsAssigned = false
    var username = ""
    var usernameColor = ""
    
    var chatMessages = [Message]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        messageField.delegate = self
        
        // Join the socket and establish handlers for users entering and submitting messages
        // message: needs to be an empty Dictionary if no message is intended to be sent
        socket.join(topic: topic, message: Message(message: ["": ""])) { channel in
            let chan = channel as! Channel
            
            chan.on(event: "join") {payload in
                self.statusLabel.text = "Connected"
            }
            
            chan.on(event: "new_user") {payload in
                guard
                    let payload = payload as? Message,
                    let username = payload["username"],
                    let usernameColor = payload["color"] else {
                        return
                }
                self.nameIsAssigned = true
                self.usernameColor = (usernameColor as? String)!
                self.username = (username as? String)!
                self.usernameLabel.text = username as? String
                self.usernameLabel.textColor = UIColor(hexString: (usernameColor as? String)!)
            }
            
            chan.on(event: "new_msg") {payload in
                guard
                    let payload = payload as? Message else {
                        return
                }
//                self.updateChatWindow(payload: payload)
                self.chatMessages.append(payload)
                self.tableView.reloadData()
//                print(String(describing: self.chatMessages.last!["message"] as! String))
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell") as! MessageTableViewCell
//        print("indexPath.row: \(indexPath.row)")
        let chatMessage = chatMessages[indexPath.row]
        cell.usernameLabel.text = chatMessage["username"] as? String
        cell.messageLabel.text = chatMessage["message"] as? String
        return cell
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
//    func updateChatWindow(payload: Message) {
//        let chatMessage = payload["message"] as! String
//        let updatedText = "\(chatWindow.text.appending(chatMessage))\n"
//        chatWindow.text = updatedText
//    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        let msg = messageField.text!
        var payload: Payload
        if nameIsAssigned == false {
            payload = Payload(topic: topic, event: "new_user", message: Message(message: ["username": msg]))
        } else {
            payload = Payload(
                topic: topic, event: "new_msg",
                message: Message(
                    message: [
                        "username": username,
                        "usernameColor": usernameColor,
                        "message": msg
                    ]
                )
            )
        }
        socket.send(data: payload)
        messageField.text = ""
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


extension UIColor {
    // http://stackoverflow.com/questions/24263007/how-to-use-hex-colour-values-in-swift-ios/33397427#33397427
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }

    // http://stackoverflow.com/questions/24263007/how-to-use-hex-colour-values-in-swift-ios/27270584#27270584
    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
    }
    
}


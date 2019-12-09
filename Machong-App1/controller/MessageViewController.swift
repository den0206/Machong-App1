//
//  MessageViewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/12/06.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore

class MessageViewController: MessagesViewController {
    
    var messageLists : [Message] = []
    
    let refreshController = UIRefreshControl()
    
    var chatRoomId : String!
    var memberIds : [String]!
    var membersToPush : [String]!
    
    let legitType = [kAUDIO, kVIDEO, kLOCATION, kTEXT, kPICTURE]
    var loadOld = false
    
    var newChatListner : ListenerRegistration?
    var updatelistner : ListenerRegistration?
    
    var maxMessageNumber = 0
    var minimumMessageNumber = 0
    var loadedMessageCount = 0
    
    var loadedMessages : [NSDictionary] = []
    
    var withUsers : [FUser] = []
    
 

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        messageInputBar.delegate = self
        messageInputBar.sendButton.tintColor = .lightGray
        
        loadMessage()
        
        // refresh Controll
        configureRefreshController()
        
        // メッセージ入力が始まった時に一番下までスクロールする
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        // 表示している画面とキーボードの重複を防ぐ
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        
        
    }
    

    
}

//MARK: MessageDate Source
extension MessageViewController : MessagesDataSource {
    
    func currentSender() -> SenderType {
        return Sender(senderId: FUser.currentId(), displayName: FUser.currentUser()!.fullname)
    }
    
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageLists[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageLists.count
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        if indexPath.section % 3 == 0 {
           
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
//    // メッセージの上に文字を表示（名前）
//      func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//          let name = message.sender.displayName
//          return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
//      }

      // （日付）
      func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
          
        return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
      }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        if isFromCurrentSender(message: message) {
            
            getUsersFromFirestore(withIds: memberIds) { (withUsers) in
                
                self.withUsers = withUsers
                
                let withUser = withUsers.last!
                
                imageFromData(pictureData: withUser.avatar) { (avatar) in
                    
                    let avatar = Avatar(image: avatar, initials: "?")
                    avatarView.set(avatar: avatar)
                }
            }
        }
    }
    
}

//MARK: messageDisplay Delagate

extension MessageViewController : MessagesDisplayDelegate {
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        return isFromCurrentSender(message: message) ?
        UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) :
        UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
     let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        
        return .bubbleTail(corner, .curved)
    }
    
    
    
}

//MARK: Message LayoutDelagate

extension MessageViewController : MessagesLayoutDelegate {

    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section % 3 == 0 { return 16}
        
        return 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return 16
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        
        return .zero
    }
    
    func footerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        
        return CGSize(width: 0, height: 8)
    }
    
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {

        return 0
    }


    
}

//MARK: inputBar Delagate


extension MessageViewController : InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        
        for component in inputBar.inputTextView.components {
            if let text = component as? String {
                self.sendMessage(text: text, picture: nil, location: nil, video: nil, audio: nil)
            }
        }
        
        // after Sending Animation
        
        messageInputBar.inputTextView.text = String()
        messageInputBar.invalidatePlugins()
        
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = "Sending..."
        DispatchQueue.global(qos: .default).async {
            // fake send request task
            sleep(1)
            DispatchQueue.main.async { [weak self] in
                self?.messageInputBar.sendButton.stopAnimating()
                self?.messageInputBar.inputTextView.placeholder = "Aa"
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    
}

//MARK: messageCell Delegate

extension MessageViewController : MessageCellDelegate {
    
}

//MARK: save & loads Methods

extension MessageViewController {
    
    //MARK: send Message
    
    func sendMessage(text : String?,  picture : String?, location : String?, video : NSURL?, audio : String?) {
        
        var outgiongMessage : OutGoingMessage?
        let currentUser = FUser.currentUser()!
        
        // text
        
        if let text = text {
            outgiongMessage = OutGoingMessage(message: text, senderId: currentUser.objectId, senderName: currentUser.firstname, status: kDELIVERED, type: kTEXT)
        }
        
        // picture
        
        
        ///
        
        outgiongMessage?.sendMessage(chatRoomId: chatRoomId, messageDictionary: outgiongMessage!.messageDictionary, membersId: memberIds, memberToPush: membersToPush)
        
       
        
    }
    
    //MARK: load Messages
    
    func loadMessage() {
        
        //update message Status
        
//        updatelistner = reference(.Message).document(FUser.currentId()).collection(chatRoomId).addSnapshotListener({ (snapshot, error) in
//
//            guard let snapshot = snapshot else {return}
//
//            if !snapshot.isEmpty {
//                snapshot.documentChanges.forEach { (diff) in
//
//                }
//            }
//        })
        
        //get last 11 messages
        
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            
            guard let snapshot = snapshot else {return}
            
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            
            self.loadedMessages = self.removeBadMessage(allMessages: sorted)
            
            self.insertMessages()
            
            self.messagesCollectionView.reloadData()
            
            self.getOldMessagesinBackGround()
            
            self.listenForNewChat()
            
    
        }
    }
    
    //New CHAT Listner
    
    func listenForNewChat() {
        
        var lastMessageDate = "0"
        
        if loadedMessages.count > 0 {
            lastMessageDate = loadedMessages.last![kDATE] as! String
        }
        
        newChatListner = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else {return}
            
            if !snapshot.isEmpty {
                
                for diff in snapshot.documentChanges {
                    if diff.type == .added {
                        
                        let itm = diff.document.data() as NSDictionary
                        
                        if let type = itm[kTYPE] {
                            if self.legitType.contains(type as! String) {
                                
                                // picture
                                
                                //
                                
                                if self.insertInitialMessages(messageDictionary: itm) {
                                    print("new")
                                }
                                
                                self.messagesCollectionView.reloadData()
                            }
                        }
                    }
                }
            }
        })
        
    }
    
    
    // insert Message
    
    func insertMessages() {
        
        maxMessageNumber = self.loadedMessages.count - loadedMessageCount
        minimumMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minimumMessageNumber < 0 {
            minimumMessageNumber = 0
        }
        
        for i in minimumMessageNumber ..< maxMessageNumber {
            let messageDictionary = loadedMessages[i]
        
            insertInitialMessages(messageDictionary: messageDictionary)
        
            loadedMessageCount += 1
        }
        
    }

    func insertInitialMessages(messageDictionary : NSDictionary) -> Bool {
        
        let inComingMessage =  InComingMessage(collectionView_: self.messagesCollectionView)
        
        if messageDictionary[kSENDERID] as! String != FUser.currentId() {
            OutGoingMessage.updateMessage(withId: messageDictionary[kMESSAGEID] as! String, chatRoomId: chatRoomId, memberIds: memberIds)
        }
        
        let message = inComingMessage.createMessage(messageDictionary: messageDictionary, chatRoomID: chatRoomId)
        
        if message != nil {
            messageLists.append(message!)
        }
        
        return isInComing(messageDictionary: messageDictionary)
        
    }
    
    // load backGround
    
    func getOldMessagesinBackGround() {
        if loadedMessages.count > 10 {
            let lastMessageDate = loadedMessages.first![kDATE] as! String
            
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: lastMessageDate).getDocuments { (snapshot, error) in
                
                guard let snapshot = snapshot else {return}
                
                 let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                
                
                
                self.loadedMessages = self.removeBadMessage(allMessages: sorted) + self.loadedMessages
                
               
                self.maxMessageNumber = self.loadedMessages.count - self.loadedMessageCount - 1
                self.minimumMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
                
                
            }
        }
    }
    
    //loadMoremessages
    
    func loadMoreMessages(maxNumber : Int, minNumber: Int) {
        
        if loadOld {
            maxMessageNumber = minimumMessageNumber - 1
            minimumMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        }
        
        if minimumMessageNumber < 0 {
            minimumMessageNumber = 0
        }
        
        for i in (minimumMessageNumber ... maxMessageNumber).reversed() {
            
            let messageDictionary = loadedMessages[i]
            insertNewMessages(messageDictionary: messageDictionary)
            loadedMessageCount += 1
        }
        
        loadOld = true
     
    }
    
    func insertNewMessages(messageDictionary : NSDictionary) {
        let inComingMessage = InComingMessage(collectionView_: self.messagesCollectionView)
        
        let message = inComingMessage.createMessage(messageDictionary: messageDictionary, chatRoomID: chatRoomId)
        
        messageLists.insert(message!, at: 0)
    }
    
    //MARK: RefreshController method
    
    func configureRefreshController() {
        if !isLastsectionVisible() {
            messagesCollectionView.addSubview(refreshController)
            refreshController.addTarget(self, action: #selector(refresh), for: .valueChanged)
        }
    }
    
    @objc func refresh() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.isLastsectionVisible() {
                self.loadMoreMessages(maxNumber: self.maxMessageNumber, minNumber: self.minimumMessageNumber)
                self.messagesCollectionView.reloadData()
            }
            self.refreshController.endRefreshing()
            
        }
    }
    
    
    

}

//MARK: helper

extension MessageViewController {
    
    func removeBadMessage(allMessages : [NSDictionary]) -> [NSDictionary] {
        
        var tempMessages = allMessages
        
        for message in tempMessages {
            if message[kTYPE] != nil {
                if !self.legitType.contains(message[kTYPE] as! String) {
                    tempMessages.remove(at: tempMessages.firstIndex(of: message)!)
                }
            } else {
                 tempMessages.remove(at: tempMessages.firstIndex(of: message)!)
            }
        }
        
        return tempMessages
    }
    
    func isInComing(messageDictionary : NSDictionary) -> Bool {
        
        if FUser.currentId() == messageDictionary[kSENDERID] as! String {
            return false
        } else {
            return true
        }
    }
    
    func isLastsectionVisible() -> Bool {
        
        guard !messageLists.isEmpty else {return false}
        
        let lastIndexPath = IndexPath(item: 0, section: messageLists.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
}

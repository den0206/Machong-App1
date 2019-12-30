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
import IQAudioRecorderController
import FirebaseFirestore
import AVFoundation
import AVKit
import ProgressHUD

class MessageViewController: MessagesViewController {
    
    // replace SceneDelegate IOS 13
    
    let appdelegate = SceneDelegate.shared?.window?.windowScene?.delegate as! SceneDelegate
    
    
    lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)
    

    var messageLists : [Message] = []
    
    
    
    let refreshController = UIRefreshControl()
    
    var chatRoomId : String!
    var memberIds : [String]!
    var membersToPush : [String]!
    
    let legitType = [kAUDIO, kVIDEO, kLOCATION, kTEXT, kPICTURE]
    var loadOld = false
    
    var typinglistner : ListenerRegistration?
    var newChatListner : ListenerRegistration?
    var updatelistner : ListenerRegistration?
    
    
    var maxMessageNumber = 0
    var minimumMessageNumber = 0
    var loadedMessageCount = 0
    var isGroup : Bool = false
    
    var typingCounter = 0
    var loadedMessages : [NSDictionary] = []
    var objectMessage : [NSDictionary] = []
    var allPctureMessages : [String] = []
    
    var showAvatars =  true
    
    var avatarItems : NSMutableDictionary?
    var avatarImageDictionary : NSMutableDictionary?
    
    var withUsers : [FUser] = []
    
    let outgoingAvatarOverlap: CGFloat = 17.5
    
    deinit {
        updatelistner?.remove()
    }

 

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let reportMenuItem = UIMenuItem(title: "削除", action: #selector(MessageCollectionViewCell.delete(_:)))
//        UIMenuController.shared.menuItems = [reportMenuItem]
        
        ProgressHUD.show()
        
        createTypingObserver()
        
        
        self.messagesCollectionView.isHidden = true
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        messageInputBar.delegate = self
        messageInputBar.sendButton.tintColor = .lightGray
        messageInputBar.backgroundView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        messageInputBar.inputTextView.backgroundColor = .white
        
        
        messagesCollectionView.backgroundColor? = UIColor(patternImage: UIImage(named: "bg0")!)
        self.navigationController?.navigationBar.barTintColor =  UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        self.navigationController?.navigationBar.tintColor = .darkGray
        
        hideCurrentSenderAvatar()
    
        self.avatarItems = [:]
        
        setCustomTitle()
   
        
        loadMessage()

        
        // refresh Controll
        configureRefreshController()
        
        // メッセージ入力が始まった時に一番下までスクロールする
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        // 表示している画面とキーボードの重複を防ぐ
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        // accesary
        
        configureAccesary()
        
      
        
       
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioController.stopAnyOngoingPlaying()
    }
    
    //MARK: Clear Counter 0
    
    override func viewWillAppear(_ animated: Bool) {
        clearRecentCounter(chatRoomID: chatRoomId)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        clearRecentCounter(chatRoomID: chatRoomId)
    }
    
    //MARK: Delete Messages LongTapped
    
    
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        let message = messageLists[indexPath.section]
        // actionは結構色んな種類(cooy, deleteなど)がデフォルトで定義されているので必要であればtrueにすればメニューに表示されるようになる
        switch action {
        case NSSelectorFromString("delete:"):
            
            if message.sender.senderId == FUser.currentId() {
                 return true
            } else {
                return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
            }
           
        default:
            return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
        }
    }
        
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
        let message = messageLists[indexPath.section]
        let messageId = objectMessage[indexPath.section][kMESSAGEID] as! String
        
        // delete message

            if action == NSSelectorFromString("delete:") {
                
                switch message.kind {
                case .text, .attributedText, .location:
                    print("text Delete")
                    
                case .photo :
                    // get URL
                    let imageUrl = objectMessage[indexPath.section][kPICTURE] as! String
                    print(imageUrl)
                    
                    // delete Image Storoge
                    
                    storage.reference(forURL: imageUrl).delete { (error) in
                        
                        if error != nil {
                            print("削除できませんでした。")
                        }
                    }
                    
                case .video :
                    
                    let videoUrl = objectMessage[indexPath.section][kVIDEO] as! String
                    print(videoUrl)
                    
                    // delete Video Stroge
                    
                    storage.reference(forURL: videoUrl).delete { (error) in
                        if error != nil {
                            print("削除できませんでした。")
                        }
                    }
                    
                case .audio :
                    let audioUrl = objectMessage[indexPath.section][kAUDIO] as! String
                    print(audioUrl)
                    
                    // delete Audio Stroge
                    storage.reference(forURL: audioUrl).delete { (error) in
                        
                        if error != nil {
                            print("削除できませんでした。")
                        }
                    }
                    
                default:
                    return
                }
                
                
                
                objectMessage.remove(at: indexPath.section)
                messageLists.remove(at: indexPath.section)
                collectionView.deleteSections([indexPath.section])
                
                
                // Get LastMessage
                
                reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 1).getDocuments { (snapshot, error) in
                    
                    guard let snapshot = snapshot else {return}
                    
                    if !snapshot.isEmpty {
                        let lastMessage = snapshot.documents[0][kMESSAGE] as! String
                        updateRecent(chatRoomId: self.chatRoomId, lastMessage: lastMessage)
                        
                    } else {
                        updateRecent(chatRoomId: self.chatRoomId, lastMessage: "削除されました。")
                    }
                }

//                 delete firestore

                OutGoingMessage.deleteMessage(withId: messageId, chatRoomId: chatRoomId)

                
                
            } else {
                super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
            }
        }
    
    
  
}

extension MessageCollectionViewCell {

    override open func delete(_ sender: Any?) {
        
        // Get the collectionView
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            if let indexPath = collectionView.indexPath(for: self) {
                // Trigger action
                collectionView.delegate?.collectionView?(collectionView, performAction: NSSelectorFromString("delete:"), forItemAt: indexPath, withSender: sender)
            }
        }
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
    
    



    
    // メッセージの上に文字を表示（日付）
      func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
        
//          let name = message.sender.displayName
//          return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
      }

      // メッセージの下に文字を表示（既読）
      func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        let messageDictionary = objectMessage[indexPath.section]
        let status : NSAttributedString
//        let atributeStringColor = [NSAttributedString.Key.foregroundColor : UIColor.lightGray]
        
        if isFromCurrentSender(message: message) {
            switch messageDictionary[kSTATUS] as! String{
            case kDELIVERED:
                status = NSAttributedString(string: kDELIVERED, attributes:  [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
            case kREAD :
                status = NSAttributedString(string: kREAD, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
            default:
                status = NSAttributedString(string: "✔︎", attributes:  [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
            }
            
            return status
        }
        
        return nil
      }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
    
        let message = messageLists[indexPath.section]
        var avatar : Avatar
        
        if avatarItems != nil {
            
            if let avatarData = avatarItems!.object(forKey: message.sender.senderId) {
                
                avatar = avatarData as! Avatar
                avatarView.set(avatar: avatar)
            }
             
        } else {
            avatar = Avatar(image: UIImage(named: "avatarPlaceholder") , initials: "?")
            avatarView.set(avatar: avatar)
        }
    }
    
    func hideCurrentSenderAvatar() {
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
        
        // Hide the outgoing avatar and adjust the label alignment to line up with the messages
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
        layout?.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
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
    
   func audioTintColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
    return isFromCurrentSender(message: message) ? .white : UIColor(red: 15/255, green: 135/255, blue: 255/255, alpha: 1.0)
   }
    
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        audioController.configureAudioCell(cell, message: message)
    }
    
//    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
//
//        switch message.kind {
//        case .video(let video) :
//            let thumb = imageFromData(pictureData: video.thumbData!) { (image) in
//                video.image = image
//                }
//        default:
//            break
//        }
//    }


    
   
}

//MARK: Message LayoutDelagate

extension MessageViewController : MessagesLayoutDelegate {

    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 35
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 30
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
        
        sendToFinish()
    }
    
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        
        if text == "" {
            
            
            setAudioButton()
            
        } else {
            messageInputBar.setStackViewItems([messageInputBar.sendButton], forStack: .right, animated: false)
        }
        
        startTypingCounter()
    }

    
    
    //MARK: Typing Indicator
    
    func setTypingIndicatorViewHidden(_ isHidden: Bool, performUpdates updates: (() -> Void)? = nil) {
        setTypingIndicatorViewHidden(isHidden, animated: true, whilePerforming: updates) { [weak self] success in
            if success, self?.isLastsectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    func createTypingObserver() {
        
        typinglistner = reference(.Typing).document(chatRoomId).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else {return}
            
            if snapshot.exists {
                
                for data in snapshot.data()! {
                    // only with person
                    if data.key != FUser.currentId() {
                        let typing = data.value as! Bool
                        
                        print(typing)
                        
                        self.setTypingIndicatorViewHidden(typing)
                    }
                }
            } else {
                reference(.Typing).document(self.chatRoomId).setData([FUser.currentId(): true])
            }
        })
        
    }
    
    
    func startTypingCounter() {
        
        typingCounter += 1
        
        typingCountSave(typing: false)
        
        print(typingCounter)
        self.perform(#selector(typingCounterStop), with: nil, afterDelay: 2.0)
    }
    
    @objc func typingCounterStop() {
        
        typingCounter -= 1
        
//        typingCounter = 0
        
        if typingCounter == 0 {
            typingCountSave(typing: true)
        }
        
    }
    
    func typingCountSave(typing : Bool) {
        reference(.Typing).document(chatRoomId).updateData([FUser.currentId() : typing]) { (error) in
            
            if error != nil {
                print("typing not reference")
            }
        }
    }
    
}




//MARK: messageCell Delegate (Tap )

extension MessageViewController : MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        
        if let indexPath = messagesCollectionView.indexPath(for: cell) {
            let message = messageLists[indexPath.section]
            
            switch message.kind {
            case .photo(let PhotoItem):
                
                print("photo")
                
            case .video(var videoItem):
                
                downloadVideo(videoUrl: (videoItem.fileUrl?.path)!) { (isReadyToPlay, fileName) in
                    print(fileName)
                    
                    let url = NSURL(fileURLWithPath: fileInDocumentsDirectry(filename: fileName))
                    
                    videoItem.fileUrl = url
                    
                }

                if let videoUrl = videoItem.fileUrl {
                    

                    let player = AVPlayer(url: videoUrl as URL)
                    
                    let avPlayer = AVPlayerViewController()
                    
                    
                    let session = AVAudioSession.sharedInstance()
                    
                    try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
                  
                    
                    avPlayer.player = player
                    
                    print("あ",player,avPlayer,session)
                    
                    self.present(avPlayer, animated: true) {
                        avPlayer.player!.play()
                    }
                }
                
            case .location(let LocationItem) :
                
                
                let mapView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "mapViewController") as! MapViewController
                
                mapView.location = LocationItem.location
                
                navigationController?.pushViewController(mapView, animated: true)
                
            case .audio(let audioItem) :
                print("audio")
                
            default:
                break
            }
        }
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                print("Failed to identify message when audio cell receive tap gesture")
                return
        }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
            // tap occur in the current cell that is playing audio sound
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }
    
}

//MARK: save & loads Methods

extension MessageViewController {
    
    //MARK: send Message
    
    func sendMessage(text : String?,  picture : UIImage?, location : String?, video : NSURL?, audio : String?) {
        
        var outgiongMessage : OutGoingMessage?
        let currentUser = FUser.currentUser()!

        
        // text
        
        if let text = text {
            outgiongMessage = OutGoingMessage(message: text, senderId: currentUser.objectId, senderName: currentUser.firstname, status: kDELIVERED, type: kTEXT)
        }
        
        // picture
        
        if let pic = picture {
            uploadImage(image: pic, chatRoomId: chatRoomId, view: self.navigationController!.view) { (imageLink) in
                if imageLink != nil {
                    let text = "[\(kPICTURE)]"
                    
                    outgiongMessage = OutGoingMessage(message: text, pictureLink: imageLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, status: kDELIVERED, type: kPICTURE)
                    
                    outgiongMessage?.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgiongMessage!.messageDictionary, membersId: self.memberIds, memberToPush: self.membersToPush)
                    
                    self.sendToFinish()
                    
                }
                
            }
            return
        }
        
        // video
        
        if let video = video {
            
            let videoData = NSData(contentsOfFile: video.path!)
            
            let dataThumbnail = videoThmbnail(video: video).jpegData(compressionQuality: 0.3)
            
            uploadVideo(video: videoData!, chatRoomId: chatRoomId, view: self.navigationController!.view) { (videoLink) in
                
                if videoLink != nil {
                    let text = "[\(kVIDEO)]"
                    
                    outgiongMessage = OutGoingMessage(message: text, videoLink: videoLink!, thumbnail: dataThumbnail! as NSData, senderId: currentUser.objectId, senderName: currentUser.firstname, status: kDELIVERED, type: kVIDEO)
                    
                    outgiongMessage?.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgiongMessage!.messageDictionary, membersId: self.memberIds, memberToPush: self.membersToPush)
                    
                    self.sendToFinish()
                }
            }
            return

        }
        
        // Audio
        
        if let audioPath = audio {
            
            uploadAudio(audioPath: audioPath, chatRoomId: chatRoomId, view: self.navigationController!.view) { (audioLink) in
                
                if audioLink != nil {
                    
                    let text = "[\(kAUDIO)]"
                    
                    outgiongMessage = OutGoingMessage(message: text, audioLink: audioLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, status: kDELIVERED, type: kAUDIO)
                    
                    
                    outgiongMessage?.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgiongMessage!.messageDictionary, membersId: self.memberIds, memberToPush: self.membersToPush)
                    
                    self.sendToFinish()
                    
                }
  
            }
            
            return
        }
        
        
        // Location
        
        if location != nil {
            if appdelegate.coodinate != nil {
                let lat : NSNumber = NSNumber(value: appdelegate.coodinate!.latitude)
                let long : NSNumber = NSNumber(value : appdelegate.coodinate!.longitude)
                
                let text = "[\(kLOCATION)]"
                
                outgiongMessage = OutGoingMessage(message: text, latitude: lat, longtude: long, senderId: currentUser.objectId, senderName: currentUser.firstname, status: kDELIVERED, type: kLOCATION)
                
                sendToFinish()
                
                
            }
        }
        
        
        
        //  For Text & Location type Func (exclude another - Type)
        
        outgiongMessage?.sendMessage(chatRoomId: chatRoomId, messageDictionary: outgiongMessage!.messageDictionary, membersId: memberIds, memberToPush: membersToPush)
        
    }
    
    //MARK: load Messages
    
    func loadMessage() {
        
        //update message Status
        
        updatelistner = reference(.Message).document(FUser.currentId()).collection(chatRoomId).addSnapshotListener({ (snapshot, error) in

            guard let snapshot = snapshot else {return}

            if !snapshot.isEmpty {
                snapshot.documentChanges.forEach { (diff) in
                    
                    if diff.type == .modified {
                        self.updateMessage(messageDictionary: diff.document.data() as NSDictionary)
                    }

                }
            }
        })
        
        //get last 11 messages
        
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            
            guard let snapshot = snapshot else {return}
        
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            
            self.loadedMessages = self.removeBadMessage(allMessages: sorted)
            
            self.insertMessages()
            
            DispatchQueue.main.async {
                ProgressHUD.dismiss()
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom(animated: true)
                sleep(1)
                self.messagesCollectionView.isHidden = false
            }
            
            self.getPicturesMessages()

            
            self.getOldMessagesinBackGround()
            
            self.listenForNewChat()
            
            print(self.messageLists.count, self.objectMessage.count)
            
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
                                
                                // New Picture Link
                                
                                if type as! String == kPICTURE {
                                    self.newPictureLinkAdd(link: itm[kPICTURE] as! String)
                                }
                                
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
            // Add Read
            
            OutGoingMessage.updateMessage(withId: messageDictionary[kMESSAGEID] as! String, chatRoomId: chatRoomId, memberIds: memberIds)
        }
        

        let message = inComingMessage.createMessage(messageDictionary: messageDictionary, chatRoomID: chatRoomId)
    
        
        
        if message != nil {
            objectMessage.append(messageDictionary)
            messageLists.append(message!)
        }
        
        
        
        return isInComing(messageDictionary: messageDictionary)
        
    }
    
    func updateMessage(messageDictionary : NSDictionary) {
        
        for index in 0 ..< objectMessage.count {
            let temp = objectMessage[index]
            
            if messageDictionary[kMESSAGEID] as! String == temp[kMESSAGEID] as! String {
                objectMessage[index] = messageDictionary
                self.messagesCollectionView.reloadData()
            }
        }
        
    }
   //MARK: LOad BackGround
    
    func getOldMessagesinBackGround() {
        if loadedMessages.count > 10 {
            let lastMessageDate = loadedMessages.first![kDATE] as! String
            
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: lastMessageDate).getDocuments { (snapshot, error) in
                
                guard let snapshot = snapshot else {return}
                
                 let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                
                
                
                self.loadedMessages = self.removeBadMessage(allMessages: sorted) + self.loadedMessages
                
                self.getPicturesMessages()
               
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
        
     
        objectMessage.insert(messageDictionary, at: 0)
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
            
            if self.loadedMessages.count > self.loadedMessageCount {
                self.loadMoreMessages(maxNumber: self.maxMessageNumber, minNumber: self.minimumMessageNumber)
                self.messagesCollectionView.reloadData()
            }
            
            self.refreshController.endRefreshing()
            
        }
    }
}

//MARK: IQAudio Delegate


extension MessageViewController : IQAudioRecorderViewControllerDelegate {
    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        
        controller.dismiss(animated: true, completion: nil)
        self.sendMessage(text: nil, picture: nil, location: nil, video: nil, audio: filePath)
    }
    
    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true, completion: nil)
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
    
    func getPicturesMessages() {
        
        allPctureMessages = []
        
        for message in loadedMessages {
            
            if message[kTYPE] as! String == kPICTURE {
                allPctureMessages.append(message[kPICTURE] as! String)
            }
        }
        
    }
    
    func newPictureLinkAdd(link : String) {
        allPctureMessages.append(link)
    }
    
    func haveAccessToUserLocation() -> Bool {
        if appdelegate.locationManger != nil {
            return true
        } else {
            return false
        }
    }
    func sendToFinish() {
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
    
    
    
    //MARK: Get Avatars

    func setCustomTitle() {
        
        getUsersFromFirestore(withIds: memberIds) { (withuser) in
            // exclude currentUser
            
            self.withUsers = withuser
            self.getAvatarImages()
            
        }
        
    }
    
    func getAvatarImages() {
        
        if showAvatars {
            
            // get currentUser avatar
            avatarImageFrom(fuser: FUser.currentUser()!)
            
            // get withUser avatar
            
            for user in withUsers {
                avatarImageFrom(fuser: user)
            }
            
        }
        
    }
    
    func avatarImageFrom(fuser : FUser) {
        
        if fuser.avatar != "" {
          
            dataImageFromString(pictureString: fuser.avatar) { (imageData) in
                
                if imageData == nil {
                    return
                }
                
                if avatarImageDictionary != nil {
                    
                    self.avatarImageDictionary!.removeObject(forKey: fuser.objectId)
                    self.avatarImageDictionary!.setObject(imageData!, forKey: fuser.objectId as NSCopying)
                } else {
                    self.avatarImageDictionary = [fuser.objectId : imageData!]
                }
                
                self.createAvatarItem(avatarDictionary: self.avatarImageDictionary)
            }
        }
    }
    
    func createAvatarItem(avatarDictionary : NSMutableDictionary?) {
        
        let dafaultAvatar = Avatar(image: UIImage(named: "avatarPlaceholder") , initials: "?")
        
        if avatarDictionary != nil {
            
            for userId in memberIds {
                if let avataImageData = avatarDictionary![userId] {
                    let avatarItem = Avatar(image: UIImage(data: avataImageData as! Data), initials: "?")
                    
                    self.avatarItems!.setValue(avatarItem, forKey: userId)
                } else {
                    self.avatarItems!.setValue(dafaultAvatar, forKey: userId)
                }
            }
            
            self.messagesCollectionView.reloadData()
        }
       
    }
    
}



//MARK: custiomize Options


extension MessageViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func configureAccesary() {
        
        // Accesary-Button(left)
        
        let optionItems = InputBarButtonItem(type: .system)
        optionItems.tintColor = .darkGray
        optionItems.image = UIImage(named: "clip")
        
        optionItems.addTarget(self, action: #selector(showOptions), for: .touchUpInside)
        
        optionItems.setSize(CGSize(width: 60, height: 30), animated: false)
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        
        messageInputBar.setStackViewItems([optionItems], forStack: .left, animated: true)
        
        // Mic-BUtton(right)
        
        setAudioButton()
        
        
    }
    
    @objc func showOptions() {
        
        let camera = Camera(delegate_: self)
        
        let optionmenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            // take Photo or Library vir your Devise
            
            print("take Devise")
        }
        
        let showPhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            // open Photo Library
            camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            camera.PresentVideoLibrary(target: self, canEdit: false)
        }
        
        let shareLocation = UIAlertAction(title: "Location", style: .default) { (action) in
            
            if self.haveAccessToUserLocation() {
                self.sendMessage(text: nil, picture: nil, location: kLOCATION, video: nil, audio: nil)
            }
            
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        
        
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        showPhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        optionmenu.addAction(takePhotoOrVideo)
        optionmenu.addAction(showPhoto)
        optionmenu.addAction(shareVideo)
        optionmenu.addAction(shareLocation)
        optionmenu.addAction(cancel)
        
        present(optionmenu,animated: true,completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[.originalImage] as? UIImage
        
        sendMessage(text: nil, picture: picture, location: nil, video: video, audio: nil)
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    func setAudioButton() {
        
        let micItem = InputBarButtonItem(type: .system)
              micItem.tintColor = .darkGray
              micItem.image = UIImage(named: "mic")
              
              micItem.addTarget(self, action: #selector(audio), for: .touchUpInside)

              micItem.setSize(CGSize(width: 60, height: 30), animated: false)
              messageInputBar.rightStackView.alignment = .center
              messageInputBar.setRightStackViewWidthConstant(to: 50, animated: false)

              messageInputBar.setStackViewItems([micItem], forStack: .right, animated: true)
        
        self.setTypingIndicatorViewHidden(true)

    }
    
    @objc func audio() {
        let audioVC = AudioViewController(delegate_: self)
        audioVC.presentAUdioRecorder(target: self)
    }
    
    
}



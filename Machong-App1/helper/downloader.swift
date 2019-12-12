//
//  downloader.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/12/09.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Firebase
import MBProgressHUD
import AVFoundation

let storage = Storage.storage()

//MARK: For Image

func uploadImage(image : UIImage, chatRoomId : String, view : UIView, completion : @escaping(_ imageLink : String?)  -> Void) {
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    
    progressHUD.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let photoFileName = "PictureMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".jpg"
    
    let strogeRef = storage.reference(forURL: kFILEREFERENCE).child(photoFileName)
    
    let imageData = image.jpegData(compressionQuality: 0.7)
    var task : StorageUploadTask!
    
    task = strogeRef.putData(imageData!, metadata: nil, completion: { (metadata, error) in
        
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        
        if error != nil {
            print(error?.localizedDescription)
            return
        }
        
        strogeRef.downloadURL { (url, error) in
            
            guard let downLoadUrl = url else {
                completion(nil)
                return
            }
            
            completion(downLoadUrl.absoluteString)
            
        }
    })
    
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
    
}

func downLoadImage(imageUrl :String) -> UIImage? {
    
    let imageURL = NSURL(string: imageUrl)
    
    let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    if fileExistPth(path: imageFileName) {
        if let comtentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectry(filename: imageFileName)) {
            return comtentsOfFile
        } else {
            print("couldnt generateimage")
            return nil
        }
    } else {
        let data = NSData(contentsOf: imageURL! as URL)
        
        if data != nil {
            var docURL = getDocumentsURL()
            
            docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)
            data!.write(to: docURL, atomically: true)
            
            let imageToReturn = UIImage(data: data! as Data)
            return imageToReturn
            
        } else {
            
            print("No image in Database")
            return nil
            
        }
        
    }
    
}


//MARK: For Video

func uploadVideo(video : NSData, chatRoomId : String, view : UIView, completion : @escaping(_ videoLink : String?) -> Void) {
    
    let progressHud = MBProgressHUD.showAdded(to: view, animated: true)
    
    progressHud.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let videoFileName = "VideoMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".mov"
    
    let strogeRef = storage.reference(forURL: kFILEREFERENCE).child(videoFileName)
    var task : StorageUploadTask!
    
    task = strogeRef.putData(video as Data, metadata: nil, completion: { (metadata, error) in
        
        task.removeAllObservers()
        progressHud.hide(animated: true)
        
        if error != nil {
            print(error?.localizedDescription)
            return
        }
        
        strogeRef.downloadURL { (url, error) in
            
            guard let downloadUrl = url else {
                completion(nil)
                return
            }
            completion(downloadUrl.absoluteString)
        }
    })
    
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        progressHud.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
}

func downloadVideo(videoUrl : String, completion : @escaping(_ isReadyToPlay: Bool, _ videoFileName: String) -> Void) {
    
    let videoURL = NSURL(string: videoUrl)
   
    
    let videoFileName = (videoUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!

    
    if fileExistPth(path: videoFileName) {
        // exist
        
        completion(true, videoFileName)
        
    } else {
        // not exist
        let downloadQue = DispatchQueue(label: "videoDownloadQueue")
        downloadQue.async {
            let data = NSData(contentsOf: videoURL! as URL)
            
            if data != nil {
                var docURL = getDocumentsURL()
                
                docURL = docURL.appendingPathComponent(videoFileName, isDirectory: false)
                data!.write(to: docURL, atomically: true)
                
              
                DispatchQueue.main.async {
                    completion(true, videoFileName)
                }
            } else {
                DispatchQueue.main.async {
                    print("No video in Database")
                }
            }
        }
        
    }
    
    
}

//MARK: helper

func fileExistPth(path :String) -> Bool {
    var doesExist = false
    
    let filePath = fileInDocumentsDirectry(filename: path)
    let fileManger = FileManager.default
    
    if fileManger.fileExists(atPath: filePath) {
        doesExist = true
    } else {
        doesExist = false
    }
    
    return doesExist
}

func fileInDocumentsDirectry(filename : String) -> String {
    
    let fileURL = getDocumentsURL().appendingPathComponent(filename)
    return fileURL.path
}

func getDocumentsURL() -> URL {
    
    let documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    return documentUrl!
    
}

func videoThmbnail(video: NSURL) -> UIImage {
    
    let asset = AVURLAsset(url: video as URL, options: nil)
    
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    let time = CMTime(seconds: 0.5, preferredTimescale: 1000)
    var actualTime = CMTime.zero
    
    var image : CGImage?
    
    do {
        image = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
    } catch let error as NSError {
        print(error.localizedDescription)
    }
    
    let thunmbnail = UIImage(cgImage: image!)
    
    return thunmbnail
}



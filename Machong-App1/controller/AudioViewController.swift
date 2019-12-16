
//
//  audioViewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/12/14.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import Foundation
import IQAudioRecorderController

class AudioViewController {

    var delegate : IQAudioRecorderViewControllerDelegate
    
    init(delegate_ : IQAudioRecorderViewControllerDelegate) {
        delegate = delegate_
    }
    
    func presentAUdioRecorder(target: UIViewController) {
        
        let controller = IQAudioRecorderViewController()
        controller.delegate = delegate
        controller.title = "Record"
        controller.maximumRecordDuration = kAUDIOMAXDURATION
        controller.allowCropping = true
        
        target.presentBlurredAudioRecorderViewControllerAnimated(controller)
        
        
        
    }

}

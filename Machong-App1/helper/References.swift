//
//  CollectionReference.swift
//  whats-up -clone
//
//  Created by 酒井ゆうき on 2019/10/05.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//



import Foundation
import FirebaseFirestore


enum FCollectionReference: String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
}


func reference(_ collectionReference: FCollectionReference) -> CollectionReference{
    return Firestore.firestore().collection(collectionReference.rawValue)
}




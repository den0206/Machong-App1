//
//  SceneDelegate.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/11/28.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation


class SceneDelegate: UIResponder, UIWindowSceneDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    private(set) static var shared: SceneDelegate?
    var autolisner : AuthStateDidChangeListenerHandle?
    
    var locationManger : CLLocationManager?
    var coodinate : CLLocationCoordinate2D?
    


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
           
//           let appDelegate = UIApplication.shared.delegate as! AppDelegate
//           appDelegate.window = self.window
        
        autolisner = Auth.auth().addStateDidChangeListener({ (auth, user) in
            
            Auth.auth().removeStateDidChangeListener(self.autolisner!)
            
            if user != nil {
                if UserDefaults.standard.object(forKey: kCURRENTUSER) != nil {
                    
                    DispatchQueue.main.async {
                        self.goToApp()
                    }
                }
            }
        })
        
           guard let _ = (scene as? UIWindowScene) else { return }
        Self.shared = self
       }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
     locationMangerStart()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
     locationMagerStop()
    }
    
   
    func goToApp() {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainApplication") as! UITabBarController
        
        self.window?.rootViewController = mainView
    }
    
    //MAR* LocationManager
        
        func locationMangerStart() {
            
            if locationManger == nil {
                locationManger = CLLocationManager()
                locationManger!.delegate = self
                
                locationManger!.desiredAccuracy = kCLLocationAccuracyBest
                locationManger!.requestWhenInUseAuthorization()
                
            }
            
            locationManger!.startUpdatingLocation()
        }
        
        func locationMagerStop() {
            if locationManger != nil {
                locationManger!.stopUpdatingLocation()
            }
        }
        
        //MARK: location manger delegate
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("failed to get location")
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            
            switch status {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse:
                manager.startUpdatingLocation()
            case .authorizedAlways :
                manager.startUpdatingLocation()
            case .restricted :
                print("restricted")
            case .denied :
                locationManger = nil
                print("denied location accessed")
                break
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            coodinate = locations.last!.coordinate
            
        }




}


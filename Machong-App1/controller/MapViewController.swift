//
//  MapViewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/12/14.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    
    @IBOutlet weak var mapView: MKMapView!
    var location : CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Map"
        
        setupUI()
        
        createOpenMapButton()
    }
    
    func setupUI() {
        
        var region = MKCoordinateRegion()
        region.center.latitude = location.coordinate.latitude
        region.center.longitude = location.coordinate.longitude
        
        region.span.latitudeDelta = 0.01
        region.span.longitudeDelta = 0.01
        
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
        
        // add Pin
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        
        mapView.addAnnotation(annotation)
        
    }
    
    func createOpenMapButton() {
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Open In Maps", style: .plain, target: self, action: #selector(openMap))]
    }
    
    @objc func openMap() {
        
        let regionDestination : CLLocationDistance = 1000
        let coodinate = location.coordinate
        
        let regionSpan = MKCoordinateRegion(center: coodinate, latitudinalMeters: regionDestination, longitudinalMeters: regionDestination)
        
        let options = [
            MKLaunchOptionsMapCenterKey : NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey : NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        
        let placeMark = MKPlacemark(coordinate: coodinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placeMark)
        
        mapItem.name = "現在地"
        mapItem.openInMaps(launchOptions: options)
    }
    



}

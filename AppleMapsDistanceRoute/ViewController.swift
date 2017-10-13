//
//  ViewController.swift
//  AppleMapsDistanceRoute
//
//  Created by Bryn Beaudry on 2017-10-13.
//  Copyright © 2017 Bryn Beaudry. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, MKMapViewDelegate,  CLLocationManagerDelegate, UIGestureRecognizerDelegate{
    
    var locationManager:CLLocationManager!
    var userLocation:CLLocation!

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var bottomBtnBar: UIToolbar!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        determineCurrentLocation()
        createMapView()
        
        
        let mapLPRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapPress))
        //Where is the UIElem we're listening for taps? This class.
        //Where is the function to handle the action defined? In the class of the delegate/order taker
        mapLPRecognizer.delegate = self //The view is responsible to provide the function. It can modify the necessary data to carry it out
        mapView.addGestureRecognizer(mapLPRecognizer)
        //I think all UI Controllers have add/remove gesture regonizers.
        
        
    }
    
    @objc func handleMapPress(gestureReconizer: UILongPressGestureRecognizer) {
        //converts CG Point to LocCoord2d
        print("In handlemap press")
        let location = gestureReconizer.location(in: mapView)
        let coordinate : CLLocationCoordinate2D = mapView.convert(location,toCoordinateFrom: mapView)
        dropPinAtCoordinate(c: coordinate)
    }
    
    func centerMapOnLocation() {
        print(userLocation)
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }
    
    func dropPinAtUserLocation() {
        // Drop a pin at user's Current Location
        let myAnnotation: MKPointAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude);
        myAnnotation.title = "Current location"
        mapView.addAnnotation(myAnnotation)
    }
    
    func dropPinAtCoordinate(c : CLLocationCoordinate2D) {
        let myAnnotation: MKPointAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = CLLocationCoordinate2DMake(c.latitude, c.longitude);
        myAnnotation.title = "Pin at \(c.latitude), \(c.longitude)"
        mapView.addAnnotation(myAnnotation)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create and Add MapView to our main view
        //createMapView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //determineCurrentLocation()
    }
    func createMapView()
    {
        print("In create MapView")
        //mapView = MKMapView()
        /*
        let leftMargin:CGFloat = 10
        let topMargin:CGFloat = 60
        let mapWidth:CGFloat = view.frame.size.width-20
        let mapHeight:CGFloat = 300
         */
        
        //mapView.frame = CGRectMake(leftMargin, topMargin, mapWidth, mapHeight)
        
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsPointsOfInterest = false
        
        // Or, if needed, we can position map in the center of the view
        //mapView.center = view.center
        //
        //view.addSubview(mapView)
    }
    
    func determineCurrentLocation()
    {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        print("Location services enabled? : \(CLLocationManager.locationServicesEnabled())")
        if CLLocationManager.locationServicesEnabled() {
            //locationManager.startUpdatingHeading()
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0] as CLLocation
        print("User's location : \(userLocation.coordinate.latitude), \(userLocation.coordinate.latitude)")
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        manager.stopUpdatingLocation()
        
        centerMapOnLocation()
        dropPinAtUserLocation()
        
        
    }

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }


}


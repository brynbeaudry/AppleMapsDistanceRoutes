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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UIToolbarDelegate{
    var totalDistance : Double = 0.00
    var locationManager:CLLocationManager!
    var userLocation:CLLocation!
    var points: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
    var overlays : [MKOverlay]!
    let directionsGroup = DispatchGroup()
    let routesGroup = DispatchGroup()
    let calculateAllDistanceGroup = DispatchGroup()
    enum Trans {
        case WALKING
        case JETPACKING
        case DRIVING
    }
    enum PopUpState {
        case OPEN
        case CLOSED
    }
    
    var transportType : MKDirectionsTransportType!
    var selectTransport : Trans = Trans.JETPACKING
    var popUpState : PopUpState = PopUpState.CLOSED
    var distType : String = "JetPacking"

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var bottomBtnBar: UIToolbar!
    
    func restoreMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        points = [CLLocationCoordinate2D]()
        totalDistance = 0.00
        distType = determineDistanceType()
    }
    
    @IBAction func driveBtn(_ sender: UIBarButtonItem) {
        transportType = MKDirectionsTransportType.automobile
        selectTransport = Trans.DRIVING
        restoreMap()
        print("Drive!")
        distType = determineDistanceType()
        
    }
    @IBAction func walkBtn(_ sender: UIBarButtonItem) {
        transportType = MKDirectionsTransportType.walking
        selectTransport = Trans.WALKING
        restoreMap()
        print("Walk!")
        distType = determineDistanceType()
        
    }
    @IBAction func jetpackBtn(_ sender: UIBarButtonItem) {
        transportType = nil
        selectTransport = Trans.JETPACKING
        restoreMap()
        print("Jetpack!")
        distType = determineDistanceType()
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View did Load")
        // Do any additional setup after loading the view, typically from a nib.
        determineCurrentLocation()
        createMapView()
        
        let mapLPRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapPress))
        //Where is the UIElem we're listening for taps? This class.
        //Where is the function to handle the action defined? In the class of the delegate/order taker
        mapLPRecognizer.delegate = self //The view is responsible to provide the function. It can modify the necessary data to carry it out
        mapLPRecognizer.minimumPressDuration = CFTimeInterval(1.5)
        mapView.addGestureRecognizer(mapLPRecognizer)
        //I think all UI Controllers have add/remove gesture regonizers.
        bottomBtnBar.delegate = self
        selectTransport = Trans.JETPACKING
    }
    
    @objc func handleMapPress(gestureRecognizer: UILongPressGestureRecognizer) {
        //converts CG Point to LocCoord2d
        print("In handlemap press")
        if (gestureRecognizer.state == UIGestureRecognizerState.ended) {
            NSLog("Long press Ended");
            if popUpState == PopUpState.CLOSED {
                popUpState = PopUpState.OPEN
                self.becomeFirstResponder()
                let location = gestureRecognizer.location(in: mapView)
                let coordinate : CLLocationCoordinate2D = mapView.convert(location,toCoordinateFrom: mapView)
                dropPinAtCoordinate(c: coordinate)
                print("after drop pin")
                if mapView.annotations.count > 1 {
                    if(selectTransport == .JETPACKING){
                        print("Before calculateJetPackDistance d: \(totalDistance)")
                        calculateJetPackDistance()
                        print("After calculateJetPackDistance d: \(totalDistance)")
                        drawJetPackPolyLine()
                        distancePopUp()
                    }else{
                        //also does overlay
                        calculateDistanceFromDirections()
                    }
                }else{
                    garGarPopUp()
                }
            }
        }
    }
    
    func distancePopUp(){
        print("In Distance Popup, distance is \(String(format: "%.2f",totalDistance))")
        popUp(message: "The \(distType) distance is \(String(format: "%.2f",totalDistance))")
    }
    
    func determineDistanceType() -> String {
        switch selectTransport {
        case .JETPACKING:
            return "Jetpacking"
        case .DRIVING:
            return "Driving"
        case .WALKING:
            return "Walking"
        }
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
        print("Annotations count : \(mapView.annotations.count)")
    }
    
    func dropPinAtCoordinate(c : CLLocationCoordinate2D) {
        let myAnnotation: MKPointAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = CLLocationCoordinate2DMake(c.latitude, c.longitude);
        myAnnotation.title = "Pin at \(c.latitude), \(c.longitude)"
        mapView.addAnnotation(myAnnotation)
        print("Annotations count : \(mapView.annotations.count)")
    }
    
    func dismissPopUp(_ : UIAlertAction) -> Void{
        print("in dismiss Popup")
        popUpState = PopUpState.CLOSED
    }
    
    func popUp(message: String) -> Void {
        print("In popup")
        var alertText : String = "\n\n\n\n\n\n\n\n\n\n\n\n"
        if(!message.isEmpty){
            alertText += message
        }
        
        let alertMessage = UIAlertController(title: "My Title", message: alertText, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: self.dismissPopUp)
        alertMessage.addAction(action)
        self.present(alertMessage, animated: true, completion: nil)
        let xPosition = alertMessage.view.frame.origin.x + 80
        let rectImg = #imageLiteral(resourceName: "routesymbol")
        let rect : CGRect = CGRect(x: xPosition, y: 100, width: 100, height: 100)
        //rectImg.draw(in: rect)
        let imageView = UIImageView(frame: rect)
        imageView.image = rectImg
        alertMessage.view.addSubview(imageView)
    }
    
    func garGarPopUp() {
        print("In gargar popup")
        let alertMessage = UIAlertController(title: "Garbage", message: "\n\n\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: self.dismissPopUp)
        alertMessage .addAction(action)
        self.present(alertMessage, animated: true, completion: nil)
        let xPosition = alertMessage.view.frame.origin.x + 80
        let garbageRes = #imageLiteral(resourceName: "garbage")
        let rect : CGRect = CGRect(x: xPosition, y: 100, width: 100, height: 100)
        //garbageRes.draw(in: rect)
        let imageView = UIImageView(frame: rect)
        imageView.image = garbageRes
        alertMessage.view.addSubview(imageView)
    }
    
    func calculateDistanceFromDirections() -> Void {
        totalDistance = 0.00
        mapView.removeOverlays(mapView.overlays)
        let annotations = mapView.annotations
        let count = (annotations.count-2 < 1) ? 0 : annotations.count-2
        calculateAllDistanceGroup.enter()
        for index in 0...count {
            print("In calc total dist NOT jetpack for loop index : \(index) count: \(count)")
            let locA = MKMapItem.init(placemark: MKPlacemark.init(coordinate: annotations[index].coordinate))
            let locB = MKMapItem.init(placemark: MKPlacemark.init(coordinate: annotations[index + 1].coordinate))
            getDirections(start: locA, end: locB)
            if(index == count) {calculateAllDistanceGroup.leave()}
        }
        directionsGroup.notify(queue: DispatchQueue.main) {
            self.distancePopUp()
        }
    }
    
    func calculateJetPackDistance() {
        totalDistance = 0.00
        points = [CLLocationCoordinate2D]()
        let annotations = mapView.annotations
        
        let count = (annotations.count-2 < 1) ? 0 : annotations.count-2
        for index in 0...count {
            points.append(annotations[index].coordinate)
            print("In calc total dist jetpack for loop index : \(index) count: \(count)")
            let locA = CLLocation(latitude: annotations[index].coordinate.latitude, longitude: annotations[index].coordinate.longitude)
            let locB = CLLocation(latitude: annotations[index+1].coordinate.latitude, longitude: annotations[index+1].coordinate.longitude)
            totalDistance += Double(locA.distance(from: locB))
        }
        points.append(annotations[annotations.count-1].coordinate)
    }
    
    func drawJetPackPolyLine(){
        print("In drawJetPackPolyLine points.count : \(points.count)")
        //let c_points = points
        let polyline = MKPolyline(coordinates: &points, count: points.count)
        //print("Any points associated with the shape?\(polyline.points())")
        self.mapView.add(polyline, level: MKOverlayLevel.aboveRoads)
    }

    
    func getDirections(start: MKMapItem, end: MKMapItem) {
        directionsGroup.enter()
        let request = MKDirectionsRequest()
        request.source = start
        request.transportType = transportType
        request.destination = end
        request.requestsAlternateRoutes = false
        let directions = MKDirections(request: request)
        DispatchQueue.main.async{
            directions.calculate(completionHandler: {(response, error) in
                if error != nil {
                    print("Error getting directions")
                    }else{
                    self.showRoute(response: response!)
                    self.directionsGroup.leave()
                }
            })
        }
    }
    
    func showRoute(response: MKDirectionsResponse) {
        routesGroup.enter()
        print(response.routes)
        for route in response.routes {
            print("In show routes for loop")
            totalDistance += Double(route.distance)
            mapView.add(route.polyline, level: MKOverlayLevel.aboveRoads)
            print("Route Distance from show route, should be multiple \(route.distance)")
        }
        routesGroup.leave()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: MKPolyline.self) {
            // draw the track
            print("calling overlay renderer")
            let polyLine = overlay
            let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
            polyLineRenderer.strokeColor = UIColor.blue
            polyLineRenderer.lineWidth = 2.0
            
            return polyLineRenderer
        }
        
        return MKPolylineRenderer()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View will appear")
        // Create and Add MapView to our main view
        //createMapView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("View did appear")
        //determineCurrentLocation()
    }
    
    func createMapView()
    {
        print("In create MapView")
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsPointsOfInterest = false
        mapView.delegate = self
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
        //dropPinAtUserLocation()
    }

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }


}


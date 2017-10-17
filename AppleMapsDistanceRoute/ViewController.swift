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

class ViewController: UIViewController, MKMapViewDelegate,  CLLocationManagerDelegate, UIGestureRecognizerDelegate, UIToolbarDelegate{
    var totalDistance : Double = 0
    var locationManager:CLLocationManager!
    var userLocation:CLLocation!
    var points: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
    var polyline : MKPolyline!
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

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var bottomBtnBar: UIToolbar!
    
    @IBAction func driveBtn(_ sender: UIBarButtonItem) {
        transportType = MKDirectionsTransportType.automobile
        selectTransport = Trans.DRIVING
        print("Drive!")
        mapView.removeAnnotations(mapView.annotations)
        points.removeAll()
    }
    @IBAction func walkBtn(_ sender: UIBarButtonItem) {
        transportType = MKDirectionsTransportType.walking
        selectTransport = Trans.WALKING
        print("Walk!")
        mapView.removeAnnotations(mapView.annotations)
        points.removeAll()
    }
    @IBAction func jetpackBtn(_ sender: UIBarButtonItem) {
        transportType = nil
        selectTransport = Trans.JETPACKING
        print("Jetpack!")
        mapView.removeAnnotations(mapView.annotations)
        points.removeAll()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        transportType = nil
        
    }
    
    @objc func handleMapPress(gestureRecognizer: UILongPressGestureRecognizer) {
        //converts CG Point to LocCoord2d
        print("In handlemap press")
        if popUpState == PopUpState.CLOSED {
            popUpState = PopUpState.OPEN
            self.becomeFirstResponder()
            let location = gestureRecognizer.location(in: mapView)
            let coordinate : CLLocationCoordinate2D = mapView.convert(location,toCoordinateFrom: mapView)
            dropPinAtCoordinate(c: coordinate)
            checkNumberOfAnnotations()
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
    }
    
    func dropPinAtCoordinate(c : CLLocationCoordinate2D) {
        let myAnnotation: MKPointAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = CLLocationCoordinate2DMake(c.latitude, c.longitude);
        myAnnotation.title = "Pin at \(c.latitude), \(c.longitude)"
        mapView.addAnnotation(myAnnotation)
    }
    
    func dismissPopUp(_ : UIAlertAction) -> Void{
        print("in dismiss Popup")
        popUpState = PopUpState.CLOSED
    }
    
    func popUp(message: String) {
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
        print("In popup")
        let alertMessage = UIAlertController(title: "My Title", message: "\n\n\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
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
    
    //TODO: Finish this implementation
    func checkNumberOfAnnotations(){
        if mapView.annotations.count > 1 {
            calculateTotalDistance(annotations : mapView.annotations)
            //show popup
            var mode : String
            switch selectTransport {
                case .DRIVING:
                        mode = "driving"
                case .JETPACKING:
                        mode = "jetpacking"
                case .WALKING:
                        mode = "walking"
            }
            let distString = NSString(format: "%.2f", totalDistance)
            popUp(message: "Total \(mode) Distance : \(distString)")
        }else{
            //show a different popup
            garGarPopUp()
        }
    }
    
    
    
    func calculateTotalDistance(annotations : [MKAnnotation]) {
        totalDistance = 0
        points.removeAll()
        if(selectTransport != Trans.JETPACKING){
            for index in 0...annotations.count-2 {
                    let locA = MKMapItem.init(placemark: MKPlacemark.init(coordinate: annotations[index].coordinate))
                    let locB = MKMapItem.init(placemark: MKPlacemark.init(coordinate: annotations[index + 1].coordinate))
                    getDirections(start: locA, end: locB)
            }
        }else{
            for index in 0...annotations.count-2 {
                    points.append(annotations[index].coordinate)
                    let locA = CLLocation(latitude: annotations[index].coordinate.latitude, longitude: annotations[index].coordinate.longitude)
                    let locB = CLLocation(latitude: annotations[index+1].coordinate.latitude, longitude: annotations[index+1].coordinate.longitude)
                    totalDistance += Double(locA.distance(from: locB))
            }
            polyline = MKPolyline(coordinates: points, count: points.count)
            mapView.add(polyline, level: MKOverlayLevel.aboveRoads)
        }
        
         print("Total Distance : \(totalDistance)")
        //If sleected thing is driving
    }
    
    func getDirections(start: MKMapItem, end: MKMapItem) {
        
        let request = MKDirectionsRequest()
        request.source = start
        request.transportType = transportType
        request.destination = end
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        directions.calculate(completionHandler: {(response, error) in
            
            if error != nil {
                print("Error getting directions")
            } else {
                self.showRoute(response!)
            }
        })
    }
    
    func showRoute(_ response: MKDirectionsResponse) {
        
        for route in response.routes {
            
            mapView.add(route.polyline,
                         level: MKOverlayLevel.aboveRoads)
            
            //for step in route.steps {
            //    print(step.instructions)
            //}
            totalDistance += Double(route.distance)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor
        overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
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
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsPointsOfInterest = false
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


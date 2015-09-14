//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Jeffrey Sulton on 9/8/15.
//  Copyright (c) 2015 notluS. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            println("Handling `Began` state for gesture")
            let touchPoint = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.title = "New pin"
            annotation.coordinate = coordinate //CLLocationCoordinate2D(latitude: 0, longitude: 0)
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "PinAnnotation")
            mapView.addAnnotation(annotation)
        } else
        {
            println("Ignoring state")
        }
    }
    
}


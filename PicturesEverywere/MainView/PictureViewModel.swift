//
//  PictureViewModel.swift
//  PicturesEverywere
//  Created by Jael Fautino Ruvalcaba Tabares on 26/01/23.

import Foundation
import Combine
import AVFoundation
import Photos
import UIKit
import CoreLocation
import SwiftUI

final class PictureViewModel: NSObject ,ObservableObject, CLLocationManagerDelegate {
    
    @Published var address = ""
    @Published var showingAlert: Bool = false
    @Published var shouldShowAlertView:Bool = false
    private var locationManager = CLLocationManager()
    @Published var cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
    public var errorDescription = ""
    @Published var showingImagePicker = false
    let geocoder = CLGeocoder()
  
    func toggleAlert(){
        showingAlert.toggle()
    }
    func requestLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                // Process Response
                if let error = error {
                    print("Unable to Reverse Geocode Location (\(error))")
                } else {
                    if let placemarks = placemarks, let placemark = placemarks.first {
                        self.address = "\(placemark.locality!), \(placemark.country!)"
                    print("\(placemark.locality!), \(placemark.country!)")
                    }
                }
            }
  
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // print the error to see what went wrong
        print("didFailwithError\(error)")
        // stop location manager if failed
        stopLocationManager()
    }
    
    func stopLocationManager() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.locationManager.stopUpdatingLocation()
            self.locationManager.delegate = nil
        }
        print("Stop locationManager")
    }
    
    func checkCameraPermission() {
        if cameraPermission == .authorized {
            // Camera permission is granted, show the image picker
            DispatchQueue.main.async {
                self.showingImagePicker = true
            }
            
        } else if cameraPermission == .denied {
            // Camera permission is denied, show an alert
            errorDescription = "Camera permission is denied."
            DispatchQueue.main.async {
                self.shouldShowAlertView = true
            }
            
        } else if cameraPermission == .restricted {
            // Camera permission is restricted, show an alert
            errorDescription = "Camera permission is restricted."
            DispatchQueue.main.async {
                self.shouldShowAlertView = true
            }
        } else if cameraPermission == .notDetermined {
            // Camera permission is not determined, request access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    // Access granted, show the image picker
                    DispatchQueue.main.async {
                        self.showingImagePicker = true
                    }
                } else {
                    // Access denied, show an alert
                    self.errorDescription = "Camera permission is denied."
                    DispatchQueue.main.async {
                        self.shouldShowAlertView = true
                    }
                }
            }
        }
    }
}


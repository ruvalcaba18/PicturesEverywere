//  TakePictureViewModel.swift
//  PicturesEverywere
//  Created by Jael Fautino Ruvalcaba Tabares on 26/01/23.

import Foundation
import Combine
import AVFoundation
import Photos
import UIKit
import SwiftUI

final class TakePictureViewModel: ObservableObject {
    
    let principalViewModel = PictureViewModel()
    @Published var showingImagePicker:Bool = false 
    @Published public var flashMode: AVCaptureDevice.FlashMode = .off
    @Published public var shouldShowAlertView = false
    @Published public var shouldShowSpinner = false
    @Published public var willCapturePhoto = false
    @Published public var isCameraButtonDisabled = true
    @Published public var isCameraUnavailable = true
    @Published public var errorDescription = ""
    @Published var isFlashOn = false
    @Published var instantPhoto:DetailPhotoModel!
    @Published var model: TakePictureModel!
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    // Communicate with the session and other session objects on this queue.
    let sessionQueue = DispatchQueue(label: "session queue")
 
    
    // MARK: Session Management Properties
    public let session = AVCaptureSession()
    var isSessionRunning = false
    var isConfigured = false
    var setupResult: SessionSetupResult = .success
    
    // MARK: Device Configuration Properties
    let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    
    // MARK: Capturing Photos
    let photoOutput = AVCapturePhotoOutput()
    var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    //    MARK: Init
       init() {
        // Disable the UI. Enable the UI later, if and only if the session starts running.
        DispatchQueue.main.async {
            self.isCameraButtonDisabled = true
            self.isCameraUnavailable = true
        }
    }


    
    /*
     Setup the capture session.
     In general, it's not safe to mutate an AVCaptureSession or any of its
     inputs, outputs, or connections from multiple threads at the same time.
     
     Don't perform these tasks on the main queue because
     AVCaptureSession.startRunning() is a blocking call, which can
     take a long time. Dispatch session setup to the sessionQueue, so
     that the main queue isn't blocked, which keeps the UI responsive.
     */
    
    func configure() {
        checkForPermissions()
        if !self.isSessionRunning && !self.isConfigured {
            sessionQueue.async {
                self.configureSession()
            }
        }
    }
    
    //    MARK: Capture Photo
    /*
     Retrieve the video preview layer's video orientation on the main queue before
     entering the session queue. This to ensures that UI elements are accessed on
     the main thread and session configuration is done on the session queue.
     */
    
    func capturePhoto(_ withLocation:String) {
        
        if self.setupResult != .configurationFailed {
            let videoPreviewLayerOrientation: AVCaptureVideoOrientation = .portrait
            self.isCameraButtonDisabled = true
            
            sessionQueue.async {
                if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                    photoOutputConnection.videoOrientation = videoPreviewLayerOrientation
                }
                var photoSettings = AVCapturePhotoSettings()
                
                // Capture HEIF photos when supported. Enable according to user settings and high-resolution photos.
                if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }
                
                if self.videoDeviceInput.device.isFlashAvailable {
                    photoSettings.flashMode = self.flashMode
                }
                
                photoSettings.isHighResolutionPhotoEnabled = true
                if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                    photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
                }
                
                photoSettings.photoQualityPrioritization = .speed
                
                let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: {
                    // Flash the screen to signal that AVCam took a photo.
                    DispatchQueue.main.async {
                        self.willCapturePhoto.toggle()
                        self.willCapturePhoto.toggle()
                    }
                }, completionHandler: { (photoCaptureProcessor) in
                    // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                    if let data = photoCaptureProcessor.photoData {
                        self.model = TakePictureModel(originalData: data)
                        self.instantPhoto = DetailPhotoModel(image: self.model.image!, location: withLocation)
                        self.principalViewModel.imagesArray.append(self.instantPhoto)
                  
                        print("passing photo")
                    } else {
                        print("No photo data.")
                        self.shouldShowAlertView = true
                        self.errorDescription = "No photo data."
                    }
                    
                    self.isCameraButtonDisabled = false
                    
                    self.sessionQueue.async {
                        self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                    }
                }, photoProcessingHandler: { animate in
                    // Animates a spinner while photo is processing
                    if animate {
                        self.shouldShowSpinner = true
                    } else {
                        self.shouldShowSpinner = false
                    }
                })
                
                // The photo output holds a weak reference to the photo capture delegate and stores it in an array to maintain a strong reference.
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
                self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
            }
        }
    }
    
    func flipCamera() {
        //        MARK: Here disable all camera operation related buttons due to configuration is due upon and must not be interrupted
        DispatchQueue.main.async {
            self.isCameraButtonDisabled = true
        }
        //
        
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
                
            @unknown default:
                self.errorDescription = "Unknown capture position. Defaulting to back, dual-camera."
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
            }
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, seek a device with both the preferred position and device type. Otherwise, seek a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, because AVCaptureSession doesn't support
                    // simultaneous use of the rear and front cameras.
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                        
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }
                    
                    if let connection = self.photoOutput.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                    
                    self.session.commitConfiguration()
                } catch {
                    self.errorDescription = "Error occurred while creating video device input: \(error)"
                }
            }
            
            DispatchQueue.main.async {
                //                MARK: Here enable all camera operation related buttons due to succesfull setup
                self.isCameraButtonDisabled = false
            }
        }
    }
    
    func zoom(with factor: CGFloat) {
        let factor = factor < 1 ? 1 : factor
        let device = self.videoDeviceInput.device
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = factor
            device.unlockForConfiguration()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func switchFlash() {
        switch self.flashMode {
           case .off:
            self.isFlashOn.toggle()
             self.flashMode = .on
           case .on:
            self.isFlashOn.toggle()
             self.flashMode = .off
           default:
            self.isFlashOn = false
            self.flashMode = .off
        }
    }
    
    
    //        MARK: Checks for permisions, setup obeservers and starts running session
    public func checkForPermissions() {
        /*
         Check the video authorization status. Video access is required and audio
         access is optional. If the user denies audio access, AVCam won't
         record audio during movie recording.
         */
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. Suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
            
            DispatchQueue.main.async {
                self.errorDescription = "No tiene permiso para usar la cámara, por favor cambia la configruación de privacidad"
                self.shouldShowAlertView = true
                self.isCameraUnavailable = true
                self.isCameraButtonDisabled = true
            }
        }
    }
    
    //  MARK: Session Managment
    
    // Call this on the session queue.
    /// - Tag: ConfigureSession
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        /*
         Do not create an AVCaptureMovieFileOutput when setting up the session because
         Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
         */
        session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                self.errorDescription = "Default video device is unavailable."
                setupResult = .configurationFailed
                self.shouldShowAlertView = true
                session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
            } else {
                self.errorDescription = "Couldn't add video device input to the session."
                setupResult = .configurationFailed
                self.shouldShowAlertView = true
                session.commitConfiguration()
                return
            }
        } catch {
            self.errorDescription = "Couldn't create video device input: \(error)"
            setupResult = .configurationFailed
            self.shouldShowAlertView = true
            session.commitConfiguration()
            return
        }
        
        // Add the photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
            
        } else {
            self.errorDescription = "Could not add photo output to the session"
            setupResult = .configurationFailed
            self.shouldShowAlertView = true
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        self.isConfigured = true
        
        self.start()
    }
    
    private func resumeInterruptedSession() {
        sessionQueue.async {
            /*
             The session might fail to start running, for example, if a phone or FaceTime call is still
             using audio or video. This failure is communicated by the session posting a
             runtime error notification. To avoid repeatedly failing to start the session,
             only try to restart the session in the error handler if you aren't
             trying to resume the session.
             */
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    self.errorDescription = "Unable to resume camera"
                    self.shouldShowAlertView = true
                    self.isCameraUnavailable = true
                    self.isCameraButtonDisabled = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isCameraUnavailable = false
                    self.isCameraButtonDisabled = false
                }
            }
        }
    }
    
    //  MARK: Device Configuration
    
    
    public func focus(with focusMode: AVCaptureDevice.FocusMode,
                      exposureMode: AVCaptureDevice.ExposureMode,
                      at devicePoint: CGPoint,
                      monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            guard let device = self.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                self.errorDescription = "Could not lock device for configuration: \(error)"
            }
        }
    }

    
    @objc public func stop(completion: (() -> ())? = nil) {
        sessionQueue.async {
            if self.isSessionRunning {
                if self.setupResult == .success {
                    self.session.stopRunning()
                    self.isSessionRunning = self.session.isRunning
                    print("CAMERA STOPPED")
                    if !self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = true
                            self.isCameraUnavailable = true
                            completion?()
                        }
                    }
                }
            }
        }
    }
    
    @objc public func start() {
        sessionQueue.async {
            if !self.isSessionRunning && self.isConfigured {
                switch self.setupResult {
                case .success:

                    self.session.startRunning()
                    print("CAMERA RUNNING")
                    self.isSessionRunning = self.session.isRunning
                    
                    if self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = false
                            self.isCameraUnavailable = false
                        }
                    }
                    
                case .notAuthorized:
                    DispatchQueue.main.async {
                        self.errorDescription = "Application not authorized to use camera"
                        self.shouldShowAlertView = true
                        self.isCameraButtonDisabled = true
                        self.isCameraUnavailable = true
                    }
                    
                case .configurationFailed:
                    DispatchQueue.main.async {
                        self.errorDescription = "Camera configuration failed. Either your device camera is not available or other application is using it"
                        self.shouldShowAlertView = true
                        self.isCameraButtonDisabled = true
                        self.isCameraUnavailable = true
                    }
                }
            }
        }
    }
        
    

    
    @objc
    private func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    
    /// - Tag: HandleSystemPressure
    private func setRecommendedFrameRateRangeForPressureState(systemPressureState: AVCaptureDevice.SystemPressureState) {
        /*
         The frame rates used here are only for demonstration purposes.
         Your frame rate throttling may be different depending on your app's camera configuration.
         */
        let pressureLevel = systemPressureState.level
        if pressureLevel == .serious || pressureLevel == .critical {
            do {
                try self.videoDeviceInput.device.lockForConfiguration()
                print("WARNING: Reached elevated system pressure level: \(pressureLevel). Throttling frame rate.")
                self.videoDeviceInput.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
                self.videoDeviceInput.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
                self.videoDeviceInput.device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        } else if pressureLevel == .shutdown {
            print("Session stopped running due to shutdown system pressure level.")
        }
    }
    
}

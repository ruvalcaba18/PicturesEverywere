//  TakePictureModel.swift
//  PicturesEverywere
//  Created by Jael Fautino Ruvalcaba Tabares on 27/01/23.

import Foundation
import Combine
import AVFoundation
import Photos
import UIKit

enum LivePhotoMode {
    case on
    case off
}

enum DepthDataDeliveryMode {
    case on
    case off
}

enum PortraitEffectsMatteDeliveryMode {
    case on
    case off
}

enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
}

enum CaptureMode: Int {
    case photo = 0
    case movie = 1
}


public struct TakePictureModel: Identifiable, Equatable {
//    The ID of the captured photo
    public var id: String
//    Data representation of the captured photo
    public var originalData: Data
    
    public var compressedData: Data? {
        ImageResizer(targetWidth: 800).resize(data: originalData)?.jpegData(compressionQuality: 0.5)
    }
    public var thumbnailData: Data? {
        ImageResizer(targetWidth: 100).resize(data: originalData)?.jpegData(compressionQuality: 0.5)
    }
    public var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    public var image: UIImage? {
        guard let data = compressedData else { return nil }
        return UIImage(data: data)
    }

    
    public init(id: String = UUID().uuidString, originalData: Data) {
        self.id = id
        self.originalData = originalData
    }
}

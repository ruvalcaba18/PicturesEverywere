//  DetailPhotoModel.swift
//  PicturesEverywere
//  Created by Jael Fautino Ruvalcaba Tabares on 29/01/23.

import Foundation
import SwiftUI
struct DetailPhotoModel: Identifiable {
    let id = UUID()
    let image: UIImage
    let location: String
}

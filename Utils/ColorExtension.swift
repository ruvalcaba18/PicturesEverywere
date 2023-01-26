//
//  ColorExtension.swift
//  PicturesEverywere
//
//  Created by Jael Fautino Ruvalcaba Tabares on 26/01/23.
//

import SwiftUI

extension Color {
    
    static let element = Color("Element")
    static let highlight = Color("Highlight")
    static let shadow = Color("Shadow")
    
    public static var backGroundColor: Color {
        return Color(#colorLiteral(red: 0.1586097777, green: 0.2777151465, blue: 0.5929754376, alpha: 1))
    }
    public static var lightPurple: Color {
        return Color(#colorLiteral(red: 0.82, green: 0.77, blue: 0.91, alpha: 1))
    }
    public static var lightedPurple: Color {
        return Color(#colorLiteral(red: 0.70, green: 0.62, blue: 0.86, alpha: 1.00))
    }
    
    public static var tealColor: Color {
        return Color(#colorLiteral(red: 0.00, green: 0.59, blue: 0.53, alpha: 1.00))
    }

}

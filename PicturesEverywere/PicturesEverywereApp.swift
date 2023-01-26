//
//  PicturesEverywereApp.swift
//  PicturesEverywere
//
//  Created by Jael Fautino Ruvalcaba Tabares on 26/01/23.
//

import SwiftUI

@main
struct PicturesEverywereApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            OnBoardingView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

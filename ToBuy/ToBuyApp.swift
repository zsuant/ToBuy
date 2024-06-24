//
//  ToBuyApp.swift
//  ToBuy
//
//  Created by 이수겸 on 2024/06/24.
//

import SwiftUI

@main
struct ToBuyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

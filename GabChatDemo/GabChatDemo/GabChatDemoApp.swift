//
//  GabChatDemoApp.swift
//  GabChatDemo
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

import ComposableArchitecture

@main
struct GabChatDemoApp: App {
    var body: some Scene {
        WindowGroup {
            let store: StoreOf<GabChatDemoReducer> = .init(initialState: GabChatDemoReducer.State()) {
                GabChatDemoReducer()
            }
            
            ContentView(store: store)
        }
    }
}

//
//  AsyncAction.swift
//  GabChat
//
//  Created by 심상갑 on 4/13/25.
//

import SwiftUI

actor UpdateQueue {
    private var isProcessing = false

    func enqueue(_ work: @escaping @Sendable () async -> Void) async {
        while isProcessing {
            await Task.yield() // Wait for previous task to finish
        }

        isProcessing = true
        await work()
        isProcessing = false
    }
}

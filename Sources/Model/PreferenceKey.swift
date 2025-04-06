//
//  PreferenceKey.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

struct InputHeightKey: PreferenceKey {
    public static var defaultValue: CGFloat = .zero
    
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

//
//  TextCell.swift
//  GabChatDemo
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

struct TextCell: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.black)
    }
}

#Preview {
    TextCell(text: "TextCell")
}

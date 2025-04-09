//
//  DateCell.swift
//  GabChatDemo
//
//  Created by Gab on 4/10/25.
//

import SwiftUI

struct DateCell: View {
    let insDate: String
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(.gray)
                .frame(height: 3)
            
            Text(insDate)
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
            
            Rectangle()
                .fill(.gray)
                .frame(height: 3)
        }
    }
}

#Preview {
    DateCell(insDate: Int(Date().timeIntervalSince1970).makeLocaleDate())
}

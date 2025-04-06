//
//  ImageCell.swift
//  GabChatDemo
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

import Kingfisher

struct ImageCell: View {
    let urlString: String
    
    var body: some View {
        KFImage(URL(string: urlString))
            .resizable()
            .frame(width: 300, height: 300)
    }
}

#Preview {
    ImageCell(urlString: "dd")
}

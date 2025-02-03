//
//  ThumbnailView.swift
//  HiPixel
//
//  Created by 十里 on 2024/11/1.
//

import SwiftUI

struct ThumbnailView: View {
    
    let item: UpscaylDataItem
    
    @EnvironmentObject var upscaylData: UpscaylData
    
    var body: some View {
        AsyncImage(url: item.thumbnail) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let imageView):
                imageView
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure(let error):
                Image(systemName: "questionmark")
                    .font(.headline)
                    .help(error.localizedDescription)
            @unknown default:
                Image(systemName: "questionmark")
                    .font(.headline)
            }
        }
        .frame(width: 64, height: 64)
        .aspectRatio(contentMode: .fill)
        .cornerRadius(16)
        .background(
            cornerRadius: 16,
            strokeColor: .primary.opacity(item.id == upscaylData.selectedItem?.id ? 0.2: 0.06),
            fill: .background.opacity(item.id == upscaylData.selectedItem?.id ? 0.8 : 0.3)
        )
        .overlay {
            if item.state == .processing {
                ProgressView(value: item.progress / 100)
                    .progressViewStyle(.circular)
                    .tint(.primary)
                    .frame(width: 64, height: 64)
                    .background(cornerRadius: 16, fill: .background.opacity(0.8))
            }
        }
        .background(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.primary.opacity(item.id == upscaylData.selectedItem?.id ? 1 : 0))
                .frame(width: 24, height: 3)
                .offset(y: 5)
        }
        .onTapGesture {
            withAnimation(.spring) {
                upscaylData.selectedItem = item
            }
        }
    }
}

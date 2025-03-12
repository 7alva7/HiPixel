//
//  MonitorItemView.swift
//  HiPixel
//
//  Created by 十里 on 2025/03/11.
//

import SwiftUI

struct MonitiorItemView: View {

    @ObservedObject
    var monitorService = MonitorService.shared

    @State
    var item: MonitorItem

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(
                    action: {
                        Common.openPanel(
                            message: String(localized: "Select a folder to auto-hipixel new images"),
                            windowTitle: "HiPixel"
                        ) { url in
                            let newOne = MonitorItem(id: item.id, url: url, enabled: item.enabled)
                            monitorService.update(newOne)
                        }
                    },
                    label: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.badge.gearshape")
                                .font(.headline)
                            Text(item.url.path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                    }
                )
                .buttonStyle(.plain)

                Spacer()

                Toggle(
                    isOn: $item.enabled,
                    label: {
                    }
                )
                .toggleStyle(.switch)
                .controlSize(.mini)
                .padding(.trailing, 8)
                .onChange(of: item.enabled) { newValue in
                    let newOne = MonitorItem(id: item.id, url: item.url, enabled: newValue)
                    monitorService.update(newOne)
                }
            }
            .font(.caption)
            .background(cornerRadius: 6, strokeColor: .primary.opacity(0.04), fill: .background.opacity(0.4))

            Button(
                action: {
                    monitorService.remove(item)
                },
                label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                }
            )
            .buttonStyle(.plain)
        }
    }
}

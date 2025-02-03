import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            AppInfoView()
            
            // Open source components section
            SettingItem(
                title: "OPEN SOURCE COMPONENTS",
                icon: "cube.transparent",
                bodyView: VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image("upscayl")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Link("Upscayl", destination: URL(string: "https://github.com/upscayl/upscayl")!)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Components used:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text("upscayl-bin")
                                    .bold()
                                + Text(" - The binary tool for AI upscaling")
                            }
                            
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text("AI Models")
                                    .bold()
                                + Text(" - The image super-resolution models")
                            }
                        }
                        .font(.caption)
                        
                        Link("Licensed under AGPLv3", destination: URL(string: "https://www.gnu.org/licenses/agpl-3.0.en.html")!)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
            )
            
            // Links section
            HStack(spacing: 16) {
                Button(action: {
                    if let url = URL(string: "https://github.com/okooo5km/HiPixel") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(.github)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                        Text("Source Code")
                    }
                }
                .buttonStyle(.gradient(configuration: .primary))
                
                Button(action: {
                    if let url = URL(string: "https://twitter.com/okooo5km") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(.twitter)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                        Text("Follow Me")
                    }
                }
                .buttonStyle(.gradient(configuration: .primary))
            }
            
            // Copyright section
            VStack(spacing: 4) {
                Text(" \(String(format: "%d", Calendar.current.component(.year, from: Date()))) 5KM Software Tech Co., Ltd.")
                Text("Licensed under AGPLv3")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            VibrantBackground()
                .edgesIgnoringSafeArea(.all)
        )
        .focusable(false)
    }
}

#Preview {
    AboutView()
}

import SwiftUI

struct AboutView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                // 顶部应用信息
                VStack(spacing: 16) {
                    // Logo 和名称
                    HStack(spacing: 20) {
                        Image(systemName: "keyboard")
                            .font(fontManager.getFont(size: 48))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("KeyMetrics")
                                .font(fontManager.getFont(size: 32))
                                .fontWeight(.bold)
                            Text(languageManager.localizedString("Version") + " 1.0.0")
                                .font(fontManager.getFont(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 应用简介
                    GroupBox {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(languageManager.localizedString("App Description"))
                                .font(fontManager.getFont(size: 14))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(8)
                    }
                    .groupBoxStyle(CustomGroupBoxStyle())
                }
                
                HStack(spacing: 24) {
                    // 开发者信息
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                Text(languageManager.localizedString("Developer Info"))
                                    .font(fontManager.getFont(size: 16))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack(spacing: 20) {
                                // 头像
                                Image("avatar")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.blue.opacity(0.5), lineWidth: 2))
                                    .shadow(color: .blue.opacity(0.3), radius: 4)
                                
                                // 联系信息
                                VStack(alignment: .leading, spacing: 10) {
                                    InfoRow(
                                        icon: "person.fill",
                                        label: languageManager.localizedString("Name"),
                                        text: languageManager.localizedString("Developer Name")
                                    )
                                    InfoRow(
                                        icon: "link",
                                        label: languageManager.localizedString("GitHub"),
                                        text: "github.com/Auroral0810",
                                        isLink: true
                                    )
                                    InfoRow(
                                        icon: "message.fill",
                                        label: "QQ",
                                        text: "1957689514",
                                        copyable: true
                                    )
                                    InfoRow(
                                        icon: "envelope.fill",
                                        label: languageManager.localizedString("Email"),
                                        text: "15968588744@163.com",
                                        copyable: true
                                    )
                                }
                            }
                        }
                        .padding(16)
                    }
                    .groupBoxStyle(CustomGroupBoxStyle())
                    
                    // 技术栈
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "hammer.fill")
                                    .foregroundColor(.blue)
                                Text(languageManager.localizedString("Tech Stack"))
                                    .font(fontManager.getFont(size: 16))
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                TechRow(
                                    name: "SwiftUI", 
                                    description: languageManager.localizedString("UI Framework"), 
                                    color: .blue
                                )
                                TechRow(
                                    name: "SwiftData", 
                                    description: languageManager.localizedString("Data Persistence"), 
                                    color: .green
                                )
                                TechRow(
                                    name: "Combine", 
                                    description: languageManager.localizedString("Reactive Programming"), 
                                    color: .orange
                                )
                                TechRow(
                                    name: "Charts", 
                                    description: languageManager.localizedString("Data Visualization"), 
                                    color: .purple
                                )
                                TechRow(
                                    name: "macOS", 
                                    description: languageManager.localizedString("Native App"), 
                                    color: .pink
                                )
                            }
                        }
                        .padding(16)
                    }
                    .groupBoxStyle(CustomGroupBoxStyle())
                }
                
                // 功能特点
                GroupBox {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.blue)
                            Text(languageManager.localizedString("Features"))
                                .font(fontManager.getFont(size: 16))
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 24) {
                            FeatureBox(
                                icon: "keyboard",
                                title: languageManager.localizedString("Real-time Monitoring"),
                                description: languageManager.localizedString("Record Every Keystroke"),
                                details: [
                                    languageManager.localizedString("Full Keyboard Capture"),
                                    languageManager.localizedString("Keystroke Frequency Stats"),
                                    languageManager.localizedString("Shortcut Recognition")
                                ],
                                color: .blue
                            )
                            
                            FeatureBox(
                                icon: "chart.bar.fill",
                                title: languageManager.localizedString("Data Analysis"),
                                description: languageManager.localizedString("Comprehensive Reports"),
                                details: [
                                    languageManager.localizedString("Daily Usage Statistics"),
                                    languageManager.localizedString("Common Key Distribution"),
                                    languageManager.localizedString("Efficiency Trend Analysis")
                                ],
                                color: .green
                            )
                            
                            FeatureBox(
                                icon: "gauge.high",
                                title: languageManager.localizedString("Performance Optimization"),
                                description: languageManager.localizedString("Low System Usage"),
                                details: [
                                    languageManager.localizedString("Background Silent Running"),
                                    languageManager.localizedString("Memory Usage <50MB"),
                                    languageManager.localizedString("Low CPU Usage")
                                ],
                                color: .orange
                            )
                            
                            FeatureBox(
                                icon: "lock.fill",
                                title: languageManager.localizedString("Privacy Protection"),
                                description: languageManager.localizedString("Local Data Storage"),
                                details: [
                                    languageManager.localizedString("No Network Communication"),
                                    languageManager.localizedString("Local Data Encryption"),
                                    languageManager.localizedString("Secure Backup Mechanism")
                                ],
                                color: .purple
                            )
                        }
                    }
                    .padding(16)
                }
                .groupBoxStyle(CustomGroupBoxStyle())
                
                Spacer()
                
                // 底部版权信息
                VStack(spacing: 4) {
                    Text("© 2025 KeyMetrics. " + languageManager.localizedString("All rights reserved"))
                        .font(fontManager.getFont(size: 12))
                    HStack(spacing: 4) {
                        Text(languageManager.localizedString("Build with"))
                            .font(fontManager.getFont(size: 12))
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text(languageManager.localizedString("by") + " Auroral")
                            .font(fontManager.getFont(size: 12))
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding(24)
        }
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
    }
}

// 辅助视图组件
struct InfoRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    
    let icon: String
    let label: String
    let text: String
    var isLink: Bool = false
    var copyable: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(label)
                .font(fontManager.getFont(size: 14))
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)
            
            if isLink {
                Link(text, destination: URL(string: "https://\(text)")!)
                    .font(fontManager.getFont(size: 14))
                    .foregroundColor(.blue)
            } else {
                Text(text)
                    .font(fontManager.getFont(size: 14))
                    .foregroundColor(.blue)
            }
            
            if copyable {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
    }
}

struct TechRow: View {
    @EnvironmentObject var fontManager: FontManager
    
    let name: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(fontManager.getFont(size: 14))
                .fontWeight(.medium)
                .foregroundColor(color)
                .frame(width: 80, alignment: .leading)
            
            Text(description)
                .font(fontManager.getFont(size: 14))
                .foregroundColor(.gray)
        }
    }
}

struct FeatureBox: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var fontManager: FontManager
    
    let icon: String
    let title: String
    let description: String
    let details: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(fontManager.getFont(size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            }
            
            Text(description)
                .font(fontManager.getFont(size: 14))
                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(details, id: \.self) { detail in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 4, height: 4)
                        Text(detail)
                            .font(fontManager.getFont(size: 12))
                            .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? color.opacity(0.1) : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    themeManager.isDarkMode 
                        ? color.opacity(0.3) 
                        : color.opacity(0.6),
                    lineWidth: 2
                )
        )
        .shadow(
            color: color.opacity(themeManager.isDarkMode ? 0.1 : 0.2),
            radius: 4,
            x: 0,
            y: 2
        )
    }
} 

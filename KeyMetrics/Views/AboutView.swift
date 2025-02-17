import SwiftUI

struct AboutView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                // 顶部应用信息
                VStack(spacing: 16) {
                    // Logo 和名称
                    HStack(spacing: 20) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("KeyMetrics")
                                .font(.system(size: 32, weight: .bold))
                            Text("版本 1.0.0")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 应用简介
                    GroupBox {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("KeyMetrics 是一款专业的键盘输入分析工具，致力于帮助用户了解和改善自己的打字习惯。通过实时监测和数据分析，为用户提供全面的键盘使用报告。")
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
                                Text("开发者信息")
                                    .font(.headline)
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
                                    InfoRow(icon: "person.fill", label: "姓名", text: "俞云烽")
                                    InfoRow(icon: "link", label: "开源地址", text: "github.com/Auroral0810", isLink: true)
                                    InfoRow(icon: "message.fill", label: "QQ", text: "1957689514", copyable: true)
                                    InfoRow(icon: "envelope.fill", label: "邮箱", text: "15968588744@163.com", copyable: true)
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
                                Text("技术栈")
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                TechRow(name: "SwiftUI", description: "用户界面框架", color: .blue)
                                TechRow(name: "SwiftData", description: "数据持久化", color: .green)
                                TechRow(name: "Combine", description: "响应式编程", color: .orange)
                                TechRow(name: "Charts", description: "数据可视化", color: .purple)
                                TechRow(name: "macOS", description: "原生应用", color: .pink)
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
                            Text("功能特点")
                                .font(.headline)
                        }
                        
                        HStack(spacing: 24) {
                            FeatureBox(
                                icon: "keyboard",
                                title: "实时监测",
                                description: "精确记录每一次按键",
                                details: ["全键盘按键捕获", "按键频率统计", "组合键识别"],
                                color: .blue
                            )
                            
                            FeatureBox(
                                icon: "chart.bar.fill",
                                title: "数据分析",
                                description: "全面的统计报告",
                                details: ["每日使用时长统计", "常用按键分布", "效率趋势分析"],
                                color: .green
                            )
                            
                            FeatureBox(
                                icon: "gauge.high",
                                title: "性能优化",
                                description: "极低的系统占用",
                                details: ["后台静默运行", "内存占用<50MB", "低CPU使用率"],
                                color: .orange
                            )
                            
                            FeatureBox(
                                icon: "lock.fill",
                                title: "隐私保护",
                                description: "本地数据存储",
                                details: ["无网络通信", "数据本地加密", "安全备份机制"],
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
                    Text("© 2025 KeyMetrics. All rights reserved.")
                    HStack(spacing: 4) {
                        Text("Build with")
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("by Auroral")
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
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)
            
            if isLink {
                Link(text, destination: URL(string: "https://\(text)")!)
                    .foregroundColor(.blue)
            } else {
                Text(text)
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
        .font(.system(size: 14))
        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
    }
}

struct TechRow: View {
    let name: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 80, alignment: .leading)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}

struct FeatureBox: View {
    @EnvironmentObject var themeManager: ThemeManager
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            }
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(details, id: \.self) { detail in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 4, height: 4)
                        Text(detail)
                            .font(.system(size: 12))
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

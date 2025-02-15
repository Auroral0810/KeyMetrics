import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部统计卡片
                HStack(spacing: 20) {
                    StatCardView(
                        title: "累计按键",
                        value: "\(keyboardMonitor.keyStats.totalCount)",
                        icon: "keyboard",
                        color: ThemeManager.ThemeColors.chartColors[0]
                    )
                    
                    StatCardView(
                        title: "今日按键",
                        value: "\(getTodayKeyCount())",
                        icon: "clock",
                        color: ThemeManager.ThemeColors.chartColors[1]
                    )
                }
                
                // 中间区域：速度计和气泡区
                HStack(spacing: 20) {
                    // 实时速度计 - 调整大小
                    SpeedMeterView(currentSpeed: getCurrentTypingSpeed())
                        .frame(width: 160, height: 160)
                    
                    // 按键气泡动画区域 - 填满剩余空间
                    KeyBubbleView(latestKeyStroke: keyboardMonitor.latestKeyStroke)
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
                        .cornerRadius(16)
                }
                
                // 准确率统计
                HStack(spacing: 20) {
                    AccuracyCardView(
                        title: "历史准确率",
                        accuracy: getHistoricalAccuracy(),
                        color: ThemeManager.ThemeColors.chartColors[2]
                    )
                    
                    AccuracyCardView(
                        title: "近1小时准确率",
                        accuracy: getHourlyAccuracy(),
                        color: ThemeManager.ThemeColors.chartColors[3]
                    )
                }
            }
            .padding()
        }
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
    }
    
    private func getTodayKeyCount() -> Int {
        let calendar = Calendar.current
        return keyboardMonitor.keyStats.dailyStats[calendar.startOfDay(for: Date())] ?? 0
    }
    
    private func getCurrentTypingSpeed() -> Double {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        let recentKeyStrokes = keyboardMonitor.keyStats.hourlyStats.filter { timestamp, _ in
            timestamp >= oneMinuteAgo && timestamp <= now
        }.values.reduce(0, +)
        
        return Double(recentKeyStrokes)
    }
    
    private func getHistoricalAccuracy() -> Double {
        let totalKeys = keyboardMonitor.keyStats.totalCount
        let totalDeletes = keyboardMonitor.keyStats.totalDeleteCount
        guard totalKeys > 0 else { return 0 }
        return Double(totalKeys - totalDeletes) / Double(totalKeys)
    }
    
    private func getHourlyAccuracy() -> Double {
        let now = Date()
        let hourAgo = now.addingTimeInterval(-3600)
        
        let hourlyKeys = keyboardMonitor.keyStats.hourlyStats.filter { timestamp, _ in
            timestamp >= hourAgo && timestamp <= now
        }.values.reduce(0, +)
        
        let hourlyDeletes = keyboardMonitor.keyStats.hourlyDeleteStats.filter { timestamp, _ in
            timestamp >= hourAgo && timestamp <= now
        }.values.reduce(0, +)
        
        guard hourlyKeys > 0 else { return 0 }
        return Double(hourlyKeys - hourlyDeletes) / Double(hourlyKeys)
    }
}

struct StatCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
        }
        .padding()
        .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
        .cornerRadius(16)
    }
}

// 改进的速度计视图 - 更紧凑的布局
struct SpeedMeterView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentSpeed: Double
    
    var body: some View {
        VStack(spacing: 8) { // 减小间距
            Text("实时击键速度")
                .font(.subheadline) // 减小字体
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            
            ZStack {
                Circle()
                    .stroke(
                        ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode).opacity(0.2),
                        lineWidth: 12 // 减小线宽
                    )
                
                Circle()
                    .trim(from: 0, to: min(currentSpeed / 300.0, 1.0))
                    .stroke(
                        ThemeManager.ThemeColors.chartColors[0],
                        style: StrokeStyle(
                            lineWidth: 12, // 减小线宽
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) { // 减小间距
                    Text("\(Int(currentSpeed))")
                        .font(.system(size: 28, weight: .bold)) // 减小字体
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    Text("次/分钟")
                        .font(.caption) // 使用更小的字体
                        .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
                }
            }
        }
        .padding()
        .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
        .cornerRadius(16)
    }
}

// 新增的准确率卡片视图
struct AccuracyCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let accuracy: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
            
            Text(String(format: "%.1f%%", accuracy * 100))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            
            ProgressView(value: accuracy)
                .tint(color)
        }
        .padding()
        .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
        .cornerRadius(16)
    }
}

// 改进的气泡动画视图
struct KeyBubbleView: View {
    let latestKeyStroke: KeyStroke?
    @State private var bubbles: [(id: UUID, key: String, position: CGPoint, offset: CGFloat, timestamp: Date)] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(bubbles, id: \.id) { bubble in
                    Text(bubble.key)
                        .modifier(BubbleTextStyle())
                        .position(x: bubble.position.x, y: bubble.position.y + bubble.offset)
                        .opacity(CGFloat(1.0) - (abs(bubble.offset) / CGFloat(200.0)))
                }
            }
            .onChange(of: latestKeyStroke) { _, newKeyStroke in
                if let keyStroke = newKeyStroke,
                   let character = keyStroke.character {
                    addNewBubble(key: character, timestamp: keyStroke.timestamp, in: geometry.size)
                }
            }
        }
    }
    
    private func addNewBubble(key: String, timestamp: Date, in size: CGSize) {
        // 随机生成起始位置（底部区域）
        let randomX = CGFloat.random(in: 20...(size.width - 20))
        let startY = size.height - 20
        
        let newBubble = (
            id: UUID(),
            key: key,
            position: CGPoint(x: randomX, y: startY),
            offset: CGFloat(0),
            timestamp: timestamp
        )
        
        bubbles.append(newBubble)
        
        withAnimation(.easeOut(duration: 2)) {
            if let index = bubbles.firstIndex(where: { $0.id == newBubble.id }) {
                bubbles[index].offset = -200 // 向上飘动的距离
            }
        }
        
        // 2秒后移除气泡
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            bubbles.removeAll { $0.id == newBubble.id }
        }
    }
}

struct BubbleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .medium))
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
    }
}

// 添加字体大小扩展
extension View {
    func fontSize(_ size: CGFloat) -> some View {
        self.font(.system(size: size))
    }
}
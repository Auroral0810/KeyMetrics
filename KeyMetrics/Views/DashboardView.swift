import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // 顶部统计卡片
                HStack(spacing: 20) {
                    StatCardView(
                        title: "累计按键",
                        value: "\(keyboardMonitor.keyStats.totalCount)",
                        icon: "keyboard",
                        color: ThemeManager.ThemeColors.chartColors[0]
                    )
                    .frame(height: 100)
                    
                    StatCardView(
                        title: "今日按键",
                        value: "\(getTodayKeyCount())",
                        icon: "clock",
                        color: ThemeManager.ThemeColors.chartColors[1]
                    )
                    .frame(height: 100)
                }
                
                // 中间区域：速度计和气泡区
                HStack(spacing: 20) {
                    SpeedMeterView(currentSpeed: getCurrentTypingSpeed())
                        .frame(width: 140, height: 140)
                    
                    KeyBubbleView(latestKeyStroke: keyboardMonitor.latestKeyStroke)
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
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
                    .frame(height: 100)
                    
                    AccuracyCardView(
                        title: "近1小时准确率",
                        accuracy: getHourlyAccuracy(),
                        color: ThemeManager.ThemeColors.chartColors[3]
                    )
                    .frame(height: 100)
                }
                
                // 键盘负荷分布图
                KeyboardHeatMapView(keyStats: keyboardMonitor.keyStats)
                    .frame(minHeight: 280, maxHeight: .infinity)
                    .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
                    .cornerRadius(16)
            }
            .padding(16)
        }
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
    }
    
    private func getTodayKeyCount() -> Int {
        let calendar = Calendar.current
        return keyboardMonitor.keyStats.dailyStats[calendar.startOfDay(for: Date())] ?? 0
    }
    
    private func getCurrentTypingSpeed() -> Double {
        return Double(keyboardMonitor.currentSpeed)
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

// 修改 StatCardView 使其更紧凑
struct StatCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            
            Text(title)
                .font(.caption)
                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
        }
        .padding(12)
        .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
        .cornerRadius(16)
    }
}

// 改进的速度计视图 - 更紧凑的布局
struct SpeedMeterView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentSpeed: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text("实时击键速度")
                .font(.subheadline)
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            
            ZStack {
                Circle()
                    .stroke(
                        ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode).opacity(0.2),
                        lineWidth: 12
                    )
                
                Circle()
                    .trim(from: 0, to: min(currentSpeed / 300.0, 1.0))
                    .stroke(
                        ThemeManager.ThemeColors.chartColors[0],
                        style: StrokeStyle(
                            lineWidth: 12,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(currentSpeed))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    Text("次/分钟")
                        .font(.caption)
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
                    addNewBubble(key: String(character), timestamp: Date(), in: geometry.size)
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

// 键盘热力图视图
struct KeyboardHeatMapView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let keyStats: KeyStats
    
    // 完整键盘布局数据，与 KeyboardMonitor 保持一致
    private let keyboardLayout: [[KeyData]] = [
        // 功能键行
        [
            KeyData(key: "esc", code: 53), 
            KeyData(key: "F1", code: 122), KeyData(key: "F2", code: 120), 
            KeyData(key: "F3", code: 160), KeyData(key: "F4", code: 177),
            KeyData(key: "F5", code: 176), KeyData(key: "F6", code: 178),
            KeyData(key: "F7", code: 130), KeyData(key: "F8", code: 131),
            KeyData(key: "F9", code: 132), KeyData(key: "F10", code: 133),
            KeyData(key: "F11", code: 134), KeyData(key: "F12", code: 135)
        ],
        // 数字键行
        [
            KeyData(key: "`", code: 50), 
            KeyData(key: "1", code: 18), KeyData(key: "2", code: 19),
            KeyData(key: "3", code: 20), KeyData(key: "4", code: 21),
            KeyData(key: "5", code: 23), KeyData(key: "6", code: 22),
            KeyData(key: "7", code: 26), KeyData(key: "8", code: 28),
            KeyData(key: "9", code: 25), KeyData(key: "0", code: 29),
            KeyData(key: "-", code: 27), KeyData(key: "=", code: 24),
            KeyData(key: "⌫", code: 51)
        ],
        // 第一行字母
        [
            KeyData(key: "⇥", code: 48),
            KeyData(key: "Q", code: 12), KeyData(key: "W", code: 13),
            KeyData(key: "E", code: 14), KeyData(key: "R", code: 15),
            KeyData(key: "T", code: 17), KeyData(key: "Y", code: 16),
            KeyData(key: "U", code: 32), KeyData(key: "I", code: 34),
            KeyData(key: "O", code: 31), KeyData(key: "P", code: 35),
            KeyData(key: "[", code: 33), KeyData(key: "]", code: 30),
            KeyData(key: "\\", code: 42)
        ],
        // 第二行字母
        [
            KeyData(key: "⇪", code: 57),
            KeyData(key: "A", code: 0), KeyData(key: "S", code: 1),
            KeyData(key: "D", code: 2), KeyData(key: "F", code: 3),
            KeyData(key: "G", code: 5), KeyData(key: "H", code: 4),
            KeyData(key: "J", code: 38), KeyData(key: "K", code: 40),
            KeyData(key: "L", code: 37), KeyData(key: ";", code: 41),
            KeyData(key: "'", code: 39), KeyData(key: "↩", code: 36)
        ],
        // 第三行字母，修正 shift 键码
        [
            KeyData(key: "⇧", code: 56, id: "shift_left"),
            KeyData(key: "Z", code: 6), KeyData(key: "X", code: 7),
            KeyData(key: "C", code: 8), KeyData(key: "V", code: 9),
            KeyData(key: "B", code: 11), KeyData(key: "N", code: 45),
            KeyData(key: "M", code: 46), KeyData(key: ",", code: 43),
            KeyData(key: ".", code: 47), KeyData(key: "/", code: 44),
            KeyData(key: "⇧", code: 60, id: "shift_right")  // 修正右 shift 键码
        ],
        // 底部功能键行，修正 fn 和其他修饰键的键码
        [
            KeyData(key: "fn", code: 179),
            KeyData(key: "⌃", code: 59),
            KeyData(key: "⌥", code: 58, id: "option_left"),
            KeyData(key: "⌘", code: 55, id: "command_left"),
            KeyData(key: "space", code: 49),
            KeyData(key: "⌘", code: 54, id: "command_right"),
            KeyData(key: "⌥", code: 61, id: "option_right"),
            KeyData(key: "←", code: 123),
            KeyData(key: "↑", code: 126),
            KeyData(key: "↓", code: 125),
            KeyData(key: "→", code: 124)
        ]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Text("键盘负荷分布")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    .padding(.bottom, 0)
                
                Spacer()
                
                VStack(spacing: 2) {
                    ForEach(keyboardLayout.indices, id: \.self) { rowIndex in
                        HStack(spacing: 2) {
                            Spacer(minLength: 0)
                            ForEach(keyboardLayout[rowIndex], id: \.key) { keyData in
                                KeyCell(
                                    key: keyData.key,
                                    frequency: getKeyFrequency(keyCode: keyData.code),
                                    maxFrequency: getMaxFrequency(),
                                    width: getKeyWidth(key: keyData.key, totalWidth: geometry.size.width)
                                )
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(8)
        }
    }
    
    private func getKeyWidth(key: String, totalWidth: CGFloat) -> CGFloat {
        let baseWidth = (totalWidth - 20) / 15
        switch key {
        case "space":
            return baseWidth * 4
        case "⌫", "⇥", "⇪", "↩":
            return baseWidth * 1.5
        case "⇧":
            return baseWidth * 1.8
        default:
            return baseWidth
        }
    }
    
    private func getKeyFrequency(keyCode: Int) -> Int {
        keyStats.keyFrequency[keyCode] ?? 0
    }
    
    private func getMaxFrequency() -> Int {
        keyStats.keyFrequency.values.max() ?? 1
    }
}

// 键盘按键数据模型
struct KeyData: Identifiable {
    let key: String
    let code: Int
    let id: String
    
    init(key: String, code: Int, id: String? = nil) {
        self.key = key
        self.code = code
        self.id = id ?? key // 如果没有提供 id，使用 key 作为默认值
    }
}

// 单个按键单元格视图
struct KeyCell: View {
    @EnvironmentObject var themeManager: ThemeManager
    let key: String
    let frequency: Int
    let maxFrequency: Int
    let width: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(getHeatColor())
                .frame(width: width, height: 32)
                .cornerRadius(4)
            
            Text(key)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
        }
    }
    
    private func getHeatColor() -> Color {
        let intensity = CGFloat(frequency) / CGFloat(max(maxFrequency, 1))
        return Color(
            red: 1,
            green: 1 - intensity * 0.8,
            blue: 1 - intensity * 0.8
        ).opacity(0.3 + intensity * 0.7)
    }
}
import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // 背景：更丰富的暖色夕阳渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.8), // 顶部浅米色
                    Color(red: 1.0, green: 0.7, blue: 0.5),  // 中间暖橙
                    Color(red: 0.9, green: 0.5, blue: 0.4)   // 底部夕阳红
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height
                let towerColor = Color(red: 0.35, green: 0.2, blue: 0.15) // 深咖啡色
                
                // 1. 塔身主体
                Path { path in
                    // 塔尖天线
                    path.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.18))
                    
                    // --- 第三层（顶部） ---
                    path.move(to: CGPoint(x: w * 0.48, y: h * 0.18))
                    path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.18))
                    path.addLine(to: CGPoint(x: w * 0.54, y: h * 0.38))
                    path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.38))
                    path.closeSubpath()
                    
                    // --- 第二层（中部） ---
                    // 顶部连接处略宽于上一层底部
                    path.move(to: CGPoint(x: w * 0.44, y: h * 0.38))
                    path.addLine(to: CGPoint(x: w * 0.56, y: h * 0.38))
                    // 向下延伸，略带弧度
                    path.addQuadCurve(to: CGPoint(x: w * 0.60, y: h * 0.62), control: CGPoint(x: w * 0.58, y: h * 0.5))
                    path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.62))
                    path.addQuadCurve(to: CGPoint(x: w * 0.44, y: h * 0.38), control: CGPoint(x: w * 0.42, y: h * 0.5))
                    
                    // --- 第一层（底部基座） ---
                    path.move(to: CGPoint(x: w * 0.38, y: h * 0.62))
                    path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.62))
                    // 右腿外侧（大幅度曲线）
                    path.addQuadCurve(to: CGPoint(x: w * 0.75, y: h * 0.9), control: CGPoint(x: w * 0.68, y: h * 0.75))
                    // 右腿底边
                    path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.9))
                    // 底部拱门（连贯的半圆弧）
                    path.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.9), control: CGPoint(x: w * 0.5, y: h * 0.78))
                    // 左腿底边
                    path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.9))
                    // 左腿外侧
                    path.addQuadCurve(to: CGPoint(x: w * 0.38, y: h * 0.62), control: CGPoint(x: w * 0.32, y: h * 0.75))
                }
                .fill(towerColor)
                
                // 2. 细节线条（平台和镂空感）
                Group {
                    // 顶部观景台
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.45, y: h * 0.38))
                        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.38))
                    }
                    .stroke(towerColor, style: StrokeStyle(lineWidth: w * 0.025, lineCap: .butt))
                    
                    // 中部观景台
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.39, y: h * 0.62))
                        path.addLine(to: CGPoint(x: w * 0.61, y: h * 0.62))
                    }
                    .stroke(towerColor, style: StrokeStyle(lineWidth: w * 0.03, lineCap: .butt))
                    
                    // 交叉纹理（X型结构）- 简化版，避免小图标太乱
                    Path { path in
                        // 中层X
                        path.move(to: CGPoint(x: w * 0.45, y: h * 0.38))
                        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.62))
                        path.move(to: CGPoint(x: w * 0.55, y: h * 0.38))
                        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.62))
                        
                        // 塔尖竖线
                        path.move(to: CGPoint(x: w * 0.5, y: h * 0.18))
                        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.38))
                    }
                    .stroke(Color.white.opacity(0.3), lineWidth: w * 0.01)
                }
            }
            .padding(20)
        }
        .frame(width: 512, height: 512)
    }
}

struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconView()
            .previewLayout(.sizeThatFits)
    }
}

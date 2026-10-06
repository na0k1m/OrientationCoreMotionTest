import SwiftUI

struct ContentView: View {
    @StateObject private var orientationManager = OrientationManager()
    
    var body: some View {
        VStack(spacing: 40) {
            Text("무대 방향 인지 프로토타입")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                Text("현재 구역")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(orientationManager.currentZone.rawValue)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(colorForZone(orientationManager.currentZone))
                
                Text(String(format: "현재 각도: %.0f°", orientationManager.relativeYawDegrees))
                    .font(.title3)
                    .monospacedDigit()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            
            Button(action: {
                orientationManager.calibrate()
            }) {
                Text("정면 캘리브레이션 (0° 맞추기)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Text("Tip: 정면에서는 진동이 울리지 않으며, 좌우 경계를 넘을 때 짧은 진동이, 후면을 볼 때는 강한 이중 진동이 울립니다.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 50)
        .onAppear {
            orientationManager.startUpdates()
        }
        .onDisappear {
            orientationManager.stopUpdates()
        }
    }
    
    private func colorForZone(_ zone: DirectionZone) -> Color {
        switch zone {
        case .front:
            return .green
        case .left, .right:
            return .orange
        case .back:
            return .red
        case .unknown:
            return .primary
        }
    }
}

#Preview {
    ContentView()
}

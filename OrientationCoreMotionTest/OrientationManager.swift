import Foundation
import CoreMotion
import Combine

// CoreMotion을 이용해 디바이스의 모션을 추적하고 방향을 계산하는 매니저입니다.
class OrientationManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var currentYawDegrees: Double = 0.0
    @Published var relativeYawDegrees: Double = 0.0
    @Published var currentZone: DirectionZone = .unknown
    
    private var referenceYawDegrees: Double = 0.0
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available.")
            return
        }
        
        // 업데이트 주기 설정 (초당 60회)
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        // 지자기 센서 간섭을 피하기 위해 .xArbitraryZVertical 사용
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            
            // yaw(Z축 회전) 값을 라디안에서 각도로 변환
            let yawRadians = data.attitude.yaw
            self.currentYawDegrees = yawRadians * 180 / .pi
            
            self.processOrientation()
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    // 현재 바라보는 방향을 정면(0도)으로 영점 조절
    func calibrate() {
        referenceYawDegrees = currentYawDegrees
        processOrientation()
        HapticManager.shared.playCalibrationSuccess()
    }
    
    private func processOrientation() {
        // 기준점을 뺀 상대적인 각도 계산 및 -180 ~ 180 범위로 정규화
        var relative = currentYawDegrees - referenceYawDegrees
        if relative > 180 { relative -= 360 }
        if relative < -180 { relative += 360 }
        
        self.relativeYawDegrees = relative
        
        // 현재 어느 구역에 있는지 판단
        let newZone = determineZone(for: relative)
        
        // 구역이 바뀔 때만 Haptic 피드백을 발생시킴
        if newZone != currentZone {
            triggerHaptic(for: newZone)
            self.currentZone = newZone
        }
    }
    
    private func determineZone(for yaw: Double) -> DirectionZone {
        switch yaw {
        case -45...45:
            return .front
        case 45...135:
            // 시계방향/반시계방향 회전은 실제 기기를 차는 방식에 따라 좌/우가 달라질 수 있습니다.
            return .left 
        case -135..<(-45):
            return .right
        default:
            return .back // 135~180, -180~-135
        }
    }
    
    private func triggerHaptic(for zone: DirectionZone) {
        switch zone {
        case .front, .unknown:
            // Safe Zone: 진동 없음
            break
        case .left, .right:
            // Warning Zone: 가벼운 질감의 햅틱 (Tick)
            HapticManager.shared.playLightTick()
        case .back:
            // Danger Zone: 뚜렷한 이중 진동 (Thud-Thud)
            HapticManager.shared.playHeavyThud()
        }
    }
}

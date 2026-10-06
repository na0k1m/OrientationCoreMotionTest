import Foundation
import CoreMotion
import Combine

class OrientationManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var currentYawDegrees: Double = 0.0
    @Published var relativeYawDegrees: Double = 0.0
    @Published var currentZone: DirectionZone = .unknown
    
    private var referenceYawDegrees: Double = 0.0
    
    // 노크 감지(Knock-Knock)를 위한 변수들
    private var lastKnockTime: Date?
//    private let knockThreshold: Double = 1.5 // G-Force 임계값 (필요에 따라 1.0 ~ 2.5 사이로 조절)
    private let knockThreshold: Double = 0.8
    private let doubleKnockMaxInterval: TimeInterval = 0.6 // 두 번째 노크를 기다리는 최대 시간 (초)
    private let doubleKnockMinInterval: TimeInterval = 0.1 // 두 번째 노크로 인정하는 최소 시간 (초 - 하나의 긴 충격 방지)
    private var lastCalibrationTime: Date = Date.distantPast // 쿨다운 타임 체크용
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available.")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            
            // 1. 방향(Yaw) 처리
            let yawRadians = data.attitude.yaw
            self.currentYawDegrees = yawRadians * 180 / .pi
            self.processOrientation()
            
            // 2. 노크(충격) 감지 처리
            self.detectKnock(userAcceleration: data.userAcceleration)
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func calibrate() {
        referenceYawDegrees = currentYawDegrees
        processOrientation()
        HapticManager.shared.playCalibrationSuccess()
        print("영점 조절(Calibration) 완료!")
    }
    
    private func processOrientation() {
        var relative = currentYawDegrees - referenceYawDegrees
        if relative > 180 { relative -= 360 }
        if relative < -180 { relative += 360 }
        
        self.relativeYawDegrees = relative
        
        let newZone = determineZone(for: relative)
        
        if newZone != currentZone {
            triggerHaptic(for: newZone)
            self.currentZone = newZone
        }
    }
    
    private func detectKnock(userAcceleration: CMAcceleration) {
        // 중력이 제거된 순수 가속도(충격)의 크기 계산
        let magnitude = sqrt(pow(userAcceleration.x, 2) + pow(userAcceleration.y, 2) + pow(userAcceleration.z, 2))
        
        // 설정한 임계값 이상의 충격이 발생했는지 확인
        if magnitude > knockThreshold {
            let now = Date()
            
            if let last = lastKnockTime {
                let interval = now.timeIntervalSince(last)
                
                // 첫 번째 노크 이후 적절한 시간 내에 두 번째 노크가 들어왔는지 확인
                if interval > doubleKnockMinInterval && interval < doubleKnockMaxInterval {
                    // 더블 노크 성공! (쿨다운 1초 적용 - 여러 번 연속해서 영점이 잡히는 것 방지)
                    if now.timeIntervalSince(lastCalibrationTime) > 1.0 {
                        self.calibrate() // 영점 조절 실행
                        self.lastCalibrationTime = now
                        self.lastKnockTime = nil // 상태 초기화
                    }
                } else if interval >= doubleKnockMaxInterval {
                    // 시간이 너무 오래 지났으면 새로운 첫 번째 노크로 간주
                    self.lastKnockTime = now
                }
            } else {
                // 첫 번째 노크 기록
                self.lastKnockTime = now
            }
        }
    }
    
    private func determineZone(for yaw: Double) -> DirectionZone {
        switch yaw {
        case -45...45:
            return .front
        case 45...135:
            return .left 
        case -135..<(-45):
            return .right
        default:
            return .back
        }
    }
    
    private func triggerHaptic(for zone: DirectionZone) {
        switch zone {
        case .front, .unknown:
            break
        case .left, .right:
            HapticManager.shared.playLightTick()
        case .back:
            HapticManager.shared.playHeavyThud()
        }
    }
}

import UIKit

// 햅틱(진동) 피드백을 전담하는 매니저 클래스입니다.
class HapticManager {
    static let shared = HapticManager()
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyHaptic = UINotificationFeedbackGenerator()
    
    private init() {
        // Haptic 엔진 예열 (반응 속도를 높이기 위함)
        lightHaptic.prepare()
        heavyHaptic.prepare()
    }
    
    func playLightTick() {
        lightHaptic.impactOccurred()
    }
    
    func playHeavyThud() {
        heavyHaptic.notificationOccurred(.error)
    }
    
    func playCalibrationSuccess() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

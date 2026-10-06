import Foundation

// 4개의 구역(Zone)을 정의합니다.
enum DirectionZone: String {
    case front = "정면 (Safe Zone)"
    case right = "우측 (Warning Zone)"
    case left = "좌측 (Warning Zone)"
    case back = "후면 (Danger Zone)"
    case unknown = "알 수 없음"
}

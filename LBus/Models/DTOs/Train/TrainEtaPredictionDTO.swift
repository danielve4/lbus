import Foundation

struct TrainEtaPredictionDTO: Codable, Equatable, Sendable {
    let staId: String
    let stpId: String
    let staNm: String
    let stpDe: String
    let rn: String
    let rt: String
    let destSt: String
    let destNm: String
    let trDr: String
    let prdt: String
    let arrT: String
    let isApp: String
    let isSch: String
    let isDly: String
    let isFlt: String
    let flags: String?
    let lat: String?
    let lon: String?
    let heading: String?
}

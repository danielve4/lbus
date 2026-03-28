import Foundation

struct TrainArrivalsResponse: Codable, Equatable, Sendable {
    let ctatt: Body

    struct Body: Codable, Equatable, Sendable {
        let tmst: String
        let errCd: String
        let errNm: String?
        let eta: [TrainEtaPredictionDTO]?
    }
}

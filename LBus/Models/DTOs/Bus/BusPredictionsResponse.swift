import Foundation

struct BusPredictionsResponse: Codable, Equatable, Sendable {
    let prd: [BusPredictionDTO]?
    let error: [BusAPIError]?
}

struct BusPredictionDTO: Codable, Equatable, Sendable {
    let tmstmp: String
    let typ: String
    let stpid: String
    let stpnm: String
    let vid: String
    let dstp: Int
    let rt: String
    let rtdd: String
    let rtdir: String
    let des: String
    let prdtm: String
    let dly: Bool
    let tablockid: String
    let tatripid: String
    let origtatripno: String
    let zone: String
    let prdctdn: String?
    let dyn: Int?
    let psgld: String?
    let stst: Int?
    let stsd: String?
    let flagstop: Int?
    let nbus: String?
}

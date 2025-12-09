//
//  NotificationRegisterResponse.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation

public struct NotificationRegisterResponse: Decodable {
    let hasError: Bool
    let errorCode: Int
    let errorDescription: String?
    let content: String?
    let totalCount: Int
    let referenceId: String
    let price: Double?

    enum CodingKeys: String, CodingKey {
        case hasError = "hasError"
        case errorCode = "errorCode"
        case errorDescription = "errorDescription"
        case content = "content"
        case totalCount = "totalCount"
        case referenceId = "referenceId"
        case price = "price"
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasError = try container.decode(Bool.self, forKey: .hasError)
        errorCode = try container.decode(Int.self, forKey: .errorCode)
        errorDescription = try container.decodeIfPresent(String.self, forKey: .errorDescription)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        totalCount = try container.decode(Int.self, forKey: .totalCount)
        referenceId = try container.decode(String.self, forKey: .referenceId)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
    }
}

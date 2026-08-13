//
//  DataSyncTestPayloads.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK

struct PatientPayload: JSONCodable, Equatable {
  let mrn: String?
  let fullName: String?
  let diagnosis: String?
  let dateOfBirth: String?
  let heightCm: Int?
  let weightKg: Double?
  let isSmoker: Bool?
  let dischargedAt: JSONCodableScalarType?
  let allergies: [String]?
  let emergencyContact: EmergencyContact?

  init(
    mrn: String? = nil,
    fullName: String? = nil,
    diagnosis: String? = nil,
    dateOfBirth: String? = nil,
    heightCm: Int? = nil,
    weightKg: Double? = nil,
    isSmoker: Bool? = nil,
    dischargedAt: JSONCodableScalarType? = nil,
    allergies: [String]? = nil,
    emergencyContact: EmergencyContact? = nil
  ) {
    self.mrn = mrn
    self.fullName = fullName
    self.diagnosis = diagnosis
    self.dateOfBirth = dateOfBirth
    self.heightCm = heightCm
    self.weightKg = weightKg
    self.isSmoker = isSmoker
    self.dischargedAt = dischargedAt
    self.allergies = allergies
    self.emergencyContact = emergencyContact
  }
}

struct UserPayload: JSONCodable, Equatable {
  let name: String
  let email: String?
  let type: String?
  let profileUrl: String?

  init(name: String, email: String? = nil, type: String? = nil, profileUrl: String? = nil) {
    self.name = name
    self.email = email
    self.type = type
    self.profileUrl = profileUrl
  }
}

struct ChannelPayload: JSONCodable, Equatable {
  let name: String
  let description: String
}

struct MembershipPayload: JSONCodable, Equatable {
  let role: String
  let joinedVia: String?
  let notifications: String?

  init(role: String, joinedVia: String? = nil, notifications: String? = nil) {
    self.role = role
    self.joinedVia = joinedVia
    self.notifications = notifications
  }
}

struct RelationshipPayload: JSONCodable, Equatable {
  let role: String?
  let since: String?
  let isPrimary: Bool?
  let visitsPerMonth: Int?

  init(
    role: String? = nil,
    since: String? = nil,
    isPrimary: Bool? = nil,
    visitsPerMonth: Int? = nil
  ) {
    self.role = role
    self.since = since
    self.isPrimary = isPrimary
    self.visitsPerMonth = visitsPerMonth
  }
}

struct EmergencyContact: Codable, Equatable {
  let name: String
  let phone: String
}

struct EmptyPayload: JSONCodable, Equatable {
}

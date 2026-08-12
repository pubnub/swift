//
//  DataSyncHealthcareFixtures.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

// MARK: - Classes

/// A DataSync class the healthcare integration tests expect to already be registered on the keyset.
struct HealthcareClass {
  /// The name the class is registered under
  let name: String
  /// The version of the class the test payloads conform to
  let version: Int

  /// A patient in the hospital network
  static let patient = HealthcareClass(name: "patient", version: 1)
  /// A clinician (physician, nurse, etc.)
  static let practitioner = HealthcareClass(name: "practitioner", version: 1)
  /// A hospital or clinic in the network
  static let careFacility = HealthcareClass(name: "care-facility", version: 1)
  /// The physician currently responsible for a patient's care, connecting a practitioner to a patient
  static let attendingPhysician = HealthcareClass(name: "attending-physician", version: 1)
  /// A many-to-many affiliation connecting a care facility to a practitioner
  static let facilityAffiliation = HealthcareClass(name: "facility-affiliation", version: 1)
}

// MARK: - Payloads

/// The `patient` class, plus the undeclared field the patch tests add.
struct TestPatientPayload: JSONCodable, Equatable {
  let mrn: String?
  let fullName: String?
  let dateOfBirth: String?
  let diagnosis: String?
  let preferredLanguage: String?

  init(
    mrn: String? = nil,
    fullName: String? = nil,
    dateOfBirth: String? = nil,
    diagnosis: String? = nil,
    preferredLanguage: String? = nil
  ) {
    self.mrn = mrn
    self.fullName = fullName
    self.dateOfBirth = dateOfBirth
    self.diagnosis = diagnosis
    self.preferredLanguage = preferredLanguage
  }

  /// Every declared property populated, under the caller's medical record number
  static func standard(mrn: String) -> TestPatientPayload {
    TestPatientPayload(
      mrn: mrn,
      fullName: "Swift ITest Patient",
      dateOfBirth: "1985-04-12",
      diagnosis: "Type 2 diabetes"
    )
  }
}

/// The `practitioner` class.
struct TestPractitionerPayload: JSONCodable, Equatable {
  let npi: String?
  let fullName: String?
  let specialty: String?
  let email: String?
  let phone: String?

  init(
    npi: String? = nil,
    fullName: String? = nil,
    specialty: String? = nil,
    email: String? = nil,
    phone: String? = nil
  ) {
    self.npi = npi
    self.fullName = fullName
    self.specialty = specialty
    self.email = email
    self.phone = phone
  }

  /// Every declared property populated, under the caller's national provider identifier
  static func standard(npi: String) -> TestPractitionerPayload {
    TestPractitionerPayload(
      npi: npi,
      fullName: "Swift ITest Practitioner",
      specialty: "Endocrinology",
      email: "swift.itest.practitioner@example.com",
      phone: "+1-503-555-0142"
    )
  }
}

/// The `care-facility` class.
struct TestCareFacilityPayload: JSONCodable, Equatable {
  let code: String?
  let name: String?
  let city: String?
  let postalCode: String?

  init(code: String? = nil, name: String? = nil, city: String? = nil, postalCode: String? = nil) {
    self.code = code
    self.name = name
    self.city = city
    self.postalCode = postalCode
  }
}

/// The `attending-physician` class, plus the undeclared field the patch tests add.
struct TestAttendingPhysicianPayload: JSONCodable, Equatable {
  let role: String?
  let since: String?
  let reviewCadenceDays: Int?

  init(role: String? = nil, since: String? = nil, reviewCadenceDays: Int? = nil) {
    self.role = role
    self.since = since
    self.reviewCadenceDays = reviewCadenceDays
  }
}

/// The `facility-affiliation` class.
struct TestFacilityAffiliationPayload: JSONCodable, Equatable {
  let department: String?

  init(department: String? = nil) {
    self.department = department
  }
}

// MARK: - Specs

/// An entity a test needs to exist before the behavior under test can run.
struct TestEntitySpec {
  let id: String
  let entityClass: HealthcareClass
  let status: String
  let payload: JSONCodable

  /// A patient whose medical record number is its own identifier, keeping failures traceable to one entity
  static func patient(id: String) -> TestEntitySpec {
    TestEntitySpec(
      id: id,
      entityClass: .patient,
      status: "active",
      payload: TestPatientPayload.standard(mrn: id)
    )
  }

  /// A practitioner whose national provider identifier is its own identifier
  static func practitioner(id: String) -> TestEntitySpec {
    TestEntitySpec(
      id: id,
      entityClass: .practitioner,
      status: "active",
      payload: TestPractitionerPayload.standard(npi: id)
    )
  }

  /// A care facility whose code is its own identifier
  static func careFacility(id: String) -> TestEntitySpec {
    TestEntitySpec(
      id: id,
      entityClass: .careFacility,
      status: "active",
      payload: TestCareFacilityPayload(code: id, name: "Swift ITest Facility", city: "Portland", postalCode: "97201")
    )
  }
}

/// A relationship a test needs to exist before the behavior under test can run.
struct TestRelationshipSpec {
  let id: String
  let relationshipClass: HealthcareClass
  let entityAId: String
  let entityBId: String
  let status: String
  let payload: JSONCodable

  /// Connects a practitioner on side A to the patient they attend on side B
  static func attendingPhysician(id: String, practitionerId: String, patientId: String) -> TestRelationshipSpec {
    TestRelationshipSpec(
      id: id,
      relationshipClass: .attendingPhysician,
      entityAId: practitionerId,
      entityBId: patientId,
      status: "active",
      payload: TestAttendingPhysicianPayload(role: "attending", since: "2024-01-15")
    )
  }

  /// Connects a care facility on side A to a practitioner affiliated with it on side B
  static func facilityAffiliation(id: String, careFacilityId: String, practitionerId: String) -> TestRelationshipSpec {
    TestRelationshipSpec(
      id: id,
      relationshipClass: .facilityAffiliation,
      entityAId: careFacilityId,
      entityBId: practitionerId,
      status: "active",
      payload: TestFacilityAffiliationPayload(department: "Endocrinology")
    )
  }
}

// MARK: - Configuration

func dataSyncHealthcareConfiguration(bundle: Bundle) -> PubNubConfiguration {
  PubNubConfiguration(
    publishKey: PubNubConfiguration(bundle: bundle).publishKey,
    subscribeKey: PubNubConfiguration(bundle: bundle).subscribeKey,
    userId: randomString(),
    authToken: dataSyncHealthcareAdminAuthToken
  )
}

// MARK: - Setup and teardown

extension XCTestCase {
  func createEntities(client: PubNub, _ specs: [TestEntitySpec]) {
    let setupExpect = expectation(description: "Create Test Entities Expectation")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true

    func createNext(_ remaining: [TestEntitySpec]) {
      guard let spec = remaining.first else {
        setupExpect.fulfill(); return
      }

      client.dataSync.createEntity(
        entityClass: spec.entityClass.name,
        entityClassVersion: spec.entityClass.version,
        id: spec.id,
        status: spec.status,
        payload: spec.payload
      ) { result in
        switch result {
        case .success:
          createNext(Array(remaining.dropFirst()))
        case let .failure(error):
          XCTFail("Failed to setup test entity \(spec.id): \(error)")
          setupExpect.fulfill()
        }
      }
    }

    createNext(specs)

    wait(for: [setupExpect], timeout: 20.0)
  }

  func createRelationships(client: PubNub, _ specs: [TestRelationshipSpec]) {
    let setupExpect = expectation(description: "Create Test Relationships Expectation")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true

    func createNext(_ remaining: [TestRelationshipSpec]) {
      guard let spec = remaining.first else {
        setupExpect.fulfill(); return
      }

      client.dataSync.createRelationship(
        relationshipClass: spec.relationshipClass.name,
        entityAId: spec.entityAId,
        entityBId: spec.entityBId,
        relationshipClassVersion: spec.relationshipClass.version,
        id: spec.id,
        status: spec.status,
        payload: spec.payload
      ) { result in
        switch result {
        case .success:
          createNext(Array(remaining.dropFirst()))
        case let .failure(error):
          XCTFail("Failed to setup test relationship \(spec.id): \(error)")
          setupExpect.fulfill()
        }
      }
    }

    createNext(specs)

    wait(for: [setupExpect], timeout: 20.0)
  }

  func removeEntities(client: PubNub, ids: [String]) {
    for id in ids {
      let removeExpect = expectation(description: "Remove Test Entity \(id) Expectation")
      client.dataSync.removeEntity(id) { _ in removeExpect.fulfill() }
      wait(for: [removeExpect], timeout: 10.0)
    }
  }

  func removeRelationships(client: PubNub, ids: [String]) {
    for id in ids {
      let removeExpect = expectation(description: "Remove Test Relationship \(id) Expectation")
      client.dataSync.removeRelationship(id) { _ in removeExpect.fulfill() }
      wait(for: [removeExpect], timeout: 10.0)
    }
  }
}

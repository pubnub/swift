//
//  PubNubEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Possible events within the PubNub module
public enum PubNubEvent {
  /// A message has been received
  case messageReceived(PubNubMessage)
  /// A signal has been received
  case signalReceived(PubNubMessage)
  /// A presence change has been received
  case presenceChanged(PubNubPresenceChange)
  /// A MessageAction was added/removed to a published message
  case messageActionChanged(PubNubMessageActionEvent)
  /// A File was uploaded to storage
  case fileChanged(PubNubFileChangeEvent)
  /// A Membership object has been added/removed/updated
  case appContextChanged(PubNubAppContextEvent)
}

/// Possible subevents for Message Actions
public enum PubNubMessageActionEvent {
  /// The Message Action was added to a message
  case added(PubNubMessageAction)
  /// The Message Action was removed from a message
  case removed(PubNubMessageAction)
}

/// Possible subevents for AppContext
public enum PubNubAppContextEvent {
  /// The `PubNubUUIDMetadataChangeset` of the set Membership
  case userMetadataSet(PubNubUUIDMetadataChangeset)
  /// The unique identifer of the UUID that was removed
  case userMetadataRemoved(metadataId: String)
  /// The changeset for the Channel object that changed
  case channelMetadataSet(PubNubChannelMetadataChangeset)
  /// The unique identifer of the Channel that was removed
  case channelMetadataRemoved(metadataId: String)
  /// The `PubNubMembershipMetadata` of the set Membership
  case membershipMetadataSet(PubNubMembershipMetadata)
  /// The `PubNubMembershipMetadata` of the removed Membership
  case membershipMetadataRemoved(PubNubMembershipMetadata)
}

/// Possible subevents for File
public enum PubNubFileChangeEvent {
  case uploaded(PubNubFileEvent)
}

//
//  PubNubContractCucumberTest.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PubNubContractTests-Swift.h"
#import <Cucumberish/Cucumberish.h>


__attribute__((constructor))
void CucumberishInit(void) {
  [Cucumberish instance].prettyFeatureNamesAllowed = NO;
  [Cucumberish instance].fixMissingLastScenario = NO;
  [Cucumberish instance].prettyNamesAllowed = YES;
  [Cucumberish instance].featureNamesPrefix = @"";
  [[PubNubContractTestCase new] setup];
    
  NSMutableArray *excludeTags = [@[
    @"contract=authSuccess",
    @"contract=authFailureExpired",
    @"contract=authFailurePermissions",
    @"contract=authFailureRevoked",
    @"contract=grantAllPermissions",
    @"contract=grantWithoutAuthorizedUUID",
    @"contract=grantWithAuthorizedUUID",
    @"contract=grantWithoutAnyPermissionsError",
    @"contract=grantWithRegExpSyntaxError",
    @"contract=grantWithRegExpNonCapturingError",
    @"missingOpenApi",
    @"na=swift",
    @"beta",
    @"skip"
  ] mutableCopy];
  
  NSString *xcTestBundlePath = NSProcessInfo.processInfo.environment[@"XCTestBundlePath"];
  NSBundle *contractTestsBundle = [NSBundle bundleForClass:[PubNubContractTestCase class]];
  Cucumberish.instance.resultsDirectory = contractTestsBundle.infoDictionary[@"CUCUMBER_REPORTS_PATH"];
    
  if ([xcTestBundlePath rangeOfString:@"PubNubContractTestsBeta"].location != NSNotFound) {
    [excludeTags removeObject:@"beta"];
  }
  // TODO: REMOVE AFTER ALL TESTS FOR OBJECTS WILL BE MERGED.
  excludeTags = nil;
  
  // TODO: REMOVE AFTER ALL TESTS FOR OBJECTS WILL BE MERGED.
  NSArray *includedTags = @[
    @"contract=getChannelMetadataOfChat",
    @"contract=getChannelMetadataOfDMWithCustom",
    @"contract=setChannelMetadataForChat",
    @"contract=removeChannelMetadataOfChat",
    @"contract=getAllChannelMetadata",
    @"contract=getAllChannelMetadataWithCustom",

    @"contract=getUUIDMetadataOfAlice",
    @"contract=getUUIDMetadataOfBobWithCustom",
    @"contract=setUUIDMetadataForAlice",
    @"contract=removeUUIDMetadataOfAlice",
    @"contract=getAllUUIDMetadata",
    @"contract=getAllUUIDMetadataWithCustom",
    
    @"contract=getMembersOfChatChannel",
    @"contract=getMembersOfVipChatChannelWithCustomAndUuidWithCustom",
    @"contract=setMembersForChatChannel",
    @"contract=setMembersForChatChannelWithCustomAndUuidWithCustom",
    @"contract=removeMembersForChatChannel",
    @"contract=manageMembersForChatChannel",

    @"contract=getAliceMemberships",
    @"contract=getAliceMemberships",
    @"contract=getBobMembershipWithCustomAndChannelCustom",
    @"contract=setAliceMembership",
    @"contract=removeAliceMembership",
    @"contract=manageAliceMemberships"
  ];
  
  NSBundle * bundle = [NSBundle bundleForClass:[PubNubContractTestCase class]];
  [Cucumberish executeFeaturesInDirectory:@"Features"
                               fromBundle:bundle
                              includeTags:includedTags
                              excludeTags:excludeTags];
}

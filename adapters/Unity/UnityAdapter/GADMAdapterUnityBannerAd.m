// Copyright 2020 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterUnityBannerAd.h"
#import "GADMAdapterUnity.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"
#import "GADMediationAdapterUnity.h"
#import "GADUnityError.h"
#import "ASAdTracker.h"

@interface GADMAdapterUnityBannerAd () <UADSBannerViewDelegate>
@end

@implementation GADMAdapterUnityBannerAd {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Unity Ads banner ad object.
  UADSBannerView *_bannerAd;

  /// Unity ads game ID.
  NSString *_gameID;

  /// Unity ads placement ID.
  NSString *_placementID;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (void)loadBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector) {
    NSLog(@"Unity Ads Adapter Error: No GADMAdNetworkConnector found.");
    return;
  }

  if (!strongAdapter) {
    NSLog(@"Unity Ads Adapter Error: No GADMAdNetworkAdapter found.");
    return;
  }

  _gameID = [[[strongConnector credentials] objectForKey:kGADMAdapterUnityGameID] copy];
  _placementID = [strongConnector.credentials[kGADMAdapterUnityPlacementID] copy];
  if (!_gameID || !_placementID) {
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
        GADMAdapterUnityErrorInvalidServerParameters, @"Game ID and Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  if (![UnityAds isInitialized]) {
    [[GADMAdapterUnity alloc] initializeWithGameID:_gameID withCompletionHandler:nil];
  }

  _bannerAd = [[UADSBannerView alloc] initWithPlacementId:_placementID size:adSize.size];
  if (!_bannerAd) {
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
        GADMAdapterUnityErrorAdObjectNil, @"Unity banner failed to initialize.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }
  _bannerAd.delegate = self;
  [_bannerAd load];
}

- (void)stopBeingDelegate {
  _bannerAd = nil;
  _bannerAd.delegate = nil;
}

#pragma mark UADSBannerView Delegate methods

- (void)bannerViewDidLoad:(UADSBannerView *)bannerView {
  NSLog(@"Unity Ads finished loading banner for placement ID '%@'.", _placementID);
	
	
	// astar
	NSMutableDictionary *networkInfo = [NSMutableDictionary dictionary];
	if (bannerView.placementId != nil) {
		networkInfo[@"placementId"] = bannerView.placementId;
	}
	
	ASAdTracker *adTracker = [ASAdTracker sharedInstance];
	[adTracker adDidLoadForMediator:@"admob" fromNetwork:@"unity" ofType:@"banner" data:networkInfo];
	
	
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    [strongConnector adapter:strongAdapter didReceiveAdView:bannerView];
  }
}

- (void)bannerViewDidClick:(UADSBannerView *)bannerView {
  NSLog(@"Unity Ads banner for placement ID '%@' was clicked.", _placementID);
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongAdapter && strongConnector) {
    [strongConnector adapterDidGetAdClick:strongAdapter];
  }
}

- (void)bannerViewDidLeaveApplication:(UADSBannerView *)bannerView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongAdapter && strongConnector) {
    [strongConnector adapterWillLeaveApplication:strongAdapter];
  }
}

- (void)bannerViewDidError:(UADSBannerView *)bannerView error:(UADSBannerError *)error {
  NSLog(@"An error occurred for Unity Ads banner with placement ID '%@'.", _placementID);
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    [strongConnector adapter:strongAdapter didFailAd:error];
  }
}

@end

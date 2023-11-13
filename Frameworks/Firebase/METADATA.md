## Dependency Graph

"(~> X)" below means that the SDK requires all of the xcframeworks from X. You
should make sure to include all of the xcframeworks from X when including the
SDK.

## FirebaseAnalyticsSwift (~> FirebaseAnalytics)
- FBLPromises.xcframework
- FirebaseAnalytics.xcframework
- FirebaseAnalyticsSwift.xcframework
- FirebaseCore.xcframework
- FirebaseCoreInternal.xcframework
- FirebaseInstallations.xcframework
- GoogleAppMeasurement.xcframework
- GoogleAppMeasurementIdentitySupport.xcframework
- GoogleUtilities.xcframework
- nanopb.xcframework

## FirebaseABTesting (~> FirebaseAnalytics)
- FirebaseABTesting.xcframework

## FirebaseAnalyticsOnDeviceConversion (~> FirebaseAnalytics)
- FirebaseAnalyticsOnDeviceConversion.xcframework
- GoogleAppMeasurementOnDeviceConversion.xcframework

## FirebaseAppCheck (~> FirebaseAnalytics)
- FirebaseAppCheck.xcframework
- FirebaseAppCheckInterop.xcframework

## FirebaseAppDistribution (~> FirebaseAnalytics)
- FirebaseAppDistribution.xcframework

## FirebaseAuth (~> FirebaseAnalytics)
- FirebaseAppCheckInterop.xcframework
- FirebaseAuth.xcframework
- GTMSessionFetcher.xcframework
- RecaptchaInterop.xcframework

## FirebaseCrashlytics (~> FirebaseAnalytics)
- FirebaseCoreExtension.xcframework
- FirebaseCrashlytics.xcframework
- FirebaseSessions.xcframework
- GoogleDataTransport.xcframework
- PromisesSwift.xcframework

## FirebaseDatabase (~> FirebaseAnalytics)
- FirebaseAppCheckInterop.xcframework
- FirebaseDatabase.xcframework
- FirebaseDatabaseSwift.xcframework
- FirebaseSharedSwift.xcframework
- leveldb-library.xcframework

## FirebaseDynamicLinks (~> FirebaseAnalytics)
- FirebaseDynamicLinks.xcframework

## FirebaseFirestore (~> FirebaseAnalytics)
- BoringSSL-GRPC.xcframework
- FirebaseAppCheckInterop.xcframework
- FirebaseCoreExtension.xcframework
- FirebaseFirestore.xcframework
- FirebaseFirestoreInternal.xcframework
- FirebaseFirestoreSwift.xcframework
- FirebaseSharedSwift.xcframework
- abseil.xcframework
- gRPC-C++.xcframework
- gRPC-Core.xcframework
- leveldb-library.xcframework

You'll also need to add the resources in the Resources
directory into your target's main bundle.

## FirebaseFunctions (~> FirebaseAnalytics)
- FirebaseAppCheckInterop.xcframework
- FirebaseAuthInterop.xcframework
- FirebaseCoreExtension.xcframework
- FirebaseFunctions.xcframework
- FirebaseMessagingInterop.xcframework
- FirebaseSharedSwift.xcframework
- GTMSessionFetcher.xcframework

## FirebaseInAppMessaging (~> FirebaseAnalytics)
- FirebaseABTesting.xcframework
- FirebaseInAppMessaging.xcframework
- FirebaseInAppMessagingSwift.xcframework

You'll also need to add the resources in the Resources
directory into your target's main bundle.

## FirebaseMLModelDownloader (~> FirebaseAnalytics)
- FirebaseMLModelDownloader.xcframework
- GoogleDataTransport.xcframework
- SwiftProtobuf.xcframework

## FirebaseMessaging (~> FirebaseAnalytics)
- FirebaseMessaging.xcframework
- GoogleDataTransport.xcframework

## FirebasePerformance (~> FirebaseAnalytics)
- FirebaseABTesting.xcframework
- FirebaseCoreExtension.xcframework
- FirebasePerformance.xcframework
- FirebaseRemoteConfig.xcframework
- FirebaseSessions.xcframework
- FirebaseSharedSwift.xcframework
- GoogleDataTransport.xcframework
- PromisesSwift.xcframework

## FirebaseRemoteConfig (~> FirebaseAnalytics)
- FirebaseABTesting.xcframework
- FirebaseRemoteConfig.xcframework
- FirebaseRemoteConfigSwift.xcframework
- FirebaseSharedSwift.xcframework

## FirebaseStorage (~> FirebaseAnalytics)
- FirebaseAppCheckInterop.xcframework
- FirebaseAuthInterop.xcframework
- FirebaseCoreExtension.xcframework
- FirebaseStorage.xcframework
- GTMSessionFetcher.xcframework

## Google-Mobile-Ads-SDK (~> FirebaseAnalytics)
- GoogleMobileAds.xcframework
- UserMessagingPlatform.xcframework

## GoogleSignIn
- AppAuth.xcframework
- GTMAppAuth.xcframework
- GTMSessionFetcher.xcframework
- GoogleSignIn.xcframework

You'll also need to add the resources in the Resources
directory into your target's main bundle.



## Versions

The xcframeworks in this directory map to these versions of the Firebase SDKs in
CocoaPods.

               CocoaPod                | Version
---------------------------------------|---------
AppAuth                                | 1.6.2
BoringSSL-GRPC                         | 0.0.24
Firebase                               | 10.17.0
FirebaseABTesting                      | 10.17.0
FirebaseAnalytics                      | 10.17.0
FirebaseAnalyticsOnDeviceConversion    | 10.17.0
FirebaseAnalyticsSwift                 | 10.17.0
FirebaseAppCheck                       | 10.17.0
FirebaseAppCheckInterop                | 10.17.0
FirebaseAppDistribution                | 10.17.0-beta
FirebaseAuth                           | 10.17.0
FirebaseAuthInterop                    | 10.17.0
FirebaseCore                           | 10.17.0
FirebaseCoreExtension                  | 10.17.0
FirebaseCoreInternal                   | 10.17.0
FirebaseCrashlytics                    | 10.17.0
FirebaseDatabase                       | 10.17.0
FirebaseDatabaseSwift                  | 10.17.0
FirebaseDynamicLinks                   | 10.17.0
FirebaseFirestore                      | 10.17.0
FirebaseFirestoreInternal              | 10.17.0
FirebaseFirestoreSwift                 | 10.17.0
FirebaseFunctions                      | 10.17.0
FirebaseInAppMessaging                 | 10.17.0-beta
FirebaseInAppMessagingSwift            | 10.17.0-beta
FirebaseInstallations                  | 10.17.0
FirebaseMLModelDownloader              | 10.17.0-beta
FirebaseMessaging                      | 10.17.0
FirebaseMessagingInterop               | 10.17.0
FirebasePerformance                    | 10.17.0
FirebaseRemoteConfig                   | 10.17.0
FirebaseRemoteConfigSwift              | 10.17.0
FirebaseSessions                       | 10.17.0
FirebaseSharedSwift                    | 10.17.0
FirebaseStorage                        | 10.17.0
GTMAppAuth                             | 2.0.0
GTMSessionFetcher                      | 3.1.1
Google-Mobile-Ads-SDK                  | 10.12.0
GoogleAppMeasurement                   | 10.17.0
GoogleAppMeasurementOnDeviceConversion | 10.17.0
GoogleDataTransport                    | 9.2.5
GoogleSignIn                           | 7.0.0
GoogleUserMessagingPlatform            | 2.1.0
GoogleUtilities                        | 7.11.6
PromisesObjC                           | 2.3.1
PromisesSwift                          | 2.3.1
RecaptchaInterop                       | 100.0.0
SwiftProtobuf                          | 1.24.0
abseil                                 | 1.20220623.0
gRPC-C++                               | 1.49.1
gRPC-Core                              | 1.49.1
leveldb-library                        | 1.22.2
nanopb                                 | 2.30909.0


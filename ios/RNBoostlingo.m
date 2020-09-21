#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <Foundation/Foundation.h>

@interface RCT_EXTERN_MODULE(RNBoostlingo, RCTEventEmitter)

    RCT_EXTERN_METHOD(supportedEvents)

    RCT_EXTERN_METHOD(initialize:(NSDictionary *)config resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

    RCT_EXTERN_METHOD(getCurrentCall: resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

    RCT_EXTERN_METHOD(getRegions: resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

    RCT_EXTERN_METHOD(getVersion: resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

    RCT_EXTERN_METHOD(getCallDictionaries: resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

    RCT_EXTERN_METHOD(getProfile: resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

    RCT_EXTERN_METHOD(getVoiceLanguages: resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

    RCT_EXTERN_METHOD(makeVoiceCall:(NSDictionary *)request resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

    RCT_EXTERN_METHOD(hangUp: resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

    RCT_EXTERN_METHOD(dispose)

@end

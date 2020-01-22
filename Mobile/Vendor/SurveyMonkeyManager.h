//
//  SurveyMonkeyManager.h
//  Mobile
//
//  Created by Marc Shilling on 12/30/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SurveyMonkeyiOSSDK/SurveyMonkeyiOSSDK.h>

@interface SurveyMonkeyManager : NSObject

- (void)presentSurveyWithHash:(nonnull NSString *)surveyHash fromViewController:(nonnull UIViewController *)viewController onCompletion: (nullable void (^)(void))callback;

@end

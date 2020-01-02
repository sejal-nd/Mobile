//
//  SurveyMonkeyManager.m
//  Mobile
//
//  Created by Marc Shilling on 12/30/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

#import "SurveyMonkeyManager.h"

@interface SurveyMonkeyManager() <SMFeedbackDelegate>

@property (nonatomic, strong) SMFeedbackViewController * feedbackController;
@property (nonatomic, copy) void (^surveyEndCallback)(void);

@end

@implementation SurveyMonkeyManager

- (void)presentSurveyWithHash:(nonnull NSString *)surveyHash fromViewController:(nonnull UIViewController *)viewController onCompletion: (nullable void (^)(void))callback {
    _surveyEndCallback = callback;
    
    _feedbackController = [[SMFeedbackViewController alloc] initWithSurvey:surveyHash];
    _feedbackController.delegate = self;
    [_feedbackController presentFromViewController:viewController animated:YES completion:nil];
}

- (void)respondentDidEndSurvey:(SMRespondent *)respondent error:(NSError *) error {
    if (error.code == 1) { // The user canceled out of the survey
        return;
    }
    
    if (_surveyEndCallback) {
        _surveyEndCallback();
    }
}

@end

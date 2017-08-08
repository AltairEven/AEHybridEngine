//
//  CPDViewController.h
//  PROJECT
//
//  Created by PROJECT_OWNER on TODAYS_DATE.
//  Copyright (c) TODAYS_YEAR PROJECT_OWNER. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AEHybridEngine/AEHybridEngine.h>

@interface CPDViewController : UIViewController


+ (void)testClassFunctionName:(NSString *)name
                             var:(NSString *)var  AE_JSHANDLED_SELECTOR(testClassFunction);

- (void)testInstanceFunctionName:(NSString *)name
                             var:(NSString *)var  AE_JSHANDLED_SELECTOR(testInstanceFunction);

@end

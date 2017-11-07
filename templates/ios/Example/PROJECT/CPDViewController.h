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

- (void)aesSetTitle:(id)body AE_JSHANDLED_SELECTOR(aesSetTitle);

@end



@interface AESJSCallBack : NSObject

@property (nonatomic, copy) NSString *succeedCallBack;

@property (nonatomic, copy) NSString *failureCallBack;

+ (instancetype)callBackWithRawData:(NSDictionary *)data;

@end

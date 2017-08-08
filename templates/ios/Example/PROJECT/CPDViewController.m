//
//  CPDViewController.m
//  PROJECT
//
//  Created by PROJECT_OWNER on TODAYS_DATE.
//  Copyright (c) TODAYS_YEAR PROJECT_OWNER. All rights reserved.
//

#import "CPDViewController.h"
#import <objc/runtime.h>


@interface CPDViewController ()

@property (weak, nonatomic) IBOutlet AEWebViewContainer *webView;

@property (nonatomic, strong) AEJavaScriptHandler *jsHandler;

@end

@implementation CPDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.jsHandler = [[AEJavaScriptHandler alloc] init];
    [self.webView setJavaScriptHandler:self.jsHandler];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com"]]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)dealloc {
}

- (void)testInstanceFunctionName:(NSString *)name var:(NSString *)var {
    NSString *functionName = [NSString stringWithUTF8String:__FUNCTION__];
    functionName = [[functionName componentsSeparatedByString:@" "] lastObject];
    functionName = [functionName substringToIndex:[functionName length] - 1];
    NSLog(@"%@", functionName);
    NSLog(@"%@", self);
}

+ (void)testClassFunctionName:(NSString *)name var:(NSString *)va {
    NSString *functionName = [NSString stringWithUTF8String:__FUNCTION__];
    functionName = [[functionName componentsSeparatedByString:@" "] lastObject];
    functionName = [functionName substringToIndex:[functionName length] - 1];
    NSLog(@"%@", functionName);
    NSLog(@"%@", self);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

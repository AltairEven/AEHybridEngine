//
//  AEJavaScriptHandler.m
//  TestWebViewContainer
//
//  Created by Altair on 12/06/2017.
//  Copyright © 2017 Alisports. All rights reserved.
//

#import "AEJavaScriptHandler.h"
#import "AEHybridEngine.h"

@interface AEJavaScriptHandler ()

- (void)automaticallySetJSContexts;

@end

@implementation AEJavaScriptHandler

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        [self automaticallySetJSContexts];
    }
    return self;
}

#pragma mark WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self responseToJSCallWithScriptMessage:message];
}

#pragma mark Private methods

- (void)automaticallySetJSContexts {
    NSSet<AEJSHandlerContext *> *contexts = [AEHybridLauncher jsContextsOfType:AEMethodTypeClass forPerformer:nil];
    _jsContexts = [contexts copy];
}

#pragma mark Public methods

- (BOOL)responseToCallWithJSContext:(AEJSHandlerContext *)context {
    if (!context.performer || !context.selector) {
        return NO;
    }
    if ([context.performer respondsToSelector:context.selector]) {
        [context.performer performSelector:context.selector withObject:context.args afterDelay:0];
        return YES;
    }
    return NO;
}

- (BOOL)responseToJSCallWithScriptMessage:(WKScriptMessage *)message {
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"JS 调用了 %@ 方法，传回参数 %@", message.name, message.body);
    AEJSHandlerContext *fullFillContext = nil;
    for (AEJSHandlerContext *context in self.jsContexts) {
        if ([context.aliasName isEqualToString:message.name] || [message.name isEqualToString:NSStringFromSelector(context.selector)]) {
            fullFillContext = [context copy];
            fullFillContext.args = message.body;
            break;
        }
    }
    return [self responseToCallWithJSContext:fullFillContext];
}

@end




@implementation AEJSHandlerContext

- (void)setAliasName:(NSString *)aliasName {
    if ([aliasName isKindOfClass:[NSString class]]) {
        _aliasName = aliasName;
    }
}

+ (instancetype)contextWithPerformer:(id)performer selector:(SEL)selector aliasName:(NSString *)aliasName {
    if (!performer || !selector) {
        return nil;
    }
    AEJSHandlerContext *context = [[AEJSHandlerContext alloc] init];
    context.performer = performer;
    context.selector = selector;
    context.aliasName = aliasName;
    return context;
}

#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    AEJSHandlerContext *context = [[AEJSHandlerContext allocWithZone:zone] init];
    context.performer = self.performer;
    context.selector = self.selector;
    context.args = self.args;
    context.aliasName = self.aliasName;
    return context;
}

@end



@implementation WeakScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate {
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end

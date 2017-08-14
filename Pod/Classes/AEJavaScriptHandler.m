//
//  AEJavaScriptHandler.m
//  TestWebViewContainer
//
//  Created by Altair on 12/06/2017.
//  Copyright © 2017 Alisports. All rights reserved.
//

#import "AEJavaScriptHandler.h"
#import "AEHybridEngine.h"

static NSHashTable *AEJavaScriptHandler_JSHandlerContainer = nil;

@interface AEJavaScriptHandler ()

- (void)autoFullfill;

@end

@implementation AEJavaScriptHandler

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        [self autoFullfill];
        //将自己添加到弱引用的HashTable
        if (!AEJavaScriptHandler_JSHandlerContainer) {
            AEJavaScriptHandler_JSHandlerContainer = [NSHashTable weakObjectsHashTable];
        }
        [AEJavaScriptHandler_JSHandlerContainer addObject:self];
    }
    return self;
}

#pragma mark Setter & Getter

- (void)setJsContexts:(NSSet<AEJSHandlerContext *> *)jsContexts {
    @synchronized (self) {
        _jsContexts = [jsContexts copy];
        if (self.HandledContextsChanged) {
            __weak typeof(self) weakSelf = self;
            self.HandledContextsChanged(weakSelf);
        }
    }
}

#pragma mark WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self responseToJSCallWithScriptMessage:message];
}

#pragma mark Private methods

- (void)autoFullfill {
    //查看是否有活动的JSHandler，如果有的话，则copy一份JSContexts
    NSArray *activeHandlers = [AEJavaScriptHandler activeHandlers];
    AEJavaScriptHandler *rootHandler = [activeHandlers firstObject];
    if ([rootHandler.jsContexts count] > 0) {
        self.jsContexts = rootHandler.jsContexts;
    } else {
        //没有合适的活动中JSHandler，则主动将类方法注册给自己
        [AEHybridLauncher registerNativeMethodsOfType:AEMethodTypeClass forPerformer:nil toJavaScriptHandler:self];
    }
}

#pragma mark Public methods

- (BOOL)addJSContexts:(NSSet<AEJSHandlerContext *> *)contexts {
    if (![contexts isKindOfClass:[NSSet class]] || [contexts count] == 0) {
        return NO;
    }
    @synchronized (self) {
        NSUInteger addCount = 0;
        NSMutableSet *tempSet = [self.jsContexts mutableCopy];
        if (!tempSet) {
            tempSet = [[NSMutableSet alloc] init];
        }
        for (AEJSHandlerContext *cont in contexts) {
            if ([cont isValidate]) {
                BOOL existing = NO;
                for (AEJSHandlerContext *selfContext in self.jsContexts) {
                    if ([cont isEqualTo:selfContext]) {
                        existing = YES;
                    }
                }
                if (!existing) {
                    //未找到相同的，则添加
                    [tempSet addObject:cont];
                    addCount ++;
                }
            }
        }
        
        if (addCount > 0) {
            self.jsContexts = tempSet;
            return YES;
        }
    }
    
    return NO;
}

- (void)removeJSContextsForPerformer:(id)performer {
    @synchronized (self) {
        NSMutableSet *tempSet = [self.jsContexts mutableCopy];
        for (AEJSHandlerContext *cont in self.jsContexts) {
            if (cont.performer == performer) {
                [tempSet removeObject:cont];
            }
        }
        self.jsContexts = tempSet;
    }
}

- (void)removeJSContextsWithSEL:(SEL)selector {
    if (!selector) {
        return;
    }
    @synchronized (self) {
        NSMutableSet *tempSet = [self.jsContexts mutableCopy];
        for (AEJSHandlerContext *cont in self.jsContexts) {
            if ([NSStringFromSelector(cont.selector) isEqualToString:NSStringFromSelector(selector)]) {
                [tempSet removeObject:cont];
            }
        }
        self.jsContexts = tempSet;
    }
}

- (void)removeJSContextsWithAliasName:(NSString *)name {
    if (!name || ![name isKindOfClass:[NSString class]]) {
        return;
    }
    @synchronized (self) {
        NSMutableSet *tempSet = [self.jsContexts mutableCopy];
        for (AEJSHandlerContext *cont in self.jsContexts) {
            if ([cont.aliasName isEqualToString:name]) {
                [tempSet removeObject:cont];
            }
        }
        self.jsContexts = tempSet;
    }
}

- (BOOL)responseToCallWithJSContext:(AEJSHandlerContext *)context {
    if (!context.performer || !context.selector) {
        return NO;
    }
    NSString *selectorString = NSStringFromSelector(context.selector);
    if ([selectorString length] > 1) {
        //针对"+"和"-"方法，做一下容错处理，方式方法名中带有类型符号
        NSString *methodTypeString = [selectorString substringToIndex:1];
        if ([methodTypeString isEqualToString:@"+"] || [methodTypeString isEqualToString:@"-"]) {
            selectorString = [selectorString substringFromIndex:1];
        }
    }
    SEL performSelector = NSSelectorFromString(selectorString);
    if ([context.performer respondsToSelector:performSelector]) {
        [context.performer performSelector:performSelector withObject:context.args afterDelay:0];
        return YES;
    }
    return NO;
}

- (BOOL)responseToJSCallWithScriptMessage:(WKScriptMessage *)message {
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"JS 调用了 %@ 方法，传回参数 %@", message.name, message.body);
    AEJSHandlerContext *fullFillContext = nil;
    @synchronized (self) {
        NSMutableSet *tempSet = [self.jsContexts mutableCopy];
        for (AEJSHandlerContext *context in self.jsContexts) {
            if ([context.aliasName isEqualToString:message.name] || [message.name isEqualToString:NSStringFromSelector(context.selector)]) {
                fullFillContext = [context copy];
                fullFillContext.args = message.body;
                if (context.performer) {
                    //如果执行者未释放，则选定
                    break;
                } else {
                    //如果执行者已释放，则删除该context，并继续遍历
                    [tempSet removeObject:context];
                    continue;
                }
            }
        }
        if ([tempSet count] != [self.jsContexts count]) {
            //数量不同，说明变动过了，则重新赋值
            self.jsContexts = tempSet;
        }
    }
    return [self responseToCallWithJSContext:fullFillContext];
}

+ (NSArray<AEJavaScriptHandler *> * _Nullable __autoreleasing)activeHandlers {
    if (!AEJavaScriptHandler_JSHandlerContainer) {
        return nil;
    }
    return [AEJavaScriptHandler_JSHandlerContainer allObjects];
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

- (BOOL)isEqualTo:(AEJSHandlerContext *)context {
    BOOL isEq = NO;
    if (self.performer == context.performer &&
        [NSStringFromSelector(self.selector) isEqualToString:NSStringFromSelector(context.selector)] &&
         [self.aliasName isEqualToString:context.aliasName]) {
        isEq = YES;
    }
    return isEq;
}

- (BOOL)isValidate {
    if (self.performer && ([self.aliasName length] > 0 || [NSStringFromSelector(self.selector) length] > 0)) {
        return YES;
    }
    return NO;
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

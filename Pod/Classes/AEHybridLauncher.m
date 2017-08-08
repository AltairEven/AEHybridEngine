//
//  AEHybridLauncher.m
//  Pods
//
//  Created by Altair on 02/08/2017.
//
//

#import "AEHybridLauncher.h"

#define AE_JSMETHOD_INFOKEY    (@"AEJavaScriptHandledMethods")
#define AE_JSMETHOD_SEPARATOR (@"|")

@interface AEHybridLauncher ()

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfClassMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *, NSArray<NSString *> *> *)info;

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfInstanceMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *, NSArray<NSString *> *> *)info;

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfAllKindsOfMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *, NSArray<NSString *> *> *)info;

@end

@implementation AEHybridLauncher

#pragma mark Private methods

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfClassMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *,NSArray<NSString *> *> *)info {
    if (!info || ![info isKindOfClass:[NSDictionary class]] || [info count] == 0) {
        return nil;
    }
    NSMutableSet *set = [[NSMutableSet alloc] init];
    NSString *performerClassName = performer ? NSStringFromClass([performer class]) : nil;
    if (performerClassName) {
        //指定了方法执行者，则只遍历方法执行者类
        NSArray<NSString *> *methods = [info objectForKey:performerClassName];
        for (NSString *methodName in methods) {
            if ([methodName hasPrefix:@"+"]) {
                //类方法（静态）
                NSArray *names = [methodName componentsSeparatedByString:AE_JSMETHOD_SEPARATOR];
                //注册时都会以别名注册，所以如果有别名，则使用别名，否则使用方法名
                AEJSHandlerContext *context = [AEJSHandlerContext contextWithPerformer:[performer class] selector:NSSelectorFromString([names firstObject]) aliasName:[names lastObject]];
                if (context) {
                    [set addObject:context];
                }
            }
        }
    } else {
        //未指定方法执行者，则遍历所有的Native类
        [info enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
            //没有指定的执行者，则将所有的类方法找出
            //类
            Class handledClass = NSClassFromString(key);
            //方法列表
            for (NSString *methodName in obj) {
                if ([methodName hasPrefix:@"+"]) {
                    //类方法（静态）
                    NSArray *names = [methodName componentsSeparatedByString:AE_JSMETHOD_SEPARATOR];
                    //注册时都会以别名注册，所以如果有别名，则使用别名，否则使用方法名
                    AEJSHandlerContext *context = [AEJSHandlerContext contextWithPerformer:handledClass selector:NSSelectorFromString([names firstObject]) aliasName:[names lastObject]];
                    if (context) {
                        [set addObject:context];
                    }
                }
            }
        }];
    }
    return set;
}

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfInstanceMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *, NSArray<NSString *> *> *)info {
    if (!info || ![info isKindOfClass:[NSDictionary class]] || [info count] == 0 || performer) {
        return nil;
    }
    //执行者的类名
    NSString *performerClassName = NSStringFromClass([performer class]);
    NSMutableSet *set = [[NSMutableSet alloc] init];
    //遍历所有的Native类
    [info enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
        //类名
        if ([performerClassName isEqualToString:key]) {
            //方法列表
            for (NSString *methodName in obj) {
                if ([methodName hasPrefix:@"-"]) {
                    //实例方法
                    NSArray *names = [methodName componentsSeparatedByString:AE_JSMETHOD_SEPARATOR];
                    //注册时都会以别名注册，所以如果有别名，则使用别名，否则使用方法名
                    AEJSHandlerContext *context = [AEJSHandlerContext contextWithPerformer:performer selector:NSSelectorFromString([names firstObject]) aliasName:[names lastObject]];
                    if (context) {
                        [set addObject:context];
                    }
                }
            }
            *stop = YES;
        }
    }];
    return set;
}

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfAllKindsOfMethodsForPerformer:(id)performer fromNativeMethodsInfo:(NSDictionary<NSString *, NSArray<NSString *> *> *)info {
    if (!info || ![info isKindOfClass:[NSDictionary class]] || [info count] == 0) {
        return nil;
    }
    //执行者的类名
    NSMutableSet *set = [[NSMutableSet alloc] init];
    NSString *performerClassName = performer ? NSStringFromClass([performer class]) : nil;
    if (performerClassName) {
        //指定了方法执行者，则只遍历方法执行者类
        NSArray<NSString *> *methods = [info objectForKey:performerClassName];
        for (NSString *methodName in methods) {
            if ([methodName hasPrefix:@"+"]) {
                //类方法（静态）
                NSArray *names = [methodName componentsSeparatedByString:AE_JSMETHOD_SEPARATOR];
                //注册时都会以别名注册，所以如果有别名，则使用别名，否则使用方法名
                AEJSHandlerContext *context = [AEJSHandlerContext contextWithPerformer:[performer class] selector:NSSelectorFromString([names firstObject]) aliasName:[names lastObject]];
                if (context) {
                    [set addObject:context];
                }
            } else if ([methodName hasPrefix:@"-"]) {
                //实例方法
                NSArray *names = [methodName componentsSeparatedByString:AE_JSMETHOD_SEPARATOR];
                //注册时都会以别名注册，所以如果有别名，则使用别名，否则使用方法名
                AEJSHandlerContext *context = [AEJSHandlerContext contextWithPerformer:performer selector:NSSelectorFromString([names firstObject]) aliasName:[names lastObject]];
                if (context) {
                    [set addObject:context];
                }
            }
        }
    } else {
        //未指定方法执行者，则与获取所有类方法的相同
        [AEHybridLauncher jsContextsOfClassMethodsForPerformer:nil fromNativeMethodsInfo:info];
    }
    return set;
}

#pragma mark Public methods

+ (NSSet<AEJSHandlerContext *> *)jsContextsOfType:(AEMethodType)type forPerformer:(id _Nullable)performer {
    //从Info.plist中找出准备好的Native类信息
    NSDictionary<NSString *, NSArray<NSString *> *> *nativeMethodsInfo = [[[NSBundle mainBundle] infoDictionary] objectForKey:AE_JSMETHOD_INFOKEY];
    NSSet *contexts = nil;
    switch (type) {
        case AEMethodTypeClass:
            contexts = [AEHybridLauncher jsContextsOfClassMethodsForPerformer:performer fromNativeMethodsInfo:nativeMethodsInfo];
            break;
        case AEMethodTypeInstance:
            contexts = [AEHybridLauncher jsContextsOfInstanceMethodsForPerformer:performer fromNativeMethodsInfo:nativeMethodsInfo];
            break;
        case AEMethodTypeAll:
            contexts = [AEHybridLauncher jsContextsOfAllKindsOfMethodsForPerformer:performer fromNativeMethodsInfo:nativeMethodsInfo];
            break;
        default:
            break;
    }
    return contexts;
}

+ (void)automaticallyRegisterNativeMethodsOfType:(AEMethodType)type forPerformer:(id _Nullable)performer toJavaScriptHandler:(nonnull AEJavaScriptHandler *)handler {
    NSSet *contexts = [AEHybridLauncher jsContextsOfType:type forPerformer:performer];
    //更新JSContexts
    handler.jsContexts = [handler.jsContexts setByAddingObjectsFromSet:contexts];
}

@end

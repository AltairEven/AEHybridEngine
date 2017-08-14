//
//  AEWebCookieStorage.m
//  Pods
//
//  Created by Altair on 11/08/2017.
//
//

#import "AEWebCookieStorage.h"

#define AEWEBCOOKIESTORAGE_SIGN (@"AEWebCookieStorageSign")

inline NSString * AE_NSHTTPCookieToDocumentDotCookie(NSHTTPCookie *cookie) {
    NSString *name = cookie.name;
    NSString *value = cookie.value;
    NSMutableString *cookieString = [[NSMutableString alloc] init];
    if (name.length > 0 && value.length > 0) {
        [cookieString appendFormat:@"%@=%@", name, value];
    }
    
    return [cookieString copy];
}

@interface AEWebCookieStorage ()

@property (nonatomic, strong) NSHTTPCookieStorage *cookieStorage;

+ (NSHTTPCookie *)signCookie:(NSHTTPCookie *)cookie;

@end

@implementation AEWebCookieStorage

+ (instancetype)sharedCookieStorage {
    static AEWebCookieStorage *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AEWebCookieStorage alloc] init];
        sharedInstance.cookieStorage = [[NSHTTPCookieStorage alloc] init];
    });
    return sharedInstance;
}

- (NSArray<NSHTTPCookie *> *)cookies {
    return self.cookieStorage.cookies;
}

#pragma mark Private methods

+ (NSHTTPCookie *)signCookie:(NSHTTPCookie *)cookie {
    if (!cookie || [cookie isKindOfClass:[NSHTTPCookie class]]) {
        return nil;
    }
    //给cookie打个标
    NSMutableDictionary *properties = [[cookie properties] mutableCopy];
    [properties setObject:AEWEBCOOKIESTORAGE_SIGN forKey:NSHTTPCookieComment];
    NSHTTPCookie *signedCookie = [NSHTTPCookie cookieWithProperties:properties];
    return signedCookie;
}

#pragma mark Public methods

- (void)setCookie:(NSHTTPCookie *)cookie {
    NSHTTPCookie *signedCookie = [AEWebCookieStorage signCookie:cookie];
    if (!signedCookie) {
        return;
    }
    //分别存到私有仓库和公共仓库
    [self.cookieStorage setCookie:signedCookie];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:signedCookie];
}

- (void)deleteCookie:(NSHTTPCookie *)cookie {
    NSHTTPCookie *signedCookie = [AEWebCookieStorage signCookie:cookie];
    if (!signedCookie) {
        return;
    }
    [self.cookieStorage deleteCookie:cookie];
}

- (void)removeAllCookies {
    //分别清理私有仓库和公共仓库中相关的cookie
    self.cookieStorage = [[NSHTTPCookieStorage alloc] init];
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy];
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.comment isEqualToString:AEWEBCOOKIESTORAGE_SIGN]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
}

+ (NSURLRequest *)cookiedRequest:(NSURLRequest *)originalRequest {
    return originalRequest;
}

@end

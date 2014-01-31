//
//  EGBingTranslate.m
//  Bing Translate
//
//  Created by Eli Greenfeld on 1/28/14.
//  Copyright (c) 2014 Eli Greenfeld. All rights reserved.
//

#import "EGBingTranslate.h"

#define TOKEN_URL       @"https://datamarket.accesscontrol.windows.net/v2/OAuth2-13"
#define TRANSLATE_URL   @"http://api.microsofttranslator.com/v2/Http.svc/Translate"
#define DETECT_URL      @"http://api.microsofttranslator.com/V2/Http.svc/Detect"

#define TOKEN_EXPIRE_INTERVAL  60*9

typedef void(^TokenHander)(BOOL tokenIsValid);

@implementation EGBingTranslate {
    NSString *access_token;
    NSTimeInterval expires_in;
    NSDate *timeOfTokenRenewal;
    NSString *scope;
    NSString *tokenType;
    NSTimer *timer;
}

+ (id)sharedInstance {
    static EGBingTranslate *egBingTranslate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        egBingTranslate = [[EGBingTranslate alloc] init];
    });
    
    return egBingTranslate;
}

- (id)init {
    self = [super init];
    if (self) {
        [self triggerTimer];
        timeOfTokenRenewal = [NSDate distantPast];
        expires_in = 0;
    }
    return self;
}

- (void)triggerTimer {
    [timer invalidate];
    timer = nil;
    timer = [NSTimer scheduledTimerWithTimeInterval:TOKEN_EXPIRE_INTERVAL
                                             target:self
                                           selector:@selector(targetMethod)
                                           userInfo:nil
                                            repeats:YES];
    
}

- (void)targetMethod {
    [self requestTokenWithHandler:^(id result) {
        NSLog(@"Bing token refresh !!");
    }];
}

- (NSArray *)supportedLanguages {
    static NSArray *array;
    if (!array) {
        array = @[
                  @[@"ar", @"Arabic"],
                  @[@"cs", @"Czech"],
                  @[@"da", @"Danish"],
                  @[@"de", @"German"],
                  @[@"en", @"English"],
                  @[@"et", @"Estonian"],
                  @[@"fi", @"Finnish"],
                  @[@"fr", @"French"],
                  @[@"nl", @"Dutch"],
                  @[@"el", @"Greek"],
                  @[@"he", @"Hebrew"],
                  @[@"ht", @"Haitian"],
                  @[@"hu", @"Hungarian"],
                  @[@"id", @"Indonesian"],
                  @[@"it", @"Italian"],
                  @[@"ja", @"Japanese"],
                  @[@"ko", @"Korean"],
                  @[@"lt", @"Lithuanian"],
                  @[@"lv", @"Latvian"],
                  @[@"no", @"Norwegian"],
                  @[@"pl", @"Polish"],
                  @[@"pt", @"Portuguese"],
                  @[@"ro", @"Romanian"],
                  @[@"es", @"Spanish"],
                  @[@"ru", @"Russian"],
                  @[@"sk", @"Slovak"],
                  @[@"sl", @"Slovene"],
                  @[@"sv", @"Swedish"],
                  @[@"th", @"Thai"],
                  @[@"tr", @"Turkish"],
                  @[@"uk", @"Ukrainian"],
                  @[@"vi", @"Vietnamese"],
                  @[@"zh-CHS", @"Simplified"],
                  @[@"zh-CHT", @"Traditional"],
                  ];
    }
    return array;
}

- (void)requestTokenWithHandler:(RequestTokenHandler)handler {
    NSString *clientSecret = (__bridge NSString *) CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                           (CFStringRef) CLIENT_SECRET,
                                                                                           NULL,
                                                                                           (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                                           kCFStringEncodingUTF8);
    
    NSString *urlAsString = @"";
    urlAsString = [urlAsString stringByAppendingFormat:@"client_id=%@", CLIENT_ID];
    urlAsString = [urlAsString stringByAppendingFormat:@"&client_secret=%@", clientSecret];
    urlAsString = [urlAsString stringByAppendingFormat:@"&scope=http://api.microsofttranslator.com"];
    urlAsString = [urlAsString stringByAppendingFormat:@"&grant_type=client_credentials"];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest
                                       requestWithURL:[NSURL URLWithString:TOKEN_URL]
                                       cachePolicy:NSURLRequestUseProtocolCachePolicy
                                       timeoutInterval:30.0];
    
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    const char *bytes = [urlAsString UTF8String];
    [urlRequest setHTTPBody:[NSData dataWithBytes:bytes length:strlen(bytes)]];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (data.length > 0 && !connectionError) {
            NSError *error;
            NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!error) {
                tokenType = d[@"token_type"];
                access_token = d[@"access_token"];
                expires_in = [d[@"expires_in"] integerValue];
                scope = d[@"scope"];
                
                timeOfTokenRenewal = [NSDate date];
                
                handler(access_token);
            }
            else {
                handler(nil);
            }
        }
        else if (data.length == 0 && !connectionError) {
            NSLog(@"got nothing");
            handler(nil);
        }
        else if (connectionError) {
            NSLog(@"error: %@", connectionError);
            handler(nil);
        }
    }];
    
}

- (void)translateText:(NSString *)text fromLanguage:(NSString *)srcLanguage toLanguage:(NSString *)trgLanguage withHandler:(TranslateHandler)handler {
    [self validateTokenWithHandler:^(BOOL tokenIsValid) {
        NSString *authToken = [@"Bearer " stringByAppendingString:access_token];
        
        NSMutableString *authHeader = [NSMutableString stringWithString:@"?text="];
        
        [authHeader appendString:text];
        [authHeader appendString:@"&from="];
        [authHeader appendString:srcLanguage];
        [authHeader appendString:@"&to="];
        [authHeader appendString:trgLanguage];
        [authHeader appendString:@"&contentType="];
        [authHeader appendString:@"text/plain"];
        
        NSString *urlString = [TRANSLATE_URL stringByAppendingString:authHeader];
        
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSMutableURLRequest *request = [NSMutableURLRequest
                                        requestWithURL:[NSURL URLWithString:urlString]
                                        cachePolicy:NSURLRequestUseProtocolCachePolicy
                                        timeoutInterval:60.0];
        
        
        [request setHTTPMethod:@"GET"];
        [request addValue:authToken forHTTPHeaderField:@"Authorization"];
        
        
        NSURLResponse *response;
        NSError *error;
        
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (data != nil) {
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *value = [self getValueInXml:content];
            handler(value);
        }
        else {
            handler(nil);
        }
    }];
}

- (void)detectLanguageOfText:(NSString *)text withHandler:(TranslateHandler)handler {
    [self validateTokenWithHandler:^(BOOL tokenIsValid) {
        
        NSString *authToken = [@"Bearer " stringByAppendingString:access_token];
        
        NSMutableString *authHeader = [NSMutableString stringWithString:@"?text="];
        
        [authHeader appendString:text];
        [authHeader appendString:@"&appId="];
        
        NSString *urlString = [DETECT_URL stringByAppendingString:authHeader];
        
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSMutableURLRequest *request = [NSMutableURLRequest
                                        requestWithURL:[NSURL URLWithString:urlString]
                                        cachePolicy:NSURLRequestUseProtocolCachePolicy
                                        timeoutInterval:60.0];
        
        
        [request setHTTPMethod:@"GET"];
        [request addValue:authToken forHTTPHeaderField:@"Authorization"];
        
        
        NSURLResponse *response;
        NSError *error;
        
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (data != nil) {
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *value = [self getValueInXml:content];
            handler(value);
        }
        else {
            handler(nil);
        }
        
    }];
}

- (NSString *)getValueInXml:(NSString *)xml {
    __block NSString *value;
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@">(.*)<"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    [regex enumerateMatchesInString:xml options:0 range:NSMakeRange(0, [xml length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        
        NSRange range = NSMakeRange(match.range.location + 1, match.range.length - 2);
        value = [xml substringWithRange:range];
        *stop = YES;
        
    }];
    
    return value;
}

- (void)validateTokenWithHandler:(TokenHander)handler {
    NSTimeInterval t = [timeOfTokenRenewal timeIntervalSinceNow];
    if (-[timeOfTokenRenewal timeIntervalSinceNow] > expires_in) {
        NSLog(@"renewed on access %lf", -t);
        
        [self requestTokenWithHandler:^(id result) {
            handler(YES);
        }];
    }
    
    NSLog(@"no need to renew %lf", -t);
    
    handler(YES);
}

@end

//
//  EGBingTranslate.h
//  Bing Translate
//
//  Created by Eli Greenfeld on 1/28/14.
//  Copyright (c) 2014 Eli Greenfeld. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CLIENT_ID       @"YOUR_CLIENT_ID"
#define CLIENT_SECRET   @"YOUR_CLIENT_SECRET"

typedef void(^RequestTokenHandler)(id result);
typedef void(^TranslateHandler)(id result);

@interface EGBingTranslate : NSObject

+(id)sharedInstance;

-(NSArray*)supportedLanguages;
-(void)requestTokenWithHandler:(RequestTokenHandler)handler;
-(void)translateText:(NSString*)text fromLanguage:(NSString*)srcLanguage toLanguage:(NSString*)trgLanguage withHandler:(TranslateHandler)handler;
-(void)detectLanguageOfText:(NSString *)text withHandler:(TranslateHandler)handler;
@end

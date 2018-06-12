//
//  VJsonPaser.h
//  VJsonPaser
//
//  Created by Weijie He on 2018/6/8.
//  Copyright © 2018年 baostorm. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VJsonPaser : NSObject

+ (NSMutableDictionary *) parseJson : (NSString *) inputJson;

@end // VJsonPaser

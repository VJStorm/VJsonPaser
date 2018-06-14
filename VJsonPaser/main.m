//
//  main.m
//  VJsonPaser
//
//  Created by Weijie He on 2018/6/8.
//  Copyright © 2018年 baostorm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VJsonPaser.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSError * err;
        
        NSString * home =[@"~" stringByExpandingTildeInPath];
        NSString * path = [NSString stringWithFormat:@"%@/Documents/test.txt", home];
        
        //从本地路径读取文件
        NSString* inputString = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &err];
        NSLog(@"the reading string is: %@", inputString);
        
        //解析
        NSObject* result = [VJsonPaser parseJson: inputString];
        
        if (result == nil) {
            NSLog(@"Json格式不合法，请检查后重试。");
            return 1;
        }
        
        NSLog(@"the result is: %@", result);
        
        NSInteger length = [inputString length];
        NSInteger i = 0;
        for (; i < length; i++) {
            if ([[inputString substringWithRange: NSMakeRange(i, 1)] isEqualToString: @" "]) {
                continue;
            }
            break;
        }

        if ( [[inputString substringWithRange: NSMakeRange(i, 1)] isEqualToString: @"{"]) {
            NSDictionary* tran = (NSDictionary *) result;
            //遍历输出
            NSEnumerator * erator = [tran keyEnumerator];
            NSString * key;
            while (key = [erator nextObject]) {
                NSLog(@"key: %@, value: %@", key, tran[key]);
            }
        }

        else if ( [[inputString substringWithRange: NSMakeRange(i, 1)] isEqualToString: @"["]) {
            NSArray* tran = (NSArray *) result;
            // todo with the result
            NSLog(@"length: %lu", [tran count]);
        }
        else {
            NSString* tran = (NSString *) result;
            NSLog(@"%@", tran);
        }
    }
    return 0;
}

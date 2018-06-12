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
        NSString* inputString = [NSString stringWithContentsOfFile: @"/Users/heweijie/Documents/result.txt" encoding: NSUTF8StringEncoding error: &err];
        NSLog(@"the reading string is: %@", inputString);
        NSInteger length = [inputString length];
        NSInteger i = 0;
        for (; i < length; i++) {
            if ([[inputString substringWithRange: NSMakeRange(i, 1)] isEqualToString: @" "]) {
                continue;
            }
            break;
        }
        
        NSObject* result = [VJsonPaser parseJson: inputString];
//        NSLog(@"the result is: %@", result);
//
//        if ( [[inputString substringWithRange: NSMakeRange(i, 1)] isEqualToString: @"{"]) {
//            NSDictionary* tran = (NSDictionary *) result;
//            NSLog(@"the result is: %@", tran[@"1"]);
//        }
//
//        else if ( [[inputString substringWithRange: NSMakeRange(i, 1)] isEqualToString: @"["]) {
//            NSArray* tran = (NSArray *) result;
//            NSLog(@"the result is: %@", [tran objectAtIndex: 1]);
//        }
//        else {
//            NSString* tran = (NSString *) result;
//            NSLog(@"%@", tran);
//        }
    }
    return 0;
}

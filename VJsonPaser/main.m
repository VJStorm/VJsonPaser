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
        NSString * path = [NSString stringWithFormat:@"%@/Downloads/data/", home];
        
        NSFileManager *manager = [NSFileManager defaultManager];
        NSDirectoryEnumerator * direnum = [manager enumeratorAtPath: path];
        NSString *filename, *filePath;
        while (filename = [direnum nextObject]) {
            filePath = [NSString stringWithFormat:@"%@%@", path, filename];
            NSLog(@"File name is: %@", filename);
            
            //从本地路径读取文件
            NSString* inputString = [NSString stringWithContentsOfFile: filePath encoding: NSUTF8StringEncoding error: &err];
            NSLog(@"the reading string is: %@", inputString);
            
            //解析
            id result = [VJsonPaser parseJson: inputString];
            
            if (result == nil) {
                NSLog(@"Json格式不合法，请检查后重试。");
                continue;
            }
            
            NSLog(@"My result is: %@", result);
            
            NSData * data = [inputString dataUsingEncoding: NSUTF8StringEncoding];
            id jsonResult = [NSJSONSerialization JSONObjectWithData: data options:0 error:nil];
            
            if ([jsonResult isEqual:result]) {
                NSLog(@"Right result.");
            } else {
                NSLog(@"Wrong. The result should be: %@", jsonResult);
            }
            
        }
    }
    return 0;
}

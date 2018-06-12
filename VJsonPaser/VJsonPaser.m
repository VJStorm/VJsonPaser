//
//  VJsonPaser.m
//  VJsonPaser
//
//  Created by Weijie He on 2018/6/8.
//  Copyright © 2018年 baostorm. All rights reserved.
//

/* 思路
 一个json首先是一个对象或数组
 一个数组包含多个对象或数组，也可能是字符串数组、数字数组、false、true、null
 一个对象含有一个或多个属性
 一个属性含有一个key和一个value
 一个value含有一个字符串或一个对象或一个数组
 */

#import "VJsonPaser.h"

//找到引号里面的字符串
NSString * findString (NSString * input, NSUInteger* star) // star传地址过来才能在内存中改变
{
    NSString * rightChar, * result = nil;
    
    NSUInteger length = [input length] ,j;
    
    for (j = *star+1; j < length; j++) {
        rightChar = [input substringWithRange: NSMakeRange(j, 1)];
        if ([rightChar isEqualToString: @"\""]) {
            if ([[input substringWithRange: NSMakeRange(j-1, 1)] isEqualToString:@"\\"]) {
                continue; //有转义符在前面就说明这不是真的结尾
            }
            
            result = [input substringWithRange: NSMakeRange(*star +1, j- *star -1)];
            *star = j;
            break;
        }
    }
    return result;
}

@implementation VJsonPaser

//内部的方法，用于验证字符串是否可以符合Json格式
+ (BOOL) checkJsonPattern : (NSString *) inputJson
{
    BOOL isJson = YES;
    //然而数组里面的字符串中可以出现任何符号，所以最好还是边解析边判断吧……
    NSMutableString* tmp = [NSMutableString stringWithCapacity:100];
    [tmp appendString: inputJson];
    NSUInteger leftBigBracket = [tmp replaceOccurrencesOfString:@"{" withString:@"|" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [tmp length])];
    NSUInteger rightBigBracket = [tmp replaceOccurrencesOfString:@"}" withString:@"|" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [tmp length])];
    if (leftBigBracket != rightBigBracket) {
//        isJson = NO;
    }
    
    return isJson;
}

//递归解析，边解析边验证
+ (NSObject *) parseToDictionary : (NSString *) inputJson
{
    NSMutableDictionary * result = [NSMutableDictionary dictionaryWithCapacity:20];
    
    NSUInteger length = [inputJson length];  // 获取输入字符串的长度
    
    NSString *leftChar, *rightChar;
    
    NSUInteger i = 0, j = 0;
    
    for (; i < length; i++) {
        
        leftChar = [inputJson substringWithRange: NSMakeRange(i, 1)];
        //是一个对象的情况
        if (![leftChar isEqualToString: @" "] && [leftChar isEqualToString: @"{"]) {
            
            NSString * key;
            NSObject * value;
            
            BOOL leftBracket=YES, rightBracket=NO, rightQuote = NO, leftQuote = NO, hasColon = NO;
            
            //对象里面有一个或多个key-value对
            for ( i++; i < length; i++) {
                leftChar = [inputJson substringWithRange: NSMakeRange(i, 1)];
                //找到key
                if ([leftChar isEqualToString: @"\""]) {
                    
                    leftQuote = YES;
                    
                    for (j = i+1; j < length; j++) {
                        rightChar = [inputJson substringWithRange: NSMakeRange(j, 1)];
                        if ([rightChar isEqualToString: @"\""]) {
                            if ([[inputJson substringWithRange: NSMakeRange(j-1, 1)] isEqualToString:@"\\"]) {
                                continue; //有转义符在前面就说明这不是真的结尾
                            }
                            
                            rightQuote = YES;
                            
                            key = [inputJson substringWithRange: NSMakeRange(i+1, j-i-1)];
                            i = j;
                            break;
                        }
                    }
                    if (rightQuote == NO) {
                        return nil;
                    }
                    continue;
                }
                
                if (rightQuote) {
                    //一定是找key之后才会执行下面的操作
                    //找到value
                    if ([leftChar isEqualToString: @":"]) {
                        
                        hasColon = YES;
                        
                        for (i++ ; i < length; i++) {
                            leftChar = [inputJson substringWithRange: NSMakeRange(i, 1)];
                            //跳过空格
                            if ([leftChar isEqualToString: @" "]) {
                                continue;
                            }
                            //value是一个字符串
                            if ([leftChar isEqualToString: @"\""]) {
                                for( j = i+1; j < length; j++) {
                                    rightChar = [inputJson substringWithRange: NSMakeRange(j, 1)];
                                    if ([rightChar isEqualToString: @"\""]) {
                                        if ([[inputJson substringWithRange: NSMakeRange(j-1, 1)] isEqualToString:@"\\"]) {
                                            continue; //有转义符在前面就说明这不是真的结尾
                                        }
                                        value = [inputJson substringWithRange: NSMakeRange(i+1, j-i-1)];
                                        break;
                                    }
                                }
                                break;
                            }
                            //value是一个数组
                            if ([leftChar isEqualToString: @"["]) {
                                //直接把剩下的字符串丢给下一级消费
                                int bracketCount = 1;
                                for( j = i+1; j < length; j++) {
                                    rightChar = [inputJson substringWithRange: NSMakeRange(j, 1)];
                                    if ([rightChar isEqualToString: @"["]) {
                                        bracketCount ++;
                                    }
                                    else if ([rightChar isEqualToString: @"]"]) {
                                        bracketCount --;
                                        if (bracketCount == 0) {
                                            //此时j就是该value结束的地方
                                            break;
                                        }
                                    }
                                }
                                value = [VJsonPaser parseToArray: [inputJson substringWithRange:
                                                                   NSMakeRange(i, j-i+1)]];
                                break;
                            }
                            //value是一个对象
                            if ([leftChar isEqualToString: @"{"]) {
                                int bracketCount = 1;
                                for( j = i+1; j < length; j++) {
                                    rightChar = [inputJson substringWithRange: NSMakeRange(j, 1)];
                                    if ([rightChar isEqualToString: @"{"]) {
                                        bracketCount ++;
                                    }
                                    else if ([rightChar isEqualToString: @"}"]) {
                                        bracketCount --;
                                        if (bracketCount == 0) {
                                            //此时j就是该value结束的地方
                                            break;
                                        }
                                    }
                                }
                                value = [VJsonPaser parseToDictionary: [inputJson substringWithRange:
                                                                        NSMakeRange(i, j-i+1)]];
                                break;
                            }
                            //value是null true false
                            if ([leftChar isEqualToString: @"n"]) {
                                value = @"null";
                                j = i+4;
                                break;
                            }
                            if ([leftChar isEqualToString: @"t"]) {
                                value = @"true";
                                j = i+4;
                                break;
                            }
                            if ([leftChar isEqualToString: @"f"]) {
                                value = @"false";
                                j = i+5;
                                break;
                            }
                            
                            //value是数字
                            NSPredicate* numberPredicate = [NSPredicate predicateWithFormat: @"SELF IN {'0','1','2','3','4','5','6','7','8','9'}"];
                            
                            if ([numberPredicate evaluateWithObject:leftChar]) {
                                for( j = i+1; j < length; j++) {
                                    rightChar = [inputJson substringWithRange: NSMakeRange(j, 1)];
                                    if ([rightChar isEqualToString: @"."] || [numberPredicate evaluateWithObject:rightChar]) {
                                        continue;
                                    }
                                    //数字里面可以包含小数点
                                    value = [inputJson substringWithRange: NSMakeRange(i, j-i)];
                                    break;
                                }
                                break;
                            }
                            
                        }
                        //已经找到value，下面生成字典
                        [result setObject: value forKey: key];
                        //i从value结束的地方开始,注意for语句还会i++
                        i = j;
                    }
                }
            }
            //根本没有找到key，返回nil
            if (leftQuote == NO || hasColon == NO) {
                return nil;
            }
        }
        //是一个数组的情况
        else if (![leftChar isEqualToString: @" "] && [leftChar isEqualToString: @"["]) {
            return [VJsonPaser parseToArray: inputJson];
        }
        //既不是对象也不是数组，直接作为字符串返回
        else {
            for (j = length - 1; j > i; j--) {
                rightChar = [inputJson substringWithRange: NSMakeRange(j, 1)];
                if ([rightChar isEqualToString: @" "]) {
                    continue;
                }
                break;
            }
            return [inputJson substringWithRange:NSMakeRange(i, j-i+1)];
        }
    }
    
    return result;
} // end parseToDictionary

+ (NSArray *) parseToArray : (NSString *) inputString
{
    NSMutableArray * result = [NSMutableArray arrayWithCapacity: 20];
    NSString * leftChar, * rightChar;
    NSUInteger length = [inputString length];
    NSUInteger i = 0, j = length-1;
    //先去掉首尾的[]
    for (; j > 0; j--) {
        rightChar = [inputString substringWithRange: NSMakeRange(j, 1)];
        if ([rightChar isEqualToString: @"]"]) {
            break;
        }
    }
    inputString = [inputString substringWithRange: NSMakeRange( i+1, j-i-1)];
    length = [inputString length];
    //然后开始分出对象
    for (i = 0; i < length; i++) {
        leftChar = [inputString substringWithRange: NSMakeRange(i, 1)];
        //直接跳过头部的空格和逗号
        if ([leftChar isEqualToString: @" "] || [leftChar isEqualToString: @","]) {
            continue;
        }
        if ([leftChar isEqualToString: @"{"]) {
            //是一个对象
            int bracketCount = 1;
            for( j = i+1; j < length; j++) {
                rightChar = [inputString substringWithRange: NSMakeRange(j, 1)];
                if ([rightChar isEqualToString: @"{"]) {
                    bracketCount ++;
                }
                else if ([rightChar isEqualToString: @"}"]) {
                    bracketCount --;
                    if (bracketCount == 0) {
                        //此时j就是该对象结束的地方
                        break;
                    }
                }
            }
            [result addObject:
              [VJsonPaser parseToDictionary:
                [inputString substringWithRange: NSMakeRange(i, j-i+1)]
              ]
            ];
            i = j+1;
        }
        else if ([leftChar isEqualToString: @"["]) {
            //是一个数组
            int bracketCount = 1;
            for( j = i+1; j < length; j++) {
                rightChar = [inputString substringWithRange: NSMakeRange(j, 1)];
                if ([rightChar isEqualToString: @"["]) {
                    bracketCount ++;
                }
                else if ([rightChar isEqualToString: @"]"]) {
                    bracketCount --;
                    if (bracketCount == 0) {
                        //此时j就是该对象结束的地方
                        break;
                    }
                }
            }
            [result addObject: [VJsonPaser parseToArray:
              [inputString substringWithRange: NSMakeRange(i, j-i+1)]]
             ];
            i = j+1;
        }
        //如果既不是数组也不是对象，那么应该就是字符串或者数字之类的，字符串的话不能通过找逗号来判断是否结束，其他可以
        //由于字符串里面可能有转义引号，我们直接判断引号前面是否有转义符即可
        else if ([leftChar isEqualToString: @"\""]) {
            for( j = i+1; j < length; j++) {
                rightChar = [inputString substringWithRange: NSMakeRange(j, 1)];
                if ([rightChar isEqualToString: @"\""]) {
                    if (![[inputString substringWithRange: NSMakeRange(j-1, 1)] isEqualToString:@"\\"]) {
                        //此时为字符串结束的引号
                        break;
                    }
                }
            }
            [result addObject:
             [inputString substringWithRange: NSMakeRange(i+1, j-i-1)]
             ];
            i = j+1;
        }
        else {
            for( j = i+1; j < length; j++) {
                rightChar = [inputString substringWithRange: NSMakeRange(j, 1)];
                if ([rightChar isEqualToString: @","]) {
                    break;
                }
            }
            for (j-- ; j > i; j--) {
                rightChar = [inputString substringWithRange: NSMakeRange(j, 1)];
                if ([rightChar isEqualToString: @" "]) {
                    continue;
                }
                //此时j就是该对象结束的位置前一个位置
                break;
            }
            [result addObject:
             [inputString substringWithRange: NSMakeRange(i, j-i+1)]
            ];
            i = j+1;
        }
    }
    return result;
} // end parseToArray

//暴露的类方法，进行Json解析
+ (NSObject *) parseJson : (NSString *) inputJson
{
    inputJson = [inputJson stringByReplacingOccurrencesOfString: @"\n" withString: @""]; //去除回车
    inputJson = [inputJson stringByReplacingOccurrencesOfString: @"\r" withString: @""]; //去除换行
    inputJson = [inputJson stringByReplacingOccurrencesOfString: @"\t" withString: @""]; //去除tab
    
    NSLog(@"preprocess string is: %@", inputJson);
    
    //首先进行json格式验证
    if ([VJsonPaser checkJsonPattern: inputJson]) {
        
        return [VJsonPaser parseToDictionary: inputJson];
        
    }
    
    return nil;
}


@end // VJsonPaser

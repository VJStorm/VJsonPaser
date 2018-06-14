//
//  VJsonPaser.m
//  VJsonPaser
//
//  Created by Weijie He on 2018/6/8.
//  Copyright © 2018年 baostorm. All rights reserved.
//

/* 思路
 一个json首先是一个对象或数组（或单独是一个true、false等也是正确的
 一个数组包含多个对象或数组，也可能是字符串数组、数字数组、false、true、null
 一个对象含有一个或多个属性
 一个属性含有一个key和一个value
 一个value含有一个字符串或一个对象或一个数组或数字 true false null
 用递归来实现最合适
 */

#import "VJsonPaser.h"

//找到引号里面的字符串
NSString * findString (NSString * input, NSUInteger star, NSUInteger *end) // star传地址过来才能在内存中改变
{
    NSString * rightChar, * result = nil;
    
    NSUInteger length = [input length];
    
    for (*end = star+1; *end < length; *end+=1) {
        rightChar = [input substringWithRange: NSMakeRange(*end, 1)];
        if ([rightChar isEqualToString: @"\""]) {
            if ([[input substringWithRange: NSMakeRange(*end-1, 1)] isEqualToString:@"\\"]) {
                continue; //有转义符在前面就说明这不是真的结尾
            }
            
            result = [input substringWithRange: NSMakeRange(star +1, *end- star -1)];
            break;
        }
    }
    return result;
} // end findString

//找到开始括号对应的结束括号
int findCorrespondBracket(NSString * input, NSString* leftBracket, NSString* rightBracket, NSUInteger star, NSUInteger* end)
{
    int bracketCount = 1;
    NSString * rightChar;
    NSUInteger length = [input length];
    
    for( *end = star+1; *end < length; *end+=1) {
        
        rightChar = [input substringWithRange: NSMakeRange(*end, 1)];
        
        //如果遇到引号,里面可能有影响判断对称的字符，需要跳过
        if ([rightChar isEqualToString: @"\""]) {
            star = *end;
            NSString* str = findString(input, star, end);
            if (str == nil) {
                return -1;
            }
            continue;
        }
        
        if ([rightChar isEqualToString: leftBracket]) {
            bracketCount ++;
        }
        else if ([rightChar isEqualToString: rightBracket]) {
            bracketCount --;
            if (bracketCount == 0) {
                //此时j就是该value结束的地方
                break;
            }
        }
        
    }
    return bracketCount;
} // end findCorrespondBracket

//检查其他合法情况
NSString* checkOtherLegal(NSString* input, NSUInteger star, NSUInteger* end, NSString* leftChar)
{
    NSString *value = nil, *rightChar;
    NSUInteger length = [input length];
    
    // null
    if ([leftChar isEqualToString: @"n"]) {
        if (length < star+4) {
            return nil;
        }
        leftChar = [input substringWithRange: NSMakeRange(star, 4)];
        if (![leftChar isEqualToString: @"null"]) {
            return nil;
        }
        value = @"null";
        *end = star+3;
    }
    
    // true
    else if ([leftChar isEqualToString: @"t"]) {
        if (length < star+4) {
            return nil;
        }
        leftChar = [input substringWithRange: NSMakeRange(star, 4)];
        if (![leftChar isEqualToString: @"true"]) {
            return nil;
        }
        value = @"true";
        *end = star+3;
    }
    
    // false
    else if ([leftChar isEqualToString: @"f"]) {
        if (length < star+5) {
            return nil;
        }
        leftChar = [input substringWithRange: NSMakeRange(star, 5)];
        if (![leftChar isEqualToString: @"false"]) {
            return nil;
        }
        value = @"false";
        *end = star+4;
    }
    
    //value是数字
    NSPredicate* numberPredicate = [NSPredicate predicateWithFormat: @"SELF IN {'0','1','2','3','4','5','6','7','8','9'}"];
    
    if ([numberPredicate evaluateWithObject:leftChar]) {
        
        *end = star+1;
        
        //开头为0只能跟小数点，逗号，空格，否则格式错误
        if ([leftChar isEqualToString: @"0"]) {
            rightChar = [input substringWithRange: NSMakeRange(*end, 1)];
            if (![rightChar isEqualToString: @"."] && ![rightChar isEqualToString:@","] && ![rightChar isEqualToString:@" "]) {
                return nil;
            }
        }
        
        BOOL alreadyDot = NO; //是否已经遇到小数点了
        
        for( ; *end < length; *end += 1) {
            
            rightChar = [input substringWithRange: NSMakeRange(*end, 1)];
            
            if ([rightChar isEqualToString: @"."]) {
                //只能有一个小数点
                if (alreadyDot) {
                    return nil;
                }
                alreadyDot = YES;
                
                //可能小数点之后啥都没有，也是错的
                if (length <= *end+1) {
                    return nil;
                }
                rightChar = [input substringWithRange: NSMakeRange(*end+1, 1)];
                if (![numberPredicate evaluateWithObject: rightChar]) {
                    return nil;
                }
                
                continue;
            }
            else if ([numberPredicate evaluateWithObject:rightChar]) {
                continue;
            }
            //遇到逗号空格才算找到value
            else if ([rightChar isEqualToString:@","] || [rightChar isEqualToString:@" "]) {
                break;
            }
            //其他符号都是格式错误
            else {
                return nil;
            }
            
        }
        value = [input substringWithRange: NSMakeRange(star, *end-star)];
        *end -= 1; // 确保在数字的最后一位
    }
    
    return value;
    
} // end checkOtherLegal


@implementation VJsonPaser

//递归解析，边解析边验证
+ (NSObject *) parseToDictionary : (NSString *) inputJson
{
    NSMutableDictionary * result = [NSMutableDictionary dictionaryWithCapacity:20];
    
    NSUInteger length = [inputJson length];  // 获取输入字符串的长度
    
    NSString *leftChar, *rightChar;
    
    NSUInteger i = 0, j = 0;
    NSUInteger *end = &j; //star指针保存变量i的地址, end保存变量j的地址
    
    // 跳过空格
    for (; i < length; i++) {
        leftChar = [inputJson substringWithRange: NSMakeRange(i, 1)];
        if (![leftChar isEqualToString: @" "]) {
            break;
        }
    }
    
    //是一个对象的情况
    if ([leftChar isEqualToString: @"{"]) {
        
        //先去掉首尾的{},从后往前找，必须先遇到}否则格式错误
        for (j = length-1; j > 0; j--) {
            rightChar = [inputJson substringWithRange: NSMakeRange(j, 1)];
            if ([rightChar isEqualToString: @" "]) {
                continue;
            }
            if (![rightChar isEqualToString: @"}"]) {
                return nil;
            } else {
                break;
            }
        }
        inputJson = [inputJson substringWithRange: NSMakeRange( i+1, j-i-1)];
        length = [inputJson length];
        i = 0;
        
        NSString * key;
        NSObject * value;
        
        // rightQuote表示key的右引号，leftQuote表示key的左引号，hasColon表示key-value之间的冒号
        // firstKeyValue表示是否在找第一对key-value，metComma表示是否已经遇到逗号
        BOOL rightQuote = NO, leftQuote = NO, hasColon = NO, firstKeyValue = YES, metComma = YES, foundValue = NO;
        
        //对象里面有一个或多个key-value对
        for ( ; i < length; i++) {
            leftChar = [inputJson substringWithRange: NSMakeRange(i, 1)];
            //跳过空格
            if ([leftChar isEqualToString: @" "]) {
                continue;
            }
            //还没遇到左引号之前不能遇到其他字符
            if ( (![leftChar isEqualToString: @"\""]) && leftQuote == NO ) {
                //除非是逗号，如果是第一个属性之后的key之前必须遇到逗号
                if (!firstKeyValue && [leftChar isEqualToString: @","] && metComma == NO) {
                    metComma = YES;
                    continue;
                }
                else {
                    return nil;
                }
            }
            //找到key
            if ([leftChar isEqualToString: @"\""] && metComma && leftQuote == NO) {
                
                leftQuote = YES;
                
                key = findString(inputJson, i, end);
                if (key == nil) {
                    return nil;
                }
                rightQuote = YES;
                i = j;
                continue;
            }
            //还没遇到逗号之前就遇到引号，格式错误
            else if ([leftChar isEqualToString: @"\""] && !metComma){
                return nil;
            }
            
            //由于之前一堆的continue和return，一定是找key之后才会执行下面的操作
            //空格在前面已经过滤了，在找到key之后一定要遇到冒号才是正确的json
            if ( ![leftChar isEqualToString: @":"] && !hasColon) {
                return nil;
            }
            //找value
            if ([leftChar isEqualToString: @":"]) {
                
                hasColon = YES;
                foundValue = NO;
                
                for (i++ ; i < length; i++) {
                    leftChar = [inputJson substringWithRange: NSMakeRange(i, 1)];
                    //跳过空格
                    if ([leftChar isEqualToString: @" "]) {
                        continue;
                    }
                    
                    //除了空格之外还有其他字符，就一定会有value（或者格式错误
                    foundValue = YES;
                    
                    //value是一个字符串
                    if ([leftChar isEqualToString: @"\""]) {
                        value = findString(inputJson, i, end);
                        if (value == nil) {
                            return nil;
                        }
                        break;
                    }
                    //value是一个数组
                    if ([leftChar isEqualToString: @"["]) {
                        //直接把剩下的字符串丢给下一级消费
                        int bracketCount = findCorrespondBracket(inputJson, @"[", @"]", i, end);
                        if (bracketCount != 0) { // 说明有不对称的方括号
                            return nil;
                        }
                        value = [VJsonPaser parseToArray: [inputJson substringWithRange:
                                                           NSMakeRange(i, j-i+1)]];
                        break;
                    }
                    //value是一个对象
                    if ([leftChar isEqualToString: @"{"]) {
                        int bracketCount = findCorrespondBracket(inputJson, @"{", @"}", i, end);
                        if (bracketCount != 0) { // 说明有不对称的花括号
                            return nil;
                        }
                        value = [VJsonPaser parseToDictionary: [inputJson substringWithRange:
                                                                NSMakeRange(i, j-i+1)]];
                        break;
                    }
                    //检查其他合法情况
                    value = checkOtherLegal(inputJson, i, end, leftChar);
                    if (value != nil) {
                        break;
                    }
                    //到这里来的话就是找不到value
                    return nil;
                    
                }
                //冒号后没有value，格式错误
                if (foundValue == NO) {
                    return nil;
                }
                if (key == nil || value == nil) {
                    return nil;
                }
                //已经找到value，下面生成字典
                [result setObject: value forKey: key];
                //重置flag，为寻找下一个key-value做准备
                firstKeyValue = NO; metComma = NO;
                leftQuote = NO; rightQuote = NO; hasColon = NO;
                //i从value结束的地方开始,注意for语句还会i++
                i = j;
            }
        
        }
        //逗号后没有key，或者key后没有冒号，返回nil
        if ( (!firstKeyValue && leftQuote == NO && metComma ) || (rightQuote && hasColon == NO)) {
            return nil;
        }
        
    }
    //是一个数组的情况
    else if ([leftChar isEqualToString: @"["]) {
        return [VJsonPaser parseToArray: [inputJson substringFromIndex: i]];
    }
    //既不是对象也不是数组，检查其他合法性
    else if ([leftChar isEqualToString: @"\""]) {
        return findString(inputJson, i, end);
    }
    else {
        NSString* str = checkOtherLegal(inputJson, i, end, leftChar);
        if (str == nil) {
            return nil;
        }
        return str;
    }
    
    return result;
} // end parseToDictionary

//解析成数组对象
+ (NSArray *) parseToArray : (NSString *) inputString
{
    NSMutableArray * result = [NSMutableArray arrayWithCapacity: 20];
    NSString * leftChar, * rightChar;
    NSUInteger length = [inputString length];
    NSUInteger i = 0, j = length-1;
    
    NSUInteger *end = &j; //end保存变量j的地址
    
    
    
    //先去掉首尾的[],从后往前找，必须先遇到]否则格式错误
    for (; j > 0; j--) {
        rightChar = [inputString substringWithRange: NSMakeRange(j, 1)];
        if ([rightChar isEqualToString: @" "]) {
            continue;
        }
        if (![rightChar isEqualToString: @"]"]) {
            return nil;
        } else {
            break;
        }
    }
    inputString = [inputString substringWithRange: NSMakeRange( i+1, j-i-1)];
    length = [inputString length];
    
    //然后开始分出子项
    BOOL firstObject = YES, metComma = YES, foundObject = YES;
    
    for (i = 0; i < length; i++) {
        leftChar = [inputString substringWithRange: NSMakeRange(i, 1)];
        //直接跳过头部的空格和逗号
        if ([leftChar isEqualToString: @" "]) {
            continue;
        }
        if (!firstObject && [leftChar isEqualToString: @","]) {
            if (metComma == YES) {
                return nil;
            }
            metComma = YES;
            //遇到逗号之后必须遇到子项
            foundObject = NO;
            continue;
        }
        //遇到第一个子项之前遇到逗号为格式错误
        else if (firstObject && [leftChar isEqualToString: @","]) {
            return nil;
        }
        
        NSObject *obj = nil;
        
        if ([leftChar isEqualToString: @"{"] && metComma) {
            //是一个对象
            int bracketCount = findCorrespondBracket(inputString, @"{", @"}", i, end);
            if (bracketCount != 0) {
                return nil;
            }
            obj = [VJsonPaser parseToDictionary:
                             [inputString substringWithRange: NSMakeRange(i, j-i+1)]];
        }
        else if ([leftChar isEqualToString: @"["] && metComma) {
            //是一个数组
            int bracketCount = findCorrespondBracket(inputString, @"[", @"]", i, end);
            if (bracketCount != 0) {
                return nil;
            }
            obj = [VJsonPaser parseToArray:
                             [inputString substringWithRange: NSMakeRange(i, j-i+1)]];
        }
        //如果既不是数组也不是对象，那么应该就是字符串或者数字之类的
        else if ([leftChar isEqualToString: @"\""] && metComma) {
            obj = findString(inputString, i, end);
        }
        //最后的挣扎
        else {
            obj = checkOtherLegal(inputString, i, end, leftChar);
        }
        
        if (obj == nil) {
            return nil;
        }
        [result addObject:obj];
        foundObject = YES;
        firstObject = NO;
        metComma = NO;
        i = j;
    }
    
    //逗号后没找到子项
    if (foundObject == NO) {
        return nil;
    }
    
    return result;
} // end parseToArray

//暴露的类方法，进行Json解析
+ (NSObject *) parseJson : (NSString *) inputJson
{
    inputJson = [inputJson stringByReplacingOccurrencesOfString: @"\n" withString: @""]; //去除回车
    inputJson = [inputJson stringByReplacingOccurrencesOfString: @"\r" withString: @""]; //去除换行
    inputJson = [inputJson stringByReplacingOccurrencesOfString: @"\t" withString: @""]; //去除tab
    
    return [VJsonPaser parseToDictionary: inputJson];
}


@end // VJsonPaser

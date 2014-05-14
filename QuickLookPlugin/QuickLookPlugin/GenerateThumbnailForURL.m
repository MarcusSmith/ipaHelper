#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
//#import <WebKit/WebKit.h>

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
CGFloat drawArrayInRectInContext2(NSArray *array, CGRect rect, CGContextRef context, CGFloat lineSpacing, CGFloat fontSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    NSURL *ipaURL = (__bridge NSURL *)url;
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/ipaHelper"];
    [task setArguments:[NSArray arrayWithObjects:@"summary", [ipaURL path], @"--json", @"--ql", @"--dont-clean", nil]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    //The magic line that keeps your log where it belongs
    [task setStandardInput:[NSPipe pipe]];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    NSLog(@"Launching Task");
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSDictionary *summaryDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers  error:nil];
    
    NSURL *iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/icon@2x.png", summaryDictionary[@"AppDirectory"]]];
    
    NSError* error = nil;
    NSData *iconData = [NSData dataWithContentsOfFile:[iconURL path] options:NSDataReadingUncached error:&error];
    NSImage *imageForSize = [[NSImage alloc] initWithData: iconData];
    CGFloat iconSize = imageForSize.size.width;
    imageForSize = nil;
    
    //Got the icon image, time to clean up
    
    NSTask *cleanTask = [[NSTask alloc] init];
    [cleanTask setLaunchPath:@"/usr/bin/ipaHelper"];
    [cleanTask setArguments:[NSArray arrayWithObjects:@"clean", [ipaURL path], nil]];
    
    pipe = [NSPipe pipe];
    [cleanTask setStandardOutput: pipe];
    [cleanTask setStandardInput:[NSPipe pipe]];
    
    NSLog(@"Launching Task");
    [cleanTask launch];
    
    CGSize contextSize = CGSizeMake(iconSize, iconSize);
//    CGFloat margin = 10.0;
    
    // Make context for ql plugin
    CGContextRef context = QLThumbnailRequestCreateContext(thumbnail, contextSize, false, NULL);
    
    //Make it pretty
    if(context && iconSize > 0.0) {
        
        CGRect iconRect = CGRectMake(0.0, 0.0, iconSize, iconSize);
        
        //Draw the icon if there was one
        CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData ((__bridge CFDataRef)iconData);
        CGImageRef iconImage = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
        
        CGContextDrawImage(context, iconRect, iconImage);
        
        CFRelease(iconImage);
        summaryDictionary = nil;
        
        QLThumbnailRequestFlushContext(thumbnail, context);
        CFRelease(context);
 
    }
    
    return noErr;
}

//OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
//{
//    NSURL *ipaURL = (__bridge NSURL *)url;
//    
//    NSTask *task = [[NSTask alloc] init];
//    [task setLaunchPath:@"/usr/bin/ipaHelper"];
//    [task setArguments:[NSArray arrayWithObjects:@"summary", [ipaURL path], @"--json", @"--ql", nil]];
//    
//    NSPipe *pipe = [NSPipe pipe];
//    [task setStandardOutput: pipe];
//    //The magic line that keeps your log where it belongs
//    [task setStandardInput:[NSPipe pipe]];
//    
//    NSFileHandle *file;
//    file = [pipe fileHandleForReading];
//    
//    NSLog(@"Launching Task");
//    [task launch];
//    
//    NSData *data;
//    data = [file readDataToEndOfFile];
//    
//    NSDictionary *summaryDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers  error:nil];
//    
//    [[summaryDictionary copy] enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
//        NSLog(@"key: %@, value:%@", key, obj);
//    }];
//    
//    CGSize contextSize = CGSizeMake(100.0, 100.0);
//    CGFloat margin = 1.0;
//    
//    CGContextRef context = QLThumbnailRequestCreateContext(thumbnail, contextSize, false, NULL);
//    
//    if (context) {
//        
//        NSArray *appInfo = @[@{@"key":@"Bundle ID:",@"value":(NSString *)summaryDictionary[@"CFBundleIdentifier"]},
//                             @{@"key":@"Version:",@"value":(NSString *)summaryDictionary[@"ShortBundleVersion"]},
//                             ];
//        NSArray *profileInfo = @[@{@"key":@"Profile:",@"value":(NSString *)summaryDictionary[@"App ID Name"]},
//                                 @{@"key":@"Certificate:",@"value":(NSString *)summaryDictionary[@"Certificate Name"]},
//                                 @{@"key":@"Team Name:",@"value":(NSString *)summaryDictionary[@"Team Name"]},
//                                 @{@"key":@"Profile Expires:",@"value":(NSString *)summaryDictionary[@"Expiration Date"]},
//                                 ];
//        
//        NSMutableArray *combinedArrays = [NSMutableArray arrayWithArray:appInfo];
////        [combinedArrays addObject:@{@"key":@"",@"value":@""}];
//        [combinedArrays addObjectsFromArray:profileInfo];
//        
//        drawArrayInRectInContext2(combinedArrays, CGRectMake(margin, margin, contextSize.width - 2 * margin, contextSize.height - 2 * margin), context, 2.0, 8.0);
//        
//        QLThumbnailRequestFlushContext(thumbnail, context);
//        NSLog(@"Did it work?");
//        CFRelease(context);
//    }
//    
//    return noErr;
//}

CGFloat drawArrayInRectInContext2(NSArray *array, CGRect rect, CGContextRef context, CGFloat lineSpacing, CGFloat fontSize)
{
    NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)context flipped:NO];
    [NSGraphicsContext setCurrentContext:nsContext];
    
    //    NSMutableParagraphStyle *rightStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    //    [rightStyle setAlignment:NSRightTextAlignment];
    
    NSMutableParagraphStyle *leftStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [leftStyle setAlignment:NSLeftTextAlignment];
    [leftStyle setLineBreakMode:NSLineBreakByWordWrapping];
    [leftStyle setLineSpacing:0.0];
    
    
    NSDictionary *keyFontAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize:fontSize],
                                        NSForegroundColorAttributeName: [NSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0],
                                        NSParagraphStyleAttributeName: leftStyle,
                                        
                                        };
    
    NSDictionary *valueFontAttributes = @{  NSFontAttributeName: [NSFont systemFontOfSize:fontSize],
                                            NSForegroundColorAttributeName: [NSColor blackColor],
                                            NSParagraphStyleAttributeName: leftStyle,
                                            };
    
    __block CGFloat longestKey;
    __block CGFloat keyHeight;
    
    NSArray *keyArray = [array.copy valueForKey:@"key"];
    
    [keyArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        NSRect testRect = [key boundingRectWithSize:NSMakeSize(500.0, 100.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:keyFontAttributes];
        if (testRect.size.width > longestKey) {
            longestKey = testRect.size.width;
        }
        if (testRect.size.height > keyHeight) {
            keyHeight = testRect.size.height;
        }
    }];
    
    __block CGFloat currentY = rect.size.height + rect.origin.y;
    CGFloat startingY = currentY;
    CGFloat horizontalSpacing = 4.0;
    CGFloat startingValuePosition = rect.origin.x + longestKey + horizontalSpacing;
    CGFloat valueWidth = rect.size.width - longestKey - horizontalSpacing;
    
    [array.copy enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
        NSString *key = dict[@"key"];
        NSString *value = dict[@"value"];
        [key drawInRect:NSMakeRect(rect.origin.x, currentY - keyHeight, longestKey, keyHeight) withAttributes:keyFontAttributes];
        NSRect valueRect = [value boundingRectWithSize:NSMakeSize(valueWidth, 500.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:valueFontAttributes];
        CGFloat valueTextHeight = valueRect.size.height;
        [value drawInRect:NSMakeRect(startingValuePosition, currentY - valueTextHeight, valueWidth, valueTextHeight) withAttributes:valueFontAttributes];
        currentY -= valueTextHeight + lineSpacing;
    }];
    
    return startingY - currentY;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}

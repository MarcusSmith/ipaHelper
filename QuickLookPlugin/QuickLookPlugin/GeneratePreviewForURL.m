#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
/// Takes an array of dictionaries, each of which contain a "key" key and "value" key, and draws them in the rect in the context.  Returns the height of what it drew.
CGFloat drawArrayInRectInContext(NSArray *array, CGRect rect, CGContextRef context, CGFloat lineSpacing, CGFloat fontSize);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSURL *ipaURL = (__bridge NSURL *)url;
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/ipaHelper"];
    [task setArguments:[NSArray arrayWithObjects:@"summary", [ipaURL path], @"--json", @"--ql", @"--dont-clean", nil]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardInput:[NSPipe pipe]];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];

    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSDictionary *summaryDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers  error:nil];
    
    //I'm sure I can refactor this
    NSURL *iconURL = [NSURL URLWithString:[[NSString stringWithFormat:@"%@/icon@2x.png", summaryDictionary[@"AppDirectory"]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSError* error = nil;
    NSData *iconData = [NSData dataWithContentsOfFile:[iconURL path] options:NSDataReadingUncached error:&error];
    
//    if (!iconData) {
//        NSString *defaultIconFilepath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/QuickLookPlugin/ipaIcon.jpg"];
//        NSLog(@"%@", defaultIconFilepath);
//        iconData = [NSData dataWithContentsOfFile:defaultIconFilepath options:NSDataReadingUncached error:&error];
//        NSLog(@"Error loading image: %@", error);
//    }
    
    NSImage *imageForSize = [[NSImage alloc] initWithData: iconData];
    CGFloat iconOffset = imageForSize.size.width;
    imageForSize = nil;
    
    //Got the icon image and the summary dictionary, time to clean up
    
    NSTask *cleanTask = [[NSTask alloc] init];
    [cleanTask setLaunchPath:@"/usr/bin/ipaHelper"];
    [cleanTask setArguments:[NSArray arrayWithObjects:@"clean", [ipaURL path], nil]];
    
    pipe = [NSPipe pipe];
    [cleanTask setStandardOutput: pipe];
    [cleanTask setStandardInput:[NSPipe pipe]];
    
    [cleanTask launch];
    
    CGSize contextSize = CGSizeMake(576.0, 256.0);
    CGFloat margin = 10.0;
    
    // Make context for ql plugin
    CGContextRef context = QLPreviewRequestCreateContext(preview, contextSize, NO, NULL);
    
    //Make it pretty
    if(context) {
        
        iconOffset = iconOffset == 0.0 ? 114 : iconOffset;
        CGRect iconRect = CGRectMake(margin, (contextSize.height - iconOffset - margin), iconOffset, iconOffset);
        
        if (iconData.length) {
            //Draw the icon if there was one
            CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData ((__bridge CFDataRef)iconData);
            CGImageRef iconImage = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
            
            CGContextDrawImage(context, iconRect, iconImage);
            
            CFRelease(iconImage);
        }
        
//        CGContextSaveGState(context);
//        CGContextSetStrokeColorWithColor(context, CGColorCreateGenericRGB(0.5, 0.5, 0.5, 0.25));
//        CGContextSetLineWidth(context, 1.0);
//        CGContextStrokeRect(context, iconRect);
//        CGContextRestoreGState(context);
        
        CGFloat sectionWidth = iconOffset + 2 * margin;
        
        NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)context flipped:NO];
        [NSGraphicsContext setCurrentContext:nsContext];

        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSLeftTextAlignment];
        
        NSString *title = (NSString *)summaryDictionary[@"CFBundleName"];
        NSDictionary *titleAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize:20.0],
                                          NSForegroundColorAttributeName: [NSColor blackColor],
                                          NSParagraphStyleAttributeName: style,
                                          };
        
        NSRect testRect = [title boundingRectWithSize:NSMakeSize(500.0, 100.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:titleAttributes];
        
        CGFloat titleHeight = testRect.size.height;

        [title drawInRect:NSMakeRect(margin + sectionWidth, contextSize.height - margin * 0.5 - titleHeight, contextSize.width - margin * 2 - sectionWidth, titleHeight) withAttributes:titleAttributes];
        
        title = nil;
        
        NSString *filetype = ipaURL.pathExtension;
        NSString *kind;
        if ([filetype isEqualToString:@"ipa"]) {
            kind = @"iOS App";
        }
        else if ([filetype isEqualToString:@"app"]) {
            kind = @"Application";
        }
        else if ([filetype isEqualToString:@"xcarchive"]) {
            kind = @"Xcode Archive";
        }
        else if ([filetype isEqualToString:@"zip"]) {
            kind = @"ZIP Archive";
        }
        //TODO: Make new QL Plugin for mobileprovision
//        else if ([filetype isEqualToString:@"mobileprovision"]) {
//            kind = @"Developer Provisioning Profile";
//        }
        filetype = nil;
        
//        @{@"key":@"",@"value":(NSString *)summaryDictionary[@""]}
        
        NSArray *fileInfo = @[@{@"key":@"Name:",@"value":(NSString *)summaryDictionary[@"File"]},
                              @{@"key":@"Kind:",@"value":kind},
                              @{@"key":@"Size:",@"value":(NSString *)summaryDictionary[@"Filesize"]}
                              ];
        
        
        drawArrayInRectInContext(fileInfo, CGRectMake(margin, margin, iconOffset, contextSize.height - margin * 3 - iconOffset), context, 4.0, 8.0);
        
        kind = nil;
        fileInfo = nil;
        
        NSArray *appInfo = @[@{@"key":@"Bundle ID:",@"value":(NSString *)summaryDictionary[@"CFBundleIdentifier"]},
                             @{@"key":@"Display Name:",@"value":(NSString *)summaryDictionary[@"CFBundleDisplayName"]},
                             @{@"key":@"Short Version:",@"value":(NSString *)summaryDictionary[@"ShortBundleVersion"]},
                             @{@"key":@"Bundle Version:",@"value":(NSString *)summaryDictionary[@"CFBundleVersion"]},
                             ];
        NSArray *profileInfo = @[@{@"key":@"App ID Name:",@"value":(NSString *)summaryDictionary[@"App ID Name"]},
                                 @{@"key":@"Profile Name:",@"value":(NSString *)summaryDictionary[@"Profile Name"]},
                                 @{@"key":@"Profile Type:",@"value":(NSString *)summaryDictionary[@"Profile Type"]},
                                 @{@"key":@"Team Name:",@"value":(NSString *)summaryDictionary[@"Team Name"]},
                                 @{@"key":@"Application ID:",@"value":(NSString *)summaryDictionary[@"App Identifier"]},
                                 @{@"key":@"Profile Expires:",@"value":(NSString *)summaryDictionary[@"Expiration Date"]},
                                 @{@"key":@"Profile UUID:",@"value":(NSString *)summaryDictionary[@"UUID"]},
                                 ];
        
        NSMutableArray *combinedArrays = [NSMutableArray arrayWithArray:appInfo];
        [combinedArrays addObject:@{@"key":@"",@"value":@""}];
        [combinedArrays addObjectsFromArray:profileInfo];
        
        drawArrayInRectInContext(combinedArrays.copy, CGRectMake(margin + sectionWidth, margin, sectionWidth * 3 - 2 * margin, contextSize.height - titleHeight - margin * 2.5), context, 4.0, 10.0);
        
        profileInfo = nil;
        summaryDictionary = nil;
        
        QLPreviewRequestFlushContext(preview, context);
        CFRelease(context);
        
        
    }
    
    return noErr;
}

CGFloat drawArrayInRectInContext(NSArray *array, CGRect rect, CGContextRef context, CGFloat lineSpacing, CGFloat fontSize)
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

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
        NSTask *cleanTask = [[NSTask alloc] init];
        [cleanTask setLaunchPath:@"/usr/bin/ipaHelper"];
        [cleanTask setArguments:[NSArray arrayWithObjects:@"clean", nil]];
        
        NSPipe *pipe = [NSPipe pipe];
        [cleanTask setStandardOutput: pipe];
        [cleanTask setStandardInput:[NSPipe pipe]];
        
        [cleanTask launch];
}

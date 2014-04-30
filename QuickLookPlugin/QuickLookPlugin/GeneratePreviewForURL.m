#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{    
    //My attempt
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
    
    [[summaryDictionary copy] enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSLog(@"key: %@, value:%@", key, obj);
    }];
    
    //I'm sure I can refactor this
    NSURL *iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/icon@2x.png", summaryDictionary[@"AppDirectory"]]];
    NSLog(@"iconURL: %@", iconURL);
    NSLog(@"path: %@", [iconURL path]);
    
    NSError* error = nil;
    NSData *iconData = [NSData dataWithContentsOfFile:[iconURL path] options:NSDataReadingUncached error:&error];
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
    
    NSLog(@"Launching Task");
    [cleanTask launch];
    
    CGSize contextSize = CGSizeMake(512.0, 512.0);
    CGFloat margin = 20.0;
    
    // Make context for ql plugin
    CGContextRef context = QLPreviewRequestCreateContext(preview, contextSize, NO, NULL);
    
    //Make it pretty
    if(context) {
        
        if (iconData.length > 0) {
            CGContextSaveGState(context);
            
            //Draw the icon if there was one
            CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData ((__bridge CFDataRef)iconData);
            CGImageRef iconImage = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
            
            CGRect iconRect = CGRectMake(margin, (contextSize.height - iconOffset - 40 - margin), iconOffset, iconOffset);
            
            CGContextDrawImage(context, iconRect, iconImage);
            
            CFRelease(iconImage);
            
            CGContextSetStrokeColorWithColor(context, CGColorCreateGenericRGB(0.5, 0.5, 0.5, 0.5));
            CGContextSetLineWidth(context, 1.0);
            CGContextStrokeRect(context, iconRect);
            iconOffset += 2 * margin;
            CGPoint points[4] = { CGPointMake(0.0, contextSize.height - 40.0), CGPointMake(contextSize.width, contextSize.height - 40.0),
                CGPointMake(iconOffset, 0.0), CGPointMake(iconOffset, contextSize.height - 40.0)};
            CGContextStrokeLineSegments(context, points, 4);
            CGContextRestoreGState(context);
            
        }
        else {
            iconOffset = margin;
            CGContextSaveGState(context);
            CGContextSetStrokeColorWithColor(context, CGColorCreateGenericRGB(0.5, 0.5, 0.5, 0.5));
            CGContextSetLineWidth(context, 1.0);
            CGPoint points[2] = { CGPointMake(0.0, contextSize.height - 40.0), CGPointMake(contextSize.width, contextSize.height - 40.0)};
            CGContextStrokeLineSegments(context, points, 2);
        }
        
        NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)context flipped:NO];
        [NSGraphicsContext setCurrentContext:nsContext];

        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSCenterTextAlignment];
        
        NSString *fileName = summaryDictionary[@"App ID Name"];
        [fileName drawInRect:NSMakeRect(iconOffset, contextSize.height - 30.0, contextSize.width - iconOffset, 20.0) withAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:20.0],
                                                                                                                                        NSForegroundColorAttributeName: [NSColor blackColor],
                                                                                                                                        NSParagraphStyleAttributeName: style,
                                                                                                                                        }];
        
        
        QLPreviewRequestFlushContext(preview, context);
        CFRelease(context);
        
        
    }
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}

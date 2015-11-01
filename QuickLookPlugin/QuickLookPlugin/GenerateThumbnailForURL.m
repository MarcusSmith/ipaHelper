#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    NSURL *ipaURL = (__bridge NSURL *)url;
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/local/bin/ipaHelper"];
    [task setArguments:[NSArray arrayWithObjects:@"summary", [ipaURL path], @"--json", @"--dont-clean", nil]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    //The magic line that keeps your log where it belongs
    [task setStandardInput:[NSPipe pipe]];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSDictionary *summaryDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers  error:nil];
    
    NSURL *iconURL = [NSURL URLWithString:[[NSString stringWithFormat:@"%@/icon@2x.png", summaryDictionary[@"AppDirectory"]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSError* error = nil;
    NSData *iconData = [NSData dataWithContentsOfFile:[iconURL path] options:NSDataReadingUncached error:&error];
    NSImage *imageForSize = [[NSImage alloc] initWithData: iconData];
    CGFloat iconSize = imageForSize.size.width;
    imageForSize = nil;
    
    //Got the icon image, time to clean up
    
    NSTask *cleanTask = [[NSTask alloc] init];
    [cleanTask setLaunchPath:@"/usr/local/bin/ipaHelper"];
    [cleanTask setArguments:[NSArray arrayWithObjects:@"clean", [ipaURL path], nil]];
    
    pipe = [NSPipe pipe];
    [cleanTask setStandardOutput: pipe];
    [cleanTask setStandardInput:[NSPipe pipe]];
    
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
        
        //Round the corners
        CGContextBeginPath(context);
        addRoundedRectToPath(context, iconRect, 5, 5);
        CGContextClosePath(context);
        CGContextClip(context);
        
        CGContextDrawImage(context, iconRect, iconImage);
        
        CFRelease(iconImage);
        summaryDictionary = nil;
        
        QLThumbnailRequestFlushContext(thumbnail, context);
        CFRelease(context);
 
    }
    
    return noErr;
}

void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
	float fw, fh;
	if (ovalWidth == 0 || ovalHeight == 0) {
		CGContextAddRect(context, rect);
		return;
	}
	CGContextSaveGState(context);
	CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
	CGContextScaleCTM (context, ovalWidth, ovalHeight);
	fw = CGRectGetWidth (rect) / ovalWidth;
	fh = CGRectGetHeight (rect) / ovalHeight;
	CGContextMoveToPoint(context, fw, fh/2);
	CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
	CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
	CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
	CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
	CGContextClosePath(context);
	CGContextRestoreGState(context);
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
        NSTask *cleanTask = [[NSTask alloc] init];
        [cleanTask setLaunchPath:@"/usr/local/bin/ipaHelper"];
        [cleanTask setArguments:[NSArray arrayWithObjects:@"clean", nil]];
        
        NSPipe *pipe = [NSPipe pipe];
        [cleanTask setStandardOutput: pipe];
        [cleanTask setStandardInput:[NSPipe pipe]];
        
        [cleanTask launch];
}

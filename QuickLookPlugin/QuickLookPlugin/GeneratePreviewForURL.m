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
    
    NSURL *iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/Icon.png", summaryDictionary[@"AppDirectory"]]];
    NSLog(@"iconURL: %@", iconURL);
    NSLog(@"path: %@", [iconURL path]);
    
    NSError* error = nil;
//    NSData *iconData = [NSData dataWithContentsOfURL:iconURL options:NSDataReadingUncached error:&error];
    NSData *iconData = [NSData dataWithContentsOfFile:[iconURL path] options:NSDataReadingUncached error:&error];
    NSImage *imageForSize = [[NSImage alloc] initWithData: iconData];
    
    if (error) {
        NSLog(@"Error: %@", error);
    } else {
        NSLog(@"Data has loaded successfully.");
    }
    
    NSLog(@"icon data: %@", iconData);
    
//	NSImage *icon = [[NSImage alloc] initWithData: iconData];
    
    //Got the image!!
    
    NSTask *cleanTask = [[NSTask alloc] init];
    [cleanTask setLaunchPath:@"/usr/bin/ipaHelper"];
    [cleanTask setArguments:[NSArray arrayWithObjects:@"clean", [ipaURL path], nil]];
    
    pipe = [NSPipe pipe];
    [cleanTask setStandardOutput: pipe];
    //The magic line that keeps your log where it belongs
    [cleanTask setStandardInput:[NSPipe pipe]];
    
    NSLog(@"Launching Task");
    [cleanTask launch];
    
    CGContextRef cgContext = QLPreviewRequestCreateContext(preview, CGSizeMake(640, 320), NO, NULL);
    
    if(cgContext) {
        
        CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData ((__bridge CFDataRef)iconData);
        CGImageRef iconImage = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
        
        CGContextDrawImage(cgContext,CGRectMake(0, 320 - imageForSize.size.height, imageForSize.size.width, imageForSize.size.width), iconImage);
        
        QLPreviewRequestFlushContext(preview, cgContext);
        
        CFRelease(cgContext);
        CFRelease(iconImage);
    }
    
//    CIImage *icon = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:MyURL]]];
    
    
//    QLPreviewRequestFlushContext(preview, cgContext);
    
//    QLPreviewRequestSetDataRepresentation(preview,(__bridge CFDataRef)data,kUTTypePlainText,NULL);
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}

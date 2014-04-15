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
    [task setArguments:[NSArray arrayWithObjects:@"summary", [ipaURL path], nil]];
    
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
    
    NSLog(@"Data: %@", data);
    
//    CGContextRef cgContext = QLPreviewRequestCreateContext(<#QLPreviewRequestRef preview#>, <#CGSize size#>, <#Boolean isBitmap#>, <#CFDictionaryRef properties#>);
//    QLPreviewRequestFlushContext(<#QLPreviewRequestRef preview#>, <#CGContextRef context#>);
    
    QLPreviewRequestSetDataRepresentation(preview,(__bridge CFDataRef)data,kUTTypePlainText,NULL);
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}

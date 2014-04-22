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
    
    NSURL *iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/icon.png", summaryDictionary[@"AppDirectory"]]];
    NSLog(@"iconURL: %@", iconURL);
    
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
    
//    CGContextRef cgContext = QLPreviewRequestCreateContext(preview, CGSizeMake(100, 100), NO, NULL);
//    QLPreviewRequestFlushContext(preview, cgContext);
    
    QLPreviewRequestSetDataRepresentation(preview,(__bridge CFDataRef)data,kUTTypePlainText,NULL);
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}

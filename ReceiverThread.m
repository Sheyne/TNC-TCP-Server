//
//  ReceiverThread.m
//  test
//
//  Created by Sheyne Anderson on 3/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ReceiverThread.h"


@implementation ReceiverThread
@synthesize delegate;
-(void)stop{
	isRunning=NO;
}
-(void)start{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	isRunning=YES;
	while (isRunning) {
		pipe = [NSPipe pipe];
		task = [[NSTask alloc] init];
		[task setLaunchPath:@"/usr/bin/nc"];
		[task setArguments:[NSArray arrayWithObjects:@"-l", @"8500",nil]];
		[task setStandardOutput: pipe];	
		[task launch];
		file = [pipe fileHandleForReading];
		data = [file readDataToEndOfFile];
		[task release];
		[delegate performSelectorOnMainThread:@selector(receivedMessage:)
								   withObject:[[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease]
								waitUntilDone:NO];
		[data release];
	}
	
    [pool drain];
	

}
@end

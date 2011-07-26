//
//  ReceiverThread.h
//  test
//
//  Created by Sheyne Anderson on 3/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ReceiverThread : NSObject {
	BOOL isRunning;
	NSTask *task;
	NSPipe *pipe;
	NSFileHandle *file;
	NSData *data;
	NSString *string;
	id delegate;
}
@property (nonatomic,retain) id delegate;
-(void)start;
-(void)stop;
@end

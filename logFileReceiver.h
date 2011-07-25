//
//  logFileReceiver.h
//  TNC_TCP_Server
//
//  Created by Sheyne Anderson on 7/8/11.
//  Copyright 2011 Sheyne Anderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "/usr/local/include/fap.h"
#import "UKKQueue.h"
#import "ParsedPacketProtocol.h"

@interface LogFileReceiver : NSObject {
	id<ParsedPacketProtocol>delegate;
}

@property (retain) id<ParsedPacketProtocol>delegate;

-(void)watcher:(UKKQueue*)kq receivedNotification:(NSString *)note forPath:(NSString*)path;

@end

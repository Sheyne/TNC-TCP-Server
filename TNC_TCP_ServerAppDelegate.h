//
//  TNC_TCP_ServerAppDelegate.h
//  TNC_TCP_Server
//
//  Created by Sheyne Anderson on 7/8/11.
//  Copyright 2011 Sheyne Anderson. All rights reserved.
//

#import "AsyncSocket.h"

#import <Cocoa/Cocoa.h>
#include "/usr/local/include/fap.h"
#import "ParsedPacketProtocol.h"
#import "logFileReceiver.h"

@interface TNC_TCP_ServerAppDelegate : NSObject <AsyncSocketDelegate,NSApplicationDelegate,ParsedPacketProtocol> {
    NSWindow *window;
	AsyncSocket *connection;
	LogFileReceiver *recvr;
	NSData *lastSent;
	UKKQueue *queue;
	int port;
	NSMutableSet *sockets;
	NSString *logfile;
}

@property (copy) NSData *lastSent;
@property (assign) IBOutlet NSWindow *window;
@property (assign) int port;
@property (retain) NSString *logfile;


@end

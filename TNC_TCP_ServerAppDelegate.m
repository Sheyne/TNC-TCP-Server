//
//  TNC_TCP_ServerAppDelegate.m
//  TNC_TCP_Server
//
//  Created by Sheyne Anderson on 7/8/11.
//  Copyright 2011 Sheyne Anderson. All rights reserved.
//

#import "TNC_TCP_ServerAppDelegate.h"

#define MAIN_TAG 98473
#define PRIVATE_TAG 94473

@implementation TNC_TCP_ServerAppDelegate

@synthesize window;
@synthesize lastSent;
@synthesize port;
@synthesize logfile;

-(BOOL)onSocketWillConnect:(AsyncSocket *)sock{
	NSLog(@"accepting connection on socket: %@", sock.connectedHost);
	if ([sock canSafelySetDelegate]) {
		sock.delegate=self;
	}
	[sockets addObject:sock];
	[sock writeData:self.lastSent withTimeout:-1 tag:PRIVATE_TAG];
	return YES;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if ([keyPath isEqualToString:@"port"]) {
		NSLog(@"setting port to: %d",self.port);
		[connection writeData:[[NSString stringWithFormat:@"{\"Port change notification\":%d}\n",self.port]dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:MAIN_TAG];
		//eventually use disconnect after writing
		
		[connection disconnect];
		NSError * err;
		[connection acceptOnPort:self.port error:&err];
		if (err) {
			NSLog(@"Error changing port: %@", [err userInfo]);
		}
	}
	if ([keyPath isEqualToString:@"logfile"]) {
		NSLog(@"setting logfile from: %@ to: %@",[change valueForKey:@"old"],self.logfile);
		if ([change valueForKey:@"old"]!=[NSNull null]) {
			[queue removePath: [change valueForKey:@"old"]];
			//sloppy fix later
		}
		[queue addPath: [change valueForKey:@"new"]];
		[recvr watcher:nil receivedNotification:nil forPath:self.logfile];	
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	sockets=[[NSMutableSet alloc] initWithCapacity:1];
	connection=[[AsyncSocket alloc]initWithDelegate:self];
	recvr=[[LogFileReceiver alloc]init];
	recvr.delegate=self;
	queue=[[UKKQueue alloc] init];
	[queue setDelegate:recvr];
	queue.alwaysNotify=YES;
	[self addObserver:self forKeyPath:@"port" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"logfile" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
	self.port=54730;
	self.logfile=[@"~/Documents/tnc.log" stringByExpandingTildeInPath];
}


-(void)gotParsedPacket:(NSString*)msg{
	self.lastSent=[msg dataUsingEncoding:NSASCIIStringEncoding];
	if (self.lastSent){
		NSLog(@"sending: %s",self.lastSent.bytes);
		for (AsyncSocket *sock in sockets) {
			[sock writeData:self.lastSent withTimeout:-1 tag:MAIN_TAG];
		}
	}
}

@end

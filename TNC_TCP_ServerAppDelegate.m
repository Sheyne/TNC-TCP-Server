//
//  TNC_TCP_ServerAppDelegate.m
//  TNC_TCP_Server
//
//  Created by Sheyne Anderson on 7/8/11.
//  Copyright 2011 Sheyne Anderson. All rights reserved.
//

#import "TNC_TCP_ServerAppDelegate.h"

@implementation TNC_TCP_ServerAppDelegate

@synthesize window;
@synthesize lastSent;
@synthesize port;
@synthesize logfile;

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if ([keyPath isEqualToString:@"port"]) {
		NSLog(@"setting port to: %d",self.port);
		[connection send:[[NSString stringWithFormat:@"{\"Port change notification\":%d}\n",self.port]dataUsingEncoding:NSASCIIStringEncoding]];
		[connection listenOnPort:self.port];
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
	connection=[[TCP alloc]init];
	connection.delegate=self;
	connection.repeatMode=YES;
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

-(void)connectionReceived:(CFSocketRef)socket{
	NSLog(@"Connection received, sending: %@",self.lastSent);
	if (self.lastSent)
		[connection send:[self.lastSent dataUsingEncoding:NSASCIIStringEncoding] socket:socket];
}
-(void)gotParsedPacket:(NSString*)msg{
	self.lastSent=msg;
	NSLog(@"sending: %@",self.lastSent);
	[connection send:[self.lastSent dataUsingEncoding:NSASCIIStringEncoding]];
}

@end

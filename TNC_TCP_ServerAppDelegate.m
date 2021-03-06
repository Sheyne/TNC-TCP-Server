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

static void * ConnectionDisconnect=@"Disconnect Connections";
static void * ConnectionConnect=@"Accept Connections";

@interface TNC_TCP_ServerAppDelegate (Private)

-(void)ensureConnectionsAreClosed;

@end


@implementation TNC_TCP_ServerAppDelegate

@synthesize isConnected=_connection_is_connected;
@synthesize window;
@synthesize lastSent;
@synthesize port;
@synthesize logfile;
@synthesize connection;

-(BOOL)onSocketWillConnect:(AsyncSocket *)sock{
	NSLog(@"accepting connection on socket: %@", sock.connectedHost);
	[sockets addObject:sock];
	[sock writeData:self.lastSent withTimeout:-1 tag:PRIVATE_TAG];
	return YES;
}

-(void)ensureConnectionsAreClosed{
	if (self.connection) {
		self.connection=nil;
	}
	for (AsyncSocket *s in sockets) {
		[s disconnect];
	}
	[sockets removeAllObjects];
}

-(IBAction)acceptConnections:(id)sender{
	if (self.isConnected==ConnectionConnect) {
		[self ensureConnectionsAreClosed];
		self.connection=[[[AsyncSocket alloc]initWithDelegate:self] autorelease];
		NSError * err=nil;
		[connection acceptOnPort:self.port error:&err];
		if (err) {
			NSLog(@"Error changing port: %@", err);
			self.isConnected=ConnectionConnect;
			return;
		}
		self.isConnected=ConnectionDisconnect;
		NSLog(@"Successfully set port to %d", self.port);
	}else{
		[self ensureConnectionsAreClosed];
		self.isConnected=ConnectionConnect;
	}
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
	return YES;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if ([keyPath isEqualToString:@"port"]) {
		//NSLog(@"setting port to: %d",self.port);
		//[connection writeData:[[NSString stringWithFormat:@"{\"Port change notification\":%d}\r\n",self.port]dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:MAIN_TAG];
		//eventually use disconnect after writing
		
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
	self.isConnected=ConnectionConnect;
	sockets=[[NSMutableSet alloc] initWithCapacity:1];
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
	self.lastSent=[[msg stringByAppendingString:@"\r\n"] dataUsingEncoding:NSASCIIStringEncoding];
	if (self.lastSent&&connection.isConnected){
		NSLog(@"sending: %s",self.lastSent.bytes);
		for (AsyncSocket *sock in sockets) {
			[sock writeData:self.lastSent withTimeout:-1 tag:MAIN_TAG];
		}
	}
}

@end

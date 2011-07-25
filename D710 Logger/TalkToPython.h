//
//  TalkToPython.h
//  TNC_TCP_Server
//
//  Created by Sheyne Anderson on 7/10/11.
//  Copyright 2011 Sheyne Anderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Python/Python.h>

@interface TalkToPython : NSObject {
	PyObject *tnc_startup;
	PyObject *tnc_shutdown;
	PyObject *tnc_script;
	PyObject *connectToSocket;
	PyObject *listen;
	BOOL isListening;
}

@property (assign) BOOL	isListening;

-(TalkToPython*)initWithLogFile:(NSString*)lf port:(NSString*)port;

-(void)sendStartup;
-(void)sendShutdown;
-(void)sendScript:(NSString*)script;


@end

//
//  TalkToPython.m
//  TNC_TCP_Server
//
//  Created by Sheyne Anderson on 7/10/11.
//  Copyright 2011 Sheyne Anderson. All rights reserved.
//

#import "TalkToPython.h"

@interface TalkToPython ()

-(void)internalListen;
@property (assign) PyObject *tnc_startup;
@property (assign) PyObject *tnc_shutdown;
@property (assign) PyObject *tnc_script;
@property (assign) PyObject *connectToSocket;
@property (assign) PyObject *listen;

@end


@implementation TalkToPython

@synthesize tnc_startup;
@synthesize tnc_shutdown;
@synthesize tnc_script;      //lines
@synthesize connectToSocket; //ser,log
@synthesize listen;
@synthesize isListening;

-(TalkToPython*)initWithLogFile:(NSString*)lf port:(NSString*)port{
	self.isListening=FALSE;
	Py_Initialize();
	const char* script=[[[NSBundle mainBundle] pathForResource:@"D710 Logger" ofType:@"py"] UTF8String];
	FILE* fp=fopen(script, "r");
	PyRun_SimpleFileExFlags(fp,script,0,NULL);
	PyObject* main_module = PyImport_AddModule("__main__");
	self.connectToSocket = PyObject_GetAttrString(main_module, "connectToSocket");
	self.tnc_startup = PyObject_GetAttrString(main_module, "tnc_startup");
	self.tnc_script = PyObject_GetAttrString(main_module, "tnc_script");
	self.tnc_shutdown = PyObject_GetAttrString(main_module, "tnc_shutdown");
	self.listen = PyObject_GetAttrString(main_module, "listen");
	
	if(self.connectToSocket && PyCallable_Check(self.connectToSocket) &&
	   self.listen && PyCallable_Check(self.listen)){		
		PyObject *theargs = PyTuple_New(2);
		PyTuple_SetItem(theargs, 0, PyString_FromString([port UTF8String]));
		PyTuple_SetItem(theargs, 1, PyString_FromString([lf UTF8String]));
		
		PyObject *result =(PyObject*) PyObject_CallObject(self.connectToSocket, theargs);
		
		char* res=PyString_AsString(result);
		
		if(strcmp("Success", res) != 0){
			NSLog(@"Error opening serial: %s",res);
			return nil;
		}
		[self performSelectorInBackground:@selector(internalListen) withObject:nil];
	}
	
}

-(void)sendStartup{
}
-(void)sendShutdown{

}
-(void)sendScript:(NSString*)script{

}

-(void)internalListen{
	self.isListening=TRUE;
	PyObject_CallObject(self.listen, NULL);
	self.isListening=FALSE;
}

@end

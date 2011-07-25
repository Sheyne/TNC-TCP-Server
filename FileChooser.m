//
//  FileChooser.m
//  Emailer
//
//  Created by Sheyne Anderson on 12/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FileChooser.h"


@implementation FileChooser
+(void)getFileForTextField:(NSTextField *)textField{
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
	[openDlg setCanChooseFiles:YES];
	[openDlg setCanChooseDirectories:NO];
	[openDlg setAllowsMultipleSelection:NO];
	if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
	{
		NSArray* files = [openDlg filenames];
		textField.stringValue=[files objectAtIndex:0];
	}
}
@end

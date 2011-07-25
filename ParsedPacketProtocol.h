//
//  ParsedPacketProtocol.h
//  TNC_TCP_Server
//
//  Created by Sheyne Anderson on 7/8/11.
//  Copyright 2011 Sheyne Anderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol ParsedPacketProtocol<NSObject>

-(void)gotParsedPacket:(NSString*)packet;

@end

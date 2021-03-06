//
//  logFileReceiver.m
//  TNC_TCP_Server
//
//  Created by Sheyne Anderson on 7/8/11.
//  Copyright 2011 Sheyne Anderson. All rights reserved.
//

#import "logFileReceiver.h"


void addFloat(NSMutableString*s, char*key, double*value){
	[s appendFormat:@"\"%s\":%f,", key, *value];
}
void addString(NSMutableString*s, char*key, char*value){
	[s appendFormat:@"\"%s\":\"%s\",", key, value];
}

int checksumNMEA(char *packet){
	int base=0;
	short done=0,start=0;
	while (!done) {
		switch (*packet) {
			case '$':
				start=1;
				break;
			case '*':
				done=1;
				break;
			default:
				if (start)
					base^=*packet;
				break;
		}
		packet++;
	}
	int scanned;
	sscanf(packet, "%x", &scanned);
	return base==scanned;
}

int isPrefixOf(char * a, char *b){
	while (*a!='\0')
		if(*a++!=*b++)
			return 0;
	return 1;
}

void strip(char * str){
	/*
	 Takes a string and strips of trailing whitespace.
	 */
	int end=strlen(str)-1;
	while (str[end]=='\n'||str[end]=='\r'||str[end]==' ')
		end--;
	str[end+1]='\0';
}

void commaLooper(char *input, void (^allblocks[])(char *)){
	char *curr=input, *lastStop=input,*send;
	BOOL exit=NO;
	int idx=0;
	while (!exit) {
		switch (*curr) {
			case '\0':
				exit=1;
			case ',':
				send=calloc(curr-lastStop, sizeof(char));
				memcpy(send, lastStop, (curr-lastStop)*sizeof(char));
				send[(curr-lastStop)*sizeof(char)]='\0';
				lastStop=curr+1;
				if (*send!='\0')
					allblocks[idx](send);
				idx++;
				break;
			default:
				break;
		}
		curr++;
	}
}

fap_packet_t* parse_pkwdpos(char*input,int input_len){
	fap_packet_t*result=malloc(sizeof(fap_packet_t));
	
	memset(result,0,sizeof(fap_packet_t));
	
	if (isPrefixOf("$PKWDPOS", input)) {
		result->error_code = malloc(sizeof(fap_error_code_t));
		result->nmea_checksum_ok=malloc(sizeof(short));
		if (checksumNMEA(input)||TRUE) {
			*result->nmea_checksum_ok=1;
			result->error_code=NULL;
		}else {
			*result->nmea_checksum_ok=0;
			*result->error_code=fapNMEA_INV_CKSUM;
		}
		
		__block char lockQuality,ns,ew,check1,check2;
		__block int month,day,year,hour,min;
		__block double latDegs,lonDegs,latMins,lonMins,landSpeed,bearing,second,altitude;


		
		void (^allblocks[])(char *)={
			  ^(char *part){//do nothing with $PKWDPOS
			},^(char *part){//take hour minute and second of UTC lock time
				sscanf(part, "%2d%2d%lf", &hour,&min,&second);
			},^(char *part){//get lock quality
				sscanf(part, "%c", &lockQuality);
				result->gps_fix_status=malloc(sizeof(short));
				*(result->gps_fix_status)=lockQuality=='A';
			},^(char *part){//lat degrees minutes
				sscanf(part, "%2lf%lf", &latDegs,&latMins);
			},^(char *part){//lat north south
				sscanf(part, "%c", &ns);
				result->latitude=malloc(sizeof(double));
				latDegs+=latMins/60;
				latDegs*=ns=='N'||ns=='n'?1:-1;
				*(result->latitude)=latDegs;
			},^(char *part){//lon degrees minutes
				sscanf(part, "%3lf%lf", &lonDegs,&lonMins);
			},^(char *part){//lon east west
				sscanf(part, "%c", &ew);
				result->longitude=malloc(sizeof(double));
				lonDegs+=lonMins/60;
				lonDegs*=ew=='E'||ns=='e'?1:-1;
				*(result->longitude)=lonDegs;
			},^(char *part){//landspeed
				sscanf(part, "%lf", &landSpeed);
				result->speed=malloc(sizeof(double));
				*(result->speed)=landSpeed*1.852;
			},^(char *part){//bearing
				sscanf(part, "%lf", &bearing);
				result->course=malloc(sizeof(int));
				*(result->course)=(int)bearing;
			},^(char *part){//utc month day year
				sscanf(part, "%2d%2d%2d", &month,&day,&year);
				struct tm packetTime;
				//years since 1900
				packetTime.tm_year=100+year;
				packetTime.tm_mon=month-1;
				packetTime.tm_mday=day;
				packetTime.tm_hour=hour;
				packetTime.tm_min=min;
				packetTime.tm_sec=round(second);
				result->timestamp=malloc(sizeof(time_t));
				*(result->timestamp)=mktime(&packetTime);
			},^(char *part){//altitude and checksum bits
				sscanf(part, "%lf*%c%c", &altitude,&check1,&check2);
				result->altitude=malloc(sizeof(double));
				*(result->altitude)=altitude;
			}
		};
		
		commaLooper(input, allblocks);


		result->path_len=0;
	}
	return result;
}

//Example gprmc packet
//$GPRMC,204038.000,A,4111.7388,N,11156.3633,W,0.00,68.07,110611,,D*4D



@implementation LogFileReceiver

@synthesize delegate;

-(void)watcher:(UKKQueue*)kq receivedNotification:(NSString *)note forPath:(NSString*)path{
	//NSLog(@"notification: %@ for path: %@",note,path);
	FILE*fp;
	if(!(fp=fopen([path UTF8String], "r")))
		return;
	if (note ==UKFileWatcherDeleteNotification) {
		[kq addPath:path];
		return;
	}

	#define GEO_LOG_MAX_LINE_LENGTH 400
	char buff1[GEO_LOG_MAX_LINE_LENGTH];
	char buff2[GEO_LOG_MAX_LINE_LENGTH];
	char tmp[GEO_LOG_MAX_LINE_LENGTH];
	char *buff, *oldbuff, *tmpbuff;
	buff=buff1;
	oldbuff=buff2;
	int i;
	int buffsize=GEO_LOG_MAX_LINE_LENGTH;
	//scan to end of file
	while(fgets(oldbuff, buffsize, fp)){
		tmpbuff=oldbuff;
		oldbuff=buff;
		buff=tmpbuff;
	}
	fclose(fp);
	//oldbuff, 2nd to last line
	//buff last line
	strip(oldbuff);
	strip(buff);
	
	
	fap_packet_t* packet;	
	
	fap_init();
	
	char *GPRMC_PACKET_CALLSIGN="D710";
	
	
	if (isPrefixOf("$PKWDPOS", buff)) {
		//PKWDPOS is not recognized by libfap. It is very simple and very similar 
		//GPRMC. I wrote my own parser `parse_pkwdpos'.
		buffsize=strlen(buff)+1;
		packet=parse_pkwdpos(buff, buffsize);
		buffsize=strlen(GPRMC_PACKET_CALLSIGN)+1;
		packet->src_callsign=malloc(buffsize);
		memcpy(packet->src_callsign,GPRMC_PACKET_CALLSIGN,buffsize);
	}else{
		if (isPrefixOf("$GPRMC", buff)) {
			sprintf(tmp,"%s>TARGET:%s",GPRMC_PACKET_CALLSIGN,buff);
			buff=tmp;
		}
		buffsize=strlen(buff);
		packet = fap_parseaprs(buff, buffsize, 0);
	}
	if ( packet->error_code )
	{
		fap_explain_error(*packet->error_code,tmp);
		NSLog(@"Failed to parse packet. %s\n",tmp);
	}
	else if ( packet->src_callsign )
	{
	
		NSMutableString*message=[[NSMutableString alloc] initWithCapacity:200];
		
		[message appendFormat:@"{\"%s\":{",packet->src_callsign];
		
		// "# MS_SINCE_EPOCH %a %b %d %H:%M:%S %Z %Y"
		//extract MS_SINCE_EPOCH
		//skip past "# " at start of time string
		oldbuff+=2;
		int end=0;
		//stop at first space
		while (oldbuff[end]!=' ')
			end++;
		oldbuff[end]='\0';
		
		//timeDifference is the time since the last packet as expressed in seconds
		time_t tim=(time_t)atoi(oldbuff);
		oldbuff-=2;
		if (tim) {
			double dtime=(double)tim;
			addFloat(message, "time",&dtime);
		}
		if (packet->latitude)
			addFloat(message, "latitude",packet->latitude);
		
		if (packet->longitude)
			addFloat(message, "longitude",packet->longitude);
		
		if (packet->altitude)
			addFloat(message, "altitude",packet->altitude);
		
		if (packet->message)
			addString(message, "message", packet->message);
		if (packet->comment)
			addString(message, "comment", packet->comment);
		[message appendFormat:@"\"path\":["];
		char *comma="";
		for (i=0;i<packet->path_len;i++){
			[message appendFormat:@"%s\"%s\"",comma,packet->path[i]];
			comma=",";
		}
		[message appendFormat:@"]}}\n"];
		if([self.delegate respondsToSelector:@selector(gotParsedPacket:)]){
			[self.delegate gotParsedPacket:message];
		}
		[message release];
	}
	
	fap_free(packet);
	fap_cleanup();
}
@end

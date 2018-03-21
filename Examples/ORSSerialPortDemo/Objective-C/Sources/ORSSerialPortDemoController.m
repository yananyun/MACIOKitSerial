//
//  ORSSerialPortDemoController.m
//  ORSSerialPortDemo
//
//  Created by Andrew R. Madsen on 6/27/12.
//	Copyright (c) 2012-2014 Andrew R. Madsen (andrew@openreelsoftware.com)
//
//	Permission is hereby granted, free of charge, to any person obtaining a
//	copy of this software and associated documentation files (the
//	"Software"), to deal in the Software without restriction, including
//	without limitation the rights to use, copy, modify, merge, publish,
//	distribute, sublicense, and/or sell copies of the Software, and to
//	permit persons to whom the Software is furnished to do so, subject to
//	the following conditions:
//
//	The above copyright notice and this permission notice shall be included
//	in all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#define POLY 0xa001

#import "ORSSerialPortDemoController.h"
#import "ORSSerialPortManager.h"

@implementation ORSSerialPortDemoController

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
		self.availableBaudRates = @[@300, @1200, @2400, @4800, @9600, @14400, @19200, @28800, @38400, @57600, @115200, @230400];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
		[nc addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];
		
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
		[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
#endif
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

// Private
- (NSString *)lineEndingString
{
	NSDictionary *map = @{@0: @"\r", @1: @"\n", @2: @"\r\n"};
	NSString *result = map[@(self.lineEndingPopUpButton.selectedTag)];
	return result ?: @"\n";
}

- (IBAction)send:(id)sender
{
	NSString *string = self.sendTextField.stringValue;
	if (self.shouldAddLineEnding && ![string hasSuffix:[self lineEndingString]]) {
		string = [string stringByAppendingString:[self lineEndingString]];
	}
	
    
  unsigned char* dataP= [self readyData:string];
    
    NSData *dataToSend =[NSData dataWithBytes:dataP length:strlen(dataP)];
    
	[self.serialPort sendData:dataToSend];
}

- (IBAction)returnPressedInTextField:(id)sender
{
	[self.sendButton performClick:sender];
}

- (IBAction)openOrClosePort:(id)sender
{
	self.serialPort.isOpen ? [self.serialPort close] : [self.serialPort open];
}

- (IBAction)clear:(id)sender
{
	self.receivedDataTextView.string = @"";
}

#pragma mark - ORSSerialPortDelegate Methods

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
	self.openCloseButton.title = @"Close";
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
	self.openCloseButton.title = @"Open";
}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if ([string length] == 0) return;
	[self.receivedDataTextView.textStorage.mutableString appendString:string];
	[self.receivedDataTextView setNeedsDisplay:YES];
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
	// After a serial port is removed from the system, it is invalid and we must discard any references to it
	self.serialPort = nil;
	self.openCloseButton.title = @"Open";
}

- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
	NSLog(@"Serial port %@ encountered an error: %@", serialPort, error);
}

#pragma mark - NSUserNotificationCenterDelegate

#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[center removeDeliveredNotification:notification];
	});
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
	return YES;
}

#endif

#pragma mark - Notifications

- (void)serialPortsWereConnected:(NSNotification *)notification
{
	NSArray *connectedPorts = [notification userInfo][ORSConnectedSerialPortsKey];
	NSLog(@"Ports were connected: %@", connectedPorts);
	[self postUserNotificationForConnectedPorts:connectedPorts];
}
-(unsigned char*)readyData:(NSString*)dataStr
{
    
    
    
    uint8_t qiandao = 0xFF;
    uint8_t qishi[2];
    qishi[0] = 0xFF;
    qishi[1] = 0xAA;
    uint8_t fasongConfirmed = 0x07;
    uint8_t fasongNOConfirmed = 0x08;
    uint8_t duquDeviceSate = 0x03;
    
    /*
     需要 准备命令字
     */
    uint8_t command =fasongNOConfirmed|0xC0;
    /*
      发送的数据报文的长度
     */
    
    
    
    
 const  char* data = [dataStr cStringUsingEncoding:NSASCIIStringEncoding];


    
    uint8_t length = strlen((const char*)data);
    
    
    uint32_t crc = ModBusCRC((unsigned char*)data, length);
    
    uint8_t end = 0x40;
    int sum = sizeof(qiandao)+sizeof(qishi)+sizeof(command)+sizeof(length)+sizeof(data)+sizeof(crc)+sizeof(end);
    
    char* dataP = malloc(sum*sizeof(char));
    char* start = dataP;
    snprintf(dataP, 8,"%x", qiandao);
    dataP = dataP + 2;
    snprintf(dataP, 8,"%x", qishi[0]);
    dataP = dataP + 2;
    snprintf(dataP, 8,"%x", qishi[1]);
      dataP = dataP + 2;
    snprintf(dataP, 8,"%2x", command);
      dataP = dataP + 2;
    snprintf(dataP, 8,"%2x", length);
      dataP = dataP + 2;
    strcpy(dataP, (char*)data);
    dataP= dataP + length;
    
    snprintf(dataP, 8, "%x",crc);
    dataP = dataP + 4;
    snprintf(dataP++, 8, "%x",end);
    
    
    
    return (unsigned char*)start;
    
    
    
    
}
- (void)serialPortsWereDisconnected:(NSNotification *)notification
{
	NSArray *disconnectedPorts = [notification userInfo][ORSDisconnectedSerialPortsKey];
	NSLog(@"Ports were disconnected: %@", disconnectedPorts);
	[self postUserNotificationForDisconnectedPorts:disconnectedPorts];
	
}

- (void)postUserNotificationForConnectedPorts:(NSArray *)connectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
	if (!NSClassFromString(@"NSUserNotificationCenter")) return;
	
	NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
	for (ORSSerialPort *port in connectedPorts)
	{
		NSUserNotification *userNote = [[NSUserNotification alloc] init];
		userNote.title = NSLocalizedString(@"Serial Port Connected", @"Serial Port Connected");
		NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was connected to your Mac.", @"Serial port connected user notification informative text");
		userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
		userNote.soundName = nil;
		[unc deliverNotification:userNote];
	}
#endif
}

- (void)postUserNotificationForDisconnectedPorts:(NSArray *)disconnectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
	if (!NSClassFromString(@"NSUserNotificationCenter")) return;
	
	NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
	for (ORSSerialPort *port in disconnectedPorts)
	{
		NSUserNotification *userNote = [[NSUserNotification alloc] init];
		userNote.title = NSLocalizedString(@"Serial Port Disconnected", @"Serial Port Disconnected");
		NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was disconnected from your Mac.", @"Serial port disconnected user notification informative text");
		userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
		userNote.soundName = nil;
		[unc deliverNotification:userNote];
	}
#endif
}


#pragma mark - Properties

- (void)setSerialPort:(ORSSerialPort *)port
{
	if (port != _serialPort)
	{
		[_serialPort close];
		_serialPort.delegate = nil;
		
		_serialPort = port;
		
		_serialPort.delegate = self;
	}
}


unsigned short ModBusCRC(unsigned char *buf,unsigned int lenth) {
    int i,j;
    unsigned short crc;
    for(i=0,crc=0xffff;i< lenth;i++) {
       
        crc ^= buf[i];
        
        for(j=0;j<8;j++) {
            if(crc&0x01)
            {
                crc = (crc >> 1) ^ POLY;
            }
            else{
              crc >>= 1;
            }
        }
            
            return crc;
    }
}
        
@end
        
        
        
        
        
        
        

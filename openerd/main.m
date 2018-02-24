@import Foundation;
#import "../HBLOHandlerController.h"
#import "../HBLOOpenOperation.h"
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>

void ReceivedRelayedNotification(CFMachPortRef port, void *bytes, CFIndex size, void *info) {
	LMMessage *request = bytes;
	mach_port_t replyPort = request->head.msgh_remote_port;

	// check that we aren’t being given a corrupt message
	if (!LMDataWithSizeIsValidMessage(request, size)) {
		HBLogError(@"received a bad message? size = %li", size);
		
		// send a blank reply, free the buffer, and return
		LMSendReply(replyPort, NULL, 0);
		LMResponseBufferFree(bytes);
		return;
	}

	// translate the message to NSData, then pass through the unarchiver to get an HBLOOpenOperation
	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8 *)LMMessageGetData(request), LMMessageGetDataLength(request), kCFAllocatorNull);
	HBLOOpenOperation *input = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)data];

	// ensure we got something…
	if (!input || ![input isKindOfClass:HBLOOpenOperation.class]) {
		HBLogError(@"received a bad message? input is missing");

		// send a blank reply, free the buffer, and return
		LMSendReply(replyPort, NULL, 0);
		LMResponseBufferFree(bytes);
		return;
	}

	// get the replacement
	NSArray <HBLOOpenOperation *> *replacements = [[HBLOHandlerController sharedInstance] getReplacementsForOpenOperation:input];

	// if there are replacements, provide them. otherwise, provide an empty array
	LMSendNSDataReply(replyPort, [NSKeyedArchiver archivedDataWithRootObject:replacements ?: @[]]);
	LMResponseBufferFree(bytes);
}

int main() {
	@autoreleasepool {
		// as our mach service is declared in the launch daemon plist, launchd opens the port itself and
		// spawns this process only when a message is sent. check in with launchd so we gain control
		// over the port
		kern_return_t result = LMCheckInService(openerdService.serverName, CFRunLoopGetCurrent(), ReceivedRelayedNotification, NULL);

		if (result != KERN_SUCCESS) {
			HBLogError(@"failed to start service! result = %i", result);
		}

		// run forever. the callback will be executed within the run loop
		CFRunLoopRun();

		// we should never get past here…
		return 1;
	}
}

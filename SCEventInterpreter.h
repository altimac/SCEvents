//
//  SCEventInterpreter.h
//  FSEventsTest
//
//  Created by Aurélien Hugelé on 17/07/13.
//
//

#import <Foundation/Foundation.h>

@class SCEvent;
@class SCFileSystemOperation;

#define SCEVENT_NOT_ENOUGH_EVENT_ERROR_CODE 1 // not fatal error? you may recall the method with a concatenation of current events and next batch events?

@interface SCEventInterpreter : NSObject

-(id)initWithPathes:(NSArray*)watchPathes trashPath:(NSString*)trashPath;

// returns SCFileSystemOperation objects. The count of returned array may not match the count of scEvents. Usually several events are necessary to be consumed to interpret them as a high level file operation.
// You should never interpret SCEvent one by one. A succession of *ordered* SCEvent makes interpretation much more correct. You typically pass the batches of SCEvents you got from coalesced FSEvents callbacks
-(NSArray*)interpretEvents:(NSArray*)scEvents error:(NSError**)error;
-(void)asyncInterpretEvents:(NSArray*)scEvents completionBlock:(void (^)(NSArray *scEvents, NSArray *fileOperations, NSError* error))completionBlock; // same as above, but async call. If error occured, fileOperations is nil and error is filled.

@end

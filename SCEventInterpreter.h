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

-(id)initWithPathes:(NSArray*)watchPathes trashPath:(NSString*)trashPath; // You should also observe the Trash path in order to get SCFileSystemOperationMoveToTrash/SCFileSystemOperationResurectFromTrash operations. Trash path can be nil if you don't need those operations
@property(assign,nonatomic) BOOL ignoreTrashInterpretationErrors; // if set to YES, uninterpretable activities in the Trash path will be silently ignored. Defaults to YES.
@property(assign,nonatomic) BOOL ignoreDotFiles; // if set to YES, all activities regarding ".DS_Store", ".localized" etc... files will be silently ignored. Defaults to YES.
@property(assign,nonatomic) BOOL ignoreActivitiesInDotFolders; // if set to YES, all file activities whose path components starts by a "." EXCEPT TRASH, will be silently ignored. Defaults to YES.

// returns SCFileSystemOperation objects. The count of returned array may not match the count of scEvents. Usually several events are necessary to be consumed to interpret them as a high level file operation.
// You should never interpret SCEvent one by one. A succession of *ordered* SCEvent makes interpretation much more correct. You typically pass the batches of SCEvents you got from coalesced FSEvents callbacks
-(NSArray*)interpretEvents:(NSArray*)scEvents error:(NSError**)error;

// this call is reentrant. You can typically call it when you got events to interprets. Only the last completionBlock set will be executed. The fileOperations array will contain all file operations waiting to be delivered since last completionBlock execution.
// latency is the limit at which the completionBlock will be called. Around 2 or 3 seconds is a good latency.
// the mail advantage of this method is that it coalesce FS operations to avoid useless ones (such as atomic write of Cocoa which creates a copy of the target file, write on the target and if it succeed, deletes the copy... 3 FS operations for what should be a single Modification FS operation...)
// If error occured, fileOperations is nil and error is filled.
-(void)asyncInterpretEvents:(NSArray*)scEvents latency:(NSTimeInterval)latency completionBlock:(void (^)(NSArray *fileOperations, NSError* error))completionBlock;

@end

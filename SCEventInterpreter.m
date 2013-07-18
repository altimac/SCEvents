//
//  SCEventInterpreter.m
//  FSEventsTest
//
//  Created by Aurélien Hugelé on 17/07/13.
//
//

#import "SCEventInterpreter.h"

#import "SCEvent.h"
#import "SCFileSystemOperation.h"

@interface SCEventInterpreter ()

@property(strong) NSArray *watchPathes;
@property(strong) NSString *trashPath;

@end

@implementation SCEventInterpreter

-(id)initWithPathes:(NSArray*)watchPathes trashPath:(NSString*)trashPath
{
    self = [super init];
    if(self)
    {
        _trashPath = trashPath;
        NSMutableArray *fixedArray = [NSMutableArray arrayWithArray:watchPathes];
        [fixedArray removeObject:trashPath];
        _watchPathes = [[NSArray alloc] initWithArray:fixedArray];
        _ignoreTrashInterpretationErrors = YES;
        _ignoreDotFiles = YES;
        _ignoreActivitiesInDotFolders = YES;
        
        NSParameterAssert([_watchPathes count] > 0);
    }
    
    return self;
}

-(NSArray*)interpretEvents:(NSArray*)scEvents error:(NSError**)error
{
    NSMutableArray *operations = [NSMutableArray array];
    NSMutableArray *remainingEvents = [NSMutableArray arrayWithArray:scEvents];
    
    while ([remainingEvents count] > 0)
    {
        NSIndexSet *consumedEventIndexes;
        SCFileSystemOperation *operation = [self operationFromEvents:remainingEvents consumedEventIndexes:&consumedEventIndexes error:error];
        if(!operation)
            return nil;

        if(operation != (SCFileSystemOperation*)[NSNull null]) // Don't generate error and silently fails interpretation, skip to next events.
        {
            [operations addObject:operation];
        }
        
        [remainingEvents removeObjectsAtIndexes:consumedEventIndexes];
    }
    
    return [NSArray arrayWithArray:operations];
}

-(SCFileSystemOperation*)operationFromEvents:(NSArray*)events consumedEventIndexes:(NSIndexSet**)consumedEventIndexes error:(NSError**)error;
{
    SCFileSystemOperation *operation = nil;
    SCFileSystemOperationType type = SCFileSystemOperationUnknown;
    NSString *oldPath = nil;
    NSString *path = nil;
    
    SCEvent *firstEvent = events[0];
    FSEventStreamEventFlags firstEventFlags = [events[0] eventFlags];
    
    if([[[firstEvent eventPath] lastPathComponent] hasPrefix:@"."] && _ignoreDotFiles == YES) // if file starts by a .
    {
        *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
        return (SCFileSystemOperation*)[NSNull null]; // Don't generate error and silently fails interpretation.
    }
    
    // if we're there's a folder in the path that starts by a .
    for(NSString *pathComponent in [[firstEvent eventPath] pathComponents])
    {
        if([pathComponent hasPrefix:@"."] && ![pathComponent isEqualToString:[_trashPath lastPathComponent]] && _ignoreActivitiesInDotFolders == YES)
        {
            *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
            return (SCFileSystemOperation*)[NSNull null]; // Don't generate error and silently fails interpretation.
        }
    }
    
    if((firstEventFlags & kFSEventStreamEventFlagItemCreated)                              &&
       (firstEventFlags & kFSEventStreamEventFlagItemRenamed) == 0                         &&
       [[firstEvent eventURL] checkResourceIsReachableAndReturnError:nil] == YES
       )
    {
        type = SCFileSystemOperationCreate;
        *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
        oldPath = nil;
        path = [firstEvent eventPath];
    }
    else if(firstEventFlags & kFSEventStreamEventFlagItemRemoved                               /*&&
                                                                                               [[initiator eventURL] checkResourceIsReachableAndReturnError:nil] == NO*/ // check the file is really deleted by not being there?
            )
    {
        type = SCFileSystemOperationDelete;
        *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
        oldPath = [firstEvent eventPath];
        path = nil;
    }
   
    // if operation is still unknown and there are no more events to continue interpretation, then it's a failure
    if((type == SCFileSystemOperationUnknown) && ([events count] <= 1))
    {
        if([_trashPath length] > 0 && [[firstEvent eventPath] hasPrefix:_trashPath] && _ignoreTrashInterpretationErrors)
        {
            *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
            return (SCFileSystemOperation*)[NSNull null]; // means it's a trash events that can't be interpreted. Don't generate error and silently fails interpretation.
        }
        else if((firstEventFlags & kFSEventStreamEventFlagItemRenamed))
        {
            // if there is no other event, then it can be a move outgoing
            type = [[firstEvent eventURL] checkResourceIsReachableAndReturnError:nil] ? SCFileSystemOperationMoveIncoming : SCFileSystemOperationMoveOutgoing;
            type |= SCFileSystemOperationMove;
            oldPath = [firstEvent eventPath];
            path = nil;
            
            *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
        }
        else
        {
            if(error)
                *error = [NSError errorWithDomain:@"com.scevent.interpreter" code:SCEVENT_NOT_ENOUGH_EVENT_ERROR_CODE userInfo:@{NSLocalizedDescriptionKey : @"There is not enough events to interpret the file system operation. Concatenate with the next batch?"}];
            
            return nil;
        }
    }
    
    // if operation is still unknown and first event is flagged kFSEventStreamEventFlagItemRenamed
    if((type == SCFileSystemOperationUnknown) && (firstEventFlags & kFSEventStreamEventFlagItemRenamed))
    {
        type = SCFileSystemOperationUnknown;
        
        FSEventStreamEventId firstEventId = [firstEvent eventId];
        SCEvent *nextEvent = events[1];
        FSEventStreamEventId nextEventId = [nextEvent eventId];
        FSEventStreamEventFlags nextEventFlags = [nextEvent eventFlags];
        
        if(nextEventFlags & kFSEventStreamEventFlagItemRenamed) // if flag renamed
        {
            if(nextEventId == firstEventId+1                                             &&
               [[nextEvent eventURL] checkResourceIsReachableAndReturnError:nil] == YES // if both events are an atomic operation and the NEXT event file exists
               )
            {
                type = SCFileSystemOperationUnknown;
                oldPath = [firstEvent eventPath];
                path = [nextEvent eventPath];
                
                // if both file URLs have different last path component, then it's a rename!
                if(![[[firstEvent eventURL] lastPathComponent] isEqual:[[nextEvent eventURL] lastPathComponent]])
                {
                    type |= SCFileSystemOperationRename;
                }
                
                // if both file parent's folder are different, then it's a move withing watched path
                if(![[[firstEvent eventURL] URLByDeletingLastPathComponent] isEqual:[[nextEvent eventURL] URLByDeletingLastPathComponent]])
                {
                    type |= SCFileSystemOperationMove;
                    
                    if([_trashPath length] > 0)
                    {
                        // if destination is trash (and source is not trash itself!)
                        if([[nextEvent eventPath] hasPrefix:_trashPath] && ![[firstEvent eventPath] hasPrefix:_trashPath])
                        {
                            type |= SCFileSystemOperationMoveToTrash;
                        }
                        // if source is trash (and and destination is anywhere else)
                        else if([[firstEvent eventPath] hasPrefix:_trashPath] && ![[nextEvent eventPath] hasPrefix:_trashPath])
                        {
                            type |= SCFileSystemOperationResurectFromTrash;
                            
                            // NOTE: should we declare SCFileSystemOperationMoveIncoming or even SCFileSystemOperationCreate if the destination path is one of the watched path ?
                        }
                        // else it's just a move between watched pathes!
                        else
                        {
                            type |= SCFileSystemOperationMoveWithin;
                        }
                    }
                    else
                    {
                        type |= SCFileSystemOperationMoveWithin;
                    }
                }
                
                *consumedEventIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
            }
            // if we can't see both events as an atomic operation but the file exists in watched path, then it's incoming!
            else if(nextEventId != firstEventId+1                                              &&
                    [[firstEvent eventURL] checkResourceIsReachableAndReturnError:nil] == YES
                    )
            {
                type = SCFileSystemOperationMoveIncoming;
                type |= SCFileSystemOperationMove;
                oldPath = nil;
                path = [firstEvent eventPath];
                
                *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
            }
            // if we can't see both events as an atomic operation but the file does not exists in watched path, then it's outgoing!
            else if(nextEventId != firstEventId+1                                              &&
                    [[firstEvent eventURL] checkResourceIsReachableAndReturnError:nil] == NO
                    )
            {
                type = SCFileSystemOperationMoveOutgoing;
                type |= SCFileSystemOperationMove;
                oldPath = [firstEvent eventPath];
                path = nil;
                
                *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
            }
        }
    }
    
    operation = [[SCFileSystemOperation alloc] initWithOldPath:oldPath path:path operationType:type];
    
    return operation;
}

@end

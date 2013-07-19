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

typedef void (^SCEventInterpreterCompletionBlock_block_t)(NSArray *fileOperations, NSError* error);


@interface SCEventInterpreter ()

@property(strong) NSArray *watchPathes;
@property(strong) NSString *trashPath;

@property(strong) NSMutableArray *operationsBuffer;
@property(strong) NSMutableArray *coalescedOperations;
@property(assign) NSTimeInterval latency;
@property(copy)  SCEventInterpreterCompletionBlock_block_t completionBlock;
@property(strong) dispatch_queue_t eventInterpreterProducerDispatchQueue;
@property(strong) dispatch_semaphore_t operationsBufferReadyDispatchSemaphore;
@property(strong) dispatch_queue_t eventInterpreterConsumerDispatchQueue;

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
        
        _operationsBuffer = [[NSMutableArray alloc] init];
        _coalescedOperations = [[NSMutableArray alloc] init];
        
        NSParameterAssert([_watchPathes count] > 0);
    }
    
    return self;
}

-(void)dealloc
{
    _completionBlock = nil;
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
    
    BOOL firstEventIsCreatedFlag = (firstEventFlags & kFSEventStreamEventFlagItemCreated) > 0;
    BOOL firstEventIsRenamedFlag = (firstEventFlags & kFSEventStreamEventFlagItemRenamed) > 0;
    BOOL firstEventIsModifiedFlag = (firstEventFlags & kFSEventStreamEventFlagItemModified) > 0;
    BOOL firstEventIsRemovedFlag = (firstEventFlags & kFSEventStreamEventFlagItemRemoved) > 0;
    
    if(firstEventIsCreatedFlag                              &&
       firstEventIsRenamedFlag == NO                        &&
       [[firstEvent eventURL] checkResourceIsReachableAndReturnError:nil] == YES
       )
    {
        type = SCFileSystemOperationCreate;
        oldPath = nil;
        path = [firstEvent eventPath];
        *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
    }
    else if(firstEventIsRemovedFlag)
    {
        type = SCFileSystemOperationDelete;
        oldPath = [firstEvent eventPath];
        path = nil;
        *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
    }
    
    // if operation is still unknown and there are no more events to continue interpretation
    if((type == SCFileSystemOperationUnknown) && ([events count] <= 1))
    {
        if([_trashPath length] > 0 && [[firstEvent eventPath] hasPrefix:_trashPath] && _ignoreTrashInterpretationErrors)
        {
            *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
            return (SCFileSystemOperation*)[NSNull null]; // means it's a trash events that can't be interpreted. Don't generate error and silently fails interpretation.
        }
        else if(firstEventIsCreatedFlag)
        {
            // it is a create
            type = SCFileSystemOperationCreate;
            oldPath = nil;
            path = [firstEvent eventPath];
            *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
        }
        else if(firstEventIsRenamedFlag)
        {
            // if there is no other event, then it can be a move outgoing
            BOOL resourceInWatchedPathes = [[firstEvent eventURL] checkResourceIsReachableAndReturnError:nil];
            type = resourceInWatchedPathes ? SCFileSystemOperationMoveIncoming : SCFileSystemOperationMoveOutgoing;
            type |= SCFileSystemOperationMove;
            oldPath = resourceInWatchedPathes ? nil : [firstEvent eventPath];
            path = resourceInWatchedPathes ? [firstEvent eventPath] : nil;
            *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
        }
        else if(firstEventIsModifiedFlag)
        {
            // if there is no other event, then it can be a modification
            type = SCFileSystemOperationModification;
            oldPath = nil;
            path = [firstEvent eventPath];
            *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
        }
        else
        {
            if(error)
                *error = [NSError errorWithDomain:@"com.scevent.interpreter" code:SCEVENT_NOT_ENOUGH_EVENT_ERROR_CODE userInfo:@{NSLocalizedDescriptionKey : @"There is not enough events to interpret the file system operation. Concatenate with the next batch?"}];
            
            return nil;
        }
    }
    
    // if operation is still unknown and first event is flagged kFSEventStreamEventFlagItemRenamed but there are other events in the queue
    if((type == SCFileSystemOperationUnknown) && firstEventIsRenamedFlag)
    {
        type = SCFileSystemOperationUnknown;
        
        FSEventStreamEventId firstEventId = [firstEvent eventId];
        SCEvent *nextEvent = events[1];
        FSEventStreamEventId nextEventId = [nextEvent eventId];
        FSEventStreamEventFlags nextEventFlags = [nextEvent eventFlags];
        
        BOOL nextEventIsRenamedFlag = (nextEventFlags & kFSEventStreamEventFlagItemRenamed) > 0;
        
        if(nextEventIsRenamedFlag)
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
    
    // If we didn't interpret anything, then at least consume the first event.
    if(type == SCFileSystemOperationUnknown)
    {
        path = [firstEvent eventPath];
        *consumedEventIndexes = [NSIndexSet indexSetWithIndex:0];
    }
    
    operation = [[SCFileSystemOperation alloc] initWithOldPath:oldPath path:path operationType:type];
    
    return operation;
}

-(void)asyncInterpretEvents:(NSArray*)scEvents latency:(NSTimeInterval)latency completionBlock:(void (^)(NSArray *fileOperations, NSError* error))completionBlock; // same as above, but async call. If error occured, fileOperations is nil and error is filled.
{
    NSParameterAssert(latency > 0);
    self.latency = latency;
    
    if(_eventInterpreterConsumerDispatchQueue == NULL)
    {
        [self setupConsumer];
    }
    
    if(_eventInterpreterProducerDispatchQueue == NULL)
    {
        _eventInterpreterProducerDispatchQueue = dispatch_queue_create("com.sceventinterpreter.producer", DISPATCH_QUEUE_SERIAL);
    }
    
    self.completionBlock = completionBlock;
    
    dispatch_async(_eventInterpreterProducerDispatchQueue, ^{
        
        NSError *error;
        NSArray *interpretedOperations = [self interpretEvents:scEvents error:&error];
        if(!interpretedOperations)
        {
            NSLog(@"%s - failed to interpret events. Dropping the events! - error:%@",__PRETTY_FUNCTION__,error);
        }
        else
        {
            @synchronized(_operationsBuffer)
            {
                [_operationsBuffer addObjectsFromArray:interpretedOperations];
            }
            
            dispatch_semaphore_signal(_operationsBufferReadyDispatchSemaphore);
        }
    });
}

-(void)setupConsumer
{
    _eventInterpreterConsumerDispatchQueue = dispatch_queue_create("com.sceventinterpreter.consumer", DISPATCH_QUEUE_SERIAL);
    _operationsBufferReadyDispatchSemaphore = dispatch_semaphore_create(0);
    
    dispatch_async(_eventInterpreterConsumerDispatchQueue, ^{
        
        while(1)
        {
            NSArray *operationsToCoalesce = nil;
            
            long timeout = dispatch_semaphore_wait(_operationsBufferReadyDispatchSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.latency * (NSTimeInterval)NSEC_PER_SEC)));
            if(!timeout)
            {
                @synchronized(_operationsBuffer)
                {
                    operationsToCoalesce = [NSArray arrayWithArray:_operationsBuffer];
                    [_operationsBuffer removeAllObjects];
                }
                
                NSError *error;
                NSArray *tmpCoalescedOperations = [self coalesceOperations:operationsToCoalesce error:&error];
                
                if(!tmpCoalescedOperations)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(self.completionBlock)
                            self.completionBlock(tmpCoalescedOperations,error);
                    });
                }
                else
                {
                    [_coalescedOperations addObjectsFromArray:tmpCoalescedOperations];
                }
            }
            else
            {
                NSArray *tmpCoalescedOperations = [NSArray arrayWithArray:_coalescedOperations];
                [_coalescedOperations removeAllObjects];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self.completionBlock)
                        self.completionBlock(tmpCoalescedOperations,nil);
                });
            }
        }
    });
}

-(NSArray *)coalesceOperations:(NSArray*)fsOperations error:(NSError**)error
{
    NSMutableArray *coalescedOperations = [NSMutableArray array];
    
    NSUInteger i = 0;
    for(SCFileSystemOperation *op in fsOperations)
    {
        NSUInteger cIndex = i;

        SCFileSystemOperation *coalescedOperation = op;
        SCFileSystemOperation *sourceOp = nil;
        do
        {
            sourceOp = coalescedOperation;
            // find other operations acting *on the same path* that is either a create rename, move, or delete  so that we drop this "furtive" create operation
            coalescedOperation = [self coalescedOperationForOperation:sourceOp followingOperations:[fsOperations  subarrayWithRange:NSMakeRange(cIndex+1, [fsOperations count]-cIndex)] index:&cIndex];
        }
        while(sourceOp != coalescedOperation);

        
        if(coalescedOperation != op)
        {
            // op has been coalesced. But we have to RE interpret again:
            if(([op operationType] & SCFileSystemOperationCreate) > 0)
            {
                SCFileSystemOperation *definitiveOp = [[SCFileSystemOperation alloc] initWithOldPath:nil path:coalescedOperation.path operationType:[self operationTypeFromSourceOperationType:[op operationType] lastOperationType:[coalescedOperation operationType]]];
                [coalescedOperations addObject:definitiveOp];
            }
        }
        else
        {
            // we can't coalesce this operation, so add it to the returned array
            [coalescedOperations addObject:op];
        }
        
        i++;
    }
    
    
    return fsOperations;
}

// returns sourceOp if it is not coalescable
// returns another operation if it has been coalesced. You should recursively call this method while the returned operation is not sourceOp
-(SCFileSystemOperation *)coalescedOperationForOperation:(SCFileSystemOperation*)sourceOp followingOperations:(NSArray*)fsOperations index:(NSUInteger*)index
{
    SCFileSystemOperation *coalescedOperation = sourceOp;
    
    NSUInteger i = 0;
    if(([sourceOp operationType] & SCFileSystemOperationCreate) != 0)
    {
        for(SCFileSystemOperation *followingOp in fsOperations)
        {
            if([[followingOp oldPath] isEqualToString:[sourceOp path]] || [[followingOp path] isEqualToString:[sourceOp path]] || [[followingOp oldPath] isEqualToString:[sourceOp oldPath]] || [[followingOp path] isEqualToString:[sourceOp oldPath]])
            {
                // followingOp targets sourceOp file!
                coalescedOperation = [[SCFileSystemOperation alloc] initWithOldPath:[sourceOp path] path:[followingOp path] operationType:followingOp.operationType];
                break;
            }
        }
        
        i++;
    }
    
    *index = i;
    return coalescedOperation;
}

-(SCFileSystemOperationType)operationTypeFromSourceOperationType:(SCFileSystemOperationType)sourceType lastOperationType:(SCFileSystemOperationType)lastType
{
    if((sourceType & SCFileSystemOperationCreate) != 0)
    {
        
        // if it was a create, then it stays a create in many case, except if trashed, deleted or moveoutgoing!
        // create + (rename) + movewithin => create to the movewithin target path
        // create + (rename) + trashed + moveincoming => the source file is fugitive but has been replaced by a new incoming file => create with moveincoming path (and new file name)
        // create + (rename) + movewithin + trashed => trashed
        // create + (rename) + movewithin + trashed + deleted => deleted
        // create + (rename) + moveoutgoing => moveoutgoing
        
        if((lastType & SCFileSystemOperationMoveToTrash) != 0    ||
           (lastType & SCFileSystemOperationDelete) != 0         ||
           (lastType & SCFileSystemOperationMoveOutgoing) != 0)
        {
            return lastType;
        }
        
        return sourceType;
    }
    
    return sourceType;
}

@end

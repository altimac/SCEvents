/*
 *  $Id: SCEvent.m 195 2011-03-15 21:47:34Z stuart $
 *
 *  SCEvents
 *  http://stuconnolly.com/projects/code/
 *
 *  Copyright (c) 2011 Stuart Connolly. All rights reserved.
 *
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 * 
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 */

#import "SCEvent.h"

@implementation SCEvent

@synthesize _eventId;
@synthesize _eventDate;
@synthesize _eventPath;
@synthesize _eventURL;
@synthesize _eventFlags;

#pragma mark -
#pragma mark Initialisation

/**
 * Returns an initialized instance of SCEvent using the supplied event ID, date, path 
 * and flag.
 *
 * @param identifer The ID of the event
 * @param date      The date of the event
 * @param path      The file system path of the event
 * @param flags     The flags associated with the event
 *
 * @return The initialized (autoreleased) instance
 */
+ (SCEvent *)eventWithEventId:(FSEventStreamEventId)identifier
					eventDate:(NSDate *)date 
					eventPath:(NSString *)path 
				   eventFlags:(FSEventStreamEventFlags)flags
{
    return [[SCEvent alloc] initWithEventId:identifier eventDate:date eventPath:path eventFlags:flags];
}

/**
 * Initializes an instance of SCEvent using the supplied event ID, path and flag.
 *
 * @param identifer The ID of the event
 * @param date      The date of the event
 * @param path      The file system path of the event
 * @param flags     The flags associated with the event
 *
 * @return The initialized instance
 */
- (id)initWithEventId:(FSEventStreamEventId)identifier
			eventDate:(NSDate *)date 
			eventPath:(NSString *)path 
		   eventFlags:(FSEventStreamEventFlags)flags
{
    if ((self = [super init])) {
        [self setEventId:identifier];
        [self setEventDate:date];
        [self setEventPath:path];
        [self setEventFlags:flags];
    }
    
    return self;
}

#pragma mark -

-(void)setEventPath:(NSString*)aPath
{
    _eventPath = aPath;
    _eventURL = nil;
}

-(NSURL*)eventURL
{
    if(!_eventURL)
    {
        _eventURL = [NSURL fileURLWithPath:self.eventPath];
    }
        
    return _eventURL;
}


#pragma mark -
#pragma mark Other

/**
 * Provides the string used when printing this object in NSLog, etc. Useful for
 * debugging purposes.
 *
 * @return The description string
 */
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ { eventId = %llu, eventPath = %@, eventFlags = %@ } >",
			[self className], 
			_eventId,
			[self eventPath], 
			(flagsStringForFlags(_eventFlags))];
}

NSString *flagsStringForFlags(FSEventStreamEventFlags flags)
{
    NSMutableString *string = [NSMutableString string];
    
    if((flags & kFSEventStreamEventFlagMustScanSubDirs) != 0)
        [string appendString:@"|kFSEventStreamEventFlagMustScanSubDirs"];
    if((flags & kFSEventStreamEventFlagUserDropped) != 0)
        [string appendString:@"|kFSEventStreamEventFlagUserDropped"];
    if((flags & kFSEventStreamEventFlagKernelDropped) != 0)
        [string appendString:@"|kFSEventStreamEventFlagKernelDropped"];
    
    if((flags & kFSEventStreamEventFlagEventIdsWrapped) != 0)
        [string appendString:@"|kFSEventStreamEventFlagEventIdsWrapped"];
    
    if((flags & kFSEventStreamEventFlagHistoryDone) != 0)
        [string appendString:@"|kFSEventStreamEventFlagHistoryDone"];
    
    if((flags & kFSEventStreamEventFlagRootChanged) != 0)
        [string appendString:@"|kFSEventStreamEventFlagRootChanged"];
    
    
    
    
    if(flags & (kFSEventStreamEventFlagItemCreated != 0))
        [string appendString:@"|kFSEventStreamEventFlagItemCreated"];
    
    if((flags & kFSEventStreamEventFlagItemRemoved) != 0)
        [string appendString:@"|kFSEventStreamEventFlagItemRemoved"];
    
    if(flags & (kFSEventStreamEventFlagItemInodeMetaMod != 0))
        [string appendString:@"|kFSEventStreamEventFlagItemInodeMetaMod"];
    
    if((flags & kFSEventStreamEventFlagItemRenamed) != 0)
        [string appendString:@"|kFSEventStreamEventFlagItemRenamed"];
    
    if((flags & kFSEventStreamEventFlagItemModified) != 0)
        [string appendString:@"|kFSEventStreamEventFlagItemModified"];
    
    if((flags & kFSEventStreamEventFlagItemFinderInfoMod) != 0)
        [string appendString:@"|kFSEventStreamEventFlagItemFinderInfoMod"];
    
    if((flags & kFSEventStreamEventFlagItemChangeOwner) != 0)
        [string appendString:@"|kFSEventStreamEventFlagItemChangeOwner"];
    
    if((flags & kFSEventStreamEventFlagItemXattrMod) != 0)
        [string appendString:@"|kFSEventStreamEventFlagItemXattrMod"];
    
    if((flags & kFSEventStreamEventFlagItemIsFile) != 0)
        [string appendString:@"|kFSEventStreamEventFlagItemIsFile"];
    
    if((flags & kFSEventStreamEventFlagItemIsDir) != 0)
        [string appendString:@"|kFSEventStreamEventFlagItemIsDir"];
    
    if((flags & kFSEventStreamEventFlagItemIsSymlink) != 0)
        [string appendString:@"|kFSEventStreamEventFlagItemIsSymlink"];
    
    
    if([string length] == 0)
        [string appendString:@"no flag..."];
    else
        [string replaceCharactersInRange:NSMakeRange(0, 1) withString:@""]; // removes leading "|"
    
    return string;
}

#pragma mark -

@end

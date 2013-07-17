//
//  SCFileSystemOperation.m
//  FSEventsTest
//
//  Created by Aurélien Hugelé on 17/07/13.
//
//

#import "SCFileSystemOperation.h"

@implementation SCFileSystemOperation

-(id)initWithOldPath:(NSString*)oldPath path:(NSString*)path operationType:(SCFileSystemOperationType)type;
{
    self = [super init];
    if(self)
    {
        _oldPath = oldPath;
        _path = path;
        
        _operationType = type;
    }
    
    return self;
}


@end

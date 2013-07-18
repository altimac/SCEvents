//
//  SCFileSystemOperation.m
//  FSEventsTest
//
//  Created by Aurélien Hugelé on 17/07/13.
//
//

#import "SCFileSystemOperation.h"

@implementation SCFileSystemOperation

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _oldPath = [coder decodeObjectForKey:@"oldPath"];
        _path = [coder decodeObjectForKey:@"path"];
        _operationType = [[coder decodeObjectForKey:@"operationType"] unsignedIntegerValue];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_oldPath forKey:@"oldPath"];
    [aCoder encodeObject:_path forKey:@"path"];
    [aCoder encodeObject:@(_operationType) forKey:@"operationType"];
}

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

-(BOOL)isDirectory
{
    BOOL isDir = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDir]) {
        return NO;
    };
    
    return isDir;
}

-(NSDictionary*)dictionaryRepresentation
{
    NSMutableDictionary *dictRep = [NSMutableDictionary dictionaryWithCapacity:3];
    
    dictRep[@"operationType"] = @(_operationType);
    if(_oldPath)
        dictRep[@"oldPath"] = _oldPath;
    if(_path)
        dictRep[@"path"] = _path;
    
    return dictRep;
}

-(NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithFormat:@"<%@ %p - type:%@",[self class],self,[self typeAsString:self.operationType]];
    [desc appendFormat:@" - oldPath:\"%@\"",self.oldPath];
    [desc appendFormat:@" - path:\"%@\"",self.path];
    [desc appendString:@">"];
    
    return desc;
}

-(NSString*)typeAsString:(SCFileSystemOperationType)type
{
    NSMutableString *typeAsString = [NSMutableString string];
    
    if (type & SCFileSystemOperationCreate) [typeAsString appendString:@"|SCFileSystemOperationCreate"];
    if (type & SCFileSystemOperationDelete) [typeAsString appendString:@"|SCFileSystemOperationDelete"];
    if (type & SCFileSystemOperationModification) [typeAsString appendString:@"|SCFileSystemOperationModification"];
    if (type & SCFileSystemOperationCopy) [typeAsString appendString:@"|SCFileSystemOperationCopy"]; 

    if (type & SCFileSystemOperationMove) [typeAsString appendString:@"|SCFileSystemOperationMove"];
    if (type & SCFileSystemOperationMoveWithin) [typeAsString appendString:@"|SCFileSystemOperationMoveWithin"];
    if (type & SCFileSystemOperationMoveIncoming) [typeAsString appendString:@"|SCFileSystemOperationMoveIncoming"];
    if (type & SCFileSystemOperationMoveOutgoing) [typeAsString appendString:@"|SCFileSystemOperationMoveOutgoing"];
    if (type & SCFileSystemOperationMoveToTrash) [typeAsString appendString:@"|SCFileSystemOperationMoveToTrash"];
    if (type & SCFileSystemOperationResurectFromTrash) [typeAsString appendString:@"|SCFileSystemOperationResurectFromTrash"];


    if (type & SCFileSystemOperationRename) [typeAsString appendString:@"|SCFileSystemOperationRename"];
    
    if([typeAsString length] > 0)
        [typeAsString replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
    else
        [typeAsString setString:@"SCFileSystemOperationUnknown"];
    
    return typeAsString;
}

@end

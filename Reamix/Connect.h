//
//  Connect.h
//  Reamix
//
//  Created by myles grant on 2014-11-04.
//  Copyright (c) 2014 Pinecone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Connect : NSObject
{
    @public
    BOOL internetConnection;
}

- (void)testInternetConnection;

-(NSURL *)setNewFile:(NSString *)filename fileFormat:(NSString *)ext;
-(NSArray *)getContextArray:(NSString *)entity;
-(NSString *)getDoc;

-(void)addNewRowIn:(NSString *)entity setValue:(id)value forKeyPath:(NSString *)key;
-(void)updateRowIn:(NSString *)entity setValue:(id)value forKeyPath:(NSString *)key atIndex:(NSInteger)index;
-(void)deleteObjectIn:(NSString *)entity atIndex:(NSInteger)index;
@end

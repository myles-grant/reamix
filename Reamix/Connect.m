//
//  Connect.m
//  Reamix
//
//  Created by myles grant on 2014-11-04.
//  Copyright (c) 2014 Pinecone. All rights reserved.
//

#import "Connect.h"
#import "CheckConnection.h"

@implementation Connect


// Checks if we have an internet connection or not
- (void)testInternetConnection
{
    CheckConnection *internetReachableFoo = [CheckConnection reachabilityWithHostname:@"www.google.com"];
    
    // Internet is reachable
    internetReachableFoo.reachableBlock = ^(CheckConnection*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            //Connected
            internetConnection = YES;
        });
    };
    
    // Internet is not reachable
    internetReachableFoo.unreachableBlock = ^(CheckConnection*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            //Disconnected
            internetConnection = NO;
        });
    };
    
    [internetReachableFoo startNotifier];
}


//retrieve managed object contexts and save data
-(NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context1 = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if([delegate performSelector:@selector(managedObjectContext)])
    {
        context1 = [delegate managedObjectContext];
    }
    return context1;
}


-(NSArray *)getContextArray:(NSString *)entity
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSArray *array = [[context executeFetchRequest:request error:nil] mutableCopy];
    
    return array;
}

-(void)addNewRowIn:(NSString *)entity setValue:(id)value forKeyPath:(NSString *)key
{
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:context];
    
    [newObject setValue:value forKeyPath:key];
    
    NSError *error = nil;
    if(![context save:&error])
    {
        NSLog(@"Cant save: %@, %@", error, [error localizedDescription]);
    }
}

-(void)updateRowIn:(NSString *)entity setValue:(id)value forKeyPath:(NSString *)key atIndex:(NSInteger)index
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSArray *array = [[context executeFetchRequest:request error:nil] mutableCopy];
    NSManagedObject *updateObject = [array objectAtIndex:index];
    
    [updateObject setValue:value forKeyPath:key];
    
    NSError *error = nil;
    if(![context save:&error])
    {
        NSLog(@"Cant save: %@, %@", error, [error localizedDescription]);
    }
}

-(void)deleteObjectIn:(NSString *)entity atIndex:(NSInteger)index
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSArray *array = [[context executeFetchRequest:request error:nil] mutableCopy];
    NSManagedObject *removeObject = [array objectAtIndex:index];
 
    [context deleteObject:removeObject];
    
    //Save deletion
    NSError *error1 = nil;
    if(![context save:&error1])
    {
        NSLog(@"Cant save: %@, %@", error1, [error1 localizedDescription]);
    }
}


-(NSString *)getDoc
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    return documentsDirectory;
}

-(NSURL *)setNewFile:(NSString *)filename fileFormat:(NSString *)ext
{
    //Setup new file in document folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%u%@", filename, (arc4random() % 9000), ext]];
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    return url;
}









@end

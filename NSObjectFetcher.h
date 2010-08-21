//
//  NSObjectFetcher.h
//
//  Created by Michael Dinerstein on 7/17/10.
//  Copyright 2010 Folio Applications, Inc. 
//  This class will return an object encoded in an NSDictionary that you can then use to create objects for your programs.
//

#import <Foundation/Foundation.h>


@protocol NSObjectFetcherDelegate <NSObject>
-(void)arrayFromFetcher:(NSArray *)fetchArray;
-(void)didFailWithError:(NSError *)error;
@optional
@end

@interface NSObjectFetcher : NSObject <NSXMLParserDelegate>{
	NSMutableData *fetchedData;  //Data fetched from a standard NSURLConnection request

	NSMutableDictionary *currentObject;
	NSMutableArray *objectsToReturn;
	NSMutableArray *stackXMLNames;
	NSMutableArray *stackObjectNames;
	NSMutableArray *stackObjects;
	NSMutableString *currentElementString;
	NSMutableDictionary *attributeDictionary;
	BOOL hasWrapperTag;
	BOOL skipFirst;
	
	id<NSObjectFetcherDelegate> delegate;
}

@property (nonatomic, retain) NSMutableData *fetchedData;	
@property (nonatomic, retain) NSMutableDictionary *currentObject;
@property (nonatomic, retain) NSMutableArray *objectsToReturn;
@property (nonatomic, retain) NSMutableArray *stackXMLNames;
@property (nonatomic, retain) NSMutableArray *stackObjectNames;
@property (nonatomic, retain) NSMutableArray *stackObjects;
@property (nonatomic, retain) NSMutableString *currentElementString;
@property (nonatomic, retain) NSMutableDictionary *attributeDictionary;
@property (nonatomic) BOOL hasWrapperTag;
@property (nonatomic) BOOL skipFirst;

@property (assign) id<NSObjectFetcherDelegate> delegate;

- (void)initUsingWrapper:(BOOL)wrapperElement;
- (void)fetchObjectsWithURLAsString:(NSString *)urlString usingData:(NSString *)requestString;
- (void)fetchObjectsWithURL:(NSURL *)url usingData:(NSString *)requestString;
- (void)fetchObjectsUsingConnection:(NSURLConnection *)theConnection;

@end

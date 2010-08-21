/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the NSObjectFetcher class.
 *
 * The Initial Developer of the Original Code is
 * Folio Applications, LLC.
 * Portions created by the Initial Developer are Copyright (C) 2010
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Michael Dinerstein <dinerstein.michael@gmail.com>
 *
 * ***** END LICENSE BLOCK ***** */

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

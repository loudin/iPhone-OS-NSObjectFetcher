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

#import "NSObjectFetcher.h"

@implementation NSObjectFetcher

@synthesize fetchedData;
@synthesize currentObject;
@synthesize objectsToReturn;
@synthesize stackXMLNames;
@synthesize stackObjectNames;
@synthesize stackObjects;
@synthesize currentElementString;
@synthesize attributeDictionary;
@synthesize hasWrapperTag;
@synthesize skipFirst;
@synthesize delegate;

- (void)initUsingWrapper:(BOOL)wrapperElement{
	hasWrapperTag = wrapperElement;
}

- (void)fetchDataWithURL:(NSURL *)requestURL usingData:(NSString *)requestString {	
	hasWrapperTag = YES;
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
	NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:requestData];
	
	NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	[self fetchObjectsUsingConnection:theConnection];
}

- (void)fetchObjectsWithURLAsString:(NSString *)urlString usingData:(NSString *)requestString{
	[self fetchDataWithURL:[NSURL URLWithString:urlString] usingData:requestString];
}

- (void)fetchObjectsWithURL:(NSURL *)url usingData:(NSString *)requestString{
	[self fetchDataWithURL:url usingData:requestString];	
}

- (void)fetchObjectsUsingConnection:(NSURLConnection *)theConnection{
	if (theConnection){
		fetchedData = [[NSMutableData data] retain];
	}
	else{
		if (self.delegate !=NULL && [self.delegate respondsToSelector:@selector(didFailWithError:)]){
			[delegate didFailWithError:[NSError errorWithDomain:@"StatusCode" code:404 userInfo:nil]];
		}
	}
}


#pragma mark -
#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	if ([response respondsToSelector:@selector(statusCode)]){
        int statusCode = [((NSHTTPURLResponse *)response) statusCode];
        if (statusCode == 404){
			[connection cancel];  // stop connecting; no more delegate messages
			[connection release];	
			if (self.delegate !=NULL && [self.delegate respondsToSelector:@selector(didFailWithError:)]){
				[delegate didFailWithError:[NSError errorWithDomain:@"StatusCode" code:404 userInfo:nil]];
			}
        }
		else{
			[fetchedData setLength:0];
		}
    }
	else{
		[fetchedData setLength:0];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	[fetchedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	[connection release];
	[fetchedData release];
	if (self.delegate !=NULL && [self.delegate respondsToSelector:@selector(didFailWithError:)]){
		[delegate didFailWithError:error];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	[connection release];	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:fetchedData];
	if ([fetchedData length] == 0){									// If file doesn't return anything, provide an empty array
		if (self.delegate !=NULL && [self.delegate respondsToSelector:@selector(arrayFromFetcher:)]){
			[delegate arrayFromFetcher:nil];
		}
	}
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
}

/* Theoretically, this code works for the simple list we currently use for Pieces */
- (void)parserDidStartDocument:(NSXMLParser *)parser{
	
	// Initialize the objects we're going to be needing for the document
	objectsToReturn = [[NSMutableArray alloc] init];		// Objects we wish to return to to the delegate
	stackXMLNames = [[NSMutableArray alloc] init];			// Names of the XML tags
	stackObjectNames = [[NSMutableArray alloc] init];		// Names of the objects in the XML file
	stackObjects = [[NSMutableArray alloc] init];			// Array of the objects in the stack. Only used for nested elements
	currentElementString = [[NSMutableString alloc] init];	// The current element string being read by the file		
	skipFirst = hasWrapperTag;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
	if (!skipFirst){			// If the user has a wrapper tag, skip it first.
		[stackXMLNames addObject:elementName];
		if (currentObject == nil)					// If the current Object does not exist, create it
		{
			currentObject = [[NSMutableDictionary alloc] init];
		}
		
		if ([attributeDict count] > 0)				// If there are attributes on the element, store it in the attribute dictionary for new storage
		{
			// Dictionary for any attributes that need to be associated with the object.
			attributeDictionary = [[NSMutableDictionary alloc] initWithDictionary:attributeDict];		
		}
	}
	else 
	{
		skipFirst = NO;
	}

}
		
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	if (currentElementString == nil)
		currentElementString = [[NSMutableString alloc] init];
	[currentElementString appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
	if ( [elementName isEqualToString:[stackXMLNames lastObject]] && ![elementName hasSuffix:@"_list"] )	// If the last element is equal to the current element, we have a match
	{	
		[stackXMLNames removeLastObject];
		if ([[stackXMLNames lastObject] isEqualToString:[stackObjectNames lastObject]])		// If the object in XMLNames is equal to the most recent object in the stackObjectNames, then we should add it to the current object
		{
			if (currentElementString == nil)
				[currentObject setObject:@"" forKey:elementName];
			else
				[currentObject setObject:[currentElementString mutableCopy] forKey:elementName];
			currentElementString = nil;
			[currentElementString release];
		}
		else					// If the object in XMLNames is NOT equal to the most recent object in stackObjectNames, then we have a NEW object if currentElementString is not nil, or an OLD object if currentElement string is nil
		{
			if (currentElementString != nil)			// NEW OBJECT
			{
				
				if ([stackObjects count] != 0)
				{
					currentObject = [[NSMutableDictionary alloc] init];
				}
				[stackObjects addObject:currentObject];
				[stackObjectNames addObject:[stackXMLNames lastObject]];
				[currentObject setObject:currentElementString forKey:elementName];
				currentElementString = nil;
				[currentElementString release];
				
				// For every new object, add the attribute dictionary to it first
				if (attributeDictionary != nil){
					NSEnumerator *enumerator = [attributeDictionary keyEnumerator];
					id key;
					while ((key = [enumerator nextObject])) {				
						// Dictionary for any attributes that need to be associated with the object.
						[currentObject setObject:[attributeDictionary objectForKey:key] forKey:key];	
					}
					// Set attributeDictionary back to nil
					attributeDictionary = nil;
					[attributeDictionary release];
				}
 			}
			else										// Finishing closed object
			{
				// Add stackObjects last object to the second to last object - WILL ALWAYS BE ONE OBJECT IN STACKOBJECTS
				if ([stackObjects count] > 1)
				{
					if ([[stackObjects objectAtIndex:[stackObjects count]-2] objectForKey:[stackObjectNames lastObject]] == nil){		// If space doesnt exist, add obj normally
						[[stackObjects objectAtIndex:[stackObjects count]-2] setObject:[[stackObjects lastObject] mutableCopy] forKey:[stackObjectNames lastObject]];
					}
					else{		// If object does exist, if it's an array, add it to the array. If it's not an array, create one
						id collisionObject = [[stackObjects objectAtIndex:[stackObjects count]-2] objectForKey:[stackObjectNames lastObject]];
						if ([collisionObject isKindOfClass:[NSMutableArray class]]){		// If it's an array, add this to the end of it
							[collisionObject addObject:[stackObjects lastObject]];
						}
						else{
							NSMutableArray *collisionArray = [[NSMutableArray alloc] initWithObjects:collisionObject,[stackObjects lastObject],nil];
							[[stackObjects objectAtIndex:[stackObjects count]-2] setObject:[collisionArray mutableCopy] forKey:[stackObjectNames lastObject]];
						}
					}
					[stackObjects removeLastObject];
					[stackObjectNames removeLastObject];
					currentObject = [stackObjects lastObject];
				}
				else
				{
					[objectsToReturn addObject:[currentObject mutableCopy]];
					currentObject = nil;
					[stackObjects removeLastObject];
					[stackObjectNames removeLastObject];
				}
			}
		}
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	[stackXMLNames release];			// Names of the XML tags
	[stackObjectNames release];		// Names of the objects in the XML file
	[stackObjects release];			// Array of the objects in the stack
	[currentElementString release];	// The current element string being read by the file
	if (self.delegate !=NULL && [self.delegate respondsToSelector:@selector(arrayFromFetcher:)]){
		[delegate arrayFromFetcher:objectsToReturn];
	}
}
	
- (void)dealloc {
	[objectsToReturn release];
	[delegate release];
	[super dealloc];
}

@end
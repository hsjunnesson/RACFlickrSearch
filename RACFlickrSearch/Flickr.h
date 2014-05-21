//
//  Flickr.h
//  RACFlickrSearch
//
//  Created by Hans Sjunnesson on 18/05/14.
//  Copyright (c) 2014 Hans Sjunnesson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Flickr : NSObject

+ (RACCommand *)searchCommand;

@end

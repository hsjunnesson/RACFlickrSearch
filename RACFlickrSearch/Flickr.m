//
//  Flickr.m
//  RACFlickrSearch
//
//  Created by Hans Sjunnesson on 18/05/14.
//  Copyright (c) 2014 Hans Sjunnesson. All rights reserved.
//

#import "Flickr.h"

static RACCommand *gSearchCommand = nil;

@implementation Flickr

+ (RACCommand *)searchCommand {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gSearchCommand = [RACCommand alloc] initWithSignalBlock:^RACSignal *(NSString *query) {
            // Send search query to Flickr api
            RACSignal *searchSignal = [[[[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                NSURL *searchURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=8f18ebc81b7788a6138f467befb0b2ce&text=%@&format=json&nojsoncallback=1", [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:searchURL] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        [subscriber sendError:error];
                        return;
                    }
                    
                    NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                    
                    if (error) {
                        [subscriber sendError:error];
                        return;
                    }
                    
                    [subscriber sendNext:results];
                    [subscriber sendCompleted];
                }];
                
                [task resume];
                
                return [RACDisposable disposableWithBlock:^{
                    [task cancel];
                }];
            }]
            // Extract photos json from search results
            flattenMap:^RACStream *(NSDictionary *d) {
                return [[d[@"photos"][@"photo"] rac_sequence] signal];
            }]
            // Map each photo json to a url which corresponds to the square thumbnail.
            map:^id(NSDictionary *photo) {
                // http://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg
                NSString *farm = photo[@"farm"];
                NSString *server = photo[@"server"];
                NSString *photoId = photo[@"id"];
                NSString *secret = photo[@"secret"];
                NSString *s = [NSString stringWithFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_q.jpg", farm, server, photoId, secret];
                return [NSURL URLWithString:s];
            }]
            // Limit to only 64 urls
            take:64]
            // Take each url, fetch them as an UIImage.
            flattenMap:^RACStream *(NSURL *imageUrl) {
                return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:imageUrl] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        if (error) {
                            [subscriber sendError:error];
                            return;
                        }

                        UIImage *image = [UIImage imageWithData:data];
                        
                        [subscriber sendNext:image];
                        [subscriber sendCompleted];
                    }];
                    
                    [task resume];
                    
                    return [RACDisposable disposableWithBlock:^{
                        [task cancel];
                    }];
                }];
            }]
            // Wait until all images are fetched, collect them into an array.
            collect];
            
            return searchSignal;
        }];
    });



    return gSearchCommand;
}


@end

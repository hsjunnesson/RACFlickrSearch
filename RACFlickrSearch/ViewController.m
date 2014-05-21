//
//  ViewController.m
//  RACFlickrSearch
//
//  Created by Hans Sjunnesson on 18/05/14.
//  Copyright (c) 2014 Hans Sjunnesson. All rights reserved.
//

#import "ViewController.h"
#import "Flickr.h"


@interface PhotoCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

@end

@implementation PhotoCell

@end


@interface ViewController ()

@property (strong) NSArray *photos;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong) RACSubject *searchSubject;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchSubject = [RACReplaySubject replaySubjectWithCapacity:1];
    
    @weakify(self);
    
    RACCommand *searchCommand = [Flickr searchCommand];
    
    [[self.searchSubject distinctUntilChanged] subscribeNext:^(NSString *searchQuery) {
        [searchCommand execute:searchQuery];
    }];
    
    [searchCommand.executing subscribeNext:^(NSNumber *executing) {
        BOOL isExecuting = [executing boolValue];
        UIApplication* app = [UIApplication sharedApplication];
        app.networkActivityIndicatorVisible = isExecuting;
    }];
    
    [[[searchCommand.executionSignals
       switchToLatest]
       deliverOn:[RACScheduler mainThreadScheduler]]
       subscribeNext:^(NSArray *photos) {
           @strongify(self);
           self.photos = photos;
           [self.collectionView reloadData];
       }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar endEditing:YES];
    [self.searchSubject sendNext:searchBar.text];
}


#pragma mark - 

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.photos count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Photo" forIndexPath:indexPath];
    
    cell.photoImageView.image = self.photos[indexPath.item];
    
    return cell;
}

@end

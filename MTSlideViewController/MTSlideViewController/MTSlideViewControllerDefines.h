//
//  MTSlideViewControllerDefines.h
//  MTSlideViewController
//
//  Created by Matthias Tretter on 21.01.11.
//  Copyright (c) 2009-2012  Matthias Tretter, @myell0w. All rights reserved.
//  Based on the original work of Andrew Carter: (c) 2001 Andrew Carter
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>

@class MTSlideViewController;

////////////////////////////////////////////////////////////////////////
#pragma mark - Defines
////////////////////////////////////////////////////////////////////////

#define kMTSlideViewControllerSectionTitleKey           @"kMTSlideViewControllerSectionTitleKey"
#define kMTSlideViewControllerSectionTitleNoTitle       @"kMTSlideViewControllerSectionTitleNoTitle"
#define kMTSlideViewControllerSectionViewControllersKey @"kMTSlideViewControllerSectionViewControllersKey"
#define kMTSlideViewControllerViewControllerTitleKey    @"kMTSlideViewControllerViewControllerTitleKey"
#define kMTSlideViewControllerViewControllerIconKey     @"kMTSlideViewControllerViewControllerIconKey"
#define kMTSlideViewControllerViewControllerKey         @"kMTSlideViewControllerViewControllerKey"

typedef enum {
    MTSlideViewControllerStateNormal = 0,
    MTSlideViewControllerStateDragging,
    MTSlideViewControllerStatePeeking,
    MTSlideViewControllerStateDrilledDown,
    MTSlideViewControllerStateSearching
} MTSlideViewControllerState;

////////////////////////////////////////////////////////////////////////
#pragma mark - MTSlideViewControllerDataSource
////////////////////////////////////////////////////////////////////////

@protocol MTSlideViewControllerDataSource <NSObject>

@optional
- (NSIndexPath *)initialSelectedIndexPathForSlideViewController:(MTSlideViewController *)slideViewController;
- (void)slideViewController:(MTSlideViewController *)slideViewController searchTermDidChange:(NSString *)searchTerm;
- (NSArray *)searchDatasourceForSlideViewController:(MTSlideViewController *)slideViewController;

@required
- (UIViewController *)initialViewControllerForSlideViewController:(MTSlideViewController *)slideViewController;
- (NSArray *)datasourceForSlideViewController:(MTSlideViewController *)slideViewController;

@end

////////////////////////////////////////////////////////////////////////
#pragma mark - MTSlideViewControllerDelegate
////////////////////////////////////////////////////////////////////////

@protocol MTSlideViewControllerDelegate <NSObject>

@optional
- (void)slideViewController:(MTSlideViewController *)slideViewController 
    didSelectViewController:(UIViewController *)viewController
                atIndexPath:(NSIndexPath *)indexPath;

- (void)slideViewControllerDidBeginSearching:(MTSlideViewController *)slideViewController;
- (void)slideViewControllerDidEndSearching:(MTSlideViewController *)slideViewController;

@end

////////////////////////////////////////////////////////////////////////
#pragma mark - MTSlideViewControllerSlideDelegate
////////////////////////////////////////////////////////////////////////

@protocol MTSlideViewControllerSlideDelegate <NSObject>

@optional
- (BOOL)shouldSlideOut;

@end

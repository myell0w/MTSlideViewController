#import "MTSlideViewController.h"
#import "MTSlideViewTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

#define kMTLeftAnchorX                  100.0f
#define kMTRightAnchorX                 190.0f
#define kMTSlideAnimationDuration       0.2


@interface MTSlideViewController () <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UISearchBarDelegate, UITextFieldDelegate> {
    BOOL rotationEnabled_;
    CGPoint startingDragPoint_;
    CGFloat startingDragTransformTx_;
}

@property (nonatomic, strong, readwrite) UINavigationController *slideNavigationController;
@property (nonatomic, strong, readwrite) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIImageView *searchBarBackgroundView;
@property (nonatomic, assign) MTSlideNavigationControllerState slideNavigationControllerState;

- (void)configureViewController:(UIViewController *)viewController;
- (void)menuBarButtonItemPressed:(id)sender;
- (void)handleNavigationBarPan:(UIPanGestureRecognizer *)gestureRecognizer;

- (void)handleTouchesBeganAtLocation:(CGPoint)location;
- (void)handleTouchesMovedToLocation:(CGPoint)location;
- (void)handleTouchesEndedAtLocation:(CGPoint)location;

@end

@implementation MTSlideViewController

@synthesize slideNavigationController = slideNavigationController_;
@synthesize searchBar = searchBar_;
@synthesize searchBarBackgroundView = searchBarBackgroundView_;
@synthesize tableView = tableView_;
@synthesize slideNavigationControllerState = slideNavigationControllerState_;
@synthesize delegate = delegate_;
@synthesize dataSource = dataSource_;
@synthesize slideOnNavigationBarOnly = slideOnNavigationBarOnly_;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nil])) {
        rotationEnabled_ = YES;
        slideOnNavigationBarOnly_ = NO;
        slideNavigationControllerState_ = MTSlideNavigationControllerStateNormal;
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController
////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    
    searchBarBackgroundView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 44.f)];
    searchBarBackgroundView_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:searchBarBackgroundView_];
    
    searchBar_ = [[UISearchBar alloc] initWithFrame:searchBarBackgroundView_.frame];
    searchBar_.delegate = self;
    searchBar_.showsCancelButton = YES;
    searchBar_.tintColor = [UIColor colorWithRed:36.f/255.f green:43.f/255.f blue:57.f/255.f alpha:1.f];
    [self.view addSubview:searchBar_];
    
    tableView_ = [[UITableView alloc] initWithFrame:CGRectMake(0.f, 44.f, 320.f, self.view.bounds.size.height-44.f) style:UITableViewStylePlain];
    tableView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView_.backgroundColor = [UIColor colorWithRed:50.f/255.f green:57.f/255.f blue:74.f/255.f alpha:1.f];
    tableView_.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView_.delegate = self;
    tableView_.dataSource = self;
    [self.view addSubview:tableView_];
    
    if (![self.dataSource respondsToSelector:@selector(slideViewController:searchTermDidChange:)] || 
        ![self.dataSource respondsToSelector:@selector(searchDatasourceForSlideViewController:)]) {
        searchBar_.hidden = YES;
        searchBarBackgroundView_.hidden = YES;
        tableView_.frame = CGRectMake(0.0f, 0.0f, 320.0f, self.view.bounds.size.height);
    }
    
    UIViewController *initalViewController = [self.dataSource initialViewControllerForSlideViewController:self];
    [self configureViewController:initalViewController];
    
    slideNavigationController_ = [[UINavigationController alloc] initWithRootViewController:initalViewController];
    slideNavigationController_.delegate = self;
    slideNavigationController_.view.layer.shadowColor = [[UIColor blackColor] CGColor];
    slideNavigationController_.view.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    slideNavigationController_.view.layer.shadowRadius = 4.0f;
    slideNavigationController_.view.layer.shadowOpacity = 0.75f;
    [slideNavigationController_ willMoveToParentViewController:self];
    [self addChildViewController:slideNavigationController_];
    [self.view addSubview:slideNavigationController_.view];
    [slideNavigationController_ didMoveToParentViewController:self];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:slideNavigationController_.view.bounds cornerRadius:4.0];
    slideNavigationController_.view.layer.shadowPath = path.CGPath;
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleNavigationBarPan:)];
    [slideNavigationController_.navigationBar addGestureRecognizer:panRecognizer];
    
    UIImage *searchBarBackground = [UIImage imageNamed:@"MTSlideViewController.bundle/search_bar_background"];
    [searchBar_ setBackgroundImage:[searchBarBackground stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
    searchBarBackgroundView_.image = [searchBarBackground stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    searchBar_.placeholder = NSLocalizedString(@"Search", @"Search");

    
    if ([self.dataSource respondsToSelector:@selector(initialSelectedIndexPathForSlideViewController:)]) {
        [tableView_ selectRowAtIndexPath:[self.dataSource initialSelectedIndexPathForSlideViewController:self]
                                animated:NO 
                          scrollPosition:UITableViewScrollPositionTop];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.searchBar = nil;
    self.searchBarBackgroundView = nil;
    self.tableView = nil;
    self.slideNavigationController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return rotationEnabled_ && toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - SlideViewController
////////////////////////////////////////////////////////////////////////

- (void)configureViewController:(UIViewController *)viewController {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MTSlideViewController.bundle/menu_icon"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(menuBarButtonItemPressed:)];
    
    viewController.navigationItem.leftBarButtonItem = barButtonItem;
}

- (void)menuBarButtonItemPressed:(id)sender {
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStatePeeking) {
        [self slideInSlideNavigationControllerView];
        return;
    }
    
    UIViewController *currentViewController = [[slideNavigationController_ viewControllers] objectAtIndex:0];
    
    if ([currentViewController conformsToProtocol:@protocol(MTSlideViewControllerSlideDelegate)]
        && [currentViewController respondsToSelector:@selector(shouldSlideOut)]) {
        if ([(id <MTSlideViewControllerSlideDelegate>)currentViewController shouldSlideOut]) {
            [self slideOutSlideNavigationControllerView];
        }
    } else {
        [self slideOutSlideNavigationControllerView];
    }
}

- (void)slideOutSlideNavigationControllerView {
    slideNavigationControllerState_ = MTSlideNavigationControllerStatePeeking;
    
    slideNavigationController_.topViewController.view.userInteractionEnabled = NO;
    [UIView animateWithDuration:kMTSlideAnimationDuration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState 
                     animations:^{
                         slideNavigationController_.view.transform = CGAffineTransformMakeTranslation(260.f, 0.f);
                     } completion:^(BOOL finished) {
                         searchBar_.frame = CGRectMake(0.f, 0.f, 320.f, searchBar_.frame.size.height);        
                     }];
}

- (void)slideInSlideNavigationControllerView {
    [UIView animateWithDuration:kMTSlideAnimationDuration 
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         slideNavigationController_.view.transform = CGAffineTransformIdentity;
                     } completion:^(BOOL finished) {
                         slideNavigationController_.topViewController.view.userInteractionEnabled = YES;
                         [self cancelSearching];
                         slideNavigationControllerState_ = MTSlideNavigationControllerStateNormal;
                     }];
}

- (void)slideSlideNavigationControllerViewOffScreen {
    slideNavigationControllerState_ = MTSlideNavigationControllerStateSearching;
    
    [UIView animateWithDuration:kMTSlideAnimationDuration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut  | UIViewAnimationOptionBeginFromCurrentState 
                     animations:^{
                         CGFloat width = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? 480.f : 320.f;
                         
                         slideNavigationController_.view.transform = CGAffineTransformMakeTranslation(width, 0.0f);
                         searchBar_.frame = CGRectMake(0.f, 0.f, width, searchBar_.frame.size.height);
                         
                     } completion:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIGestureRecognizer
////////////////////////////////////////////////////////////////////////

- (void)handleNavigationBarPan:(UIPanGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self handleTouchesBeganAtLocation:[gestureRecognizer locationInView:self.view]];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        [self handleTouchesMovedToLocation:[gestureRecognizer locationInView:self.view]];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
               gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        [self handleTouchesEndedAtLocation:[gestureRecognizer locationInView:self.view]];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UITouch Handling
////////////////////////////////////////////////////////////////////////

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    [self handleTouchesBeganAtLocation:[touch locationInView:self.view]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    [self handleTouchesMovedToLocation:[touch locationInView:self.view]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    [self handleTouchesEndedAtLocation:[touch locationInView:self.view]];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UINavigationControllerDelegate
////////////////////////////////////////////////////////////////////////

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self cancelSearching];
    
    if ([navigationController viewControllers].count > 1) {
        slideNavigationControllerState_ = MTSlideNavigationControllerStateDrilledDown;
    } else {
        slideNavigationControllerState_ = MTSlideNavigationControllerStateNormal;
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource
////////////////////////////////////////////////////////////////////////

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStateSearching) {
        return [self.dataSource searchDatasourceForSlideViewController:self].count;
    } else {
        return [[[[self.dataSource datasourceForSlideViewController:self] objectAtIndex:section] objectForKey:kMTSlideViewControllerSectionViewControllersKey] count];        
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStateSearching) {
        return 1;
    } else {
        return [self.dataSource datasourceForSlideViewController:self].count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MTSlideViewTableViewCell *cell = [MTSlideViewTableViewCell cellForTableView:tableView style:UITableViewCellStyleDefault ];
    NSDictionary *viewControllerDictionary = nil;
    
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStateSearching) {
        viewControllerDictionary = [[self.dataSource searchDatasourceForSlideViewController:self] objectAtIndex:indexPath.row];
    } else {
        viewControllerDictionary = [[[[self.dataSource datasourceForSlideViewController:self] objectAtIndex:indexPath.section] objectForKey:kMTSlideViewControllerSectionViewControllersKey] objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = [viewControllerDictionary objectForKey:kMTSlideViewControllerViewControllerTitleKey];
    
    if ([[viewControllerDictionary objectForKey:kMTSlideViewControllerViewControllerIconKey] isKindOfClass:[UIImage class]]) {
        cell.imageView.image = [viewControllerDictionary objectForKey:kMTSlideViewControllerViewControllerIconKey];
    } else {
        cell.imageView.image = nil;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStateSearching) {
        return nil;
    }
    
    NSDictionary *sectionDictionary = [[self.dataSource datasourceForSlideViewController:self] objectAtIndex:section];
    
    if ([sectionDictionary objectForKey:kMTSlideViewControllerSectionTitleKey]) {
        NSString *sectionTitle = [sectionDictionary objectForKey:kMTSlideViewControllerSectionTitleKey];
        
        if ([sectionTitle isEqualToString:kMTSlideViewControllerSectionTitleNoTitle]) {
            return nil;
        } else {
            return sectionTitle;
        }
    } else {
        return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStateSearching) {
        return nil;
    }
    
    NSString *titleString = [self tableView:tableView titleForHeaderInSection:section];
    
    if (titleString == nil) {
        return nil;
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.bounds.size.width, 22.0f)];
    imageView.image = [[UIImage imageNamed:@"MTSlideViewController.bundle/section_background"] stretchableImageWithLeftCapWidth:0.0f topCapHeight:0.0f];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(imageView.frame, 10.0f, 0.0f)];
    titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12.0f];
    titleLabel.textAlignment = UITextAlignmentLeft;
    titleLabel.textColor = [UIColor colorWithRed:125.0f/255.0f green:129.0f/255.0f blue:146.0f/255.0f alpha:1.0f];
    titleLabel.shadowColor = [UIColor colorWithRed:40.0f/255.0f green:45.0f/255.0f blue:57.0f/255.0f alpha:1.0f];
    titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = titleString;
    [imageView addSubview:titleLabel];
    
    return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStateSearching) {
        return 0.0f;
    } else if ([self tableView:tableView titleForHeaderInSection:section]) {
        return 22.0f;
    } else {
        return 0.0f;
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDelegate
////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *viewControllerDictionary = nil;
    
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStateSearching) {
        viewControllerDictionary = [[self.dataSource searchDatasourceForSlideViewController:self] objectAtIndex:indexPath.row];
    } else {
        viewControllerDictionary = [[[[self.dataSource datasourceForSlideViewController:self] objectAtIndex:indexPath.section] objectForKey:kMTSlideViewControllerSectionViewControllersKey] objectAtIndex:indexPath.row];
    }
    
    id viewController = [viewControllerDictionary objectForKey:kMTSlideViewControllerViewControllerKey];
    
    if ([self.delegate respondsToSelector:@selector(slideViewController:didSelectViewController:atIndexPath:)]) {
        [self.delegate slideViewController:self
                   didSelectViewController:viewController
                               atIndexPath:indexPath];
    }
    
    [self configureViewController:viewController];
    [slideNavigationController_ setViewControllers:[NSArray arrayWithObject:viewController] animated:NO];
    [self slideInSlideNavigationControllerView];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UISearchBarDelegate
////////////////////////////////////////////////////////////////////////

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if ([self.dataSource respondsToSelector:@selector(slideViewController:searchTermDidChange:)]) {
        [self slideSlideNavigationControllerViewOffScreen];
        [self.dataSource slideViewController:self searchTermDidChange:searchBar.text];
        [tableView_ reloadData];
    }
    
    rotationEnabled_ = NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([self.dataSource respondsToSelector:@selector(slideViewController:searchTermDidChange:)]) {
        [self.dataSource slideViewController:self searchTermDidChange:searchBar.text];
        [tableView_ reloadData];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    rotationEnabled_ = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self cancelSearching];
    [self slideOutSlideNavigationControllerView];
    [tableView_ reloadData];
    rotationEnabled_ = YES;
}

- (void)cancelSearching {
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStateSearching) {
        [searchBar_ resignFirstResponder];
        slideNavigationControllerState_ = MTSlideNavigationControllerStateNormal;
        searchBar_.text = @"";
        [tableView_ reloadData];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)handleTouchesBeganAtLocation:(CGPoint)location {
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStateDrilledDown
        || slideNavigationControllerState_ == MTSlideNavigationControllerStateSearching) {
        return;
    }
    
    startingDragPoint_ = location;
    
    if ((CGRectContainsPoint(slideNavigationController_.view.frame, startingDragPoint_)) && 
        slideNavigationControllerState_ == MTSlideNavigationControllerStatePeeking) {
        slideNavigationControllerState_ = MTSlideNavigationControllerStateDragging;
        startingDragTransformTx_ = slideNavigationController_.view.transform.tx;
    }
    
    // we only trigger a swipe if either navigationBarOnly is deactivated
    // or we swiped in the navigationBar
    if (!self.slideOnNavigationBarOnly || startingDragPoint_.y <= self.slideNavigationController.navigationBar.frame.size.height) {
        slideNavigationControllerState_ = MTSlideNavigationControllerStateDragging;
        startingDragTransformTx_ = slideNavigationController_.view.transform.tx;
    }
}

- (void)handleTouchesMovedToLocation:(CGPoint)location {
    if (slideNavigationControllerState_ != MTSlideNavigationControllerStateDragging) {
        return;
    }
    
    [UIView animateWithDuration:0.05f 
                          delay:0.0f 
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState 
                     animations:^{
                         slideNavigationController_.view.transform = CGAffineTransformMakeTranslation(MAX(startingDragTransformTx_ + (location.x - startingDragPoint_.x), 0.0f), 0.0f);
                     } completion:nil];
}

- (void)handleTouchesEndedAtLocation:(CGPoint)location {
    if (slideNavigationControllerState_ == MTSlideNavigationControllerStateDragging) {
        // Check in which direction we were dragging
        if (location.x < startingDragPoint_.x) {
            if (slideNavigationController_.view.transform.tx <= kMTRightAnchorX) {
                [self slideInSlideNavigationControllerView];
            } else {
                [self slideOutSlideNavigationControllerView]; 
            }
        } else {
            if (slideNavigationController_.view.transform.tx >= kMTLeftAnchorX) {
                [self slideOutSlideNavigationControllerView];
            } else {
                [self slideInSlideNavigationControllerView];
            }
        }
    }
}

@end

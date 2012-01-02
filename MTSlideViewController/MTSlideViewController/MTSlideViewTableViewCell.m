#import "MTSlideViewTableViewCell.h"

@implementation MTSlideViewTableViewCell

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

+ (NSString *)cellIdentifier {
    return NSStringFromClass([self class]);
}

+ (id)cellForTableView:(UITableView *)tableView style:(UITableViewCellStyle)cellStyle {
    NSString *cellID = [NSString stringWithFormat:@"%@_%d", [self cellIdentifier], cellStyle];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil) {
        cell = [[self alloc] initWithStyle:cellStyle reuseIdentifier:cellID];
    }
    
    return cell; 
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {    
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        UIImageView *background = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
        [background setImage:[[UIImage imageNamed:@"MTSlideViewController.bundle/cell_background"] stretchableImageWithLeftCapWidth:0.0f topCapHeight:0.0f]];
        self.backgroundView = background;
        
        UIImageView *selectedBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
        [selectedBackground setImage:[[UIImage imageNamed:@"MTSlideViewController.bundle/cell_selected_background"] stretchableImageWithLeftCapWidth:0.0f topCapHeight:0.0f]];
        self.selectedBackgroundView = selectedBackground;
        
        self.textLabel.textColor = [UIColor colorWithRed:190.0f/255.0f green:197.0f/255.0f blue:212.0f/255.0f alpha:1.0f];
        self.textLabel.highlightedTextColor = self.textLabel.textColor;
        self.textLabel.shadowColor = [UIColor colorWithRed:33.0f/255.0f green:38.0f/255.0f blue:49.0f/255.0f alpha:1.0f];
        self.textLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0f];
        
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(5.0f, 5.0f, 34.0f, 34.0f);
    
}

@end

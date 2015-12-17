//
//  ViewController.m
//  ReverseTable
//
//  Created by nataliepo on 12/7/15.
//

#import "ViewController.h"

static NSUInteger StartingValue = 200;
static NSUInteger ValuesPerPage = 50;

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *data;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIView *headerView;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) UILabel *upToDateLabel;

@property (nonatomic) BOOL needsRefresh;
@property (nonatomic) BOOL isRedrawing;
@property (nonatomic) BOOL isUpToDate;

- (void)beginToDrawMore;
- (void)loadPreviousPageData;
- (void)drawPreviousPage;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    self.headerView = [UIView new];
    self.headerView.frame = (CGRect){CGPointZero, [UIScreen mainScreen].bounds.size.width, 50};
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = self.headerView.center;
    self.spinner.tintColor = [UIColor redColor];
    [self.spinner hidesWhenStopped];
    [self.headerView addSubview:self.spinner];
    
    self.upToDateLabel = [UILabel new];
    self.upToDateLabel.text = @"You're up to date!";
    self.upToDateLabel.textAlignment = NSTextAlignmentCenter;
    self.upToDateLabel.alpha = 0; // hidden by default.
    self.upToDateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:10];
    self.upToDateLabel.frame = (CGRect){0, (self.headerView.frame.size.height - 16) / 2.0, self.headerView.frame.size.width, 16};
    [self.headerView addSubview:self.upToDateLabel];
    
    self.tableView = [UITableView new];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 50;
    self.tableView.allowsSelection = NO;
    self.tableView.frame = (CGRect){0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 20};

    [self.view addSubview:self.tableView];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    
    [self resetData];
 
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(resetData) forControlEvents:UIControlEventTouchUpInside];
    resetButton.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    resetButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
    resetButton.layer.cornerRadius = 5;
    resetButton.frame = (CGRect){10, [UIScreen mainScreen].bounds.size.height - 50, 100, 40};
    [self.view addSubview:resetButton];
}

- (void)resetData {
    self.data = @[].mutableCopy;
    for (NSUInteger i = StartingValue - ValuesPerPage; i < StartingValue; i++) {
        [self.data addObject:@(i + 1)];
    }

    self.needsRefresh = NO;
    self.isUpToDate = NO;
    self.isRedrawing = NO;
    
    [self.tableView reloadData];
    
    // scroll to the bottom.
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.data.count inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)beginToDrawMore {
    
    if (self.isRedrawing) {
        return;
    }
    
    self.needsRefresh = YES;

    // don't draw while dragging.
    if (self.tableView.isDragging) {
        return;
    }
    
    self.isRedrawing = YES;
    [self.spinner startAnimating];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Prepare data.
        [self loadPreviousPageData];
        [self drawPreviousPage];
    });
}

- (void)loadPreviousPageData {
    if (self.data.count == StartingValue && !self.isUpToDate) {
        self.needsRefresh = NO;
        [self.spinner stopAnimating];

        return;
    }
    NSMutableArray *newValues = @[].mutableCopy;
    for (NSInteger i = ValuesPerPage; i > 0; i--) {
        [newValues addObject:@(StartingValue - self.data.count - i + 1)];
    }
    
    self.data = [[newValues arrayByAddingObjectsFromArray:self.data] mutableCopy];
    
    // determine if you're up to date BEFORE drawing anything new.
    self.isUpToDate = self.data.count == StartingValue;
}

- (void)drawPreviousPage {
    CGFloat currentHeight = self.tableView.contentSize.height;
    [self.tableView reloadData];
    [self.tableView setContentOffset:(CGPoint){0, self.tableView.contentSize.height - currentHeight} animated:NO];
    [self.spinner stopAnimating];
    
    self.needsRefresh = NO;
    self.isRedrawing = NO;
}

#pragma mark - UITableViewDatasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.data) {
        return 0;
    }
    
    return self.data.count + (self.isUpToDate ? 0 : 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 && !self.isUpToDate) {
        // header cell.
        UITableViewCell *header = [tableView dequeueReusableCellWithIdentifier:@"Header"];
        if (!header) {
            header = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Header"];
            [header addSubview:self.headerView];
        }
        return header;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Row: %d", [self.data[indexPath.row - (self.isUpToDate ? 0 : 1)] intValue]];
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 && !self.isUpToDate) {
        [self.spinner startAnimating];
        [self beginToDrawMore];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.needsRefresh) {
        if (scrollView.contentOffset.y <= 0) {
            [self beginToDrawMore];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y <= self.headerView.frame.size.height / 2.0 && self.needsRefresh && !self.isRedrawing && !self.isUpToDate && !scrollView.isDragging) {
        [self beginToDrawMore];
    }
}

@end

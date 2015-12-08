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
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) BOOL needsRefresh;

- (void)beginToDrawMore;
- (void)loadPreviousPageData;
- (void)drawPreviousPage;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [UITableView new];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.frame = (CGRect){0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 20};

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor colorWithWhite:0.3 alpha:.7];
    [self.refreshControl addTarget:self action:@selector(beginToDrawMore) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

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

    [self.tableView reloadData];
    
    // scroll to the bottom.
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.data.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)beginToDrawMore {
    self.needsRefresh = YES;
    
    if (self.tableView.isDragging) {
        return;
    }
    CGRect firstRow = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat yOffset = firstRow.origin.y - self.refreshControl.frame.size.height;
    
    [self.tableView setContentOffset:CGPointMake(0, yOffset) animated:YES];
    [self.refreshControl beginRefreshing];
    
    // Prepare data.
    [self loadPreviousPageData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self drawPreviousPage];
    });
}

- (void)loadPreviousPageData {
    if (self.data.count == StartingValue) {
        // stop refreshing.
        [self.tableView setContentOffset:CGPointZero animated:YES];
        [self.refreshControl endRefreshing];
        
        return;
    }
    NSMutableArray *newValues = @[].mutableCopy;
    for (NSInteger i = ValuesPerPage; i > 0; i--) {
        [newValues addObject:@(StartingValue - self.data.count - i + 1)];
    }
    
    self.data = [[newValues arrayByAddingObjectsFromArray:self.data] mutableCopy];
}

- (void)drawPreviousPage {
    
    CGFloat currentHeight = self.tableView.contentSize.height;
    [self.tableView reloadData];
    
    [self.tableView setContentOffset:(CGPoint){0, self.tableView.contentSize.height - currentHeight - self.refreshControl.frame.size.height} animated:NO];
    
    [self.refreshControl endRefreshing];

    self.needsRefresh = NO;
}

#pragma mark - UITableViewDatasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Row: %d", [self.data[indexPath.row] intValue]];
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y <= 0 && self.needsRefresh) {
        [self beginToDrawMore];
    }
}
@end

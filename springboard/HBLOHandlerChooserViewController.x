#import "HBLOHandlerChooserViewController.h"
#import <version.h>

@implementation HBLOHandlerChooserViewController {
	NSURL *_url;
	NSArray *_items;

	NSDictionary *_sections;
}

- (instancetype)initWithURL:(NSURL *)url items:(NSArray *)items {
	if (!IS_IOS_OR_NEWER(iOS_8_0)) {
		return nil;
	}

	self = [self init];

	if (self) {
		_url = [url copy];
		_items = [items copy];

		self.presentationStyle = UIModalPresentationOverFullScreen;
	}

	return self;
}

- (void)loadView {
	[super loadView];

	_contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 410.f)];
	_contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_contentView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:_contentView];

	_backgroundView = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	_backgroundView.frame = CGRectMake(0, 0, _contentView.frame.size.width, 0);
	_backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_backgroundView.backgroundColor = [UIColor colorWithWhite:100.f / 255.f alpha:0.25f];
	[_backgroundView addTarget:self action:@selector(cancelButtonTouchBegan) forControlEvents:UIControlEventTouchDown];
	[_backgroundView addTarget:self action:@selector(cancelButtonTouchBegan) forControlEvents:UIControlEventTouchDragEnter];
	[_backgroundView addTarget:self action:@selector(cancelButtonTouchEnded) forControlEvents:UIControlEventTouchDragExit];
	[_backgroundView addTarget:self action:@selector(cancelButtonTouchEnded) forControlEvents:UIControlEventTouchCancel];
	[_backgroundView addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_backgroundView];

	_cancelButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	_cancelButton.frame = CGRectMake(0, _contentView.frame.size.height - 53.f, _contentView.frame.size.width, 53.f);
	_cancelButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_cancelButton.titleLabel.font = [UIFont systemFontOfSize:23.f];
	[_cancelButton setTitle:L18N(@"Cancel") forState:UIControlStateNormal];
	[_cancelButton addTarget:self action:@selector(cancelButtonTouchBegan) forControlEvents:UIControlEventTouchDown];
	[_cancelButton addTarget:self action:@selector(cancelButtonTouchBegan) forControlEvents:UIControlEventTouchDragEnter];
	[_cancelButton addTarget:self action:@selector(cancelButtonTouchEnded) forControlEvents:UIControlEventTouchDragExit];
	[_cancelButton addTarget:self action:@selector(cancelButtonTouchEnded) forControlEvents:UIControlEventTouchCancel];
	[_cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
	[_contentView addSubview:_cancelButton];

	[self _setupSections];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];

	CGRect contentFrame = _contentView.frame;
	contentFrame.origin.y = self.view.frame.size.height;
	contentFrame.size.height = ((CGFloat)_items.allKeys.count * [HBAPActivitySectionView height]) + _cancelButton.frame.size.height;
	_contentView.frame = contentFrame;

	CGRect backgroundFrame = _backgroundView.frame;
	backgroundFrame.size.height = self.view.frame.size.height;
	_backgroundView.frame = backgroundFrame;
}

- (void)viewWillAppear:(BOOL)animated {
	_backgroundView.alpha = 0;

	void (^animationBlock)() = ^{
		_backgroundView.alpha = 1;

		CGRect contentFrame = _contentView.frame;
		contentFrame.origin.y -= contentFrame.size.height;
		_contentView.frame = contentFrame;

		CGRect backgroundFrame = _backgroundView.frame;
		backgroundFrame.size.height = contentFrame.origin.y;
		_backgroundView.frame = backgroundFrame;
	};

	if (animated) {
		[UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1.f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseIn animations:animationBlock completion:NULL];
	} else {
		animationBlock();
	}
}

#pragma mark - Sections

- (void)_setupSections {
	for (UIView *view in _contentView.subviews) {
		if ([view isKindOfClass:HBLOActivitySectionView.class]) {
			[view removeFromSuperview];
		}
	}

	NSMutableDictionary *sectionItems = [NSMutableDictionary dictionary];

	for (HBLOActivity *activity in _items) {
		if (!sectionItems[@(activity.category)]) {
			sectionItems[@(activity.category)] = [NSMutableArray array];
		}

		[sectionItems[@(activity.category)] addObject:activity];
	}

	NSMutableDictionary *newSections = [NSMutableDictionary dictionary];

	CGFloat top = 0;

	for (NSNumber *key in sectionItems.allKeys) {
		UIActivityGroupViewController *viewController = [[[%c(UIActivityGroupViewController) alloc] initWithActivityCategory:0 userDefaults:nil userDefaultsIdentifier:@"libopener"] autorelease];
		HBLOActivitySectionView *sectionView = [[[HBLOActivitySectionView alloc] initWithFrame:CGRectMake(0, top, _contentView.frame.size.width, 0) title:[HBLOActivity nameForCategory:key] items:_items[key]] autorelease];
		[_contentView addSubview:sectionView];
		[newSections addObject:sectionView];

		top += height;
	}

	_sections = [newSections copy];
}

#pragma mark - Callbacks

- (void)cancelButtonTouchBegan {
	[UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1.f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
		_cancelButton.backgroundColor = [UIColor colorWithWhite:100.f / 255.f alpha:0.35f];
	} completion:nil];
}

- (void)cancelButtonTouchEnded {
	[UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1.f initialSpringVelocity:1.f options:UIViewAnimationOptionCurveEaseOut animations:^{
		_cancelButton.backgroundColor = nil;
	} completion:nil];
}

- (void)cancelButtonTapped {
	[self dismissViewControllerAnimated:YES];
}

#pragma mark - Memory management

- (void)dealloc {
	[_url release];
	[_items release];

	[super dealloc];
}

@end

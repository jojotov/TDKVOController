//
//  ViewController.m
//  TDKVOControllerSample
//
//  Created by jojo on 2020/4/22.
//  Copyright © 2020 jojotov. All rights reserved.
//

#import "ViewController.h"
#import <TDKVOController/TDKVOController.h>

@interface TDKVOControllerSampleModel: NSObject
@property (nonatomic, copy  ) NSString *name;
@end
@implementation TDKVOControllerSampleModel
- (void)dealloc
{
    NSLog(@"Dealloc: %@", self);
}
@end


@interface TDKVOControllerSampleViewModel: NSObject
@property (nonatomic, strong) TDKVOControllerSampleModel *model;
@property (nonatomic, copy  ) NSAttributedString *attributedTitle;
@end


@implementation TDKVOControllerSampleViewModel

- (void)dealloc
{
    NSLog(@"Dealloc: %@", self);
}

- (void)setModel:(TDKVOControllerSampleModel *)model {
    _model = model;
    __weak __typeof(self) weakSelf = self;
    [self.td_KVOController observeValueForKeyPath:@"name" ofObject:model block:^(id  _Nullable observer,   TDKVOControllerSampleModel *object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
        NSString *newValue = change[NSKeyValueChangeNewKey];
        if (![newValue isKindOfClass:[NSString class]]) {
            return;
        }
        CGFloat r = arc4random() % 256 / 255.0;
        CGFloat g = arc4random() % 256 / 255.0;
        CGFloat b = arc4random() % 256 / 255.0;

        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:newValue attributes:@{
            NSForegroundColorAttributeName: [UIColor colorWithRed:r green:g blue:b alpha:1],
            NSFontAttributeName: [UIFont boldSystemFontOfSize:24.f]
        }];
        weakSelf.attributedTitle = attrString;
    }];
}

- (NSAttributedString *)attributedTitle {
    if (!_attributedTitle) {
        _attributedTitle = [[NSAttributedString alloc] initWithString:@"Click Me!" attributes:@{
            NSForegroundColorAttributeName: [UIColor redColor],
            NSFontAttributeName: [UIFont boldSystemFontOfSize:24.f]
        }];
    }
    return _attributedTitle;
}
@end

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *titleButton;
@property (weak, nonatomic) IBOutlet UILabel *oldValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *newerValueLabel;
@property (nonatomic, strong) TDKVOControllerSampleViewModel *viewModel;
@end

@implementation ViewController

- (void)dealloc
{
    NSLog(@"Dealloc: %@", self);
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleButton.layer.masksToBounds = YES;
    self.titleButton.layer.cornerRadius = 8.f;
    
    self.viewModel = [TDKVOControllerSampleViewModel new];
    
    __weak __typeof(self) weakSelf = self;
    [self.td_KVOController observeValueForKeyPath:@"attributedTitle" ofObject:self.viewModel block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
        NSLog(@"hit!!");
        NSAttributedString *newValue = change[NSKeyValueChangeNewKey];
        [weakSelf.titleButton setAttributedTitle:newValue forState:UIControlStateNormal];
    }];
    
    [self.oldValueLabel.td_KVOController observeValueForKeyPaths:@[@"attributedTitle"] ofObject:self.viewModel options:NSKeyValueObservingOptionOld block:^(UILabel *label, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
        NSAttributedString *oldValue = change[NSKeyValueChangeOldKey];
        if (oldValue) {
            label.attributedText = [weakSelf oldValueAttributedString:oldValue];
        }
    }];

    [self.newerValueLabel.td_KVOController observeValueForKeyPaths:@[@"attributedTitle"] ofObject:self.viewModel options:NSKeyValueObservingOptionNew block:^(UILabel *label, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
        NSAttributedString *newValue = change[NSKeyValueChangeNewKey];
        if (newValue) {
            label.attributedText = [weakSelf newerValueAttributedString:newValue];
        }
    }];
    
    TDKVOControllerSampleModel *model = [TDKVOControllerSampleModel new];
    self.viewModel.model = model;
}

- (IBAction)clickAction:(id)sender {
    NSArray *names = @[@"John", @"Lisa", @"Andrew", @"Wendy", @"Alice"];
    self.viewModel.model.name = names[(rand() % 5)];
}

- (NSAttributedString *)newerValueAttributedString:(NSAttributedString *)string {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@"New value: " attributes:@{
        NSForegroundColorAttributeName: [UIColor lightGrayColor],
        NSFontAttributeName: [UIFont italicSystemFontOfSize:18.f]
    }];
    [result appendAttributedString:string];
    return result.copy;
}

- (NSAttributedString *)oldValueAttributedString:(NSAttributedString *)string {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@"Old value: " attributes:@{
        NSForegroundColorAttributeName: [UIColor lightGrayColor],
        NSFontAttributeName: [UIFont italicSystemFontOfSize:18.f]
    }];
    [result appendAttributedString:string];
    return result.copy;
}
@end

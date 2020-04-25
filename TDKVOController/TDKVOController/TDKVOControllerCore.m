//
//  TDKVOControllerCore.m
//  TDKVOController
//
//  Created by jojo on 2020/4/22.
//  Copyright © 2020 jojotov. All rights reserved.
//

#import "TDKVOControllerCore.h"
#import <objc/runtime.h>

static NSKeyValueObservingOptions TDDefaultKVOOptions =
NSKeyValueObservingOptionNew |
NSKeyValueObservingOptionOld |
NSKeyValueObservingOptionInitial;

#pragma mark - Utilities
NSArray<NSString *> *td_MethodNamesOfClass(Class cls) {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    NSMutableArray<NSString *> *methodNames = [NSMutableArray arrayWithCapacity:count];
    
    for (unsigned int i = 0; i < count; i ++) {
        Method method = methods[i];
        NSString *methodName = NSStringFromSelector(method_getName(method));
        
        if (methodName.length) {
            [methodNames addObject:methodName];
        }
    }
    
    free(methods);
    return methodNames;
}

BOOL td_ContainsKeyPath(id target, NSString *keyPath) {
    if (!target || !keyPath.length) {
        return NO;
    }
    
    NSArray<NSString *> *methodNames = td_MethodNamesOfClass([target class]);
    return [methodNames containsObject:keyPath];
}


#pragma mark - TDKVOItem
NS_ASSUME_NONNULL_BEGIN
@interface TDKVOItem : NSObject

@property (nonatomic, weak  ) TDKVOController        *controller;
@property (nonatomic, weak  ) id                     target;
@property (nonatomic, strong) NSString               *keyPath;
@property (nonatomic, copy  ) TDKVONotificationBlock block;
@property (nonatomic, assign) NSKeyValueObservingOptions options;

+ (instancetype)KVOItemWithKeyPath:(NSString *)keyPath
                          ofTarget:(id)target
                        controller:(TDKVOController *)controller;

+ (instancetype)KVOItemWithKeyPath:(NSString *)keyPath
                          ofTarget:(id)target
                        controller:(TDKVOController *)controller
                             block:(TDKVONotificationBlock)block;

@end
NS_ASSUME_NONNULL_END

@implementation TDKVOItem

+ (instancetype)KVOItemWithKeyPath:(NSString *)keyPath
                          ofTarget:(id)target
                        controller:(TDKVOController *)controller {
    return [[self alloc] initWithKeyPath:keyPath ofTarget:target controller:controller block:nil];
}

+ (instancetype)KVOItemWithKeyPath:(NSString *)keyPath
                          ofTarget:(id)target
                        controller:(TDKVOController *)controller
                             block:(TDKVONotificationBlock)block {
    return [[self alloc] initWithKeyPath:keyPath ofTarget:target controller:controller block:block];
}

- (instancetype)initWithKeyPath:(NSString *)keyPath
                       ofTarget:(id)target
                     controller:(TDKVOController *)controller
                          block:(TDKVONotificationBlock __nullable)block {
    if (!td_ContainsKeyPath(target, keyPath)) {
        return nil;
    }
    
    if (self = [super init]) {
        _controller = controller;
        _block = block;
        _target = target;
        _keyPath = keyPath;
        _options = TDDefaultKVOOptions;
    }
    return self;
}

- (NSUInteger)hash {
    return [self.keyPath hash];
}

- (BOOL)isEqual:(NSObject *)object {
    if (!object || ![object isKindOfClass:self.class]) {
        return NO;
    }
    
    if (self == object) {
        return YES;
    }
    
    return [self.keyPath isEqualToString:((TDKVOItem *)object).keyPath];
}

@end

#pragma mark - TDKVOSharedController

NS_ASSUME_NONNULL_BEGIN
@interface TDKVOSharedController : NSObject

+ (instancetype)sharedController;
- (void)observe:(id)object item:(TDKVOItem *)item;
- (void)unobserve:(id)object item:(TDKVOItem *)item;
- (void)unobserve:(id)object items:(NSSet<TDKVOItem *> *)items;

@end
NS_ASSUME_NONNULL_END

static NSString *TDKVOSharedControllerLockName = @"TDKVOSharedControllerLock";
static TDKVOSharedController *sharedController = nil;

@implementation TDKVOSharedController {
    NSHashTable<TDKVOItem *> *_items;
    NSRecursiveLock *_lock;
}

#pragma mark - Life Cycle
+ (instancetype)sharedController {
    if (!sharedController) {
        @synchronized (self) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sharedController = [[TDKVOSharedController alloc] init];
            });
        }
    }
    return sharedController;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _items = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality capacity:0];
        _lock = [[NSRecursiveLock alloc] init];
        _lock.name = TDKVOSharedControllerLockName;
    }
    return self;
}

- (void)dealloc {
    
}

#pragma mark -
- (void)observe:(id)object item:(TDKVOItem *)item {
    if (!item) {
        return;
    }
    
    [_lock lock];
    [_items addObject:item];
    [_lock unlock];
    
    [item.target addObserver:self
                  forKeyPath:item.keyPath
                     options:item.options
                     context:(__bridge void *__nullable)(item)];
}

- (void)unobserve:(id)object item:(TDKVOItem *)item {
    if (!item) {
        return;
    }
    
    [_lock lock];
    [_items removeObject:item];
    [_lock unlock];
    
    [object removeObserver:self
                forKeyPath:item.keyPath
                   context:(__bridge void *__nullable)(item)];
}

- (void)unobserve:(id)object items:(NSSet<TDKVOItem *> *)items {
    if (0 == items.count) {
        return;
    }
    
    [_lock lock];
    for (TDKVOItem *item in items) {
        [_items removeObject:item];
    }
    [_lock unlock];
    
    for (TDKVOItem *item in items) {
        [object removeObserver:self
                    forKeyPath:item.keyPath
                       context:(__bridge void *__nullable)(item)];
    }
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(nullable NSString *)keyPath
                      ofObject:(nullable id)object
                        change:(nullable NSDictionary<NSString*, id> *)change
                       context:(nullable void *)context
{
    if (![((__bridge id)context) isKindOfClass:[TDKVOItem class]]) {
        return;
    }
    
    TDKVOItem *item;
    
    [_lock lock];
    item = [_items member:(__bridge id)context];
    [_lock unlock];
    
    if (!item) {
        return;
    }
    
    NSMutableDictionary *infos = [change mutableCopy];
    [infos setObject:keyPath forKey:TDKVONotificationKeyPathKey];
    
    if (item.block) {
        item.block(item.controller.observer, item.target, infos);
    }
}
@end

#pragma mark - TDKVOController

NSString *const TDKVONotificationKeyPathKey = @"com.TDKVOController.notification";
static NSString *const TDKVOControllerLockName = @"com.TDKVOController.lock";

@interface TDKVOController ()

@property (nonatomic, weak  , readwrite) id observer;
@property (nonatomic, strong) NSMapTable<id, NSMutableSet<TDKVOItem *> *> *KVOItemsMap;
@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation TDKVOController

#pragma mark - Life cycle
+ (instancetype)KVOControllerWithObeserver:(id)observer{
    return [[self alloc] initWithObserver:observer];
}

- (instancetype)initWithObserver:(id)observer {
    if (self = [super init]) {
        _observer = observer;
        NSPointerFunctionsOptions keyOptions = NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality;
        NSPointerFunctionsOptions valueOptions = NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality;
        _KVOItemsMap = [[NSMapTable alloc] initWithKeyOptions:keyOptions valueOptions:valueOptions capacity:1];
        _lock = [[NSRecursiveLock alloc] init];
        _lock.name = TDKVOControllerLockName;
    }
    return self;
}

- (void)dealloc {
    [self unobserveAll];
}

#pragma mark - Public
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object block:(TDKVONotificationBlock)block {
    [self _observeValueForKeyPath:keyPath ofObject:object options:TDDefaultKVOOptions block:block];
}

- (void)observeValueForKeyPaths:(NSArray<NSString *> *)keyPaths ofObject:(id)object block:(TDKVONotificationBlock)block {
    [self _observeValueForKeyPaths:keyPaths ofObject:object options:TDDefaultKVOOptions block:block];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object options:(NSKeyValueObservingOptions)options block:(TDKVONotificationBlock)block {
    [self _observeValueForKeyPath:keyPath ofObject:object options:TDDefaultKVOOptions block:block];
}

- (void)observeValueForKeyPaths:(NSArray<NSString *> *)keyPaths ofObject:(id)object options:(NSKeyValueObservingOptions)options block:(TDKVONotificationBlock)block {
    [self _observeValueForKeyPaths:keyPaths ofObject:object options:options block:block];
}

- (void)unobserveKeyPath:(NSString *)keyPath ofObject:(id)object {
    [self _unobserveKeyPath:keyPath ofObject:object];
}

- (void)unobserveObject:(id)object {
    [self _unobserveObject:object];
}

- (void)unobserveAll {
    [self _unobserveAll];
}

#pragma mark - Private
- (TDKVOItem *)_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object options:(NSKeyValueObservingOptions)options block:(nonnull TDKVONotificationBlock)block{
    TDKVOItem *item = [TDKVOItem KVOItemWithKeyPath:keyPath ofTarget:object controller:self block:block];
    item.options = options;
    return [self addKVOItem:item];
}


- (NSMutableSet<TDKVOItem *> *)_observeValueForKeyPaths:(NSArray<NSString *> *)keyPaths ofObject:(id)object options:(NSKeyValueObservingOptions)options block:(nonnull TDKVONotificationBlock)block{
    NSMutableSet<TDKVOItem *> *items = [NSMutableSet setWithCapacity:keyPaths.count];
    [keyPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull keyPath, NSUInteger idx, BOOL * _Nonnull stop) {
        TDKVOItem *item = [self _observeValueForKeyPath:keyPath ofObject:object options:options block:block];
        if (item) {
            [items addObject:item];
        }
    }];
    
    return items;
}

- (TDKVOItem *)addKVOItem:(TDKVOItem *)item {
    if (!item) {
        return nil;
    }

    [_lock lock];
    
    NSMutableSet<TDKVOItem *> *items = [_KVOItemsMap objectForKey:item.target];
    
    if (!items) {
        items = [NSMutableSet set];
        [_KVOItemsMap setObject:items forKey:item.target];
    }
    
    if ([items member:item]) {
        [_lock unlock];
        return nil;
    }
    
    [items addObject:item];
    [_lock unlock];
    
    [[TDKVOSharedController sharedController] observe:item.target item:item];
    return item;
}

- (void)_unobserveKeyPath:(NSString *)keyPath ofObject:(id)object {
    if (!object) {
        return;
    }
    
    TDKVOItem *item = [TDKVOItem KVOItemWithKeyPath:keyPath ofTarget:object controller:self];
    [self _unobserve:object KVOItem:item];
}

- (void)_unobserveObject:(id)object {
    if (!object) {
        return;
    }
    
    [_lock lock];
    NSMutableSet *items = [_KVOItemsMap objectForKey:object];
    
    if (0 == items.count) {
        return [_lock unlock];
    }
    
    [_KVOItemsMap removeObjectForKey:object];
    [_lock unlock];
    
    [[TDKVOSharedController sharedController] unobserve:object items:items];
}

- (void)_unobserveAll {
    if (0 == _KVOItemsMap.count) {
        return;
    }
    
    [_lock lock];
    
    NSMapTable *itemsMap = [_KVOItemsMap copy];
    [_KVOItemsMap removeAllObjects];
    
    [_lock unlock];
    
    for (id object in itemsMap) {
        NSSet<TDKVOItem *> *items = [itemsMap objectForKey:object];
        [[TDKVOSharedController sharedController] unobserve:object items:items];
    }
}


- (void)_unobserve:(id)object KVOItem:(TDKVOItem *)item {
    [_lock lock];
    
    NSMutableSet<TDKVOItem *> *items = [_KVOItemsMap objectForKey:object];
    TDKVOItem *memberItem = [items member:item];
    
    if (!memberItem) {
        return [_lock unlock];
    }
    
    [items removeObject:memberItem];
    
    if (0 == items.count) {
        [_KVOItemsMap removeObjectForKey:object];
    }
    
    [_lock unlock];
    
    [[TDKVOSharedController sharedController] unobserve:item.target item:item];
}

@end




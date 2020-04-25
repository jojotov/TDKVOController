//
//  NSObject+TDKVOController.m
//  TDKVOController
//
//  Created by jojo on 2017/11/14.
//  Copyright © 2017年 jojo. All rights reserved.
//

#import "NSObject+TDKVOController.h"
#import <objc/message.h>

@implementation NSObject (TDKVOController)

- (TDKVOController *)td_KVOController {
    id controller = objc_getAssociatedObject(self, @selector(td_KVOController));
    
    if (!controller) {
        controller = [TDKVOController KVOControllerWithObeserver:self];
        self.td_KVOController = controller;
    }
    
    return controller;
}

- (void)setTd_KVOController:(TDKVOController *)td_KVOController {
    objc_setAssociatedObject(self, @selector(td_KVOController), td_KVOController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


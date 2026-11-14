#import <UIKit/UIKit.h>

@interface HUDLoader : NSObject
@end

@implementation HUDLoader

+ (void)load {
    __block id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification * _Nonnull note) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        observer = nil;

        Class managerClass = NSClassFromString(@"HUDManager");
        SEL startSel = NSSelectorFromString(@"start");
        if (managerClass && [managerClass respondsToSelector:startSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [managerClass performSelector:startSel];
#pragma clang diagnostic pop
        }
    }];
}

@end

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Security/Security.h>
#import <CoreGraphics/CoreGraphics.h>

@interface SongAIMenu : NSObject
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UIButton *logo;
@end

@implementation SongAIMenu

static SongAIMenu *shared;

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        shared = [SongAIMenu new];
        [shared setup];
    });
}

- (void)setup {
    UIWindow *win = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                win = scene.windows.firstObject;
                break;
            }
        }
    }
    if (!win) win = [UIApplication sharedApplication].keyWindow;
    if (!win) return; // Tránh crash nếu chưa có window
    
    self.logo = [[UIButton alloc] initWithFrame:CGRectMake(100, 150, 50, 50)];
    self.logo.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:0.9];
    [self.logo setTitle:@"AI" forState:UIControlStateNormal];
    self.logo.layer.cornerRadius = 25;
    self.logo.layer.zPosition = 9999;
    [self.logo addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
    [self.logo addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];

    self.container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 175)];
    self.container.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    self.container.layer.cornerRadius = 10;
    self.container.layer.zPosition = 9998;
    self.container.hidden = YES;

    [self addBtn:@"RESET ID" col:[UIColor systemRedColor] y:10 t:1];
    [self addBtn:@"NO ADS" col:[UIColor systemBlueColor] y:65 t:2];
    [self addBtn:@"UNLOCK PRO" col:[UIColor systemGreenColor] y:120 t:3];

    [win addSubview:self.container];
    [win addSubview:self.logo];
}

- (void)addBtn:(NSString *)title col:(UIColor *)col y:(CGFloat)y t:(NSInteger)t {
    UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(10, y, 130, 45)];
    [b setTitle:title forState:UIControlStateNormal];
    b.backgroundColor = col;
    b.layer.cornerRadius = 8;
    b.tag = t;
    [b addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    [self.container addSubview:b];
}

- (void)pan:(UIPanGestureRecognizer *)p {
    CGPoint loc = [p translationInView:p.view.superview];
    p.view.center = CGPointMake(p.view.center.x + loc.x, p.view.center.y + loc.y);
    [p setTranslation:CGPointZero inView:p.view.superview]; // CGPointZero giờ đã có framework CoreGraphics lo
    self.container.center = CGPointMake(self.logo.center.x, self.logo.center.y + 120);
}

- (void)tap { 
    self.container.hidden = !self.container.hidden; 
    self.container.center = CGPointMake(self.logo.center.x, self.logo.center.y + 120); 
}

- (void)click:(UIButton *)s {
    if (s.tag == 1) {
        NSString *h = NSHomeDirectory();
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSString *f in @[@"Documents", @"Library", @"tmp"]) {
            [fm removeItemAtPath:[h stringByAppendingPathComponent:f] error:nil];
        }
        NSDictionary *q = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword};
        SecItemDelete((__bridge CFDictionaryRef)q);
        exit(0);
    } else if (s.tag == 3) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPremiumUser"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"aisong_00899_trial_3d_weekly"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [s setTitle:@"SUCCESS" forState:UIControlStateNormal];
    }
}
@end

static id (*o_obj)(id, SEL, id);
id h_obj(id self, SEL _cmd, NSString *key) {
    if ([key containsString:@"ad_unit"] || [key containsString:@"ads_enabled"]) return @"";
    if ([key isEqualToString:@"isPremiumUser"]) return @YES;
    return o_obj(self, _cmd, key);
}

__attribute__((constructor)) static void init() {
    Method m = class_getInstanceMethod([NSUserDefaults class], @selector(objectForKey:));
    o_obj = (id (*)(id, SEL, id))method_getImplementation(m);
    method_setImplementation(m, (IMP)h_obj);
}

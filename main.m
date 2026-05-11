#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Security/Security.h>

@interface SongAIMenu : NSObject
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UIButton *logo;
@end

@implementation SongAIMenu

static SongAIMenu *shared;

+ (void)load {
    // Tăng thời gian chờ lên 7 giây để app load xong hoàn toàn database nội bộ
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        shared = [SongAIMenu new];
        [shared setup];
    });
}

- (void)setup {
    // Cách lấy Window chắc chắn nhất cho iOS đời mới
    UIWindow *win = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) { win = w; break; }
    }
    if (!win) win = [[UIApplication sharedApplication] keyWindow];
    if (!win) return;

    // Thiết lập Logo
    self.logo = [[UIButton alloc] initWithFrame:CGRectMake(50, 150, 55, 55)];
    self.logo.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.9];
    [self.logo setTitle:@"AI" forState:UIControlStateNormal];
    self.logo.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.logo.layer.cornerRadius = 27.5;
    self.logo.layer.zPosition = 10000;
    self.logo.clipsToBounds = YES;
    
    [self.logo addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
    [self.logo addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];

    // Thiết lập Bảng nút
    self.container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 180)];
    self.container.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
    self.container.layer.cornerRadius = 15;
    self.container.layer.borderWidth = 1;
    self.container.layer.borderColor = [UIColor cyanColor].CGColor;
    self.container.layer.zPosition = 9999;
    self.container.hidden = YES;

    [self addBtn:@"RESET DATA" col:[UIColor systemRedColor] y:15 t:1];
    [self addBtn:@"NO ADS" col:[UIColor systemBlueColor] y:70 t:2];
    [self addBtn:@"ACTIVATE PRO" col:[UIColor systemGreenColor] y:125 t:3];

    [win addSubview:self.container];
    [win addSubview:self.logo];
}

- (void)addBtn:(NSString *)title col:(UIColor *)col y:(CGFloat)y t:(NSInteger)t {
    UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(10, y, 140, 45)];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    b.backgroundColor = col;
    b.layer.cornerRadius = 10;
    b.tag = t;
    [b addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    [self.container addSubview:b];
}

- (void)pan:(UIPanGestureRecognizer *)p {
    CGPoint loc = [p translationInView:p.view.superview];
    p.view.center = CGPointMake(p.view.center.x + loc.x, p.view.center.y + loc.y);
    [p setTranslation:CGPointZero inView:p.view.superview];
    self.container.center = CGPointMake(self.logo.center.x, self.logo.center.y + 125);
}

- (void)tap { 
    self.container.hidden = !self.container.hidden; 
    self.container.center = CGPointMake(self.logo.center.x, self.logo.center.y + 125); 
}

- (void)click:(UIButton *)s {
    if (s.tag == 1) { // Lệnh Reset triệt để
        NSString *h = NSHomeDirectory();
        NSFileManager *fm = [NSFileManager defaultManager];
        // Xóa sạch các folder
        for (NSString *f in @[@"Documents", @"Library", @"tmp"]) {
            NSString *p = [h stringByAppendingPathComponent:f];
            [fm removeItemAtPath:p error:nil];
            [fm createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil];
        }
        // Xóa sạch Keychain
        NSDictionary *q = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword};
        SecItemDelete((__bridge CFDictionaryRef)q);
        
        // Reset UserDefaults
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleId];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        exit(0);
    } else if (s.tag == 3) { // Ép Premium mạnh hơn
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        [d setBool:YES forKey:@"isPremiumUser"];
        [d setBool:YES forKey:@"premium_unlocked"];
        [d setBool:NO forKey:@"show_ads"];
        [d setObject:@"aisong_00899_trial_3d_weekly" forKey:@"active_subscription_id"];
        [d synchronize];
        
        [s setTitle:@"PRO ACTIVE!" forState:UIControlStateNormal];
        s.backgroundColor = [UIColor grayColor];
    }
}
@end

// HOOK - ĐÁNH CHẶN TRỰC TIẾP LỆNH ĐỌC DỮ LIỆU CỦA APP
static id (*o_obj)(id, SEL, id);
id h_obj(id self, SEL _cmd, NSString *key) {
    // Chặn Ads
    if ([key containsString:@"ad_unit"] || [key containsString:@"ads_enabled"] || [key isEqualToString:@"show_ads"]) {
        return @""; 
    }
    // Ép Premium
    if ([key isEqualToString:@"isPremiumUser"] || [key isEqualToString:@"premium_unlocked"]) {
        return @YES;
    }
    return o_obj(self, _cmd, key);
}

__attribute__((constructor)) static void init() {
    Method m = class_getInstanceMethod([NSUserDefaults class], @selector(objectForKey:));
    o_obj = (id (*)(id, SEL, id))method_getImplementation(m);
    method_setImplementation(m, (IMP)h_obj);
}

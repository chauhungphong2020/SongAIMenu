#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Security/Security.h>

@interface SongAIMenu : NSObject
@property (nonatomic, strong) UIView *buttonContainer;
@property (nonatomic, strong) UIButton *logoButton;
@end

@implementation SongAIMenu

static SongAIMenu *sharedMenu;

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sharedMenu = [[SongAIMenu alloc] init];
        [sharedMenu setupUI];
    });
}

- (void)setupUI {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) window = [[UIApplication sharedApplication] windows].firstObject;

    // 1. Tạo Logo tròn di chuyển được
    self.logoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.logoButton.frame = CGRectMake(50, 150, 50, 50);
    self.logoButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.9];
    [self.logoButton setTitle:@"AI" forState:UIControlStateNormal];
    self.logoButton.layer.cornerRadius = 25;
    self.logoButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.logoButton.layer.shadowOpacity = 0.5;
    
    [self.logoButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.logoButton addGestureRecognizer:pan];

    // 2. Tạo bảng Menu (3 nút)
    self.buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 175)];
    self.buttonContainer.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    self.buttonContainer.layer.cornerRadius = 12;
    self.buttonContainer.hidden = YES;

    [self addMenuButton:@"RESET ID" color:[UIColor systemRedColor] y:10 tag:1];
    [self addMenuButton:@"NO ADS" color:[UIColor systemBlueColor] y:65 tag:2];
    [self addMenuButton:@"UNLOCK PRO" color:[UIColor systemGreenColor] y:120 tag:3];

    [window addSubview:self.buttonContainer];
    [window addSubview:self.logoButton];
}

- (void)addMenuButton:(NSString *)title color:(UIColor *)color y:(CGFloat)y tag:(NSInteger)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(10, y, 140, 45);
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setBackgroundColor:color];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.layer.cornerRadius = 8;
    btn.tag = tag;
    [btn addTarget:self action:@selector(actionPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonContainer addSubview:btn];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:pan.view.superview];
    pan.view.center = CGPointMake(pan.view.center.x + translation.x, pan.view.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:pan.view.superview];
    if (!self.buttonContainer.hidden) [self updateMenuPos];
}

- (void)toggleMenu {
    self.buttonContainer.hidden = !self.buttonContainer.hidden;
    [self updateMenuPos];
}

- (void)updateMenuPos {
    self.buttonContainer.center = CGPointMake(self.logoButton.center.x, self.logoButton.center.y + 120);
}

- (void)actionPressed:(UIButton *)sender {
    if (sender.tag == 1) { // RESET ID & DATA
        NSString *home = NSHomeDirectory();
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSString *f in @[@"Documents", @"Library", @"tmp"]) {
            [fm removeItemAtPath:[home stringByAppendingPathComponent:f] error:nil];
        }
        // Xóa Keychain
        NSDictionary *spec = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword};
        SecItemDelete((__bridge CFDictionaryRef)spec);
        exit(0);
    } 
    else if (sender.tag == 2) { // THÔNG BÁO TẮT ADS
        [sender setTitle:@"ADS DISABLED" forState:UIControlStateNormal];
        sender.enabled = NO;
    }
    else if (sender.tag == 3) { // FAKE PREMIUM
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        [defs setBool:YES forKey:@"isPremiumUser"];
        [defs setBool:YES forKey:@"aisong_00899_trial_3d_weekly"];
        [defs synchronize];
        [sender setTitle:@"PRO UNLOCKED" forState:UIControlStateNormal];
    }
}
@end

// HOOK HỆ THỐNG ĐỂ CHẶN ADS VÀ ÉP PRO
static id (*orig_objectForKey)(id, SEL, id);
id hook_objectForKey(id self, SEL _cmd, NSString *key) {
    if ([key containsString:@"ad_unit"] || [key containsString:@"ads_enabled"]) return @"";
    if ([key isEqualToString:@"isPremiumUser"]) return @YES;
    return orig_objectForKey(self, _cmd, key);
}

__attribute__((constructor))
static void init() {
    Method m = class_getInstanceMethod([NSUserDefaults class], @selector(objectForKey:));
    orig_objectForKey = (id (*)(id, SEL, id))method_getImplementation(m);
    method_setImplementation(m, (IMP)hook_objectForKey);
}

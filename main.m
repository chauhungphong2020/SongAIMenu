#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Security/Security.h>

// --- PHẦN 1: TỰ ĐỘNG RESET KHI MỞ APP (ĐỂ HỒI CREDIT) ---
__attribute__((constructor))
static void autoReset() {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    // Nếu chưa đánh dấu đã reset trong phiên này thì tiến hành xóa
    if (![defs boolForKey:@"did_auto_reset"]) {
        NSString *home = NSHomeDirectory();
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSString *f in @[@"Documents", @"Library", @"tmp"]) {
            [fm removeItemAtPath:[home stringByAppendingPathComponent:f] error:nil];
        }
        
        // Tạo ID mới
        NSString *newID = [[NSUUID UUID] UUIDString];
        [defs setObject:newID forKey:@"stk_idfv_key"];
        [defs setObject:newID forKey:@"userID"];
        [defs setBool:YES forKey:@"did_auto_reset"]; // Đánh dấu để không bị lặp vô hạn
        [defs synchronize];
        
        // Không gọi exit(0) ở đây để app tiếp tục chạy với ID mới
    }
}

// --- PHẦN 2: HOOK HỆ THỐNG ĐỂ BẺ KHÓA PREMIUM ---
@interface NSBundle (SongAIHack)
@end

@implementation NSBundle (SongAIHack)

// Đánh chặn lệnh kiểm tra cấu hình
- (id)hook_objectForKey:(NSString *)key {
    NSArray *proKeys = @[@"isPremiumUser", @"premium_unlocked", @"is_vip", @"has_sub", @"aisong_00899_trial_3d_weekly"];
    if ([proKeys containsObject:key]) return @YES;
    
    // Chặn Ads
    if ([key containsString:@"ad_unit"] || [key containsString:@"ads_enabled"]) return @"";
    
    return [self hook_objectForKey:key];
}

@end

__attribute__((constructor))
static void setupHooks() {
    // 1. Hook NSUserDefaults (Cho các giá trị YES/NO)
    Method original = class_getInstanceMethod([NSUserDefaults class], @selector(boolForKey:));
    Method swizzled = class_getStaticMethod(objc_getClass("NSBundle"), @selector(hook_bool_fake:)); 
    // (Sử dụng cách thức đơn giản hơn để tránh lỗi biên dịch)
    
    // 2. Tự động ép giá trị Pro vào bộ nhớ
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        [d setBool:YES forKey:@"isPremiumUser"];
        [d setBool:YES forKey:@"premium_unlocked"];
        [d setBool:NO forKey:@"show_ads"];
        [d synchronize];
    });
}

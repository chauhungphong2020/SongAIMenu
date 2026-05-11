#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation NSObject (SongAIHack)

// Hàm này sẽ thay thế hàm kiểm tra của hệ thống
- (BOOL)hook_boolForKey:(NSString *)key {
    // Danh sách các "tên" mà app thường dùng để kiểm tra bản quyền
    NSArray *proKeys = @[
        @"isPremiumUser", @"premium_unlocked", @"is_vip", 
        @"has_sub", @"pro_enabled", @"all_features_unlocked",
        @"aisong_00899_trial_3d_weekly", @"is_pro"
    ];

    for (NSString *proKey in proKeys) {
        if ([key isEqualToString:proKey]) {
            return YES; // Luôn trả về ĐÃ MUA
        }
    }
    
    // Nếu là các key liên quan đến quảng cáo
    if ([key containsString:@"ad_unit"] || [key containsString:@"ads_enabled"] || [key isEqualToString:@"show_ads"]) {
        return NO; // Luôn trả về KHÔNG HIỆN QUẢNG CÁO
    }

    // Trả về giá trị gốc của các cài đặt khác
    return [self hook_boolForKey:key];
}

@end

__attribute__((constructor))
static void init() {
    // Đánh tráo hàm: Cứ khi nào app hỏi "Có phải Premium không?" thì chạy hàm của mình
    Method original = class_getInstanceMethod([NSUserDefaults class], @selector(boolForKey:));
    Method swizzled = class_getInstanceMethod([NSObject class], @selector(hook_boolForKey:));
    method_exchangeImplementations(original, swizzled);
    
    // Tự động ghi đè thêm vào bộ nhớ khi app vừa mở
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        [defs setBool:YES forKey:@"isPremiumUser"];
        [defs setBool:YES forKey:@"premium_unlocked"];
        [defs synchronize];
        
        printf("SongAI Hack: Premium Spoofed\n");
    });
}

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation NSObject (SongAIFinal)

// Hàm khởi tạo tự động chạy khi App vừa được nạp vào bộ nhớ
__attribute__((constructor))
static void init() {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    
    // ---------------------------------------------------------
    // 1. CHIẾN THUẬT RESET ID: Lấy 1 Credit mới mỗi lần mở App
    // ---------------------------------------------------------
    NSString *newUUID = [[NSUUID UUID] UUIDString];
    
    // Ghi đè các định danh cũ bằng mã ngẫu nhiên mới
    [defs setObject:newUUID forKey:@"stk_idfv_key"];
    [defs setObject:newUUID forKey:@"userID"];
    [defs setObject:newUUID forKey:@"uuidStringFromStore"];
    
    // Đánh dấu đây là lần đầu chạy để App cấp Credit khởi nghiệp
    [defs setBool:YES forKey:@"IsFirstLaunch"]; 
    
    // ---------------------------------------------------------
    // 2. CHIẾN THUẬT PREMIUM & CHẶN ADS: Ép giá trị trực tiếp
    // ---------------------------------------------------------
    [defs setBool:YES forKey:@"isPremiumUser"];
    [defs setBool:YES forKey:@"premium_unlocked"];
    [defs setBool:NO forKey:@"show_ads"];
    
    // Vô hiệu hóa các mã đơn vị quảng cáo (Ad Units)
    NSArray *adKeys = @[
        @"ad_unit_admob_banner", 
        @"ad_unit_admob_interstitial", 
        @"ad_unit_admob_native", 
        @"ad_unit_applovin_banner"
    ];
    for (NSString *key in adKeys) {
        [defs setObject:@"" forKey:key];
    }
    
    // Lưu các thay đổi vào bộ nhớ máy
    [defs synchronize];

    // ---------------------------------------------------------
    // 3. DỌN DẸP CACHE: Sau 3 giây để tránh xung đột gây văng App
    // ---------------------------------------------------------
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Chỉ xóa Cache (Lịch sử ID), KHÔNG xóa Documents (Bài hát của bạn)
        NSString *cachePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
        
        NSLog(@"[SongAI] ID Reset & Ads Blocked Successfully!");
    });
}
@end

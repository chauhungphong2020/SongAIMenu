#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface SongAIHack : NSObject
@end

@implementation SongAIHack

// 1. Đánh chặn để ép App tin là Premium & Tắt Ads
- (BOOL)hook_boolForKey:(NSString *)key {
    if ([key isEqualToString:@"isPremiumUser"] || [key isEqualToString:@"premium_unlocked"]) {
        return YES;
    }
    if ([key containsString:@"ad_unit"] || [key isEqualToString:@"show_ads"]) {
        return NO;
    }
    return [self hook_boolForKey:key];
}
@end

// 2. Hàm chỉ Reset ID mà không mất bài hát đã tạo
void resetIDOnly() {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    
    // Kiểm tra nếu đã dùng hết Credit (hoặc đơn giản là mỗi lần mở app)
    // Tạo ID mới ngẫu nhiên
    NSString *newUUID = [[NSUUID UUID] UUIDString];
    
    // Ghi đè các ID định danh mà app dùng
    [defs setObject:newUUID forKey:@"stk_idfv_key"];
    [defs setObject:newUUID forKey:@"userID"];
    [defs setObject:newUUID forKey:@"uuidStringFromStore"];
    
    // Reset trạng thái Onboarding để app cấp lại Credit như người mới
    [defs setBool:YES forKey:@"IsFirstLaunch"]; 
    
    [defs synchronize];
    
    // Xóa file chứa ID cũ trong Library/Preferences nhưng KHÔNG xóa Documents (nơi chứa nhạc)
    NSString *prefPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:prefPath error:nil];
    
    for (NSString *file in files) {
        // Chỉ xóa file cấu hình của App, không xóa folder nhạc
        if ([file containsString:[[NSBundle mainBundle] bundleIdentifier]]) {
            [fm removeItemAtPath:[prefPath stringByAppendingPathComponent:file] error:nil];
        }
    }
}

__attribute__((constructor))
static void init() {
    // Thực hiện đổi ID ngay khi mở
    resetIDOnly();

    // Hook để bẻ khóa các tính năng
    Method original = class_getInstanceMethod([NSUserDefaults class], @selector(boolForKey:));
    Method swizzled = class_getInstanceMethod([SongAIHack class], @selector(hook_boolForKey:));
    if (original && swizzled) {
        method_exchangeImplementations(original, swizzled);
    }
}

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface SongAIHack : NSObject
@end

@implementation SongAIHack

// Hàm này dùng để trả về giá trị Pro mà không gây vòng lặp vô hạn
- (BOOL)hook_boolForKey:(NSString *)key {
    if ([key isEqualToString:@"isPremiumUser"] || [key isEqualToString:@"premium_unlocked"] || [key isEqualToString:@"is_vip"]) {
        return YES;
    }
    if ([key containsString:@"ad_unit"] || [key isEqualToString:@"show_ads"]) {
        return NO;
    }
    // Gọi về hàm gốc thật sự của NSUserDefaults thông qua selector đã tráo
    return [self hook_boolForKey:key]; 
}
@end

// Hàm Reset ID an toàn: Chỉ đổi ID, giữ nguyên âm nhạc (Documents)
void safeResetID() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        NSString *newUUID = [[NSUUID UUID] UUIDString];
        
        // Ghi đè ID mới
        [defs setObject:newUUID forKey:@"stk_idfv_key"];
        [defs setObject:newUUID forKey:@"userID"];
        [defs setObject:newUUID forKey:@"uuidStringFromStore"];
        [defs setBool:YES forKey:@"IsFirstLaunch"];
        [defs synchronize];
        
        // Chỉ xóa nhẹ file cache để App nhận diện ID mới, không xóa Documents
        NSString *libPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
        [[NSFileManager defaultManager] removeItemAtPath:libPath error:nil];
    });
}

__attribute__((constructor))
static void init() {
    // Chạy Reset ID
    safeResetID();

    // Đánh tráo hàm an toàn (Method Swizzling)
    static dispatch_once_t swizzleToken;
    dispatch_once(&swizzleToken, ^{
        Class class = [NSUserDefaults class];
        SEL originalSelector = @selector(boolForKey:);
        SEL swizzledSelector = @selector(hook_boolForKey:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod([SongAIHack class], swizzledSelector);

        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

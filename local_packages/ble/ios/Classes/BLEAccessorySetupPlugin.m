#import "BLEAccessorySetupPlugin.h"
#import <AccessorySetupKit/AccessorySetupKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <TargetConditionals.h>
#import <UIKit/UIKit.h>

@interface BLEAccessorySetupPlugin ()
@property(nonatomic, strong) ASAccessorySession *session API_AVAILABLE(ios(18.0));
@property(nonatomic) BOOL activated;
@property(nonatomic, copy) FlutterResult pendingResult;
@property(nonatomic, copy) NSString *pendingMethod;
@property(nonatomic, copy) NSArray<NSDictionary *> *filters;
@property(nonatomic, strong) ASAccessory *pickedAccessory API_AVAILABLE(ios(18.0));
@end

@implementation BLEAccessorySetupPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"ble/accessory_setup"
                                 binaryMessenger:registrar.messenger];
  [registrar addMethodCallDelegate:[BLEAccessorySetupPlugin new] channel:channel];
}

- (BOOL)isSupported {
#if TARGET_OS_SIMULATOR || TARGET_OS_MACCATALYST
  return NO;
#else
  if (@available(iOS 18.0, *)) {
    return [[NSBundle.mainBundle objectForInfoDictionaryKey:@"NSAccessorySetupKitSupports"]
        containsObject:@"Bluetooth"];
  }
  return NO;
#endif
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:@"isSupported"]) {
    result(@([self isSupported]));
    return;
  }
  if (![call.method isEqualToString:@"getAccessories"] &&
      ![call.method isEqualToString:@"pickAccessory"]) {
    result(FlutterMethodNotImplemented);
    return;
  }
  if (![self isSupported]) {
    result([FlutterError errorWithCode:@"unsupported"
                              message:@"AccessorySetupKit is unavailable."
                              details:nil]);
    return;
  }
  if (self.pendingResult) {
    result([FlutterError errorWithCode:@"busy"
                              message:@"Accessory setup is already in progress."
                              details:nil]);
    return;
  }
  if (@available(iOS 18.0, *)) {
    // Filter against the host declarations before calling ASK: undeclared
    // discovery identifiers cause an OS exception rather than a picker error.
    NSArray *declaredNames = [NSBundle.mainBundle objectForInfoDictionaryKey:@"NSAccessorySetupBluetoothNames"];
    NSArray *declaredServices = [NSBundle.mainBundle objectForInfoDictionaryKey:@"NSAccessorySetupBluetoothServices"];
    NSMutableArray *filters = [NSMutableArray new];
    NSArray *requested = [call.arguments isKindOfClass:NSArray.class] ? call.arguments : @[];
    for (id candidate in requested) {
      if (![candidate isKindOfClass:NSDictionary.class]) continue;
      NSDictionary *filter = candidate;
      NSString *name = filter[@"nameSubstring"];
      NSString *service = filter[@"serviceUuid"];
      if (![name isKindOfClass:NSString.class] || name.length == 0 ||
          ![service isKindOfClass:NSString.class] || service.length == 0 ||
          ![filter[@"type"] isKindOfClass:NSString.class] ||
          ![filter[@"label"] isKindOfClass:NSString.class] ||
          ![declaredNames containsObject:name]) continue;
      BOOL declared = NO;
      for (NSString *value in declaredServices) {
        if ([[value uppercaseString] isEqualToString:service.uppercaseString]) {
          declared = YES;
          break;
        }
      }
      if (declared) [filters addObject:filter];
    }
    if (filters.count == 0) {
      result([FlutterError errorWithCode:@"configuration"
                                message:@"No supported Bluetooth readers are declared in Info.plist."
                                details:nil]);
      return;
    }
    self.filters = filters;
    self.pendingResult = result;
    self.pendingMethod = call.method;
    if (self.activated) {
      [self performOperation];
      return;
    }
    self.session = [ASAccessorySession new];
    __weak BLEAccessorySetupPlugin *weakSelf = self;
    __weak ASAccessorySession *activatingSession = self.session;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      BLEAccessorySetupPlugin *strongSelf = weakSelf;
      if (strongSelf && strongSelf.session == activatingSession && !strongSelf.activated) {
        [strongSelf.session invalidate];
        strongSelf.session = nil;
        [strongSelf finish:[FlutterError errorWithCode:@"activation_timeout"
                                               message:@"Accessory setup did not activate."
                                               details:nil]];
      }
    });
    [self.session activateWithQueue:dispatch_get_main_queue() eventHandler:^(ASAccessoryEvent *event) {
      BLEAccessorySetupPlugin *strongSelf = weakSelf;
      if (!strongSelf || strongSelf.session != activatingSession) return;
      switch (event.eventType) {
        case ASAccessoryEventTypeActivated:
          strongSelf.activated = YES;
          [strongSelf performOperation];
          break;
        case ASAccessoryEventTypeAccessoryAdded:
          if ([strongSelf.pendingMethod isEqualToString:@"pickAccessory"])
            strongSelf.pickedAccessory = event.accessory;
          break;
        case ASAccessoryEventTypePickerDidDismiss: {
          // Wait until the system sheet is gone before Flutter selects a reader.
          NSDictionary *picked = [strongSelf mapAccessory:strongSelf.pickedAccessory];
          strongSelf.pickedAccessory = nil;
          [strongSelf finish:picked];
          break;
        }
        case ASAccessoryEventTypeInvalidated:
          strongSelf.activated = NO;
          strongSelf.session = nil;
          [strongSelf finish:[FlutterError errorWithCode:@"session_invalidated"
                                                 message:event.error.localizedDescription ?: @"Accessory setup ended."
                                                 details:nil]];
          break;
        default:
          break;
      }
    }];
  }
}

- (NSDictionary *)mapAccessory:(ASAccessory *)accessory API_AVAILABLE(ios(18.0)) {
  if (!accessory.bluetoothIdentifier) return nil;
  for (NSDictionary *filter in self.filters) {
    ASDiscoveryDescriptor *descriptor = accessory.descriptor;
    if ([descriptor.bluetoothServiceUUID isEqual:[CBUUID UUIDWithString:filter[@"serviceUuid"]]] &&
        [descriptor.bluetoothNameSubstring isEqualToString:filter[@"nameSubstring"]]) {
      return @{@"id": accessory.bluetoothIdentifier.UUIDString,
               @"name": accessory.displayName,
               @"type": filter[@"type"]};
    }
  }
  return nil;
}

- (void)performOperation API_AVAILABLE(ios(18.0)) {
  if (!self.pendingResult) return;
  if ([self.pendingMethod isEqualToString:@"getAccessories"]) {
    NSMutableArray *accessories = [NSMutableArray new];
    for (ASAccessory *accessory in self.session.accessories) {
      NSDictionary *value = [self mapAccessory:accessory];
      if (value) [accessories addObject:value];
    }
    [self finish:accessories];
    return;
  }
  self.pickedAccessory = nil;
  NSMutableArray *items = [NSMutableArray new];
  UIImage *image = [[UIImage systemImageNamed:@"simcard" withConfiguration:
      [UIImageSymbolConfiguration configurationWithPointSize:180]]
      imageWithTintColor:UIColor.systemBlueColor renderingMode:UIImageRenderingModeAlwaysOriginal];
  for (NSDictionary *filter in self.filters) {
    ASDiscoveryDescriptor *descriptor = [ASDiscoveryDescriptor new];
    descriptor.bluetoothServiceUUID = [CBUUID UUIDWithString:filter[@"serviceUuid"]];
    descriptor.bluetoothNameSubstring = filter[@"nameSubstring"];
    if (@available(iOS 18.2, *)) {
      descriptor.bluetoothNameSubstringCompareOptions = NSCaseInsensitiveSearch;
    }
    // Authorization is sufficient for these GATT readers; don't force bonding
    // or rename the device name, which some readers use for authentication.
    [items addObject:[[ASPickerDisplayItem alloc] initWithName:filter[@"label"]
                                              productImage:image descriptor:descriptor]];
  }
  __weak BLEAccessorySetupPlugin *weakSelf = self;
  [self.session showPickerForDisplayItems:items completionHandler:^(NSError *error) {
    if ([error.domain isEqualToString:ASErrorDomain] && error.code == ASErrorCodeUserCancelled) {
      [weakSelf finish:nil];
      return;
    }
    if (error) {
      [weakSelf finish:[FlutterError errorWithCode:@"picker_failed"
                                          message:error.localizedDescription details:nil]];
    }
  }];
}

- (void)finish:(id)value {
  FlutterResult result = self.pendingResult;
  self.pendingResult = nil;
  self.pendingMethod = nil;
  if (result) result(value);
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [self finish:[FlutterError errorWithCode:@"detached" message:@"Flutter engine detached." details:nil]];
  if (@available(iOS 18.0, *)) [self.session invalidate];
}
@end

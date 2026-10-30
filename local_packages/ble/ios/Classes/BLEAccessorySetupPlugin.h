#import <Flutter/Flutter.h>

/// Accessory discovery has its own channel so checking availability never
/// initializes CoreBluetooth or triggers its broad permission prompt.
@interface BLEAccessorySetupPlugin : NSObject <FlutterPlugin>
@end

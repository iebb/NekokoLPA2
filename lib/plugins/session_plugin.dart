import '../adapter/euicc_adapter.dart';

abstract class SessionPlugin {
  String get id;
  String? get aid => null;

  /// Check if the plugin is interested in this session.
  Future<bool> isInterested(Adapter adapter, String? eid);

  /// Hook before a high-level command is sent to the eUICC.
  /// [command] is a string identifier like 'authenticateServer' or 'getEuiccChallenge'.
  /// [params] contains the arguments passed to the command.
  Future<void> beforeCommand(
    String command,
    Map<String, dynamic> params,
    Channel channel,
  ) async {}

  /// Hook after a high-level command is sent to the eUICC.
  /// [result] is the value returned by the command.
  Future<void> afterCommand(
    String command,
    Map<String, dynamic> params,
    dynamic result,
    Channel channel,
  ) async {}

  /// Provide extra AIDs to try during session opening based on ATR.
  List<String> getExtraAids(String atr) => [];

  /// Provide available device modes.
  Future<List<AdapterMode>> getAvailableModes(
    Adapter adapter,
    Reader reader,
  ) async => [];

  /// Perform mode switch.
  Future<void> switchMode(
    Adapter adapter,
    Reader reader,
    AdapterMode mode,
  ) async {}

  /// Called in the background to determine if a reader has special capabilities.
  /// Returns a map of properties to update on the reader, or null.
  Future<Map<String, dynamic>?> probeReaderCapabilities(
    String? eid,
    String? aid,
  ) async => null;
}

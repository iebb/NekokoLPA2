/// TS.43 string constants, ported from `ts43-go/ts43/types.go`.
class Ts43Constants {
  static const appOdsaPrimary = 'ap2009';
  static const appVoWiFi = 'ap2004';
  static const defaultResponseAccept =
      'application/json, text/vnd.wap.connectivity-xml';
  static const wfcResponseAccept = 'text/vnd.wap.connectivity-xml';
  static const samsungResponseAccept = 'application/xml, text/xml';
  static const eapRelayContentType = 'application/vnd.gsma.eap-relay.v1.0+json';
  static const defaultOdsaClientTs43 = 'client-Primary-ODSA';
  static const samsungOdsaClientTs43 = 'Primary-ODSA';
  static const defaultWfcClientTs43 = 'client-IMS-Entitlement';
  static const defaultEapAkaRealm = 'nai.epc';
}

import PubNubSDK

func aesCbcCryptoModuleExample() {
  // snippet.crypto-module
  // Provides the recommended encryption mechanism (256-bit AES-CBC) introduced
  // from version 6.1.0. Also supports decryption of data encrypted using the legacy
  // method used prior to version 6.1.0, ensuring backward compatibility:
  let pubnub = PubNub(
    configuration: PubNubConfiguration(
      publishKey: "yourPublishKey",
      subscribeKey: "yourSubscribeKey",
      userId: "yourUserId",
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "pubnubenigma")
    )
  )
  // snippet.end
}

func legacyCryptoModuleExample() {
  // snippet.legacy-crypto-module
  // Uses a legacy encryption mechanism (128-bit cipher key entropy) that is no longer recommended.
  // Supports only decryption of data encrypted with the legacy method used prior to version 6.1.0.
  let pubnub = PubNub(
    configuration: PubNubConfiguration(
      publishKey: "yourPublishKey",
      subscribeKey: "yourSubscribeKey",
      userId: "yourUserId",
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "pubnubenigma")
    )
  )
  // snippet.end
}

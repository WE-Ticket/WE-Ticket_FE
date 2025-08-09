import UIKit
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

  private let channelName = "did_sdk"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      switch call.method {
      case "createDid":
        self.handleCreateDid(result: result)

      case "delDidDoc":
        self.handleDelDidDoc(result: result)

      case "didAuth":
        self.handleDidAuth(result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Flutter 등록
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

extension AppDelegate {

  func handleCreateDid(result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        print("[ios] WE-Ticket DID 생성 시작작")
        // 1) KeyManager 생성 & 키 생성 (예시: 생체/Keychain/Secure Enclave 등)
        let keyManager = try .init(fileName:  "WETicketWallet")

        let keyId = "weticket_key_\(Int(Date().timeIntervalSince1970 * 1000))"
        let bioKeyRequest = SecureKeyGenRequest(id: keyId,
                                        accessMethod: .currentSet
                                        prompt : "Need to authenticate user")
        try keyManager.generateKey(keyGenRequest: bioKeyRequest)
        print("[ios] BIO 개인키 생성 완료 : \(keyId)")

        // 2) 공개키 조회
        // let keyInfo = try keyManager.getKeyInfos([keyId]).first!

        // 3) DID 생성
        // let didManager = DIDManager<BaseObject>(namespace: "weticket_did", context: /* ... */)
        // let did = DIDManager.genDID("weticket")

        // 4) DID Document 생성 & proof 채우기
        // try didManager.createDocument(did: did, didKeyInfos: [...], controller: did, services: nil)
        // var didDocument = try didManager.getDocument()
        // didDocument.proof = Proof(...)

        // 5) 직렬화 -> 해시 -> 서명 -> base58btc 인코딩
        // let jsonData = didDocument.toJson().data(using: .utf8)!
        // let digest = DigestUtils.getDigest(jsonData, .sha256)
        // let signature = try keyManager.sign(keyId: keyId, context: nil, digest: digest)
        // let encodedSig = MultibaseUtils.encode(.base58btc, signature)
        // didDocument.proof.proofValue = encodedSig

        // 6) 저장
        // try didManager.saveDocument()

        // 7) Flutter로 반환 (안드로이드와 동일한 키 구성)
        let payload: [String: Any] = [
          "success": true,
          "did": /* did */ "",
          "publicKey": /* keyInfo.publicKey */ "",
          "keyId": /* keyId */ "",
          "didDocument": /* didDocument.toJson() */ "{}",
          "keyAttestation": [
            "keyId": /* keyId */ "",
            "algorithm": "SECP256R1",
            "storage": "Keychain/SecureEnclave",
            "createdAt": Int(Date().timeIntervalSince1970 * 1000)
          ],
          "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]

        DispatchQueue.main.async { result(payload) }

      } catch {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "\(error)",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
          ])
        }
      }
    }
  }

  func handleDelDidDoc(result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        // let didManager = DIDManager<BaseObject>(namespace: "weticket_did", context: /* ... */)
        // try didManager.deleteDocument()

        DispatchQueue.main.async {
          result([
            "success": true,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
          ])
        }
      } catch {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "\(error)",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
          ])
        }
      }
    }
  }

  func handleDidAuth(result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        // let keyManager = KeyManager<DetailKeyInfo>(walletId: "WETicketWallet", context: /* ... */)
        // let didManager = DIDManager<BaseObject>(namespace: "weticket_did", context: /* ... */)
        // var didDocument = try didManager.getDocument()
        // let keyId = didDocument.verificationMethod.first!.id

        // let proof = Proof(created: nowISO8601(),
        //                   proofPurpose: .authentication,
        //                   verificationMethod: "\(didDocument.id)?versionId=\(didDocument.versionId)#\(keyId)",
        //                   type: .secp256r1Signature2018)

        // var didAuth = DIDAuth(did: didDocument.id, authNonce: "auth_nonce_dummy_dddddd", proof: proof)

        // let digest = DigestUtils.getDigest(didAuth.toJson().data(using: .utf8)!, .sha256)
        // let sig = try keyManager.sign(keyId: keyId, context: nil, digest: digest)
        // didAuth.proof.proofValue = MultibaseUtils.encode(.base58btc, sig)

        let payload: [String: Any] = [
          "success": true,
          "didDocument": /* didDocument.toJson() */ "{}",
          "didAuth": /* didAuth.toJson() */ "{}",
          "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        DispatchQueue.main.async { result(payload) }

      } catch {
        DispatchQueue.main.async {
          result([
            "success": false,
            "error": "\(error)",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
          ])
        }
      }
    }
  }
}

// 유틸: ISO8601 문자열
func nowISO8601() -> String {
  let f = ISO8601DateFormatter()
  f.timeZone = TimeZone(secondsFromGMT: 0)
  f.formatOptions = [.withInternetDateTime]
  return f.string(from: Date())
}

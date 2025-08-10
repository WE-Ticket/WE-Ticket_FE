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
        print("[ios] WE-Ticket DID 생성 시작")
        // 1) KeyManager 생성 & 키 생성 (예시: 생체/Keychain/Secure Enclave 등)
        let keyManager = try .init(fileName:  "WETicketWallet")

        let keyId = "weticket_key_\(Int(Date().timeIntervalSince1970 * 1000))"
        let bioKeyRequest = SecureKeyGenRequest(id: keyId,
                                        accessMethod: .currentSet
                                        prompt : "Need to authenticate user")
        try keyManager.generateKey(keyGenRequest: bioKeyRequest)
        print("[ios] BIO 개인키 생성 완료 : \(keyId)")

        // 2) 공개키 조회
        let keyInfos = try keyManager.getKeyInfos(ids: [keyId])
        let keyInfo = keyInfos.first
        let publicKey = keyInfo.publicKey
        print("[ios] key info 조회 - 공개키 : \(publicKey)")
        

        // 3) DID 생성
        let didManager = try DIDManager(fileName: "weticket_did")
        let did = try didManager.genDID(methodName: "weticket")
        print("[ios] WE-Ticket DID 생성 : \(did)")

        var didKeyInfos: [DIDKeyInfo] = .init()
        didKeyInfos.append(.init(keyInfo: keyInfo, methodType: [.assertionMethod, .authentication]))
        print("[ios] DID Key Info 생성 : \(didKeyInfos)")

        // 4) DID Document 생성 & proof 채우기
        try didManager.createDocument(did: did, keyInfos: keyInfos, controller: did, service: nil)
        let didDocument = try didManager.getDocument()
        print("[ios] DID Document 생성 완료 (Proof 전) : \(didDocument) ")
        
        let proof = Proof(created: nowISO8601(),
                          proofPurpose: .assertionMethod,
                          verificationMethod: "\(didDocument.id)?versionId=\(didDocument.versionId)#\(keyId)",
                          type: .secp256r1Signature2018)
        didDocument.proof = proof

        // 5) 직렬화 -> 해시 -> 서명 -> base58btc 인코딩
        let jsonData = didDocument.toJson().data(using: .utf8)!
        let digest = DigestUtils.getDigest(jsonData, .sha256)

        let signature = try keyManager.sign(id: keyId,  digest: digest)
        let encodedSig = MultibaseUtils.encode(.base58btc, signature)
        didDocument.proof.proofValue = encodedSig

        print("[ios] 서명 완료 - DID Document 조회 : \(didDocument) ")

        // 6) 저장
        try didManager.saveDocument()

        // 7) Flutter로 반환 (안드로이드와 동일한 키 구성)
        let payload: [String: Any] = [
          "success": true,
          "did": did,
          "publicKey": publicKey,
          "keyId": keyId,
          "didDocument": didDocument.toJson(),
          "keyAttestation": [
            "keyId": keyId,
            "algorithm": "SECP256R1",
            "storage": "Keychain/SecureEnclave",
            "createdAt": Int(Date().timeIntervalSince1970 * 1000)
          ],
          "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        
        print("[ios] WE-Ticket DID 생성 과정 완료 ")
        DispatchQueue.main.async { result(payload) }

      } catch {
        print("❌ [ios] WE-Ticket DID 생성 과정 실패 ")
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
        print("[ios] DID Documtent 삭제 과정 시작 ")

        let didManager = try DIDManager(fileName: "weticket_did")
        try didManager.deleteDocument()

        print("[ios] DID Documtent 삭제 과정 완료 ")

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
        print("[ios] DID Auth 과정 시작 ")

        let nonce = call.arguments["nonce"] as? String
        print("[ios] 전달받은 nonce : \(nonce)")

        let keyManager = try .init(fileName:  "WETicketWallet")
        let didManager = try DIDManager(fileName: "weticket_did")

        var didDocument = try didManager.getDocument()
        print("[ios] DID Doc 조회 : \(didDocument)")

        let keyId = didDocument.verificationMethod.first!.id
        print("[ios] key Id 조회 : \(keyId)")

        let proof = Proof(created: nowISO8601(),
                          proofPurpose: .authentication,
                          verificationMethod: "\(didDocument.id)?versionId=\(didDocument.versionId)#\(keyId)",
                          type: .secp256r1Signature2018)

        var didAuth = DIDAuth(did: didDocument.id, authNonce: nonce, proof: proof)
        print("[ios] proof 및 did Auth 생성 완료")
        print("[ios] 서명 전 DID Auth : \(didAuth)")

        let jsonData = didAuth.toJson().data(using: .utf8)!
        let digest = DigestUtils.getDigest(jsonData, .sha256)
        let signature = try keyManager.sign(id: keyId,  digest: digest)
        let encodedSig = MultibaseUtils.encode(.base58btc, signature)
        didAuth.proof.proofValue = encodedSig
        print("[ios] 서명 후 DID Auth : \(didAuth)")

        let payload: [String: Any] = [
          "success": true,
          "didDocument": didDocument.toJson(),
          "didAuth": didAuth.toJson(),
          "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]

        print("[ios] DID Auth 서명 과정 완료. ")
        DispatchQueue.main.async { result(payload) }

      } catch {
        print("❌ [ios] DID Auth 서명 과정 실패.")
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

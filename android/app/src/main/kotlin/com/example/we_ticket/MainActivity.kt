package com.example.we_ticket

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.omnione.did.sdk.core.api.KeyManager
import org.omnione.did.sdk.core.api.DIDManager
import org.omnione.did.sdk.core.keymanager.datamodel.*
import org.omnione.did.sdk.core.didmanager.datamodel.*
import org.omnione.did.sdk.datamodel.common.enums.AlgorithmType
import org.omnione.did.sdk.datamodel.common.BaseObject
import org.omnione.did.sdk.datamodel.did.Service
import org.omnione.did.sdk.datamodel.common.Proof
import org.omnione.did.sdk.utility.DigestUtils
import org.omnione.did.sdk.utility.MultibaseUtils
import org.omnione.did.sdk.utility.DataModels.DigestEnum
import org.omnione.did.sdk.utility.DataModels.MultibaseType
import org.omnione.did.sdk.datamodel.common.enums.ProofPurpose
import org.omnione.did.sdk.datamodel.common.enums.ProofType

class MainActivity : FlutterActivity() {
    private val CHANNEL = "did_sdk"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "createDid" -> {
                        try {
                            Log.d(TAG, "WE-Ticket DID 생성 시작")
                            
                            // 1. KeyManager로 개인키 생성

                            // KeyManager 인스턴스 생성
                            //FIXME SDK 는 java로 설치하고, 얘는 kt로 해서 api 섞어서 보는 실수함 .. java api로 코드 짬 -> 통일 하기
                           val keyManager = KeyManager<DetailKeyInfo>("WETicketWallet", this)
                            // KeyManager<DetailKeyInfo> keyManager = new KeyManager<>("WETicketWallet", this);
                            // val keyManager = KeyManager<BaseObject>("weticket_wallet", this)
                            Log.i(TAG, "KeyManager 생성 완료")

                            // key ID (꼭 고유해야하나?)
                            val keyId = "weticket_key"


                            // key 타입 결정 및 키 생성 (generateKey API)
                            val bioKeyRequest = SecureKeyGenRequest(
                                keyId,
                                AlgorithmType.ALGORITHM_TYPE.SECP256R1,
                                StorageOption.STORAGE_OPTION.KEYSTORE,
                                KeyStoreAccessMethod.KEYSTORE_ACCESS_METHOD.BIOMETRY
                            )
                            keyManager.generateKey(bioKeyRequest)

                            Log.i(TAG, "BIO 개인키 생성 완료 (Android KeyStore)")

                            // val keyId = "weticket_key_${System.currentTimeMillis()}"
                            // val keyGenRequest = WalletKeyGenRequest(
                            //     keyId,
                            //     AlgorithmType.ALGORITHM_TYPE.SECP256R1,
                            //     StorageOption.STORAGE_OPTION.WALLET,
                            //     KeyGenWalletMethodType()
                            // )
                            // Log.d(TAG, "KeyGenRequest 생성 완료 - KeyId: $keyId")
                            
                            // keyManager.generateKey(keyGenRequest)
                            // Log.i(TAG, "개인키 생성 완료 (Android KeyStore)")

                            // 2. 키 정보 조회 (getKeyInfos API)
                            val keyInfoList: List<KeyInfo> = keyManager.getKeyInfos(listOf(keyId))
                            // List<KeyInfo> keyInfoList = keyManager.getKeyInfos(List.of(keyId));
                            // // val keyInfoList = keyManager.getKeyInfos(listOf(keyId))
                            val keyInfo = keyInfoList.first()
                            Log.d(TAG, "KeyInfo 조회 완료")
                            
                            // 공개키 추출
                            val publicKey = keyInfo.publicKey
                            Log.i(TAG, "공개키: ${publicKey.substring(0, 30)}...")

                            // 3. DID 문서 생성 (weticket 도메인)
                            // DID Manager 인스턴스 생성 
                            // val didManager = DIDManager<DIDDocument>("WETicketWallet", this)
                            val didManager = DIDManager<BaseObject>("weticket_did", this)
                            // DIDManager<DIDDocument> didManager = new DIDManager<>("WETicketWallet", this);

                            Log.i(TAG, "DIDManager 생성 완료")

                            // weticket 도메인으로 DID 생성
                            val did: String = DIDManager.genDID("weticket")
                            // String did = DIDManager.genDID("weticket")
                            Log.i(TAG, "WE-Ticket DID 생성: $did")

                            // DID Key Info
                            // val didKeyInfo = DIDKeyInfo(
                            //     keyInfo,
                            //     listOf(DIDMethodType.DID_METHOD_TYPE.authentication),
                            //     "controller"
                            // )

                            val didKeyInfos = listOf(
                                DIDKeyInfo(
                                    keyInfo,
                                    listOf(DIDMethodType.DID_METHOD_TYPE.authentication),
                                    did
                                ),
                                DIDKeyInfo(
                                    keyInfo,
                                    listOf(DIDMethodType.DID_METHOD_TYPE.assertionMethod),
                                    did
                                )
                            )

                            
                            
                            // 4. DID Document 생성 (createDocument API)
                            /* API 설명
                            didManager.createDocument(did, 사용자 DID
                            didKeyInfos, //List<DIDKeyInfo>	DID 문서에 등록할 공개키 정보 객체의 배열
                            did, controller	String	DID 문서에 controller로 등록할 DID. null이면, did 항목을 사용한다.
                            null);service	List<Service>	DID 문서에 명시할 서비스 정보 객체
                             */
                            didManager.createDocument(did, didKeyInfos, did, null);
                            // didManager.createDocument(
                            //     generatedDid, 
                            //     listOf(didKeyInfo), 
                            //     "controller", 
                            //     emptyList<Service>()
                            // )
                            Log.d(TAG, "DID Document 생성 완료")
                            
                            // 6. DID Document 내용 조회
                            val didDocument = didManager.getDocument()
                            Log.d(TAG, "DID Document 내용 조회 완료")
                            Log.d(TAG, didDocument.toJson())

                            //7. 서명
                             val now = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", java.util.Locale.US).apply {
                                timeZone = java.util.TimeZone.getTimeZone("UTC")
                            }.format(java.util.Date())

                            // Proof 객체 생성
                            val proof = Proof().apply {
                                created = now
                                proofPurpose = ProofPurpose.PROOF_PURPOSE.assertionMethod
                                verificationMethod = "${didDocument.id}?versionId=${didDocument.versionId}#$keyId"
                                type = ProofType.PROOF_TYPE.secp256r1Signature2018
                            }
                            didDocument.proof = proof

                                // JSON 직렬화 → SHA-256 해시
                            val jsonData = didDocument.toJson().toByteArray()
                            val digest = DigestUtils.getDigest(jsonData, DigestEnum.DIGEST_ENUM.SHA_256)

                            // 3. KeyManager로 서명
                            val signature = keyManager.sign(keyId, null, digest)

                            // 4. 서명값을 base58btc 인코딩
                            val encodedSignature = MultibaseUtils.encode(
                                MultibaseType.MULTIBASE_TYPE.BASE_58_BTC,
                                signature
                            )

                            // 5. 인코딩된 서명을 proof에 대입
                            proof.proofValue = encodedSignature

                            didDocument.proof = proof

                            Log.d(TAG, "서명 후 DID Document 내용 조회")
                            Log.d(TAG, didDocument.toJson())


                            // 7. Key Attestation 정보 
                            val keyAttestation = mapOf(
                                "keyId" to keyId,
                                "algorithm" to "SECP256R1",
                                "storage" to "Android KeyStore",
                                "createdAt" to System.currentTimeMillis()
                            )
                            Log.i(TAG, "Key Attestation 정보 생성 완료")

                            // 8. 상세 정보를 Flutter로 반환
                            val detailedResult = mapOf(
                                "success" to true,
                                "did" to did,
                                "publicKey" to publicKey,
                                "keyId" to keyId,
                                "didDocument" to didDocument.toString(),
                                "keyAttestation" to keyAttestation,
                                "timestamp" to System.currentTimeMillis()
                            )
                            
                            Log.i(TAG, "WE-Ticket DID 생성 과정 완료")
                            result.success(detailedResult)
                            
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ WE-Ticket DID 생성 실패: ${e.message}", e)
                            val errorResult = mapOf(
                                "success" to false,
                                "error" to e.message,
                                "timestamp" to System.currentTimeMillis()
                            )
                            result.success(errorResult)
                        }
                    }
                
                "saveDidDoc" -> {
                    try {
                        Log.i(TAG, "WE-Ticket DID 저장 플로우 시작")
                        val didManager = DIDManager<BaseObject>("weticket_did", this)
                        didManager.saveDocument();
                        Log.i(TAG, "DID Document 저장 완료")

                        val didDocument = didManager.getDocument()
                        Log.d(TAG, "DID Document 내용 조회 완료")
                        Log.d(TAG, didDocument.toJson())

                        val detailedResult = mapOf(
                                "success" to true,
                                "didDocument" to didDocument.toString(),
                                "timestamp" to System.currentTimeMillis()
                            )

                        Log.i(TAG, "WE-Ticket DID 저장 플로우 완료")
                        result.success(detailedResult)

                    }catch (e: Exception) {
                            Log.e(TAG, "❌ WE-Ticket DID 저장 실패: ${e.message}", e)
                            val errorResult = mapOf(
                                "success" to false,
                                "error" to e.message,
                                "timestamp" to System.currentTimeMillis()
                            )
                            result.success(errorResult)
                        }
                }
                else -> {
                        Log.w(TAG, "⚠️ 알 수 없는 메서드 호출: ${call.method}")
                        result.notImplemented()
                }
            }

        }
    }
}

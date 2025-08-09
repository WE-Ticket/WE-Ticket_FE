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
import org.omnione.did.sdk.datamodel.security.DIDAuth

///서버와 json 맞추기
import com.google.gson.GsonBuilder
import com.google.gson.JsonParser

import java.nio.charset.StandardCharsets

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
                           val keyManager = KeyManager<DetailKeyInfo>("WETicketWallet", this)
                            Log.i(TAG, "KeyManager 생성 완료")

                            // key ID 
                            // did Doc은 지워져도 key는 지워지는게 아니라서 고유해야함 그래서 고유 값 추가
                            val keyId = "weticket_key_${System.currentTimeMillis()}"

                            // key 타입 결정 및 키 생성 (generateKey API)
                            val bioKeyRequest = SecureKeyGenRequest(
                                keyId,
                                AlgorithmType.ALGORITHM_TYPE.SECP256R1,
                                StorageOption.STORAGE_OPTION.KEYSTORE,
                                KeyStoreAccessMethod.KEYSTORE_ACCESS_METHOD.BIOMETRY
                            )
                            keyManager.generateKey(bioKeyRequest)

                            Log.i(TAG, "BIO 개인키 생성 완료 (Android KeyStore)")

                            // 2. 키 정보 조회 (getKeyInfos API)
                            val keyInfoList: List<KeyInfo> = keyManager.getKeyInfos(listOf(keyId))
                            val keyInfo = keyInfoList.first()
                            Log.d(TAG, "KeyInfo 조회 완료")
                            
                            // 공개키 추출
                            val publicKey = keyInfo.publicKey
                            Log.i(TAG, "공개키: ${publicKey}")
                            //FIXME 나중에 지우기 
                            try {
                                val pubkeyBytes = MultibaseUtils.decode(publicKey)
                                Log.i(TAG, "공개키(hex): ${pubkeyBytes.joinToString("") { "%02x".format(it) }}")
                            } catch (e: Exception) {
                                Log.e(TAG, "공개키 디코딩 실패: ${e.message}")
                            }

                            // 3. DID 문서 생성 (weticket 도메인)
                            // DID Manager 인스턴스 생성 
                            val didManager = DIDManager<BaseObject>("weticket_did", this)
                            Log.i(TAG, "DIDManager 생성 완료")

                            // weticket 도메인으로 DID 생성
                            val did: String = DIDManager.genDID("weticket")
                            Log.i(TAG, "WE-Ticket DID 생성: $did")

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
                            Log.d(TAG, "DID Document 생성 완료")
                            
                            // 6. DID Document 내용 조회
                            val didDocument = didManager.getDocument()
                            Log.d(TAG, "처음 DID Document 내용 조회 완료")
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

                            Log.d(TAG, "직렬화 전 DID Document 내용 조회 완료")
                            Log.d(TAG, didDocument.toJson())

                            //서버랑 맞추는 중
                            val gson = GsonBuilder()
                                .disableHtmlEscaping() // Python JSON escape와 맞추기
                                .create()

                            val jsonElement = JsonParser.parseString(didDocument.toJson())
                            val sortedJsonString = gson.toJson(jsonElement)

                            Log.d(TAG, "--- CLIENT SIDE ---")
                            Log.d(TAG, "Signing JSON String: $sortedJsonString")

                            val jsonData = sortedJsonString.toByteArray()

                            // JSON 직렬화 → SHA-256 해시
                            // val jsonData = didDocument.toJson().toByteArray()
                            val digest = DigestUtils.getDigest(jsonData, DigestEnum.DIGEST_ENUM.SHA_256)

                            @OptIn(kotlin.ExperimentalStdlibApi::class)
                            Log.d(TAG, "클라이언트 digest: ${digest.toHexString()}")

                            // 3. KeyManager로 서명
                            val signature = keyManager.sign(keyId, null, digest)

                            Log.d(TAG, "서명 바이트 길이: ${signature.size}")
                            Log.d(TAG, "서명(hex): ${signature.joinToString("") { "%02x".format(it) }}")

                            // 4. 서명값을 base58btc 인코딩
                            val encodedSignature = MultibaseUtils.encode(
                                MultibaseType.MULTIBASE_TYPE.BASE_58_BTC,
                                signature
                            )

                            //FIXME 디버깅
                            // === 서명 검증 테스트 ===
                            Log.d(TAG, "=== Android 내에서 서명 검증 시작 ===")

                            try {
                                // 1. 이미 가져온 공개키 사용 (keyInfo.publicKey)
                                val pubkeyBytes = MultibaseUtils.decode(publicKey) // publicKey는 이미 String
                                
                                // 2. 서명에서 v 제거 (65바이트 → 64바이트)
                                // val signatureWithoutV = signature.copyOfRange(0, 64)
                                
                                // 3. KeyManager의 verify 메소드 사용
                                 keyManager.verify(
                                    AlgorithmType.ALGORITHM_TYPE.SECP256R1,
                                    pubkeyBytes,
                                    digest,
                                    signature //그냥 원본 데이터를 사용 
                                )
                                
                                Log.d(TAG, "✅ Android 내 서명 검증 성공!")
                                
                            } catch (e: Exception) {
                                Log.e(TAG, "❌ Android 검증 실패: ${e.message}")
                            }
                            Log.d(TAG, "=== Android 검증 끝 ===")

                            

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

                            didManager.saveDocument()
                            Log.i(TAG, "DID Document 저장 완료")

                            // 8. 상세 정보를 Flutter로 반환
                            val detailedResult = mapOf(
                                "success" to true,
                                "did" to did,
                                "publicKey" to publicKey,
                                "keyId" to keyId,
                                "didDocument" to didDocument.toJson(),
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
                
                // "saveDidDoc" -> {
                //     try {
                //         Log.i(TAG, "WE-Ticket DID 저장 플로우 시작")
                //         val didManager = DIDManager<BaseObject>("weticket_did", this)

                //         val didJson = call.argument<String>("didDoc") ?: throw Exception("didDocumentJson is null")

                //         didManager.saveDocument()
                //         Log.i(TAG, "DID Document 저장 완료")

                //         val didDocument = didManager.getDocument()
                //         Log.d(TAG, "DID Document 내용 조회 완료")
                //         Log.d(TAG, didDocument.toJson())

                //         val detailedResult = mapOf(
                //                 "success" to true,
                //                 "didDocument" to didDocument.toString(),
                //                 "timestamp" to System.currentTimeMillis()
                //             )

                //         Log.i(TAG, "WE-Ticket DID 저장 플로우 완료")
                //         result.success(detailedResult)

                //     }catch (e: Exception) {
                //             Log.e(TAG, "❌ WE-Ticket DID 저장 실패: ${e.message}", e)
                //             val errorResult = mapOf(
                //                 "success" to false,
                //                 "error" to e.message,
                //                 "timestamp" to System.currentTimeMillis()
                //             )
                //             result.success(errorResult)
                //         }
                // }

                "delDidDoc" -> {
                    try {
                        Log.i(TAG, "WE-Ticket DID 삭제  플로우 시작")
                        val didManager = DIDManager<BaseObject>("weticket_did", this)

                        didManager.deleteDocument()
                        Log.i(TAG, "DID Document 삭제 완료")

                        val detailedResult = mapOf(
                                "success" to true,
                                "timestamp" to System.currentTimeMillis()
                            )
                        result.success(detailedResult)

                    }catch (e: Exception) {
                            Log.e(TAG, "❌ WE-Ticket DID 삭제 실패: ${e.message}", e)
                            val errorResult = mapOf(
                                "success" to false,
                                "error" to e.message,
                                "timestamp" to System.currentTimeMillis()
                            )
                            result.success(errorResult)
                        }
                }

                "didAuth" -> {
                    try {
                        Log.i(TAG, "WE-Ticket DID 검증 플로우 시작")

                        val keyManager = KeyManager<DetailKeyInfo>("WETicketWallet", this)
                        val didManager = DIDManager<BaseObject>("weticket_did", this)
                        Log.i(TAG, "KeyManager, DID Manager 생성 완료 ")

                        val didDocument = didManager.getDocument()
                        Log.d(TAG, "DID Document 내용 조회")
                        Log.d(TAG, didDocument.toJson())

                        val keyId = didDocument.verificationMethod[0].id
                        Log.d(TAG, "keyId 조회 : $keyId")

                        // Proof 객체 생성
                         val now = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", java.util.Locale.US).apply {
                                timeZone = java.util.TimeZone.getTimeZone("UTC")
                        }.format(java.util.Date())


                        val proof = Proof().apply {
                                created = now
                                proofPurpose = ProofPurpose.PROOF_PURPOSE.authentication
                                verificationMethod = "${didDocument.id}?versionId=${didDocument.versionId}#$keyId"
                                type = ProofType.PROOF_TYPE.secp256r1Signature2018
                        }

                        Log.d(TAG, "Proof 객체 생성 완료")

                        var didAuth = DIDAuth().apply{
                            did = didDocument.id
                            authNonce = "auth_nonce_dummy_dddddd"
                            this.proof = proof
                        }
                        Log.d(TAG, "DID Auth 객체 생성 완료")

                        val jsonData = didAuth.toJson().toByteArray()
                        val digest = DigestUtils.getDigest(jsonData, DigestEnum.DIGEST_ENUM.SHA_256)

                        //  KeyManager로 서명
                        val signature = keyManager.sign(keyId, null, digest)

                        // 4. 서명값을 base58btc 인코딩
                        val encodedSignature = MultibaseUtils.encode(
                             MultibaseType.MULTIBASE_TYPE.BASE_58_BTC,
                            signature
                        )

                        didAuth.proof.proofValue = encodedSignature

                        Log.d(TAG, "서명 후 DID Auth 내용 조회")
                        Log.d(TAG, didAuth.toJson())

                        val detailedResult = mapOf(
                                "success" to true,
                                "didDocument" to didDocument.toJson(),
                                "didAuth" to didAuth.toJson(),
                                "timestamp" to System.currentTimeMillis()
                            )

                        Log.i(TAG, "WE-Ticket DID Auth 플로우 완료")
                        result.success(detailedResult)

                    }catch (e: Exception) {
                            Log.e(TAG, "❌ WE-Ticket DID Auth 생성 실패: ${e.message}", e)
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

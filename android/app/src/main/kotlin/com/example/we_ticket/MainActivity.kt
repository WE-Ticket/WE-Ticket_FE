package com.example.we_ticket

import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.omnione.did.sdk.core.api.KeyManager
import org.omnione.did.sdk.core.api.DIDManager
import org.omnione.did.sdk.core.api.WalletApi
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

// 생체인증 관련 import
import androidx.biometric.BiometricPrompt
import androidx.biometric.BiometricManager
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity

class MainActivity : FlutterActivity() {
    private val CHANNEL = "did_sdk"
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Surface 버퍼링 최적화
        window.setFlags(
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        )
        
        // View 계층 최적화 (WebView 렌더링 최적화)
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "createDid" -> {
                        try {
                            Log.d(TAG, "WE-Ticket DID 생성 시작")

                            // 0. 저장된 doc이 있다면 삭제
                            // DID Manager 인스턴스 생성 
                            val didManager = DIDManager<BaseObject>("weticket_did", this)
                            Log.i(TAG, "DIDManager 생성 완료")

                            if (didManager.isSaved()) {
                            Log.i(TAG, "기존 DID doc 발견")

                               didManager.deleteDocument()
                            Log.i(TAG, "기존 DID doc 삭제 완료 ")

                            }
                            
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

                            // Bio 키는 KeyManager의 BIOMETRY 옵션으로 이미 생성됨
                            // WalletApi 없이도 생체인증 키가 Android KeyStore에 저장됨
                            Log.i(TAG, "Bio 키가 Android KeyStore에 생성 및 저장됨")

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
                            

                            // weticket 도메인으로 DID 생성
                            val did: String = DIDManager.genDID("weticket")
                            Log.i(TAG, "WE-Ticket DID 생성: $did")

                            // 생체인증 등록 확인
                            val biometricManager = BiometricManager.from(this)
                            when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK)) {
                                BiometricManager.BIOMETRIC_SUCCESS -> {
                                    Log.i(TAG, "✅ 생체인증 사용 가능 - 등록 프롬프트 표시")
                                    // DID 생성시 생체인증 등록 (DID Document 생성 전)
                                    showBiometricRegistrationPrompt(keyManager, keyId, keyInfo, didManager, did, result)
                                    return@setMethodCallHandler
                                }
                                BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> {
                                    Log.w(TAG, "⚠️ 생체인증 하드웨어 없음 - 일반 DID로 생성")
                                }
                                BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> {
                                    Log.w(TAG, "⚠️ 생체인증 하드웨어 사용 불가 - 일반 DID로 생성")
                                }
                                BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> {
                                    Log.w(TAG, "⚠️ 생체인증 등록되지 않음 - 일반 DID로 생성")
                                }
                                else -> {
                                    Log.w(TAG, "⚠️ 생체인증 기타 오류 - 일반 DID로 생성")
                                }
                            }

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

                        val nonce = call.argument<String>("nonce")
                        Log.i(TAG, "전달 받은 nonce : ${nonce}")

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

                        val didAuth = DIDAuth().apply{
                            did = didDocument.id
                            authNonce = nonce
                            this.proof = proof
                        }
                        Log.d(TAG, "DID Auth 객체 생성 완료")

                        // 생체인증 가능 여부 확인
                        val biometricManager = BiometricManager.from(this)
                        when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK)) {
                            BiometricManager.BIOMETRIC_SUCCESS -> {
                                Log.i(TAG, "✅ 생체인증 사용 가능")
                                // 생체인증 프롬프트 실행
                                showBiometricPrompt(keyManager, keyId, didAuth, didDocument, result)
                                return@setMethodCallHandler
                            }
                            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> {
                                Log.w(TAG, "⚠️ 생체인증 하드웨어 없음 - 일반 서명 진행")
                            }
                            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> {
                                Log.w(TAG, "⚠️ 생체인증 하드웨어 사용 불가 - 일반 서명 진행")
                            }
                            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> {
                                Log.w(TAG, "⚠️ 생체인증 등록되지 않음 - 일반 서명 진행")
                            }
                        }

                        val jsonData = didAuth.toJson().toByteArray()
                        val digest = DigestUtils.getDigest(jsonData, DigestEnum.DIGEST_ENUM.SHA_256)

                        // 생체인증이 사용 불가능한 경우 일반 서명 진행
                        Log.i(TAG, "🔑 일반 키 서명 진행")
                        
                        //  KeyManager로 서명
                        val signature = keyManager.sign(keyId, null, digest)
                        Log.i(TAG, "✅ 일반 서명 완료")

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

    // DID 생성시 생체인증 등록 프롬프트
    private fun showBiometricRegistrationPrompt(keyManager: KeyManager<DetailKeyInfo>, keyId: String, keyInfo: KeyInfo, didManager: DIDManager<BaseObject>, did: String, result: MethodChannel.Result) {
        val executor = ContextCompat.getMainExecutor(this)
        
        val biometricPrompt = BiometricPrompt(this as FragmentActivity,
            executor, object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    Log.e(TAG, "❌ 생체인증 등록 에러: $errString")
                    // 생체인증 실패시 일반 DID로 진행
                    completeDIDCreationWithBiometricResult(keyManager, keyId, keyInfo, didManager, did, result, false)
                }

                override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(authResult)
                    Log.i(TAG, "✅ 생체인증 등록 성공!")
                    // 생체인증 성공시 Bio DID로 완료
                    completeDIDCreationWithBiometricResult(keyManager, keyId, keyInfo, didManager, did, result, true)
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    Log.w(TAG, "⚠️ 생체인증 등록 실패 - 재시도 가능")
                }
            })

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("WE-Ticket DID 생체인증 등록")
            .setSubtitle("DID 생성을 위한 생체인증을 등록해주세요")
            .setDescription("이 생체인증은 향후 DID 인증시 사용됩니다")
            .setNegativeButtonText("건너뛰기")
            .build()

        Log.i(TAG, "🔐 생체인증 등록 프롬프트 표시")
        biometricPrompt.authenticate(promptInfo)
    }

    // 생체인증 프롬프트 표시 메서드  
    private fun showBiometricPrompt(keyManager: KeyManager<DetailKeyInfo>, keyId: String, didAuth: DIDAuth, didDocument: org.omnione.did.sdk.datamodel.did.DIDDocument, result: MethodChannel.Result) {
        val executor = ContextCompat.getMainExecutor(this)
        
        val biometricPrompt = BiometricPrompt(this as FragmentActivity,
            executor, object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    Log.e(TAG, "❌ 생체인증 에러: $errString")
                    // 생체인증 실패시 일반 서명으로 진행
                    performNormalSigning(keyManager, keyId, didAuth, didDocument, result)
                }

                override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(authResult)
                    Log.i(TAG, "✅ 생체인증 성공!")
                    // 생체인증 성공시 서명 진행
                    performBiometricSigning(keyManager, keyId, didAuth, didDocument, result)
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    Log.w(TAG, "⚠️ 생체인증 실패 - 재시도 가능")
                }
            })

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("WE-Ticket 생체인증")
            .setSubtitle("DID 인증을 위한 생체인증이 필요합니다")
            .setNegativeButtonText("취소")
            .build()

        Log.i(TAG, "🔐 생체인증 프롬프트 표시")
        biometricPrompt.authenticate(promptInfo)
    }

    // 생체인증 성공 후 서명
    private fun performBiometricSigning(keyManager: KeyManager<DetailKeyInfo>, keyId: String, didAuth: DIDAuth, didDocument: org.omnione.did.sdk.datamodel.did.DIDDocument, result: MethodChannel.Result) {
        try {
            Log.i(TAG, "🔐 생체인증 후 서명 시작")
            
            val jsonData = didAuth.toJson().toByteArray()
            val digest = DigestUtils.getDigest(jsonData, DigestEnum.DIGEST_ENUM.SHA_256)
            
            // Bio 키로 서명
            val signature = keyManager.sign(keyId, null, digest)
            Log.i(TAG, "✅ 생체인증 서명 완료")
            
            completeDIDAuthSigning(didAuth, didDocument, signature, result)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ 생체인증 서명 실패: ${e.message}")
            // 실패시 일반 서명으로 fallback
            performNormalSigning(keyManager, keyId, didAuth, didDocument, result)
        }
    }

    // 일반 서명 (생체인증 없음)
    private fun performNormalSigning(keyManager: KeyManager<DetailKeyInfo>, keyId: String, didAuth: DIDAuth, didDocument: org.omnione.did.sdk.datamodel.did.DIDDocument, result: MethodChannel.Result) {
        try {
            Log.i(TAG, "🔑 일반 서명 진행")
            
            val jsonData = didAuth.toJson().toByteArray()
            val digest = DigestUtils.getDigest(jsonData, DigestEnum.DIGEST_ENUM.SHA_256)
            
            val signature = keyManager.sign(keyId, null, digest)
            Log.i(TAG, "✅ 일반 서명 완료")
            
            completeDIDAuthSigning(didAuth, didDocument, signature, result)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ 일반 서명도 실패: ${e.message}")
            result.success(mapOf(
                "success" to false,
                "error" to e.message,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }

    // DID Auth 서명 완료 처리
    private fun completeDIDAuthSigning(didAuth: DIDAuth, didDocument: org.omnione.did.sdk.datamodel.did.DIDDocument, signature: ByteArray, result: MethodChannel.Result) {
        try {
            // 서명값을 base58btc 인코딩
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
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ DID Auth 완료 처리 실패: ${e.message}")
            result.success(mapOf(
                "success" to false,
                "error" to e.message,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }

    // 생체인증 결과를 포함한 DID 생성 완료 처리
    private fun completeDIDCreationWithBiometricResult(keyManager: KeyManager<DetailKeyInfo>, keyId: String, keyInfo: KeyInfo, didManager: DIDManager<BaseObject>, did: String, result: MethodChannel.Result, isBiometricEnabled: Boolean) {
        try {
            Log.i(TAG, "DID 생성 완료 처리 시작 - 생체인증 ${if (isBiometricEnabled) "활성화" else "비활성화"}")

            // DID Document 생성 계속 진행
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

            // DID Document 생성
            didManager.createDocument(did, didKeyInfos, did, null)
            Log.d(TAG, "DID Document 생성 완료")
            
            // DID Document 내용 조회
            val didDocument = didManager.getDocument()
            Log.d(TAG, "처음 DID Document 내용 조회 완료")
            Log.d(TAG, didDocument.toJson())

            // 서명 과정
            val now = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", java.util.Locale.US).apply {
                timeZone = java.util.TimeZone.getTimeZone("UTC")
            }.format(java.util.Date())

            val proof = Proof().apply {
                created = now
                proofPurpose = ProofPurpose.PROOF_PURPOSE.assertionMethod
                verificationMethod = "${didDocument.id}?versionId=${didDocument.versionId}#$keyId"
                type = ProofType.PROOF_TYPE.secp256r1Signature2018
            }
            didDocument.proof = proof

            Log.d(TAG, "직렬화 전 DID Document 내용 조회 완료")
            Log.d(TAG, didDocument.toJson())

            // 서명 처리
            val gson = GsonBuilder().disableHtmlEscaping().create()
            val jsonElement = JsonParser.parseString(didDocument.toJson())
            val sortedJsonString = gson.toJson(jsonElement)
            val jsonData = sortedJsonString.toByteArray()
            val digest = DigestUtils.getDigest(jsonData, DigestEnum.DIGEST_ENUM.SHA_256)

            // KeyManager로 서명
            val signature = keyManager.sign(keyId, null, digest)
            val encodedSignature = MultibaseUtils.encode(
                MultibaseType.MULTIBASE_TYPE.BASE_58_BTC,
                signature
            )

            proof.proofValue = encodedSignature
            didDocument.proof = proof
            Log.d(TAG, "서명 후 DID Document 내용 조회")
            Log.d(TAG, didDocument.toJson())

            didManager.saveDocument()
            Log.i(TAG, "DID Document 저장 완료")

            // Key Attestation 정보 
            val keyAttestation = mapOf(
                "keyId" to keyId,
                "algorithm" to "SECP256R1",
                "storage" to "Android KeyStore",
                "biometricEnabled" to isBiometricEnabled,
                "createdAt" to System.currentTimeMillis()
            )
            Log.i(TAG, "Key Attestation 정보 생성 완료")

            // 상세 정보를 Flutter로 반환
            val detailedResult = mapOf(
                "success" to true,
                "did" to did,
                "publicKey" to keyInfo.publicKey,
                "keyId" to keyId,
                "didDocument" to didDocument.toJson(),
                "keyAttestation" to keyAttestation,
                "biometricEnabled" to isBiometricEnabled,
                "timestamp" to System.currentTimeMillis()
            )
            
            val statusMessage = if (isBiometricEnabled) "생체인증 DID 생성" else "일반 DID 생성"
            Log.i(TAG, "WE-Ticket $statusMessage 과정 완료")
            result.success(detailedResult)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ DID 생성 완료 처리 실패: ${e.message}")
            result.success(mapOf(
                "success" to false,
                "error" to e.message,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }

    // DID 생성 완료 처리 (기존)
    private fun completeDIDCreation(didDocument: org.omnione.did.sdk.datamodel.did.DIDDocument, keyId: String, result: MethodChannel.Result, isBiometricEnabled: Boolean) {
        try {
            // DID Document 저장
            val didManager = DIDManager<BaseObject>("weticket_did", this)
            didManager.saveDocument()
            Log.i(TAG, "DID Document 저장 완료")

            // Key Attestation 정보 
            val keyAttestation = mapOf(
                "keyId" to keyId,
                "algorithm" to "SECP256R1",
                "storage" to "Android KeyStore",
                "biometricEnabled" to isBiometricEnabled,
                "createdAt" to System.currentTimeMillis()
            )
            Log.i(TAG, "Key Attestation 정보 생성 완료")

            // 상세 정보를 Flutter로 반환
            val detailedResult = mapOf(
                "success" to true,
                "did" to didDocument.id,
                "keyId" to keyId,
                "didDocument" to didDocument.toJson(),
                "keyAttestation" to keyAttestation,
                "biometricEnabled" to isBiometricEnabled,
                "timestamp" to System.currentTimeMillis()
            )
            
            val statusMessage = if (isBiometricEnabled) "생체인증 DID 생성" else "일반 DID 생성"
            Log.i(TAG, "WE-Ticket $statusMessage 과정 완료")
            result.success(detailedResult)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ DID 생성 완료 처리 실패: ${e.message}")
            result.success(mapOf(
                "success" to false,
                "error" to e.message,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }
}

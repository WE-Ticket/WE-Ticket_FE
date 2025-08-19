package com.example.we_ticket

import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// OmniOne SDK
import org.omnione.did.sdk.core.api.KeyManager
import org.omnione.did.sdk.core.api.DIDManager
import org.omnione.did.sdk.core.keymanager.datamodel.*
import org.omnione.did.sdk.core.didmanager.datamodel.*
import org.omnione.did.sdk.datamodel.common.enums.AlgorithmType
import org.omnione.did.sdk.datamodel.common.BaseObject
import org.omnione.did.sdk.datamodel.did.Service
import org.omnione.did.sdk.datamodel.common.Proof
import org.omnione.did.sdk.datamodel.common.enums.ProofPurpose
import org.omnione.did.sdk.datamodel.common.enums.ProofType
import org.omnione.did.sdk.datamodel.security.DIDAuth
import org.omnione.did.sdk.utility.DigestUtils
import org.omnione.did.sdk.utility.MultibaseUtils
import org.omnione.did.sdk.utility.DataModels.DigestEnum
import org.omnione.did.sdk.utility.DataModels.MultibaseType

import org.omnione.did.sdk.core.api.WalletApi


// JSON (서버와 동일 직렬화)
import com.google.gson.GsonBuilder
import com.google.gson.JsonParser

class MainActivity : FlutterActivity() {
    private val CHANNEL = "did_sdk"
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Surface/뷰 최적화(기존 유지)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        )
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

                    // ----------------------------------------------------------
                    // 1) DID 생성 + BIO 프롬프트로 서명 + 저장
                    // ----------------------------------------------------------
                    "createDid" -> {
                        try {
                            Log.d(TAG, "WE-Ticket DID 생성 시작")

                            // DID & Key Manager
                            val didManager = DIDManager<BaseObject>("weticket_did", this)
                            if (didManager.isSaved()) {
                                Log.i(TAG, "기존 DID doc 발견 → 삭제")
                                didManager.deleteDocument()
                            }

                            val keyManager = KeyManager<DetailKeyInfo>("WETicketWallet", this)
                            Log.i(TAG, "KeyManager 생성 완료")

                            // 고유 keyId (키는 DIDDoc 삭제와 별개로 남으므로 고유값 권장)
                            val keyId = "weticket_key_${System.currentTimeMillis()}"

                            // BIO 키 생성 (Android KeyStore)
                            val bioKeyRequest = SecureKeyGenRequest(
                                keyId,
                                AlgorithmType.ALGORITHM_TYPE.SECP256R1,
                                StorageOption.STORAGE_OPTION.KEYSTORE,
                                KeyStoreAccessMethod.KEYSTORE_ACCESS_METHOD.BIOMETRY
                            )
                            keyManager.generateKey(bioKeyRequest)
                            Log.i(TAG, "BIO 개인키 생성 완료 (Android KeyStore)")

                            // 공개키 조회
                            val keyInfoList: List<KeyInfo> = keyManager.getKeyInfos(listOf(keyId))
                            val keyInfo = keyInfoList.first()
                            val publicKey = keyInfo.publicKey
                            Log.i(TAG, "공개키(multibase): $publicKey")

                            // DID 생성
                            val did: String = DIDManager.genDID("weticket")
                            Log.i(TAG, "WE-Ticket DID 생성: $did")

                            // DIDKeyInfo 구성 (authentication + assertionMethod)
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

                            // DIDDocument 생성 (임시 객체)
                            didManager.createDocument(did, didKeyInfos, did, /*service*/ null)
                            var didDocument = didManager.getDocument()
                            Log.d(TAG, "DID Document(초안): ${didDocument.toJson()}")

                            // Proof 골격(서명 전) — verificationMethod는 실제 vm.id로 나중에 갱신
                            val now = java.text.SimpleDateFormat(
                                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                                java.util.Locale.US
                            ).apply {
                                timeZone = java.util.TimeZone.getTimeZone("UTC")
                            }.format(java.util.Date())

                            val proof = Proof().apply {
                                created = now
                                proofPurpose = ProofPurpose.PROOF_PURPOSE.assertionMethod
                                type = ProofType.PROOF_TYPE.secp256r1Signature2018
                            }
                            didDocument.proof = proof

                            // 서버와 동일 직렬화(정렬/escape 일치)
                            val gson = GsonBuilder().disableHtmlEscaping().create()
                            val jsonElement = JsonParser.parseString(didDocument.toJson())
                            val sortedJsonString = gson.toJson(jsonElement)
                            Log.d(TAG, "[직렬화 미서명] $sortedJsonString")

                            // === 여기부터 BIO 프롬프트 + SDK가 서명 ===
                            val walletApi = WalletApi.getInstance(this)

                            // BIO 키 미등록 시 1회 등록
                            try {
                                if (!walletApi.isSavedBioKey()) {
                                    Log.i(TAG, "BIO 키 미등록 → registerBioKey()")
                                    walletApi.registerBioKey(this)
                                }
                            } catch (e: Exception) {
                                Log.w(TAG, "isSavedBioKey/registerBioKey 처리 중 경고: ${e.message}")
                            }

                            // 프롬프트(반드시 뜸)
                            Log.i(TAG, "BiometricPrompt 표시 → authenticateBioKey()")
                            walletApi.authenticateBioKey(this, this)

                            // verificationMethod의 실제 id를 proof.verificationMethod에 반영
                            // DIDManager가 생성한 vm의 id를 그대로 사용해야 검증측에서 찾을 수 있음
                            val vmIdFromDoc = didDocument.verificationMethod.first().id
                            didDocument.proof.verificationMethod =
                                "${didDocument.id}?versionId=${didDocument.versionId}#$vmIdFromDoc"

                            // SDK가 Proof 포함 문서에 서명(패스코드 null = BIO)
                            // type: 1=deviceKey DID Document, 2=holder DID Document (현재 로컬 생성 장치키로 서명 → 1)
                            Log.i(TAG, "walletApi.addProofsToDocument() 호출(BIO)")
                            didDocument = walletApi.addProofsToDocument(
                                /*document=*/didDocument,
                                /*keyIds=*/listOf(keyId),
                                /*did=*/did,
                                /*type=*/1,
                                /*passcode=*/null,
                                /*isDIDAuth=*/false
                            ) as DIDDocument

                            Log.d(TAG, "서명 완료 DID Document: ${didDocument.toJson()}")

                            // 저장
                            didManager.replaceDocument(didDocument, /*needUpdate=*/false)
                            didManager.saveDocument()
                            Log.i(TAG, "DID Document 저장 완료")

                            val detailedResult = mapOf(
                                "success" to true,
                                "did" to did,
                                "publicKey" to publicKey,
                                "keyId" to keyId,
                                "didDocument" to didDocument.toJson(),
                                "timestamp" to System.currentTimeMillis()
                            )
                            Log.i(TAG, "WE-Ticket DID 생성 전체 완료")
                            result.success(detailedResult)

                        } catch (e: Exception) {
                            Log.e(TAG, "❌ WE-Ticket DID 생성 실패: ${e.message}", e)
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "error" to e.message,
                                    "timestamp" to System.currentTimeMillis()
                                )
                            )
                        }
                    }

                    // ----------------------------------------------------------
                    // 2) DID 문서 삭제
                    // ----------------------------------------------------------
                    "delDidDoc" -> {
                        try {
                            val didManager = DIDManager<BaseObject>("weticket_did", this)
                            didManager.deleteDocument()
                            Log.i(TAG, "DID Document 삭제 완료")
                            result.success(
                                mapOf(
                                    "success" to true,
                                    "timestamp" to System.currentTimeMillis()
                                )
                            )
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ DID 삭제 실패: ${e.message}", e)
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "error" to e.message,
                                    "timestamp" to System.currentTimeMillis()
                                )
                            )
                        }
                    }

                    // ----------------------------------------------------------
                    // 3) DID Auth 생성(BIO 프롬프트 포함)
                    // ----------------------------------------------------------
                    "didAuth" -> {
                        try {
                            val nonce = call.argument<String>("nonce")
                                ?: throw IllegalArgumentException("nonce is null")
                            Log.i(TAG, "전달 받은 nonce: $nonce")

                            val didManager = DIDManager<BaseObject>("weticket_did", this)
                            val didDocument = didManager.getDocument()
                            Log.d(TAG, "저장된 DID Document: ${didDocument.toJson()}")

                            // DIDAuth 골격
                            val now = java.text.SimpleDateFormat(
                                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                                java.util.Locale.US
                            ).apply {
                                timeZone = java.util.TimeZone.getTimeZone("UTC")
                            }.format(java.util.Date())

                            val vmIdFromDoc = didDocument.verificationMethod.first().id

                            val proof = Proof().apply {
                                created = now
                                proofPurpose = ProofPurpose.PROOF_PURPOSE.authentication
                                type = ProofType.PROOF_TYPE.secp256r1Signature2018
                                verificationMethod =
                                    "${didDocument.id}?versionId=${didDocument.versionId}#$vmIdFromDoc"
                            }

                            var didAuth = DIDAuth().apply {
                                did = didDocument.id
                                authNonce = nonce
                                this.proof = proof
                            }
                            Log.d(TAG, "DIDAuth(서명 전): ${didAuth.toJson()}")

                            // BIO 프롬프트 → addProofsToDocument로 서명
                            val walletApi = WalletApi.getInstance(this)

                            // 필요 시 BioKey 등록 확인
                            try {
                                if (!walletApi.isSavedBioKey()) {
                                    walletApi.registerBioKey(this)
                                }
                            } catch (_: Exception) { /* optional */ }

                            walletApi.authenticateBioKey(this, this)

                            // DIDAuth는 ProofContainer 이므로 그대로 사용
                            // DIDAuth의 서명에 사용할 keyId = DID 문서의 첫 VM이 가리키는 키 id와 동일해야 함.
                            // DIDManager가 DIDDocument를 만들 때 집어넣은 KeyInfo.id 가 우리가 만든 keyId이므로,
                            // 아래에서는 DID 문서의 verificationMethod[0].id에서 fragment(#...)를 제거하여 원 키 id를 추출해도 되고,
                            // 본 예제에서는 DID 생성 시 사용한 keyId를 Flutter 측에서 함께 보관/재사용하도록 설계하는 것을 권장.
                            // 여기서는 간단히 DID 문서의 첫 verificationMethod가 참조하는 키 이름을 그대로 쓴다고 가정.
                            val firstVmId = didDocument.verificationMethod.first().id
                            // 보통 vm.id 는  "<did>#<keyId>" 꼴일 수 있으니, 뒤쪽 fragment만 키 이름으로 가정
                            val keyIdForSign = firstVmId.substringAfterLast("#", firstVmId)

                            didAuth = walletApi.addProofsToDocument(
                                /*document=*/didAuth,
                                /*keyIds=*/listOf(keyIdForSign),
                                /*did=*/didDocument.id,
                                /*type=*/1,              // deviceKey DID로 서명한 경우 1
                                /*passcode=*/null,       // BIO 서명
                                /*isDIDAuth=*/true
                            ) as DIDAuth

                            Log.d(TAG, "DIDAuth(서명 후): ${didAuth.toJson()}")

                            result.success(
                                mapOf(
                                    "success" to true,
                                    "didDocument" to didDocument.toJson(),
                                    "didAuth" to didAuth.toJson(),
                                    "timestamp" to System.currentTimeMillis()
                                )
                            )
                            Log.i(TAG, "WE-Ticket DID Auth 플로우 완료")

                        } catch (e: Exception) {
                            Log.e(TAG, "❌ WE-Ticket DID Auth 실패: ${e.message}", e)
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "error" to e.message,
                                    "timestamp" to System.currentTimeMillis()
                                )
                            )
                        }
                    }

                    else -> {
                        Log.w(TAG, "⚠️ 알 수 없는 메서드: ${call.method}")
                        result.notImplemented()
                    }
                }
            }
    }
}
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
import org.omnione.did.sdk.datamodel.did.Proof
import org.omnione.did.sdk.datamodel.did.DIDAuth
import org.omnione.did.sdk.util.MultibaseUtils
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "did_sdk"
    private val TAG = "MainActivity"
    private lateinit var keyManager: KeyManager<BaseObject>
    private lateinit var didManager: DIDManager<BaseObject>
    private lateinit var generatedDid: String
    private lateinit var currentKeyId: String

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // KeyManager 및 DIDManager 초기화
        keyManager = KeyManager("weticket_wallet", this)
        didManager = DIDManager("weticket_did", this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // 1️. DID 생성
                    "createDid" -> {
                        try {
                            Log.d(TAG, "[createDid] DID 생성 시작")

                            // 키 ID 생성 (유니크 값 사용)
                            currentKeyId = "weticket_key_${System.currentTimeMillis()}"
                            Log.d(TAG, "[createDid] 키 ID: $currentKeyId")

                            // 키 생성 요청 (Android Wallet에 저장)
                            val keyGenRequest = WalletKeyGenRequest(
                                currentKeyId,
                                AlgorithmType.ALGORITHM_TYPE.SECP256R1,
                                StorageOption.STORAGE_OPTION.WALLET,
                                KeyGenWalletMethodType()
                            )
                            keyManager.generateKey(keyGenRequest)
                            Log.i(TAG, "[createDid] 개인키 생성 완료")

                            // 생성된 키 정보 조회
                            val keyInfoList = keyManager.getKeyInfos(listOf(currentKeyId))
                            val keyInfo = keyInfoList.first()
                            val publicKey = keyInfo.publicKey
                            Log.i(TAG, "[createDid] 공개키 조회 완료 (앞 30자): ${publicKey.take(30)}...")

                            // DIDKeyInfo 생성
                            val didKeyInfo = DIDKeyInfo(
                                keyInfo,
                                DIDMethodType.DID_METHOD_TYPE.authentication,
                                "controller"
                            )

                            // DID 생성
                            generatedDid = DIDManager.genDID("weticket")
                            Log.i(TAG, "[createDid] DID 생성 완료: $generatedDid")

                            // DID Document 생성 및 저장
                            didManager.createDocument(
                                generatedDid,
                                listOf(didKeyInfo),
                                "controller",
                                emptyList<Service>()
                            )
                            didManager.saveDocument()
                            val didDocument = didManager.getDocument()
                            Log.i(TAG, "[createDid] DID Document 생성 및 저장 완료")

                            // Key Attestation 정보 생성
                            val keyAttestation = mapOf(
                                "keyId" to currentKeyId,
                                "algorithm" to "SECP256R1",
                                "storage" to "Android KeyStore",
                                "createdAt" to System.currentTimeMillis()
                            )

                            Log.i(TAG, "[createDid] DID 생성 프로세스 성공적으로 완료됨")
                            result.success(mapOf(
                                "success" to true,
                                "did" to generatedDid,
                                "publicKey" to publicKey,
                                "keyId" to currentKeyId,
                                "didDocument" to didDocument.toString(),
                                "keyAttestation" to keyAttestation
                            ))
                        } catch (e: Exception) {
                            Log.e(TAG, "[createDid] DID 생성 실패: ${e.message}", e)
                            result.error("CREATE_DID_ERROR", e.message, null)
                        }
                    }

                    // 2️. Proof 서명
                    "signProof" -> {
                        try {
                            Log.d(TAG, "[signProof] Proof 서명 시작")
                            val keyId = call.argument<String>("keyId") ?: currentKeyId
                            val didDocument = didManager.getDocument()

                            // Proof 객체 생성
                            val proof = Proof().apply {
                                type = "secp256r1Signature2018"
                                created = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date())
                                proofPurpose = "assertionMethod"
                                verificationMethod = "${generatedDid}?versionId=${didDocument.versionId}#$keyId"
                            }

                            // DID Document 해시 생성 및 서명
                            val didJson = didDocument.toJson()
                            val didHash = MessageDigest.getInstance("SHA-256").digest(didJson.toByteArray())
                            val signature = keyManager.sign(keyId, null, didHash)
                            proof.proofValue = MultibaseUtils.encode(MultibaseUtils.Base.Base58BTC, signature)

                            // Proof 추가 후 저장
                            didDocument.proof = proof
                            didManager.replaceDocument(didDocument, false)
                            didManager.saveDocument()

                            Log.i(TAG, "[signProof] Proof 서명 완료")
                            result.success(mapOf(
                                "success" to true,
                                "proof" to proof.toString()
                            ))
                        } catch (e: Exception) {
                            Log.e(TAG, "[signProof] Proof 서명 실패: ${e.message}", e)
                            result.error("SIGN_PROOF_ERROR", e.message, null)
                        }
                    }

                    // 3️.  DIDAuth 생성
                    "createDidAuth" -> {
                        try {
                            Log.d(TAG, "[createDidAuth] DIDAuth 생성 시작")
                            val nonce = call.argument<String>("nonce") ?: UUID.randomUUID().toString()
                            val didDocument = didManager.getDocument()

                            val auth = DIDAuth().apply {
                                did = generatedDid
                                authNonce = nonce
                                proof = Proof().apply {
                                    type = "secp256r1Signature2018"
                                    created = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date())
                                    proofPurpose = "authentication"
                                    verificationMethod = "${generatedDid}?versionId=${didDocument.versionId}#$currentKeyId"
                                }
                            }

                            val didAuthHash = MessageDigest.getInstance("SHA-256")
                                .digest(auth.toJson().toByteArray())
                            val authSignature = keyManager.sign(currentKeyId, null, didAuthHash)
                            auth.proof.proofValue = MultibaseUtils.encode(MultibaseUtils.Base.Base58BTC, authSignature)

                            Log.i(TAG, "[createDidAuth] DIDAuth 객체 생성 완료")
                            result.success(mapOf(
                                "success" to true,
                                "didAuth" to auth.toString()
                            ))
                        } catch (e: Exception) {
                            Log.e(TAG, "[createDidAuth] DIDAuth 생성 실패: ${e.message}", e)
                            result.error("CREATE_DIDAUTH_ERROR", e.message, null)
                        }
                    }

                    // 4.  생체 인증 키 등록
                    "registerBioKey" -> {
                        try {
                            Log.d(TAG, "[registerBioKey] 생체 인증 키 등록 시작")
                            val bioKeyId = "bio_key_${System.currentTimeMillis()}"
                            val bioKeyRequest = SecureKeyGenRequest(
                                bioKeyId,
                                AlgorithmType.ALGORITHM_TYPE.SECP256R1,
                                StorageOption.STORAGE_OPTION.KEYSTORE,
                                KeyStoreAccessMethod.KEYSTORE_ACCESS_METHOD.BIOMETRY
                            )
                            keyManager.generateKey(bioKeyRequest)

                            Log.i(TAG, "[registerBioKey] 생체 인증 키 등록 완료: $bioKeyId")
                            result.success(mapOf(
                                "success" to true,
                                "bioKeyId" to bioKeyId
                            ))
                        } catch (e: Exception) {
                            Log.e(TAG, "[registerBioKey] 생체 인증 키 등록 실패: ${e.message}", e)
                            result.error("REGISTER_BIO_KEY_ERROR", e.message, null)
                        }
                    }

                    // 5️ DID & 키 삭제
                    "deleteDid" -> {
                        try {
                            Log.d(TAG, "[deleteDid] DID 및 키 삭제 시작")
                            didManager.deleteDocument()
                            keyManager.deleteAllKeys()
                            Log.i(TAG, "[deleteDid] DID 문서와 키 모두 삭제 완료")
                            result.success(mapOf("success" to true))
                        } catch (e: Exception) {
                            Log.e(TAG, "[deleteDid] DID 삭제 실패: ${e.message}", e)
                            result.error("DELETE_DID_ERROR", e.message, null)
                        }
                    }

                    else -> {
                        Log.w(TAG, "알 수 없는 메서드 호출: ${call.method}")
                        result.notImplemented()
                    }
                }
            }
    }
}
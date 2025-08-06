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
                            
                            // 1. KeyManager로 개인키 생성 (Android KeyStore)
                            val keyManager = KeyManager<BaseObject>("weticket_wallet", this)
                            Log.i(TAG, "KeyManager 생성 완료")
                            
                            val keyId = "weticket_key_${System.currentTimeMillis()}"
                            val keyGenRequest = WalletKeyGenRequest(
                                keyId,
                                AlgorithmType.ALGORITHM_TYPE.SECP256R1,
                                StorageOption.STORAGE_OPTION.WALLET,
                                KeyGenWalletMethodType()
                            )
                            Log.d(TAG, "KeyGenRequest 생성 완료 - KeyId: $keyId")
                            
                            keyManager.generateKey(keyGenRequest)
                            Log.i(TAG, "개인키 생성 완료 (Android KeyStore)")

                            // 2. 키 정보 조회
                            val keyInfoList = keyManager.getKeyInfos(listOf(keyId))
                            val keyInfo = keyInfoList.first()
                            Log.d(TAG, "KeyInfo 조회 완료")
                            
                            // 공개키 추출
                            val publicKey = keyInfo.publicKey
                            Log.i(TAG, "공개키: ${publicKey.substring(0, 30)}...")

                            // 3. DID 생성 (weticket 도메인)
                            val didKeyInfo = DIDKeyInfo(
                                keyInfo,
                                listOf(DIDMethodType.DID_METHOD_TYPE.authentication),
                                "controller"
                            )

                            val didManager = DIDManager<BaseObject>("weticket_did", this)
                            Log.i(TAG, "DIDManager 생성 완료")
                            
                            // weticket 도메인으로 DID 생성
                            val generatedDid = DIDManager.genDID("weticket")
                            Log.i(TAG, "WE-Ticket DID 생성: $generatedDid")
                            
                            // 4. DID Document 생성
                            didManager.createDocument(
                                generatedDid, 
                                listOf(didKeyInfo), 
                                "controller", 
                                emptyList<Service>()
                            )
                            Log.d(TAG, "DID Document 생성 완료")
                            
                            // 5. DID Document 저장
                            didManager.saveDocument()
                            Log.i(TAG, "DID Document 저장 완료")
                            
                            // 6. DID Document 내용 조회
                            val didDocument = didManager.getDocument()
                            Log.d(TAG, "DID Document 내용 조회 완료")

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
                                "did" to generatedDid,
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
                    else -> {
                        Log.w(TAG, "⚠️ 알 수 없는 메서드 호출: ${call.method}")
                        result.notImplemented()
                    }
                }
            }
    }
}

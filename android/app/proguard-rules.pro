# WebView 관련 규칙
-keep class android.webkit.WebView { *; }
-keep class android.webkit.WebViewClient { *; }
-keep class android.webkit.WebChromeClient { *; }
-keep class android.webkit.JavascriptInterface { *; }

# 포트원 결제 관련
-keep class com.portone.** { *; }

# Chrome WebView 관련
-keep class org.chromium.** { *; }
-keep class com.android.webview.** { *; }

# 네트워크 관련
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# JSON 파싱 관련
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
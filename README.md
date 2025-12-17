# WE-Ticket Frontend

## 목차

- [How to Install](#-how-to-install)
- [How to Build](#-how-to-build)
- [How to Test](#-how-to-test)
- [주요 기능](#-주요-기능)
- [기술 스택](#-기술-스택)
- [아키텍처](#-아키텍처)
- [소스코드 구조](#-소스코드-구조)
- [주요 라이브러리](#-주요-라이브러리)
- [개발 가이드](#-개발-가이드)
- [트러블슈팅](#-트러블슈팅)

---

## 🔧 How to Install

### Prerequisites (필수 요구사항)

#### 1. Flutter SDK

- **Flutter 3.8.1** 이상
- **Dart 3.8.1** 이상

설치 확인:

```bash
flutter --version
dart --version
```

Flutter 설치: [공식 문서](https://docs.flutter.dev/get-started/install)

#### 2. Platform Requirements (플랫폼별 요구사항)

##### Android

- **Android Studio** Arctic Fox 이상
- **Android SDK** API 21 (Lollipop) 이상
- **JDK** 11 이상
- **Gradle** 7.0 이상

##### iOS

- **Xcode** 14.0 이상
- **macOS** Monterey (12.0) 이상
- **CocoaPods** 1.11 이상

CocoaPods 설치:

```bash
sudo gem install cocoapods
```

#### 3. Development Tools (개발 도구 - 권장)

- **IDE**:
  - Android Studio / IntelliJ IDEA
  - Visual Studio Code (+ Flutter/Dart 확장)
- **Git**: 버전 관리
- **Postman**: API 테스트

### Installation Steps (설치 단계)

#### Step 1: Clone Repository (저장소 클론)

```bash
git clone https://github.com/WE-Ticket/WE-Ticket_FE.git
cd WE-Ticket_FE
```

#### Step 2: Install Dependencies (의존성 설치)

```bash
# Flutter 패키지 다운로드
flutter pub get

# iOS 의존성 설치 (macOS만 해당)
cd ios
pod install
cd ..
```

#### Step 3: Configure Environment (환경 설정)

##### API Endpoint 확인

`lib/core/config/app_config.dart` 파일에서 백엔드 API URL을 확인한다:

```dart
static const String baseUrl = 'http://43.201.185.8:8000/api';
```

필요 시 로컬 개발 서버 주소로 변경:

```dart
static const String baseUrl = 'http://localhost:8000/api';
// 또는 Android Emulator에서
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

##### Generate App Icon & Splash Screen (앱 아이콘 및 스플래시 생성)

```bash
# 앱 아이콘 생성
flutter pub run flutter_launcher_icons

# 스플래시 스크린 생성
flutter pub run flutter_native_splash:create
```

#### Step 4: Prepare Device/Emulator (디바이스/에뮬레이터 준비)

##### Android Emulator

```bash
# 사용 가능한 에뮬레이터 확인
flutter emulators

# 에뮬레이터 실행
flutter emulators --launch <emulator_id>
```

##### iOS Simulator (macOS만 해당)

```bash
# 시뮬레이터 실행
open -a Simulator
```

##### Physical Device (실제 디바이스)

- **Android**: USB 디버깅 활성화
- **iOS**: Apple Developer 계정 필요 (실기기 테스트 시)

연결된 디바이스 확인:

```bash
flutter devices
```

#### Step 5: Run Application (앱 실행)

```bash
# 디버그 모드로 실행
flutter run

# 특정 디바이스에서 실행
flutter run -d <device_id>

# Hot Reload: 앱 실행 중 'r' 키 입력
# Hot Restart: 앱 실행 중 'R' 키 입력
```

---

## 🐳 How to Build

### Android Build

#### 1. Debug APK

```bash
flutter build apk --debug
```

**생성 위치**: `build/app/outputs/flutter-apk/app-debug.apk`

#### 2. Release APK

```bash
flutter build apk --release
```

**생성 위치**: `build/app/outputs/flutter-apk/app-release.apk`

#### 3. App Bundle (Google Play Store)

```bash
flutter build appbundle --release
```

**생성 위치**: `build/app/outputs/bundle/release/app-release.aab`

#### 4. Install APK to Device

```bash
# 연결된 디바이스에 설치
flutter install

# 또는 adb 직접 사용
adb install build/app/outputs/flutter-apk/app-release.apk
```

### iOS Build (macOS only)

#### 1. Simulator Build

```bash
flutter build ios --debug --simulator
```

#### 2. Release Build for Device

```bash
flutter build ios --release
```

---

## 🧪 How to Test

WE-Ticket 앱은 실제 디바이스 또는 에뮬레이터에서 수동 테스트를 수행할 수 있다. 아래는 주요 기능별 테스트 시나리오이다.

### Test Environment Setup

#### 1. Start Emulator/Simulator

```bash
# Android Emulator
flutter emulators --launch <emulator_id>

# iOS Simulator (macOS only)
open -a Simulator
```

#### 2. Run Application

```bash
# Debug mode
flutter run

# Release mode (for performance testing)
flutter run --release
```

### Feature Testing Guide

#### 1. Login Testing

```
1. 앱 실행 → 마이페이지 접근
2. "회원가입" 버튼 클릭
3. 필수 정보 입력 (아이디, 비밀번호, 이름, 전화번호 등)
4. 회원가입 완료 확인
5. 로그인 정보 입력 후 로그인
6. 로그인 성공 시 마이페이지 접근
```

**예상 결과:**

- 유효성 검증 메시지 표시 (입력 형식, 비밀번호 규칙 등)
- 중복 아이디 에러 처리
- 로그인 성공 시 JWT 토큰 저장 및 마이페이지 접근

#### 2. Performance Browsing Testing

```
1. 공연 목록 화면으로 이동
2. 상단 탭에서 카테고리 선택 가능 (전체/콘서트 등)
3. 공연 카드 클릭하여 상세 화면 진입
4. 공연 정보 확인 (일시, 장소, 가격, 설명)
5. 뒤로 가기 버튼으로 목록 복귀 가능
```

**예상 결과:**

- 공연 목록 스크롤 시 부드러운 동작
- 이미지 로딩 및 캐싱 정상 작동
- 상세 정보 정확한 표시

#### 3. Ticketing Testing

```
1. 공연 상세 화면에서 "예매하기" 버튼 클릭
2. 공연 회차 선택
3. 구역 배치도에서 구역 선택
4. 좌석 배치도에서 좌석 선택
5. 결제 수단 선택
7. 결제 진행
8. 결제 완료 후 티켓 발행 완료 확인
```

**예상 결과:**

- 이미 예매된 좌석 선택 불가 처리
- 좌석 선택 시 실시간 업데이트
- 결제 성공 시 NFT 티켓 발행 완료 표시
- 결제 실패 시 에러 메시지 표시 및 이전 화면 복귀

#### 4. NFC Entry Testing

```
1. 마이페이지 → 내 티켓 선택
2. 티켓 상세 화면에서 "입장하기" 버튼 클릭
3. NFC 스캔하기 버튼 클릭 후 NFC 스캔
4. 생체 인증 진행 (지문/Face ID)
5. 검증 결과 확인
6. 입장 완료 메시지 확인
```

**예상 결과:**

- NFC 태그 인식 성공
- 현재 입장 가능한 유효한 티켓인 경우 입장 승인
- 중복 입장 시도 시 차단
- 입장 시간 기록

#### 5. Ticket Transfer Testing

```
1. 메인 화면 -> 양도 마켓 이동
2. 내 양도 가능한 티켓 확인
3. 양도 등록하기 (공개 / 비공개 선택)
4. 양도 등록 완료된 티켓 확인
5. 비공개 양도일 경우 고유 코드 확인 가능
6. 양도 거래가 성사될 경우 티켓의 소유권 이전
```

**예상 결과:**

- 양도 가능한 티켓만 양도 버튼 활성화
- 양도 완료 시 티켓 소유권 이전

#### 6. MyPage Testing

```
1. 메인 호면 -> 마이페이지 선택
2. "본인 인증 관리" 탭에서 현재 본인 인증 레벨 확인 및 인증
3. "내 티켓 관리" 탭에서 예매 및 양도 받은 티켓 확인 가능
4. "구매 이력" 탭에서 티켓 구매, 양도/양수 이력 확인 가능
5. "설정 및 계정 관리" 탭에서 계정 정보 및 계정 설정 (비밀번호 변경), 약관 및 정책 확인 가능
6. "1:1문의" 탭에서 고객센터로 문의 가능
```

---

## 🛠 기술 스택

### Framework & Language

- **Flutter** 3.8.1 - 크로스 플랫폼 모바일 앱 프레임워크
- **Dart** 3.8.1 - 프로그래밍 언어

### 상태 관리

- **Provider** 6.0.5 - 경량 상태 관리 솔루션
- **ChangeNotifier** - Flutter 기본 상태 관리 패턴

### 아키텍처 & 디자인 패턴

- **Clean Architecture** - 계층 분리 및 의존성 역전
- **Repository Pattern** - 데이터 소스 추상화
- **Dependency Injection** - GetIt 7.6.4 활용
- **MVVM Pattern** - View와 비즈니스 로직 분리

### 네트워크 & 통신

- **Dio** 5.3.2 - HTTP 클라이언트
- **HTTP** 1.1.0 - 기본 HTTP 통신
- **WebView Flutter** 4.2.4 - 인앱 웹뷰 (결제, 인증)

### 인증 & 보안

- **JWT (JSON Web Token)** - 인증 토큰 관리
- **Local Auth** 2.1.6 - 생체 인증 (지문/Face ID)
- **Shared Preferences** 2.2.2 - 로컬 데이터 암호화 저장

### 하드웨어 통합

- **Flutter NFC Kit** 3.3.1 - NFC 태그 읽기/쓰기
- **URL Launcher** 6.2.1 - 외부 브라우저 및 앱 실행

### UI/UX

- **Flutter SVG** 2.0.9 - SVG 이미지 렌더링
- **Flutter Launcher Icons** 0.13.1 - 앱 아이콘 생성
- **Flutter Native Splash** 2.4.0 - 스플래시 스크린

### 함수형 프로그래밍

- **Dartz** 0.10.1 - Either, Option 등 함수형 데이터 타입
- **Equatable** 2.0.5 - 값 객체 동등성 비교

### 현지화

- **Intl** 0.20.2 - 날짜/시간 포맷팅
- **Flutter Localizations** - 다국어 지원 (한국어/영어)

---

## 📁 소스코드 구조

```
lib/
├── main.dart                          # 앱 진입점 및 Provider 설정
│
├── core/                              # 공통 핵심 기능
│   ├── config/                        # 앱 설정 상수
│   ├── constants/
│   │   ├── api_constants.dart         # API 엔드포인트 상수
│   │   ├── app_colors.dart            # 앱 컬러 팔레트
│   │   └── text_styles.dart           # 텍스트 스타일 정의
│   ├── network/
│   ├── errors/
│   ├── utils/
│   ├── extensions/
│   ├── services/
│   ├── mixins/
│   └── widgets/                       # 공통 재사용 위젯
│
├── features/                          # 기능별 모듈 (Feature-First)
│   ├── auth/                          # 인증 시스템
│   ├── contents/                      # 공연 및 콘텐츠
│   ├── ticketing/                     # 티켓팅 시스템
│   ├── entry/                         # 입장 시스템
│   ├── transfer/                      # 티켓 양도 시스템
│   └── mypage/                        # 마이페이지
├── shared/                            # 여러 Feature가 공유하는 로직
├── injection/                         # 의존성 주입
└── routes/

android/                               # Android 네이티브 코드
ios/                                   # iOS 네이티브 코드
```

---

## 📦 주요 라이브러리

### 상태 관리

| 라이브러리                                    | 버전  | 용도                     |
| --------------------------------------------- | ----- | ------------------------ |
| [provider](https://pub.dev/packages/provider) | 6.0.5 | 상태 관리 및 의존성 주입 |

### 네트워크

| 라이브러리                            | 버전  | 용도                         |
| ------------------------------------- | ----- | ---------------------------- |
| [dio](https://pub.dev/packages/dio)   | 5.3.2 | HTTP 클라이언트, Interceptor |
| [http](https://pub.dev/packages/http) | 1.1.0 | 기본 HTTP 요청               |

### 아키텍처

| 라이브러리                                      | 버전   | 용도                               |
| ----------------------------------------------- | ------ | ---------------------------------- |
| [get_it](https://pub.dev/packages/get_it)       | 7.6.4  | 서비스 로케이터 (DI)               |
| [dartz](https://pub.dev/packages/dartz)         | 0.10.1 | 함수형 프로그래밍 (Either, Option) |
| [equatable](https://pub.dev/packages/equatable) | 2.0.5  | 값 객체 동등성 비교                |

### UI/UX

| 라이브러리                                                                | 버전   | 용도                |
| ------------------------------------------------------------------------- | ------ | ------------------- |
| [flutter_svg](https://pub.dev/packages/flutter_svg)                       | 2.0.9  | SVG 이미지 렌더링   |
| [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) | 0.13.1 | 앱 아이콘 자동 생성 |
| [flutter_native_splash](https://pub.dev/packages/flutter_native_splash)   | 2.4.0  | 스플래시 스크린     |

### 하드웨어 & 플랫폼

| 라이브러리                                                  | 버전  | 용도                      |
| ----------------------------------------------------------- | ----- | ------------------------- |
| [flutter_nfc_kit](https://pub.dev/packages/flutter_nfc_kit) | 3.3.1 | NFC 태그 읽기/쓰기        |
| [local_auth](https://pub.dev/packages/local_auth)           | 2.1.6 | 생체 인증 (지문, Face ID) |
| [webview_flutter](https://pub.dev/packages/webview_flutter) | 4.2.4 | 웹뷰 (결제, 인증)         |
| [url_launcher](https://pub.dev/packages/url_launcher)       | 6.2.1 | 외부 URL 실행             |

### 로컬 저장소

| 라이브러리                                                        | 버전  | 용도                      |
| ----------------------------------------------------------------- | ----- | ------------------------- |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | 2.2.2 | 키-값 저장소 (토큰, 설정) |

### 유틸리티

| 라이브러리                            | 버전   | 용도                     |
| ------------------------------------- | ------ | ------------------------ |
| [intl](https://pub.dev/packages/intl) | 0.20.2 | 날짜/시간 포맷팅, 다국어 |

---

## 추가 자료

- [Flutter 공식 문서](https://docs.flutter.dev/)
- [Dart 공식 문서](https://dart.dev/guides)

---

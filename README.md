# Imn — Privacy-First P2P Chat App

A fully encrypted peer-to-peer messenger for Android and iOS.  
No servers store your messages. Ever.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Imn App                             │
│                                                             │
│  Flutter (Android + iOS)                                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Crypto  │  │WebRTC P2P│  │Local DB  │  │   UI     │   │
│  │X25519    │  │DataChannel│  │  Drift   │  │Riverpod  │   │
│  │Ed25519   │  │STUN/TURN │  │ SQLite   │  │Material3 │   │
│  │ChaCha20  │  │Ice Restart│  │Encrypted │  │          │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                          │  (handshake only)
                    ┌─────▼──────┐
                    │ Signaling  │
                    │   Server   │
                    │ Node.js WS │
                    └─────┬──────┘
                          │
                    ┌─────▼──────┐
                    │    TURN    │
                    │  (coturn)  │
                    └────────────┘
```

## Project Structure

```
imn/
├── lib/
│   ├── core/
│   │   ├── crypto/          # X25519, Ed25519, ChaCha20-Poly1305
│   │   ├── storage/         # Secure Storage helpers
│   │   ├── network/         # Connectivity monitor
│   │   ├── utils/           # Theme, Logger
│   │   └── providers.dart   # Riverpod DI
│   │
│   ├── features/
│   │   ├── identity/        # Key generation, Device ID, Onboarding
│   │   ├── pairing/         # QR generation, scanning, handshake
│   │   ├── chat/            # Messages, typing indicators
│   │   ├── chats/           # Conversation list
│   │   ├── contacts/        # Contact management
│   │   ├── files/           # File transfer with chunking
│   │   └── settings/        # Settings, key viewer
│   │
│   ├── services/
│   │   ├── webrtc/          # WebRTCService, ConnectionManager
│   │   ├── signaling/       # WebSocket signaling client
│   │   ├── encryption/      # EncryptionService, EncryptionSession
│   │   ├── database/        # Drift DB (app_database.dart)
│   │   └── network_monitor/ # NetworkMonitorService
│   │
│   ├── shell/               # AppShell (bottom nav)
│   ├── app.dart             # AppRoot with routing
│   └── main.dart
│
├── backend/
│   ├── signaling-server/    # Node.js WebSocket server
│   │   ├── src/server.js
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── coturn/
│   │   └── turnserver.conf  # TURN server config
│   └── docker-compose.yml
│
└── test/
    ├── unit/
    │   ├── crypto_service_test.dart
    │   └── pairing_test.dart
    └── widget_test.dart
```

## Security

| Layer | Algorithm |
|---|---|
| Identity | Ed25519 (permanent key pair) |
| Key Exchange | X25519 ECDH (ephemeral per session) |
| Message Encryption | ChaCha20-Poly1305 |
| Key Derivation | HKDF-SHA256 |
| Storage | Keychain (iOS) / EncryptedSharedPrefs (Android) |

## Getting Started

### 1. Flutter App

```bash
cd imn
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 2. Signaling Server (local)

```bash
cd backend/signaling-server
npm install
npm start
# Runs on ws://localhost:8080
```

### 3. Signaling Server (Docker)

```bash
cd backend
docker-compose up -d
```

### 4. Configure Server URL

In `lib/core/providers.dart`, set:
```dart
const _signalingUrl = 'ws://YOUR_SERVER_IP:8080';
```

In `lib/features/pairing/my_qr_screen.dart`, update:
```dart
signalingUrl: 'ws://YOUR_SERVER_IP:8080',
```

## Running Tests

```bash
# Unit tests (no device needed)
flutter test test/unit/crypto_service_test.dart
flutter test test/unit/pairing_test.dart

# All tests
flutter test
```

## Implementation Phases

| Phase | Status | Description |
|---|---|---|
| 1 | ✅ | Flutter UI + Device Identity + Secure Storage |
| 2 | ✅ | QR Pairing Protocol |
| 3 | ✅ | Signaling Server (Node.js) |
| 4 | ✅ | WebRTC PeerConnection + STUN/TURN |
| 5 | ✅ | E2E Encryption Layer |
| 6 | ✅ | Text Messaging + ACK + Typing |
| 7 | ✅ | Local DB + Offline Queue |
| 8 | ✅ | Network Change Detection + Reconnection |
| 9 | ✅ | File Transfer with Chunking |
| 10 | 🔄 | Security Hardening + Production Build |

## Privacy Guarantees

- ✅ Messages never leave your device unencrypted
- ✅ Signaling server sees only encrypted SDP (no message content)  
- ✅ QR codes expire in 5 minutes
- ✅ Each session uses a unique ephemeral X25519 key pair
- ✅ ChaCha20-Poly1305 with unique nonce per message
- ✅ Ed25519 signatures verify identity during pairing
- ✅ Keys stored in OS Keychain/Keystore

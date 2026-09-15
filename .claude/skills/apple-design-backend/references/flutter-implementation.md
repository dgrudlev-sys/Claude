# Flutter Implementation — Consuming Apple Platform Services
Scope: this skill's core content (`web-delivery-infra.md`, `inferred-backend-architecture.md`) documents how **Apple itself** delivers and operates apple.com/iCloud/APNs/CloudKit — infrastructure a third-party developer does not control or replicate. A Flutter app author's actual job is narrower and different: **consume** the public-facing pieces of that stack (push notifications, Sign in with Apple, adaptive video, image delivery, cross-device sync) from a cross-platform app. This file reframes each documented service in those terms. Confidence labels follow the family convention: `[documented]` verifiable API/package behavior, `[inferred]` reasonable but unconfirmed, `[speculative]` untested idea — and package names/versions should always be checked against pub.dev before depending on them, since none are pinned here.

---

## Framing

Everything in `inferred-backend-architecture.md`'s "Documented & Observed Services" section (CloudKit, APNs, Sign in with Apple, StoreKit, PCC) is a real, integratable Apple developer service — that part is not reverse-engineered, it's public API. What changes for a Flutter app is the **path** to each service: Flutter has no native Swift/Obj-C runtime of its own, so every one of these integrations goes through either (a) a Dart plugin that wraps the native SDK via platform channels, or (b) a cross-platform intermediary service (most commonly Firebase) that itself talks to Apple's service on your behalf. Where the source doc gives you a raw HTTP/JWT recipe for a backend you own, this file gives you the client-side Flutter package that fronts it — the backend-side JWT/JWS verification code in `inferred-backend-architecture.md`'s Recipes section is unchanged and still what your server should run.

| Apple service (source doc) | Flutter-side path |
|---|---|
| APNs | `firebase_messaging` (FCM relays to APNs on iOS) or a direct APNs-only plugin |
| Sign in with Apple | `sign_in_with_apple` package |
| HLS adaptive video | `video_player` (+ `chewie` for player chrome) |
| mzstatic-style image delivery | `cached_network_image` + your own responsive-URL logic |
| CloudKit / iCloud sync | No first-party plugin — Firebase/Supabase, or an iOS-only native bridge |

---

## 1. Push notifications — APNs via a wrapper, not directly

**A Flutter app does not talk to APNs directly.** [documented — Flutter has no built-in APNs client, and Apple's HTTP/2+JWT provider API described in `inferred-backend-architecture.md` is meant for a server, not a mobile client] The standard architecture is: your Dart code registers with a cross-platform push SDK, that SDK's iOS implementation registers the device with APNs under the hood, and your backend sends through that SDK's server API (which forwards to APNs on iOS and to its own channel on Android) rather than hand-rolling the HTTP/2 JWT calls from the earlier reference file. `[documented — general architecture]`. **Which exact package to use is an `[inferred]` choice** — verify current maintenance and feature parity on pub.dev before committing:

- **`firebase_messaging`** — the default choice for most apps. Wraps FCM, which relays to APNs on iOS and to Google's own channel on Android, giving you one client API and one server API for both platforms.
- **A direct-APNs plugin** (e.g. a package positioned as "no Firebase required") — relevant if you specifically want to avoid a Firebase dependency and are willing to run separate send paths for iOS (APNs) vs Android (FCM/another service). `[inferred — verify current pub.dev options; this space has historically had less-maintained packages than firebase_messaging]`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> setupPushNotifications() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus != AuthorizationStatus.authorized) {
    return; // user declined — don't register a token
  }

  // On iOS, FCM needs the APNs token to exist before it can hand back an FCM
  // token; some firebase_messaging versions require an explicit wait here.
  // Verify the exact sequencing against your installed package version. [inferred]
  final apnsToken = await messaging.getAPNSToken();
  if (apnsToken == null) return; // APNs registration not ready yet — retry later

  final fcmToken = await messaging.getToken();
  await sendTokenToBackend(fcmToken); // your server sends via FCM's API, not raw APNs HTTP/2

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Foreground notification — FCM does not auto-display a system banner
    // while the app is foregrounded; show your own UI (e.g. a SnackBar or
    // local notification) if you want one.
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // User tapped a notification that opened/resumed the app from background.
  });
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Must be a top-level or static function, registered before runApp().
}
```

Your backend's send path is still the JWS/HTTP verification logic from `inferred-backend-architecture.md`'s APNs recipe **if you go the direct-APNs route**; if you go through Firebase, replace that recipe with a call to the Firebase Admin SDK's `send()` API instead — the payload shape (`alert`, `badge`, `sound`, `content-available`) is preserved conceptually but wrapped in FCM's own message format. `[documented general mapping]`

---

## 2. Sign in with Apple — the `sign_in_with_apple` package

```dart
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

Future<void> signInWithApple() async {
  final credential = await SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
  );

  // credential.identityToken and credential.authorizationCode are what your
  // backend needs — send both up rather than trusting anything client-side.
  await myBackend.exchangeAppleCredential(
    identityToken: credential.identityToken,
    authorizationCode: credential.authorizationCode,
    email: credential.email,       // present only on the user's FIRST authorization
    givenName: credential.givenName,
    familyName: credential.familyName,
  );
}
```

The typical end-to-end flow: [documented — this is the package's documented usage shape; verify exact method/field names against the current pub.dev version]

1. Call `SignInWithApple.getAppleIDCredential(...)`. On iOS/macOS this presents the native Apple ID sheet; on Android and web, the package drives an OAuth web-redirect flow instead, since there is no native Apple ID account on those platforms — this requires configuring a **Services ID** and redirect URL in your Apple Developer account, not just adding the package. `[documented general requirement — exact setup steps live in the package's README]`
2. Send `identityToken` (a JWT) and `authorizationCode` to your backend — **never trust `credential.email`/`credential.givenName` as authoritative on their own**, per the source doc's "client-trusted claims" anti-pattern.
3. Your backend validates `identityToken` against Apple's JWKS exactly as shown in `inferred-backend-architecture.md`'s "Sign in with Apple — Server-Side Token Validation" recipe — that Node.js code is unchanged by the fact that the client is Flutter rather than a native app; the wire format Apple returns is identical.
4. Store `payload.sub` (the stable, app-scoped user id) as your user's identifier, matching the source doc's guidance.

`email` is only ever present on the first authorization — persist it server-side on first sign-in, since Apple will not send it again on subsequent sign-ins from the same device or a reinstall. `[documented]`

---

## 3. Adaptive video — HLS via `video_player` (+ `chewie`)

Apple authored HLS and the source doc documents its multi-bitrate `.m3u8` structure; on the Flutter side, `video_player` is the package that actually decodes and plays it, since Flutter has no built-in media pipeline of its own.

```dart
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class HlsPlayerScreen extends StatefulWidget {
  const HlsPlayerScreen({required this.hlsUrl, super.key});
  final String hlsUrl;

  @override
  State<HlsPlayerScreen> createState() => _HlsPlayerScreenState();
}

class _HlsPlayerScreenState extends State<HlsPlayerScreen> {
  late final VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.hlsUrl));
    _videoController.initialize().then((_) {
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoController.value.aspectRatio,
        );
      });
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController == null
        ? const Center(child: CircularProgressIndicator())
        : Chewie(controller: _chewieController!);
  }
}
```

- `video_player` plays `.m3u8` (HLS) URLs directly on both iOS (via `AVPlayer` under the hood) and Android (via ExoPlayer under the hood), including adaptive bitrate switching between the renditions the source doc's master-playlist recipe describes. `[documented general capability — verify current HLS feature parity (e.g. captions, fairplay DRM support) against the installed `video_player` version and its iOS/Android platform implementations on pub.dev, since ABR behavior details can differ by platform under the hood]`
- `chewie` adds a Material/Cupertino-styled player UI (play/pause, scrubber, fullscreen) on top of `video_player`'s bare `VideoPlayerController` — it is a UI layer only, not a separate video engine. `[documented]`
- The `FairPlay`/DRM story for HLS content is a separate, platform-specific concern not covered by the base `video_player` package — if your content requires DRM, verify a specific plugin or native integration supports it before assuming `video_player` alone handles it. `[speculative — flagging a likely gap, not asserting one]`

---

## 4. Image delivery — `cached_network_image` for the mzstatic caching pattern

`web-delivery-infra.md`'s core image-delivery pattern is: content-hashed/immutable URLs + edge caching + a transform-on-demand size parameter. The Flutter equivalent splits into "caching" (a package's job) and "responsive sizing" (your own logic, since Flutter has no `srcset`/`<picture>` primitive).

```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: buildResponsiveImageUrl(context, baseUrl: 'https://cdn.example.com/hero.jpg'),
  placeholder: (context, url) => const _ImageSkeleton(),
  errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined),
  fadeInDuration: const Duration(milliseconds: 200),
)
```

- `cached_network_image` persists decoded images to disk and memory so a given URL is fetched once, mirroring the source doc's "immutable URL + long cache" principle — but the immutability guarantee itself is still on you: **use a content-hashed or version-stamped URL** (`hero__a3f9c2d.jpg`, not a bare `hero.jpg` you silently overwrite server-side), exactly as the source doc's anti-pattern #3 ("mutable URLs with long Cache-Control") warns against, so the package's cache never serves a stale image under an old URL. `[inferred — the package caches by URL; the immutability contract is your CDN's responsibility, not the package's]`
- Standard HTTP caching headers (`Cache-Control`, `ETag`) from your CDN/origin are respected by the underlying HTTP client `cached_network_image` uses — verify current behavior against the installed package version if you need precise revalidation semantics (e.g. honoring `stale-while-revalidate`). `[inferred]`

**Responsive sizing without `srcset`** — Flutter has no native equivalent of `<picture>`/`srcset`'s "let the browser choose"; you compute the target width yourself and bake it into the URL, assuming a backend/CDN that accepts a width query parameter the way mzstatic's `{W}x{H}` path segment does:

```dart
String buildResponsiveImageUrl(BuildContext context, {required String baseUrl}) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final logicalWidth = MediaQuery.sizeOf(context).width;
  final targetPx = (logicalWidth * dpr).round();

  // Snap up to the nearest bucket your CDN/image service actually generates —
  // mirrors mzstatic's fixed-dimension transform pattern rather than
  // requesting an arbitrary exact width per device. [inferred]
  const buckets = [400, 800, 1200, 1920, 2560];
  final width = buckets.firstWhere((w) => w >= targetPx, orElse: () => buckets.last);

  return '$baseUrl?w=$width'; // requires your own image-transform backend or a
                              // service like Cloudinary/imgix/Cloudflare Images
                              // to actually honor the ?w= parameter
}
```

If you don't operate your own image-transform CDN, a managed image CDN (Cloudinary, imgix, Cloudflare Images) gives you the mzstatic-style "one master, many derivatives via URL parameter" behavior out of the box — this is the same "Faithful Replication" substitution table `web-delivery-infra.md` already recommends for a website, and it applies unchanged to an app's image backend. `[inferred]`

---

## 5. iCloud / CloudKit sync — the gap, and what to use instead

**There is no first-party (or well-established third-party) Flutter plugin exposing CloudKit as of this writing.** [documented — absence; verify current pub.dev state before assuming otherwise, since this is exactly the kind of gap a new package could close] CloudKit is a Swift/Objective-C framework tied to an iCloud account; it has no meaning on Android or the web, which is the fundamental mismatch for a cross-platform framework like Flutter.

Two paths, neither of which is "just add a package":

### 5.1 The pragmatic default: Firebase or Supabase

For a genuinely cross-platform Flutter app, sync almost always goes through a backend-as-a-service that works identically on iOS, Android, and web — Firebase (Firestore/Realtime Database) or Supabase (Postgres + realtime) being the two most common choices. `[inferred — this is a strong ecosystem convention, not a documented Apple recommendation, since Apple has no reason to endorse a non-CloudKit sync layer]` This trades away some of the privacy-by-architecture invariants `inferred-backend-architecture.md` documents for CloudKit/Advanced Data Protection — notably, "the server never holds plaintext" is not true by default on Firebase/Supabase the way it can be architected to be with client-held CloudKit keys. If that invariant matters to your app, encrypt sensitive fields client-side before writing them (e.g. via the `cryptography` package) regardless of which backend you choose, so the backend only ever stores ciphertext — approximating CloudKit's Advanced Data Protection tier on top of a non-Apple backend. `[inferred]`

### 5.2 An iOS-only native bridge (only if you specifically need real CloudKit)

If you need actual CloudKit — for example, syncing into a user's existing iCloud data that a companion native iOS/macOS app also reads — the only path is a `MethodChannel` to hand-written Swift code in `ios/Runner`, since no Dart API can reach CloudKit directly. This is **iOS/macOS-only by construction**: Android and web builds of the same app need an entirely separate sync path, which usually means running two sync backends side by side rather than one. `[speculative — this is an architecture sketch, not a verified example; nobody in this skill family has shipped or tested it]`

```dart
// Dart side — a thin call into native Swift code you write yourself.
// This is NOT a package; there is no Dart CloudKit API to call.
const _cloudKitChannel = MethodChannel('com.example.app/cloudkit');

Future<void> saveNoteToCloudKit({required String id, required String text}) async {
  await _cloudKitChannel.invokeMethod('saveRecord', {
    'recordType': 'Note',
    'recordId': id,
    'fields': {'text': text},
  });
}
```

```swift
// ios/Runner/CloudKitChannel.swift — sketch only, not a complete implementation.
// You would implement this against CloudKit's CKRecord/CKContainer APIs as
// documented in inferred-backend-architecture.md's CloudKit section.
import CloudKit
import Flutter

class CloudKitChannel {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.example.app/cloudkit",
                                        binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      // Dispatch on call.method ("saveRecord", etc.), build a CKRecord,
      // save to CKContainer.default().privateCloudDatabase, call result(...).
    }
  }
}
```

Before committing to this path, weigh it against just running Firebase/Supabase on all platforms including iOS — the maintenance cost of a second, iOS-only sync backend is substantial, and is only justified if real interop with a native Apple-ecosystem app or iCloud data is a hard requirement. `[inferred recommendation]`

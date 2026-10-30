# Analog Gate

แอป Android ที่ช่วยลดเวลาเล่นโซเชียลมีเดีย เมื่อผู้ใช้เปิดแอปที่ถูกบล็อกจนเกินเวลาที่กำหนด แอปจะแสดงหน้าจอทับ (overlay) และให้ทำภารกิจในโลกจริงก่อน เช่น ออกไปเดินหรือถ่ายรูปท้องฟ้า แล้วถ่ายรูปเป็นหลักฐาน AI ฝั่งเซิร์ฟเวอร์จะตรวจรูป ถ้าผ่านจึงให้ XP เพิ่ม streak และปลดล็อกแอปสำหรับวันนั้น

ข้อมูลในเอกสารนี้ตรงกับโค้ดที่ commit `f474f7f` (31 ต.ค. 2026)

---

## 1. ภาพรวมสถาปัตยกรรม

```
มือถือ Android (Flutter app)
 ├─ Background service ─ เช็กแอปที่ใช้อยู่ทุก 5 วินาที (UsageStats)
 ├─ Overlay window ──── บล็อกแอปเมื่อเกินเวลา
 └─ Supabase client ─── Auth / อ่าน profiles, missions / เรียก RPC unlock_app
          │
          ▼
Supabase Cloud (project ref: jvdyfsfvwwzhaiwmwwql)
 ├─ Auth (email + password)
 ├─ Postgres: profiles, missions (+ RLS)
 ├─ Storage: bucket "avatars" (public)
 ├─ RPC: complete_mission (เฉพาะ service_role), unlock_app (authenticated)
 └─ Edge Function: verify-photo (Deno/TypeScript)
          │
          ▼
OpenRouter API → โมเดล vision (ค่าเริ่มต้น google/gemini-2.5-flash)
```

หลักการด้านความปลอดภัย: แอปไม่มี API key ของ AI และเขียน XP/streak เองไม่ได้ การบันทึกภารกิจทำผ่าน Edge Function ที่ตรวจรูปผ่านแล้วเท่านั้น

ไม่มี backend อื่น โฟลเดอร์ `C:\Users\comsc\analog_gate_backend` (FastAPI) ไม่ได้เชื่อมกับแอป

---

## 2. ภาษาและเฟรมเวิร์ก

| ส่วน | ภาษา / เทคโนโลยี |
|------|-------------------|
| แอปมือถือ | Dart (SDK ^3.11.5), Flutter 3.47.9 stable |
| Edge Function | TypeScript บน Deno (Supabase Edge Runtime) |
| ฐานข้อมูล | PostgreSQL (SQL, PL/pgSQL) บน Supabase |
| Android build | Kotlin DSL (Gradle `.kts`), Java 17 |
| UI | Material Design, ธีมมืดกำหนดเองใน `lib/theme/app_theme.dart` |
| State management | Riverpod 3 (เฉพาะ auth/profile) + singleton services + SharedPreferences |

---

## 3. Dependencies (pubspec.yaml)

### ใช้งานจริง

| แพ็กเกจ | ใช้ทำอะไร | ใช้ที่ไหน |
|---------|-----------|-----------|
| supabase_flutter ^2.12.4 | Auth, query ตาราง, เรียก RPC และ Edge Function | services/*, main.dart |
| flutter_riverpod ^3.4.3 | สถานะล็อกอินและโปรไฟล์ | providers/, login/register/settings/gate |
| shared_preferences ^2.2.3 | cache XP, streak, แอปที่บล็อก, ภารกิจปัจจุบัน, testing mode | หลายไฟล์ |
| usage_stats ^2.0.1, app_usage ^4.1.0 | อ่านว่าแอปไหนกำลังใช้และใช้ไปนานเท่าไร | app_monitor_service, permission_screen |
| flutter_background_service ^5.1.0 | รันตัวตรวจแอปเบื้องหลังเป็น foreground service | app_monitor_service |
| flutter_overlay_window ^1.0.2 | หน้าจอทับแอปอื่น (entry point `overlayMain`) | overlay_screen, home_screen |
| flutter_local_notifications ^22.3.3 | แจ้งเตือนเวลาที่เหลือและสถานะ | notification_service |
| permission_handler ^13.0.2 | ขอสิทธิ์กล้อง แจ้งเตือน ฯลฯ | permission_screen, main.dart |
| android_intent_plus ^6.0.0 | เปิดหน้าตั้งค่า Android (Usage access, overlay) และกลับไปหน้า Home | overlay_screen, permission_screen |
| image_picker ^1.1.4 | ถ่ายรูป/เลือกรูปสำหรับภารกิจและรูปโปรไฟล์ | gate_screen, settings_screen |
| camera ^0.12.2 | กล้องแบบกำหนดเอง | camera_screen (ยังไม่มีหน้าไหนเปิดไปหน้านี้) |
| path_provider ^2.1.5 | ไฟล์ชั่วคราวตอนอัปโหลดรูปโปรไฟล์ | profile_service |
| flutter_animate ^4.5.0 | แอนิเมชัน UI | หลายหน้าจอ |

`dependency_overrides`: `image_picker_android: 0.8.13+4`

### ประกาศไว้แต่ไม่ได้ import ในโค้ด (ลบได้)

- `google_generative_ai` (เดิมใช้ Gemini ในแอป ตอนนี้ย้ายไป Edge Function แล้ว)
- `http`
- `url_launcher`
- `riverpod` (ใช้ผ่าน flutter_riverpod อยู่แล้ว)
- `google_mlkit_image_labeling`: import เฉพาะใน `photo_verification_service.dart` ซึ่งตอนนี้เหลือไว้ใช้แค่คลาส `VerificationResult` ไม่มีที่ไหนเรียกการ label รูปด้วย ML Kit แล้ว

### Dev

- flutter_lints ^6.0.0, flutter_test
- ยังไม่มีโฟลเดอร์ `test/`

---

## 4. โครงสร้างโค้ด (`lib/`, ประมาณ 5,700 บรรทัด)

```
lib/
├─ main.dart                  เริ่ม Supabase, notifications, background service; overlayMain(); root shell + bottom nav
├─ models/
│   ├─ models.dart            Mission, MissionDifficulty ฯลฯ
│   └─ user_profile.dart      map แถว profiles
├─ providers/
│   ├─ auth_provider.dart     สถานะล็อกอิน (Riverpod)
│   └─ profile_provider.dart
├─ screens/
│   ├─ login_screen / register_screen
│   ├─ permission_screen      onboarding ขอสิทธิ์ทั้งหมด
│   ├─ home_screen            ภารกิจวันนี้, streak, ปุ่มไปหน้าบล็อกแอปและตั้งค่า
│   ├─ gate_screen            ถ่ายรูปภารกิจ → ส่งตรวจ → แสดงผล
│   ├─ overlay_screen         หน้าจอทับแอปที่ถูกบล็อก
│   ├─ blocked_apps_screen    เลือกแอปที่จะบล็อก
│   ├─ progress_screen        XP, streak, ประวัติสัปดาห์
│   ├─ settings_screen        โปรไฟล์/รูป avatar, testing mode, ออกจากระบบ
│   └─ camera_screen          (ไม่ได้ใช้)
├─ services/
│   ├─ app_monitor_service    ลูปเบื้องหลังทุก 5 วินาที นับเวลาแอปที่บล็อก แล้วเปิด overlay
│   ├─ progress_service       cache + sync XP/streak จาก profiles, unlock_app RPC, หมุนภารกิจ
│   ├─ mission_data           โหลด missions จาก Supabase (มีรายการ fallback ในโค้ด)
│   ├─ photo_verifier_service เรียก Edge Function verify-photo
│   ├─ photo_verification_service  เหลือแค่คลาส VerificationResult (โค้ด ML Kit เก่า)
│   ├─ profile_service        อ่าน/แก้ username, อัปโหลด avatar
│   ├─ auth_service           signUp / signIn / signOut
│   └─ notification_service
├─ theme/app_theme.dart
└─ widgets/                   mission_card, streak_bar, locked_app_chip
```

---

## 5. การทำงานหลัก

1. สมัครหรือล็อกอินด้วยอีเมลและรหัสผ่าน (Supabase Auth) เมื่อสร้างผู้ใช้ใหม่ trigger `handle_new_user` จะสร้างแถวใน `profiles` ให้อัตโนมัติ
2. หน้า Permission ขอสิทธิ์ Usage access, Display over other apps, กล้อง, แจ้งเตือน และ battery optimization
3. ผู้ใช้เลือกแอปที่จะบล็อก รายการนี้เก็บใน SharedPreferences บนเครื่อง
4. Background service เช็กทุก 5 วินาทีว่าเปิดแอปที่บล็อกอยู่หรือไม่ ถ้าใช่จะสะสมเวลาไว้
   - เวลาจำกัดขึ้นกับความยากของภารกิจปัจจุบัน: easy 10 นาที, medium 20 นาที, hard 30 นาที
   - Testing mode (เปิดในหน้าตั้งค่า): 15, 30 หรือ 45 วินาที
5. เมื่อเกินเวลา แอปจะแสดง overlay ทับแอปนั้น ผู้ใช้ต้องทำภารกิจก่อน หรือสุ่มภารกิจที่สั้นกว่าแทน (reroll)
6. Gate screen: ถ่ายรูปแล้วส่ง base64 ไปที่ Edge Function `verify-photo`
   - ฟังก์ชันตรวจ JWT ของผู้ใช้ อ่าน `ai_labels` ของภารกิจจากฐานข้อมูล
   - ถ้า avatar ของผู้ใช้อยู่ใน bucket `avatars` จะส่งรูป avatar ไปด้วยเพื่อเทียบว่าเป็นคนเดียวกัน
   - ถาม OpenRouter ว่ารูปตรงโจทย์หรือไม่ (ตอบ YES/NO)
   - ถ้าตอบ YES จะเรียก `complete_mission` ด้วย service role เพื่อเพิ่ม XP, streak, `today_completed` และ `week_history`
7. แอปปลดล็อกผ่าน RPC `unlock_app` แล้ว sync ค่าจาก `profiles`

### ภารกิจ (ตาราง `missions`, มี 5 รายการ)

`walk_outside`, `find_tree`, `sky_photo`, `basketball`, `open_book`

แต่ละรายการมีคอลัมน์: title, description, photo_prompt, difficulty, category, xp, duration, ai_labels, icon_name, color_name

---

## 6. ฐานข้อมูล (Supabase)

สคริปต์หลัก: `supabase_cloud_setup.sql` (รันบน Cloud แล้ว)

| ตาราง | คอลัมน์สำคัญ | สิทธิ์ |
|-------|--------------|--------|
| `profiles` | id (FK auth.users), username, avatar_url, total_xp, current_streak, last_active_date, today_completed, today_unlocked, week_history | RLS: อ่านได้เฉพาะของตัวเอง; client แก้ได้แค่ username, avatar_url, updated_at |
| `missions` | id (text), title, …, xp, duration, ai_labels | อ่านได้เมื่อล็อกอิน |
| `storage.avatars` | รูปโปรไฟล์ | public read; อัปโหลด/แก้/ลบได้เฉพาะโฟลเดอร์ของตัวเอง |

| ฟังก์ชัน | เรียกได้โดย | หน้าที่ |
|----------|-------------|---------|
| `complete_mission(p_user_id, p_mission_id)` | service_role เท่านั้น | เพิ่ม XP/streak กันทำซ้ำในวันเดียว รีเซ็ตรายการเมื่อขึ้นวันใหม่ |
| `unlock_app(p_app_id)` | authenticated | เพิ่มแอปใน `today_unlocked` |
| `handle_new_user()` | trigger | สร้างแถว profiles เมื่อมีผู้ใช้ใหม่ |

ไฟล์ SQL อื่น:
- `progress_rpc.sql`: RPC สำหรับเรื่อง progress (รวมอยู่ใน cloud setup แล้ว)
- `sql_tests/progress_rpc_test.sql`: เทสต์ RPC ห้ามรันบน Supabase เพราะสคริปต์ drop schema `auth` ให้ใช้กับฐานข้อมูลทดสอบเท่านั้น
- `database_schema.sql`, `database_setup.sql`, `missions_setup.sql`, `progress_setup.sql`: สคริปต์รุ่นเก่าตอนใช้ self-hosted

### Edge Function secrets

`OPENROUTER_API_KEY` (ตั้งแล้ว), `VERIFY_MODEL` (ไม่บังคับ ค่าเริ่มต้นคือ `google/gemini-2.5-flash`) และตัวแปร `SUPABASE_*` ที่ระบบตั้งให้

---

## 7. Android

| ค่า | ค่าที่ตั้งไว้ |
|-----|--------------|
| applicationId / namespace | `com.example.analog_gate` |
| compileSdk | 37 (plugin ทุกตัวถูกบังคับเป็น 37 ใน `android/build.gradle.kts`) |
| targetSdk | 36 |
| minSdk | `flutter.minSdkVersion` |
| Java / Kotlin JVM target | 17 |
| Gradle wrapper | 8.14.3 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin plugin | 2.2.20 |
| Core library desugaring | desugar_jdk_libs 2.1.5 |
| `gradle.properties` | `android.newDsl=false`, `android.builtInKotlin=false` (Flutter migrator ตั้งให้) |

Permissions: INTERNET, CAMERA, PACKAGE_USAGE_STATS, SYSTEM_ALERT_WINDOW, FOREGROUND_SERVICE, FOREGROUND_SERVICE_SPECIAL_USE, POST_NOTIFICATIONS, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, READ/WRITE_EXTERNAL_STORAGE

ตอนนี้รองรับเฉพาะ Android โฟลเดอร์ ios, macos, web, windows และ linux มาจาก template แต่ฟีเจอร์หลัก (usage stats, overlay) ใช้ได้เฉพาะ Android

---

## 8. เครื่องมือพัฒนา (บนเครื่อง Windows นี้)

| เครื่องมือ | รายละเอียด |
|------------|------------|
| Flutter SDK | `analog_gate\flutter` (อยู่ในโปรเจกต์แต่ไม่ได้ track ใน git; `analysis_options.yaml` ยกเว้น `flutter/**` ไว้) |
| JDK | Temurin 17 ที่ `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot` ตั้งผ่าน `flutter config --jdk-dir` |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk` (platforms 34 ถึง 37.0, cmdline-tools) |
| Android Studio | มี JBR 25 ซึ่งใช้ build ไม่ได้ จึงต้องตั้ง jdk-dir |
| Supabase CLI | v2.98.2 (scoop) deploy ด้วย `supabase functions deploy verify-photo --use-api` |
| Deno | ใช้ type-check Edge Function |
| Git | branch `main` → origin |
| อุปกรณ์ทดสอบ | Samsung SM A156E ต่อผ่าน USB debugging |

### คำสั่งที่ใช้บ่อย (PowerShell บนเครื่อง PC ในโฟลเดอร์ analog_gate)

```powershell
.\flutter\bin\flutter pub get
.\flutter\bin\flutter analyze
.\flutter\bin\flutter run                    # ติดตั้งและรันบนมือถือ
.\flutter\bin\flutter build apk --debug
supabase functions deploy verify-photo --use-api
supabase secrets list --project-ref jvdyfsfvwwzhaiwmwwql
```

---

## 9. สถานะและข้อจำกัดที่รู้แล้ว

สถานะ ณ commit นี้:
- Build ผ่าน ติดตั้งบนมือถือได้ เปิดถึงหน้า Login และเชื่อม Supabase ได้
- `flutter analyze`: error 0, warning 2 (import ที่ไม่ได้ใช้และตัวแปร `allGranted` ใน main.dart), info 65
- ทดสอบฝั่งเซิร์ฟเวอร์ครบวงจรแล้ว (31 ต.ค. 2026): รูปท้องฟ้ากับภารกิจ sky_photo ได้ +20 XP และ streak 1, ส่งซ้ำได้ 0 XP, รูปท้องฟ้ากับภารกิจ open_book ถูกปฏิเสธพร้อมเหตุผล, client เขียน total_xp เองไม่ได้ (403)
- ยังไม่ได้ทดสอบ flow เดียวกันผ่านแอปบนมือถือ (ล็อกอิน → ถ่ายรูป → ได้ XP)

ข้อจำกัด:
- Gate screen เลือกรูปจากแกลเลอรีได้ จึงใช้รูปเก่าผ่านภารกิจได้
- Edge Function ยังไม่มี rate limit ทุกครั้งที่ส่งรูปจะมีค่า OpenRouter
- ทำภารกิจตอนออฟไลน์ไม่ได้ และไม่มีคิวส่งรูปใหม่ภายหลัง
- รายการแอปที่บล็อกและเวลาสะสมอยู่บนเครื่องเท่านั้น ลบแอปแล้วข้อมูลจะหาย
- ระบบอีเมลของ Supabase ที่ใช้ฟรีส่งได้ประมาณ 2 ฉบับต่อชั่วโมง ทำให้สมัครหลายบัญชีติดกันไม่ได้ (ขึ้น `email rate limit exceeded`)
- ข้อความจาก flutter_background_service_android ใน log ("should only be used in the main isolate") ยังไม่ได้ตรวจว่ามีผลจริงหรือไม่
- Flutter เตือนว่าจะเลิกรองรับ Gradle 8.x, AGP 8.11 และ Kotlin 2.2 เร็ว ๆ นี้ ต้องอัปเกรดเป็น AGP 9 / Gradle 9.1 / Kotlin 2.3.20
- applicationId ยังเป็น `com.example.*` ต้องเปลี่ยนก่อนขึ้น Play Store
- ยังไม่มี automated test ฝั่ง Dart
- `README.md` ยังเป็น template เดิมของ Flutter

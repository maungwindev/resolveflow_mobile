# ResolveFlow

> **Enterprise mobile diagnostic & inventory management app** for field technicians and inventory managers — built with Flutter + Appwrite.

---

## 📦 Product Overview

**ResolveFlow** is a field-service operations platform that bridges **AI-powered symptom diagnostics** with **transactional inventory management**. It allows technicians to search known issues using natural language, apply fixes, and automatically deduct parts from the live inventory — while giving managers full audit and CRUD control over stock and work order history.

**Package ID:** `com.darkwinglabs.resolveflow`  
**Version:** `1.0.0+1`  
**Platform:** Android (Play Store), iOS

---

## ✨ App Features

### 🔍 Semantic Diagnostic Search
- Enter freeform symptom descriptions (e.g., *"coolant boiling into reservoir after highway speed"*)
- Vector-based cosine similarity search against the `resolutions_vector` knowledge base
- Each result shows:
  - Match confidence score (e.g., `94% match`)
  - Diagnostic observation checklist
  - Step-by-step fix procedure
  - Required spare part **SKU chip** (highlighted in Lime Cream)

### ⚙️ Apply Fix & Deduct Stock (Technicians)
- One-tap **"Apply Fix & Deduct Stock"** action on a matched result
- Automatically:
  1. Validates live stock availability
  2. Decrements `quantity_on_hand` by 1
  3. Creates a `WO-XXXX` work order record
  4. Logs an immutable `work_order_parts` audit entry
- Displays a success receipt with the Work Order number

### 🧠 Adaptive Knowledge Ingestion
- When no match is found (similarity < 0.60), an inline **Knowledge Ingestion Form** appears
- Technicians or Managers can submit:
  - Symptom Title, Diagnostic Observation, Fix Procedure, Required SKU
- Immediately re-indexes and surfaces in future searches

### 📦 Live Inventory Management
- Real-time parts catalog with color-coded stock badges:
  - 🟢 **Healthy** — stock ≥ min threshold (Fern Green)
  - 🟡 **Low Stock** — stock < min threshold (Amber)
  - 🔴 **Depleted** — stock = 0 (Red)
- Technicians: Read-only stock lookup with bin/shelf location
- Managers: Full CRUD — Add Part, Restock (+N), Edit Price, Edit Threshold, Delete

### 📋 Work Orders & Audit History
- Technicians: View their own completed work orders and part deductions
- Managers: Full audit log of all technician work orders with timestamps, parts consumed, and technician identity

### 👥 Team Management
- Manage technician team members
- Assign users to `technicians` or `managers` Appwrite teams

### 👤 Profile & Role Display
- Profile screen with dynamic role badge:
  - 🔧 `Technician` — Fern Green badge
  - 📋 `Inventory Manager` — Hunter Green badge
- Secure logout and account management

### 🔐 Authentication
- Email/password login, signup, and forgot password flows
- Session persistence via Secure Storage
- Onboarding screen for first-time users

---

## 🏗️ Architecture

```
Architecture:       MVC
State Management:   GetX (reactive Rx<> state)
Navigation:         GetX named routes
Backend:            Appwrite (Auth + Database + Storage)
Networking:         Dio (with interceptor logging)
Local Storage:      SharedPreferences + Flutter Secure Storage
Theme:              Cupertino adaptive (dark mode follows system)
Localization:       easy_localization (English)
```

```
lib/src/
├── controllers/    # GetX controllers (state & orchestration)
├── models/         # Domain models (WorkOrder, InventoryPart, etc.)
├── services/       # Repositories & Appwrite service calls
├── views/          # Screens & widgets
├── routing/        # AppRouter, AppRoutes, bindings
└── theme/          # Design tokens, color palette, text theme
```

---

## 🗄️ Database (Appwrite)

**Database ID:** `resolveflow_main`

| Collection | Type | Purpose |
|---|---|---|
| `resolutions_vector` | VectorsDB (HNSW Cosine) | Semantic symptom-to-fix knowledge base |
| `parts_inventory` | TablesDB | Live spare parts catalog with stock levels |
| `work_orders` | TablesDB | Repair execution records (`WO-XXXX`) |
| `work_order_parts` | TablesDB | Immutable part deduction audit ledger |

### Key Fields

**`parts_inventory`** — `sku`, `name`, `quantity_on_hand`, `min_threshold`, `unit_price`, `location`

**`work_orders`** — `work_order_number`, `symptom_title`, `resolution_summary`, `technician_id`, `technician_name`, `status`, `created_at`

**`work_order_parts`** — `work_order_id`, `sku`, `part_name`, `quantity_deducted`, `timestamp`

**`resolutions_vector`** — `title`, `symptom`, `observation`, `fix_procedure`, `required_sku`, `similarity_score`

---

## 🔑 Roles & Permissions (RBAC)

Access is enforced at both the **Appwrite server level** (collection permissions) and **Flutter UI level** (role-gated widgets).

| Feature | Technician (`team:technicians`) | Manager (`team:managers`) |
|---|:---:|:---:|
| Semantic symptom search | ✅ | ✅ |
| Knowledge ingestion (add fix) | ✅ | ✅ |
| View parts inventory | ✅ Read-only | ✅ Read-only |
| Add / Edit / Delete parts | ❌ | ✅ |
| Restock parts | ❌ | ✅ |
| Create work orders (`WO-XXXX`) | ✅ | ❌ |
| Deduct stock via Apply Fix | ✅ | ❌ |
| View own work orders | ✅ | 👁️ All |
| Full audit of all work orders | ❌ | ✅ |
| Team member management | ❌ | ✅ |

---

## 🛠️ Tech Stack & Key Packages

| Category | Package | Version |
|---|---|---|
| State & Navigation | `get` | ^4.7.3 |
| Backend | `appwrite` | ^22.0.0 |
| Networking | `dio` | ^5.9.2 |
| Functional types | `fpdart` | ^1.2.0 |
| Local storage | `shared_preferences` | ^2.5.4 |
| Secure storage | `flutter_secure_storage` | ^10.0.0 |
| Image caching | `cached_network_image` | ^3.4.1 |
| Responsive UI | `flutter_screenutil` | ^5.9.3 |
| Localization | `easy_localization` | ^3.0.8 |
| Skeleton loading | `skeletonizer` | ^2.1.3 |
| Animations | `flutter_animate` | ^4.5.2 |
| Permissions | `permission_handler` | ^12.0.1 |
| Connectivity | `internet_connection_checker_plus` | ^2.9.1 |
| Device info | `device_info_plus` | ^11.2.0 |
| Logging | `logger` | ^2.6.2 |
| SVG icons | `flutter_svg` | ^2.2.4 |
| Splash screen | `flutter_native_splash` | ^2.4.7 |

---

## 🎨 Design System

**Theme preset:** Cupertino adaptive · **Dark mode:** System-follows

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| `evergreen` | `#132A13` | Dark headers, background |
| `hunterGreen` | `#31572C` | Secondary surfaces, Manager badge |
| `fern` | `#4F772D` | Primary action color, Technician badge |
| `palmLeaf` | `#90A955` | Accent, borders, confidence meters |
| `limeCream` | `#ECF39E` | SKU chips, surface highlights |

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|---|---|
| Flutter (via FVM) | **3.38.6** |
| FVM | Latest |
| Dart SDK | `>=3.5.0 <4.0.0` |
| Android `minSdk` | **24** |
| Android `compileSdk` | **36** |

### 1. Install FVM & Flutter version

```bash
# Install FVM (if not already installed)
dart pub global activate fvm

# Install and use the pinned Flutter version
fvm install 3.38.6
fvm use 3.38.6
```

### 2. Clone & Install Dependencies

```bash
git clone <repo-url>
cd resolveflow

fvm flutter pub get
```

### 3. Configure Environment

Copy the example secrets file and fill in your Appwrite credentials:

```bash
cp lib/src/config/app_secrets.example.dart lib/src/config/app_secrets.dart
```

Edit `.env` with your Appwrite project details:

```env
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your_project_id
```

> ⚠️ **Never commit `.env` or `app_secrets.dart` with real credentials.**

### 4. Run the App

```bash
# Debug
fvm flutter run

# Release build (Android App Bundle for Play Store)
fvm flutter build appbundle --release
```

---

## 🔐 Android Release / Keystore Setup

A `key.properties` file is required for release builds. Place it at `android/key.properties`:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=../app/release-key.jks
```

> ⚠️ Add `android/key.properties` and `android/app/*.jks` to `.gitignore` — never commit these.

Generate keystore:

```bash
keytool -genkey -v -keystore android/app/release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias your_key_alias
```

---

## 🌍 Localization

After editing `assets/translations/*.json`:

```bash
fvm flutter pub run easy_localization:generate \
  -S assets/translations \
  -O lib/src/core/i18n \
  -o locale_keys.g.dart
```

---

## ✅ Verification

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

---

## 📁 Project Structure (Key Paths)

```
resolveflow/
├── lib/
│   ├── main.dart
│   └── src/
│       ├── config/          # App config, Appwrite client, secrets
│       ├── controllers/     # GetX controllers per feature
│       ├── models/          # Domain models
│       ├── services/        # Repositories & Appwrite service layer
│       ├── views/           # Screens (auth, diagnostic, inventory, work_orders, profile, team)
│       ├── routing/         # AppRouter, routes, bindings
│       ├── theme/           # Colors, spacing, text theme, design tokens
│       └── shared/          # Reusable widgets, helpers, wrappers
├── android/
│   ├── app/build.gradle.kts # compileSdk 36, minSdk 24
│   └── key.properties       # Keystore config (not committed)
├── assets/
│   ├── translations/        # en.json localization
│   └── icons/
└── pubspec.yaml
```

---

## 📄 License

Private — All rights reserved · © 2026 Darkwing Labs

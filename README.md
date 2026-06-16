# Warraich Petroleum

A complete petrol pump management system built with Flutter. Track sales, manage inventory, handle expenses, generate reports, and run payroll — all in one app.

## Features

- **Dashboard** — Daily summary, monthly performance, active shifts, inventory alerts, sales/expense/profit trends
- **Shifts** — Start morning/evening shifts, record fuel sales with meter readings, track cash/card/credit payments
- **Inventory** — Stock levels for fuel and lubricants, min/max alerts, stock history, add stock purchases
- **Expenses** — Log expenses by category, edit/delete, grouped by day
- **Employees** — Add staff, set roles (Operator/Manager/Supervisor), assign shifts, set salary
- **Payroll** — Generate monthly payroll, adjust deductions/bonuses, mark as paid
- **Sales History** — Search, filter by type/status, date range picker
- **Reports** — Generate PDF shift reports and monthly summaries
- **Backup & Restore** — Local backup, Google Drive cloud backup, auto-backup
- **App Lock** — Biometric authentication (fingerprint/face) on mobile
- **Responsive** — Works on mobile, tablet, and desktop (Windows/Linux)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter + Material 3 |
| State | Riverpod |
| Database | Drift (SQLite) |
| Charts | fl_chart |
| PDF | pdf + printing |
| Auth | Google Sign-In (backup), Local Auth (biometrics) |
| Storage | Flutter Secure Storage |
| CI/CD | GitHub Actions (Android, Linux, Windows) |

## Getting Started

### Prerequisites
- Flutter 3.44.x or later
- Dart SDK 3.12.1+

### Setup

```bash
# Clone the repo
git clone https://github.com/Muneeb1195/warraich_petroleum_inv_mang.git
cd warraich_petroleum_inv_mang

# Install dependencies
flutter pub get

# Run database migrations
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Building

```bash
# Android
flutter build apk --release --target-platform android-arm64 \
  --dart-define=GOOGLE_CLIENT_ID=<your-id> \
  --dart-define=GOOGLE_CLIENT_SECRET=<your-secret>

# Linux
flutter build linux --release \
  --dart-define=GOOGLE_CLIENT_ID=<your-id> \
  --dart-define=GOOGLE_CLIENT_SECRET=<your-secret>

# Windows
flutter build windows --release \
  --dart-define=GOOGLE_CLIENT_ID=<your-id> \
  --dart-define=GOOGLE_CLIENT_SECRET=<your-secret>
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `GOOGLE_CLIENT_ID` | OAuth2 client ID for Google Drive backup |
| `GOOGLE_CLIENT_SECRET` | OAuth2 client secret for Google Drive backup |

These are required for cloud backup. The app works without them (local backup only).

## Testing

```bash
# Run all tests
flutter test

# Run analyzer
dart analyze lib/
```

## Project Structure

```
lib/
├── config/          # App configuration
├── database/        # Drift schema, DAOs, tables
├── providers/       # Riverpod state management
├── repositories/    # Data access layer
├── screens/         # UI screens (dashboard, shifts, inventory, etc.)
├── services/        # Business logic (backup, PDF, biometrics, error logging)
├── theme/           # Material 3 themes
└── utils/           # Helpers (constants, extensions, responsive)
```

## License

Private — Warraich Petroleum

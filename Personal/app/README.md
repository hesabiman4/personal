# Personal Income Tracker - Flutter Application

A personal finance tracking application for freelancers and small business owners to track income, expenses, clients, and receivables.

## Project Structure

```
Personal/app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── account.dart
│   │   ├── category.dart
│   │   ├── client.dart
│   │   ├── receivable.dart
│   │   └── transaction.dart
│   ├── services/                 # Business logic services
│   │   ├── database_service.dart
│   │   └── export_service.dart
│   ├── providers/                # State management
│   │   ├── finance_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/                  # UI screens
│   │   ├── home/
│   │   ├── transactions/
│   │   ├── clients/
│   │   ├── reports/
│   │   ├── settings/
│   │   └── shared/
│   ├── widgets/                  # Reusable widgets
│   └── utils/                    # Utilities
│       ├── constants.dart
│       ├── formatters.dart
│       └── validators.dart
├── test/                         # Unit and widget tests
├── android/                      # Android-specific configuration
├── ios/                          # iOS-specific configuration
└── pubspec.yaml                  # Dependencies
```

## Features (Phase 1 - MVP)

- **Home Dashboard**: Balance overview, quick actions, recent transactions, outstanding clients
- **Transaction Management**: Record income/expenses with categories, accounts, dates, and notes
- **Client Management**: Create clients, track invoices, record payments, view history
- **Reports**: Visual income vs expense comparison over selectable time periods
- **Settings**: Local profile, currency selection, dark mode, CSV export, data management
- **Offline-First**: All data stored locally in encrypted SQLite database

## Tech Stack

- **Framework**: Flutter + Dart
- **State Management**: Provider + ChangeNotifier
- **Database**: SQLite with SQLCipher encryption
- **Secure Storage**: flutter_secure_storage for database keys
- **Dependencies**: See pubspec.yaml

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Android SDK (for Android development)

### Installation

1. Navigate to the app directory:
   ```bash
   cd Personal/app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Data Model

The app uses five core tables:

1. **accounts**: Cash, Card, Bank accounts with opening balances
2. **categories**: Income and expense categories with icons
3. **clients**: Client contact information and service details
4. **receivables**: Invoices with amounts, due dates, and payment status
5. **transactions**: Income/expense records linked to accounts, categories, and optionally clients/receivables

Money is stored as integer minor units (e.g., $24.50 = 2450 cents) to avoid floating-point precision issues.

## Architecture

The app follows a simple architecture:

```
Screens (UI) → Providers (State) → Services (Business Logic) → Database
```

- **Screens**: Build UI and handle user interactions
- **Providers**: Manage state using ChangeNotifier pattern
- **Services**: Handle database operations and business logic
- **Database**: Encrypted SQLite storage

## Key Design Decisions

- **Cash-basis accounting**: Income recorded when received, not when invoiced
- **Single currency per installation**: USD default, selectable before financial records exist
- **One payment per invoice**: No split payments or overpayments in v1
- **Local-first**: No cloud sync in Phase 1; all data stored on device
- **Archive, don't delete**: Clients with history are archived, not deleted

## Testing

Run tests with:
```bash
flutter test
```

Key test areas:
- Money calculations and parsing
- Database operations and migrations
- Widget rendering and interactions
- Form validation

## Next Steps (Phase 2)

- Full data backup/restore for device replacement
- Dari/Pashto localization with RTL support
- Optional cloud synchronization (Node.js + Express + PostgreSQL backend)

## License

This project is proprietary software.

# NestPilot Mobile App

Society Management Mobile App built with Flutter (MVP Phase-1).

## Features

- **Auth**: OTP-based login and registration.
- **Roles**:
  - **Super Admin**: Create societies, buildings, and flats.
  - **Secretary**: Approve members, publish notices, create bills, and record payments.
  - **Member**: View notices, file complaints, view bills, and track payment history.
- **Billing**: Automatic bill generation and manual payment recording (Cash/Cheque).
- **Notices & Complaints**: Communication hub for society members.

## Tech Stack

- **Framework**: Flutter (Material 3)
- **Networking**: `http` package
- **Storage**: `shared_preferences` (for JWT)
- **State Management**: `setState` (Simple & Clean)

## Setup Instructions

1.  **Prerequisites**:
    - Flutter SDK installed (`flutter doctor` should pass).
    - Backend API running (update `baseUrl` in `lib/config/app_config.dart`).

2.  **Installation**:
    ```bash
    cd nest_pilot_mobile
    flutter pub get
    ```

3.  **Run the App**:
    ```bash
    flutter run
    ```

## Project Structure

- `lib/config`: App configuration and API endpoints.
- `lib/models`: Data models for API responses.
- `lib/services`: API service wrappers.
- `lib/screens`: UI screens grouped by role/feature.
- `lib/widgets`: Reusable UI components.

## Implementation Details

- **Offline Mode**: Not implemented (as per requirements).
- **Networking**: Standard `http` with Bearer token authentication.
- **UI**: Material 3 with clean, readable code.
- **Permissions**: `permission_handler` used for storage access (receipt downloads).

# Society Management Backend

## Setup

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Database Setup**
   - Ensure PostgreSQL is running.
   - Create database `NestPilot`.
   - Update `.env` with credentials.

3. **Migrations & Seeds**
   ```bash
   npm run migrate
   npm run seed
   ```

4. **Run Server**
   ```bash
   npm run dev
   ```

## API Documentation

- **Base URL**: `http://localhost:5000`
- **Postman Collection**: `docs/postman_collection.json`
- **Swagger**: `http://localhost:5000/api-docs` (TODO: Enable in app.js if needed)

## Features

- **Auth**: OTP Login, JWT.
- **Roles**: Super Admin, Secretary, Member.
- **Modules**: Notices, Complaints, Bills, Payments (Offline Sync).

## Project Structure
- `src/models`: Sequelize Models
- `src/controllers`: Request Handlers
- `src/services`: Business Logic
- `src/routes`: API Routes

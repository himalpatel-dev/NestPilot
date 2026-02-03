# NestPilot Backend

This is the backend server for the NestPilot Society Management System. It is built with **Node.js**, **Express**, and **PostgreSQL** (via **Sequelize** ORM).

## 🏗 Project Architecture

The project follows a layered architecture to separate concerns:

1.  **Routes** (`src/routes`): Define API endpoints and map them to controllers.
2.  **Controllers** (`src/controllers`): Handle HTTP requests, validate input, and send responses. They delegate business logic to services.
3.  **Services** (`src/services`): Contain the core business logic and interact with the database.
4.  **Models** (`src/models`): Define the database schema using Sequelize.
5.  **Middlewares** (`src/middlewares`): Handle cross-cutting concerns like Authentication, Role-based Access Control (RBAC), and Error Handling.

---

## 🚀 How It Works: The "Whole Process"

Here is a step-by-step breakdown of how a request is processed, using the **Bill Management** feature as an example.

### 1. The Request
A client (Mobile App or Web Dashboard) sends an HTTP request.
*   **Example**: A Society Admin wants to publish a maintenance bill.
*   **Endpoint**: `POST /api/bills/:id/publish`
*   **Headers**: `Authorization: Bearer <token>`

### 2. Entry Point (`app.js`)
The request hits `app.js`, which sets up global middleware (CORS, Helmet, Body Parser) and forwards the request to the main router.

### 3. Routing (`src/routes`)
*   `src/routes/index.js` directs `/api/bills` requests to `bill.routes.js`.
*   `src/routes/bill.routes.js` defines the specific route:
    ```javascript
    router.post('/:id/publish', role(['SOCIETY_ADMIN']), controller.publish);
    ```
*   **Middleware Execution**:
    *   `auth.middleware`: Verifies the JWT token to ensure the user is logged in.
    *   `role.middleware`: Checks if the user has the `SOCIETY_ADMIN` role.

### 4. Controller (`src/controllers/bill.controller.js`)
The `publish` function in the controller receives the request.
*   It extracts `billId` from `req.params` and `societyId` from `req.user`.
*   It calls the service layer: `await api.publishBill(billId, societyId)`.
*   It handles the response (success or error).

### 5. Service (`src/services/bill.service.js`)
This is where the actual work happens.
1.  **Transaction Start**: A database transaction is started to ensure data integrity.
2.  **Validation**: Checks if the bill exists and is not already published.
3.  **Update Status**: Updates the Bill status to `PUBLISHED`.
4.  **Generate Member Bills**:
    *   Fetches all `BillTarget`s (houses linked to this bill).
    *   Iterates through targets and finds the active user for each house (`UserHouseMapping`).
    *   Creates individual `MemberBill` records for each user.
5.  **Commit**: If all steps succeed, the transaction is committed.

### 6. Database (`PostgreSQL`)
The data is persisted in the `Bills`, `BillTargets`, and `MemberBills` tables.

---

## 📂 Key Modules

### Authentication (`src/routes/auth.routes.js`)
*   **Login**: Users login with Mobile Number & OTP.
*   **Token**: A JWT (JSON Web Token) is issued upon successful verification.
*   **Flow**: `Send OTP` -> `Verify OTP` -> `Get Token`.

### Society Management (`src/routes/society.routes.js`)
*   **Structure**: Manages Societies, Buildings, and Houses.
*   **Users**: Manages User profiles and their mapping to houses (Owner/Tenant).

### Billing (`src/routes/bill.routes.js`)
*   **Creation**: Admins create a bill definition (Amount, Due Date, Targets).
*   **Publishing**: "Publishing" a bill generates actual payable records for members.
*   **Viewing**: Members view their specific `MemberBill` records.

### Security & Access Control
*   **Visitors** (`src/routes/visitor.routes.js`): Pre-approve guests, log entry/exit (Guard).
*   **Vehicles** (`src/routes/vehicle.routes.js`): Register resident vehicles.

### Community & Lifestyle
*   **Amenities** (`src/routes/amenity.routes.js`): Book facilities like Clubhouse, Gym.
*   **Staff** (`src/routes/staff.routes.js`): Manage daily help (Maids, Drivers) and attendance.

### Governance
*   **Polls** (`src/routes/poll.routes.js`): Conduct society surveys and voting.
*   **Documents** (`src/routes/document.routes.js`): Repository for By-laws, Minutes, etc.

---

## 🛠 Setup & Run

### Prerequisites
*   Node.js (v18+)
*   PostgreSQL

### Installation
1.  **Install Dependencies**:
    ```bash
    npm install
    ```
2.  **Environment Variables**:
    Create a `.env` file (copy from `.env.example` if available) and set your DB credentials.

3.  **Database Init**:
    ```bash
    npm run migrate # Run Sequelize migrations
    npm run seed    # Seed initial data
    ```

4.  **Start Server**:
    ```bash
    npm run dev
    ```

## 📚 API Documentation
*   **Swagger UI**: Visit `http://localhost:5000/api-docs` to explore the API interactively.
*   **Postman**: Import `docs/postman_collection.json` for pre-configured requests.

# NestPilot Expansion Plan: Towards a Fully Functional Society Management System

Based on the analysis of the current backend, the following core modules are implemented:
- ✅ **Authentication & Users** (Login, Roles, Profile)
- ✅ **Society Structure** (Societies, Buildings, Houses)
- ✅ **Billing & Payments** (Invoicing, History, Receipts)
- ✅ **Complaints** (Helpdesk tickets)
- ✅ **Notices** (Digital Notice Board)

To make this a **"Fully Functional"** system comparable to market leaders (like MyGate, NoBrokerHood), we need to implement the following missing modules.

## 🚀 Phase 1: Security & Access Control (Priority: High)
*Focus: Gatekeeper App & Resident Safety*

### 1. Visitor Management
*   **Features**:
    *   **Pre-approval**: Residents invite guests (generates a code).
    *   **Gate Entry**: Security guard logs entry (Delivery, Cab, Guest).
    *   **Approval**: Guard requests approval from resident via app notification.
*   **New Models**: `Visitor`, `VisitorLog`.

### 2. Vehicle & Parking Management
*   **Features**:
    *   **Registry**: Residents add their vehicles (Car/Bike).
    *   **Parking Slots**: Assign specific parking slots to houses.
    *   **Stickers**: Manage parking stickers/RFID tags.
*   **New Models**: `Vehicle`, `ParkingSlot`.

---

## 🚀 Phase 2: Community & Lifestyle (Priority: Medium)
*Focus: Resident Convenience*

### 3. Facility & Amenity Booking
*   **Features**:
    *   **Listing**: List amenities (Clubhouse, Tennis Court, BBQ Area).
    *   **Booking**: Residents book slots (paid or free).
    *   **Calendar**: View availability.
*   **New Models**: `Amenity`, `Booking`.

### 4. Daily Help / Service Staff
*   **Features**:
    *   **Registry**: Database of Maids, Drivers, Cooks, etc.
    *   **Attendance**: Entry/Exit tracking by security.
    *   **Ratings**: Residents rate staff.
*   **New Models**: `ServiceStaff`, `StaffAttendance`, `StaffRating`.

---

## 🚀 Phase 3: Governance & Communication (Priority: Medium)
*Focus: Admin & Decision Making*

### 5. Polls & Surveys
*   **Features**:
    *   Admins create polls for decisions (e.g., "New Gym Equipment?").
    *   Residents vote.
*   **New Models**: `Poll`, `PollOption`, `PollVote`.

### 6. Document Repository
*   **Features**:
    *   Store Society By-laws, AGM Minutes, Audits.
    *   Folder structure and access control.
*   **New Models**: `Document`, `DocumentCategory`.
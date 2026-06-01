# Smart Nivaas (NestPilot) — Complete App Design & Field Specifications

This document serves as the master blueprint and ready-to-design specification sheet for the **Smart Nivaas** mobile application. It outlines the visual style guide, role-based workflows, screen-by-screen layouts, interactive forms, validation rules, and navigation flows.

---

## 1. Visual Style Guide & Design System

The app utilizes a modern, high-contrast, premium aesthetic. To create a sleek and trustworthy look suitable for housing and security, we employ a **Slate Gray & Warm Cream** palette, enhanced with dark glassmorphism containers and clean, round typography.

### 1.1 Color Tokens
| Token | HEX Code | Usage |
| :--- | :--- | :--- |
| **Primary Base** | `#708090` (Slate Gray) | Toolbars, active borders, brand icons, primary buttons |
| **Primary Light** | `#8E9DAE` (Light Slate) | Borders, secondary icons, selected chips |
| **Background Dark** | `#0F172A` (Slate 900) | Root gradient start (page backgrounds) |
| **Background Mid** | `#1B2234` (Slate 950) | Card fill overlays, modal sheet backdrops |
| **Warm Highlight** | `#FAF3E0` (Warm Cream) | Primary titles, branding text, high-emphasis text, action icons |
| **Warm Accent** | `#E6DFCD` (Soft Cream) | Subtext, paragraph description, hints, secondary text |
| **Emerald Green** | `#10B981` | Approved status, paid bills, active logs, check-in markers |
| **Amber Orange** | `#F59E0B` | Pending status, waiting approval, outstanding dues |
| **Crimson Red** | `#EF4444` | Rejected status, denied entry, unpaid bills, delete triggers |

### 1.2 Typography (Inter / Outfit Font)
- **Brand Title**: 32pt, Extra Bold (`FontWeight.w900`), Letter spacing: 1.0, Color: Warm Cream (`#FAF3E0`)
- **Headline Large**: 24pt, Bold (`FontWeight.bold`), Color: Warm Cream (`#FAF3E0`)
- **Headline Medium / Section Title**: 20pt, Semi-Bold (`FontWeight.w600`), Color: White
- **Body Text**: 14pt, Medium (`FontWeight.w500`), Color: Soft Cream (`#E6DFCD`)
- **Subtitle / Small Caption**: 12pt, Regular (`FontWeight.w400`), Color: Slate Light (`#8E9DAE`)

### 1.3 Card & Input Styling
- **Card Radius**: `BorderRadius.circular(16)`
- **Card Fill**: Solid Dark Slate (`#1B2234`) or Frosted Glassmorphism (White with `0.06` opacity + 1.2pt border with `0.12` opacity)
- **Input Fields**:
  - Fill Color: White with `0.04` opacity or Slate 900
  - Border: Outlined `BorderRadius.circular(14)`
  - Active/Focused Border: Solid Slate Gray (`#708090`), 2pt thick
  - Padding: `symmetric(horizontal: 16, vertical: 16)`

---

## 2. User Roles & Permission Matrix

The application handles 4 distinct user profiles, each landing on a customized quick-actions dashboard:

1. **Super Admin**: System operator. Creates societies, wings/buildings, and individual flats.
2. **Society Admin (Secretary)**: Oversees society operations, approves members, creates notices, schedules amenities, marks payments, reviews complaints, manages staff, and uploads documents.
3. **Member (Resident)**: Can be an **Owner**, **Tenant**, or **Family Member**. Manages personal vehicles, books amenities, file complaints, reads notices, views ledger/outstanding bills, invites guests, and votes on polls.
4. **Security Guard**: Manages gate entry. Scans/checks visitor passcodes, logs walk-ins/deliveries, and monitors currently active visitors inside the premises.

---

## 3. Screen Specifications (Role-by-Role)

---

### Phase A: Authentication & Onboarding Flow

#### 1. Splash Screen
*   **Route**: `/splash`
*   **Purpose**: Launch screen displaying branding, detecting authentication tokens, and routing accordingly.
*   **UI Layout**: Deep gradient background. Centered high-resolution animated brand logo (icon of a modular building cluster overlaying a compass pilot wing). 
*   **Transition Rules**:
    *   If token exists and is valid -> Navigates to `/dashboard`
    *   If registered but status is `PENDING` -> Navigates to `/pending_approval`
    *   Otherwise -> Navigates to `/login`

#### 2. Login Screen
*   **Route**: `/login`
*   **Purpose**: Single-factor mobile number entrance.
*   **UI Layout**: Top and bottom soft circular glow effects. Centered logo and bold app title: "Smart Nivaas - Connected Living Made Simple". A frosted glass card container holds the login form.
*   **Interactive Fields**:

| Field Name | Type | Hint / Placeholder | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Mobile Number** | Phone Number | `10-digit number` | Required, Must be exactly 10 digits, Numeric only |

*   **Actions**:
    *   **"Send Verification OTP" Button**: Triggers API request. On success, transitions to `/otp` screen, passing the entered mobile number.

#### 3. OTP Verification Screen
*   **Route**: `/otp`
*   **Purpose**: Verify the user's mobile number.
*   **UI Layout**: Back navigation button on top-left. Brand title shown in header. Centered code entry row.
*   **Interactive Fields**:

| Field Name | Type | Hint / Placeholder | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **OTP Code** | 6-digit PIN | `123456` | Required, Must be exactly 6 digits, Numeric only |

*   **Actions**:
    *   **"Verify & Proceed" Button**: Calls verification API.
        *   If user exists and is approved -> Route to `/dashboard`
        *   If user exists but is pending -> Route to `/pending_approval`
        *   If user does not exist -> Route to `/register` (passing phone number)
    *   **"Resend OTP" Link**: Disabled for a 30-second countdown timer, then clickable to fire request again.

#### 4. Complete Registration Screen
*   **Route**: `/register`
*   **Purpose**: Collect new user details, flat assignment, and roles.
*   **UI Layout**: Scrollable card sheet with clear grouping. Dropdown elements fetch data reactively (selecting a Society loads its Buildings; selecting a Building loads its Flats).
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Full Name** | Text | `e.g. John Doe` | Required, alphabetic letters only |
| **Email** | Email | `e.g. john@example.com` | Optional, must match standard email regex pattern |
| **Society** | Dropdown | `Choose Society` | Required. Loaded dynamically from API |
| **Building/Sector**| Dropdown | `Choose Building/Block`| Required. Loaded dynamically based on chosen Society |
| **Flat/Unit** | Dropdown | `Choose Flat Number` | Required. Loaded dynamically based on chosen Building |
| **Relation Type** | Dropdown | `OWNER`, `TENANT`, `FAMILY_MEMBER` | Required |

*   **Actions**:
    *   **"Register" Button**: Submits payload to database. Redirects user to `/pending_approval`.

#### 5. Pending Approval Screen
*   **Route**: `/pending_approval`
*   **Purpose**: Holding screen for registered users awaiting verification from their Society Admin.
*   **UI Layout**: Large center clock/sandglass icon colored Amber Orange (`#F59E0B`). Frosted glass message card: "Your registration has been submitted. Please wait for the society administrator to approve your unit assignment."
*   **Actions**:
    *   **"Refresh Status" Button**: Re-checks profile API. If status is updated to `APPROVED` or `ACTIVE`, automatically routes to `/dashboard`.
    *   **"Logout" Icon**: Allows logging out to enter a different account.

---

### Phase B: Super Admin Flow (System Setup)

#### 6. Society Creation Screen
*   **Route**: `/super_admin/create_society`
*   **Purpose**: Onboard a new residential community or commercial compound.
*   **UI Layout**: Sleek form with input groups for basic info and addresses.
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Society Name** | Text | `e.g. Green Valley Residency` | Required |
| **Society Type** | Dropdown | `APARTMENT`, `TENEMENT`, `ROW_HOUSE`, `COMMERCIAL`, `MIXED` | Default: `APARTMENT` |
| **Address** | Text | `Street name, Land mark` | Required, Min length 10 |
| **City** | Text | `e.g. Mumbai` | Required |
| **State** | Text | `e.g. Maharashtra` | Required |
| **Pincode** | Number | `e.g. 400001` | Required, exact 6 digits |

*   **Actions**:
    *   **"Create Society" Button**: Saves society and pops back to the dashboard.

#### 7. Building/Block Creation Screen
*   **Route**: `/super_admin/create_building`
*   **Purpose**: Define blocks, wings, or sectors within a society.
*   **UI Layout**: Dropdown selectors on top, followed by block configuration fields.
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Society** | Dropdown | `Select target society` | Required |
| **Building Name** | Text | `e.g. Wing A / Block 1 / Sector 3`| Required |

*   **Actions**:
    *   **"Add Building" Button**: Saves wing configuration.

#### 8. Flat/Unit Creation Screen
*   **Route**: `/super_admin/create_flat`
*   **Purpose**: Add individual units, flats, offices, or row houses to blocks.
*   **UI Layout**: Form adjusts dynamically based on the parent Society's type. For example, if it's a `ROW_HOUSE` society, it hides floor configurations and labels the field "House Number".
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Society** | Dropdown | `Choose Society` | Required |
| **Building/Block** | Dropdown | `Choose Building/Block` | Required |
| **Unit Number** | Text | `e.g. A-102 or Shop 5` | Required |
| **Unit Type** | Dropdown | `FLAT`, `ROW_HOUSE`, `VILLA`, `SHOP`, `OFFICE` | Dynamically filtered based on society type |
| **Floor Number** | Number | `e.g. 1` (default `0`) | Required unless Unit Type is Row House/Villa |
| **Wing/Block** | Text | `e.g. Wing A` | Optional |
| **Area (Sq. Ft.)** | Decimal | `e.g. 1250.50` | Optional, must be positive |

*   **Actions**:
    *   **"Add Flat / Unit" Button**: Saves flat record to db.

#### 9. Flats Directory List Screen
*   **Route**: `/super_admin/flats`
*   **Purpose**: Manage and search flats across all societies.
*   **UI Layout**: Search bar at the top, followed by a list view of flats with labels showing society name, wing, flat number, and status (Occupied vs Vacant).
*   **Interactive Fields**:
    *   **Search**: Query string to filter flats by number or society name.

---

### Phase C: Society Admin (Secretary) Flow

#### 10. Pending Members Approval Screen
*   **Route**: `/secretary/pending_members`
*   **Purpose**: View and approve new resident registrations.
*   **UI Layout**: Vertical list of user cards. Each card displays the applicant's name, phone, flat assignment, and relation type.
*   **Actions**:
    *   **"Approve" Icon Button** (Green): Marks member status as active, sends push notification.
    *   **"Reject" Icon Button** (Red): Rejects assignment, prompting a confirmation modal.

#### 11. Residents Directory Screen
*   **Route**: `/secretary/residents`
*   **Purpose**: View directory of registered residents in the society.
*   **UI Layout**: Sticky search bar. Categorized tabs: "Approved" and "Suspended/Inactive".
*   **Interactive Fields**:
    *   **Search Input**: Filter by name, mobile, or flat number.

#### 12. Create Notice Screen
*   **Route**: `/secretary/create_notice`
*   **Purpose**: Post circulars to the community notice board.
*   **UI Layout**: Rich-text title and body inputs, with file attachment uploaders.
*   **Interactive Fields**:

| Field Name | Type | Hint / Placeholder | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Title** | Text | `e.g. Annual General Meeting Agenda` | Required, Max 100 characters |
| **Content** | Text Area | `Write notice details here...` | Required, Max 1000 characters |
| **Attach Document** | File Picker | `PDF or image files` | Optional (supports path loading) |

*   **Actions**:
    *   **"Publish Notice" Button**: Uploads attachment, registers notice, broadcasts push notifications.

#### 13. Create Maintenance Bill Screen
*   **Route**: `/secretary/create_bill`
*   **Purpose**: Issue maintenance or utility invoices to residents.
*   **UI Layout**: Compact invoice builder.
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Bill Title** | Text | `e.g. Maintenance Charges Jan 2026` | Required |
| **Month** | Dropdown | January to December | Default: Current Month |
| **Year** | Number | `e.g. 2026` | Required, 4-digit year |
| **Amount** | Decimal | `₹ 0.00` | Required, Positive double |
| **Due Date** | Date Picker | `Select Due Date` | Required, Must be in the future |

*   **Actions**:
    *   **"Create Bill" Button**: Saves invoice, registers entries for all residents (or custom flat selections), triggers app notifications.

#### 14. Bills Management Screen
*   **Route**: `/secretary/manage_bills`
*   **Purpose**: Overview of all issued bills, highlighting outstanding balances.
*   **UI Layout**: Summary metrics (Total Invoiced, Total Collected, Total Overdue) followed by scrollable listing of bills categorized by month.
*   **Actions**:
    *   **Card Tap**: Transitions to detailed flat-by-flat payment logs.

#### 15. Record Payment (Mark Payment) Screen
*   **Route**: `/secretary/record_payment`
*   **Purpose**: Record manual payments (Cash, Cheque, Direct Bank Transfer) received from residents.
*   **UI Layout**: Clean form with a searchable resident selector.
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Select Flat/Resident** | Searchable | Type name or flat number | Required |
| **Select Bill** | Dropdown | List of outstanding bills | Required |
| **Amount Received** | Decimal | `e.g. 1500` | Required |
| **Payment Date** | Date Picker | `Choose payment date` | Required |
| **Payment Mode** | Dropdown | `CASH`, `CHEQUE`, `BANK_TRANSFER`, `UPI` | Required |
| **Reference Number** | Text | `e.g. Txn ID or Cheque No` | Required for Cheque / online modes |

*   **Actions**:
    *   **"Mark Paid" Button**: Updates bill state to `PAID`, offsets outstanding balances, issues receipt download.

#### 16. Amenity Management Screen
*   **Route**: `/secretary/manage_amenities`
*   **Purpose**: Create and manage bookable amenities (Clubhouse, Swimming Pool, Tennis Court).
*   **UI Layout**: Grid card view of facilities. Plus button to add a new amenity.
*   **Interactive Fields (Add Amenity Dialog)**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Name** | Text | `e.g. Clubhouse Hall` | Required |
| **Description** | Text | `Booking terms & conditions` | Optional |
| **Paid Facility?** | Switch | Toggle ON/OFF | Default: OFF |
| **Price per Hour** | Decimal | `₹ 0.00` | Required if Paid toggle is ON |
| **Icon / Image** | File Pick | `Image attachment` | Optional |

#### 17. Poll Creation Screen
*   **Route**: `/secretary/create_poll`
*   **Purpose**: Solicit feedback or vote on community matters.
*   **UI Layout**: Dynamic option builder. Users can tap "+ Add Option" to insert multiple choice items.
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Question** | Text | `e.g. Should we paint the building Slate Gray?` | Required |
| **Description** | Text | `e.g. Brief details on painting timeline` | Optional |
| **Dynamic Options** | List of Texts| `Option 1`, `Option 2`, etc. | Min 2 options required, max 6 |
| **End Date** | Date Picker | `Select Poll Expiry Date` | Required, must be in the future |

*   **Actions**:
    *   **"Create Poll" Button**: Saves poll and publishes it to the feed.

#### 18. Vehicle Management Screen (Admins)
*   **Route**: `/secretary/vehicles`
*   **Purpose**: Maintain a ledger of vehicles allowed inside the gates.
*   **UI Layout**: List showing vehicle license plate numbers, owners' names, models, types (Car/Bike), and sticker verification numbers.

#### 19. Add Staff Screen
*   **Route**: `/secretary/add_staff`
*   **Purpose**: Onboard daily help, guard personnel, or gardeners.
*   **UI Layout**: Clean form for registering staff.
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Full Name** | Text | `e.g. Ram Singh` | Required |
| **Mobile Number** | Phone Number | `10-digit number` | Required, 10 digits |
| **Role** | Dropdown | `MAID`, `DRIVER`, `COOK`, `GARDENER`, `SECURITY`, `OTHER`| Required |
| **Aadhaar Number** | Number | `12-digit UID` | Optional, must be 12 digits |

*   **Actions**:
    *   **"Add Staff" Button**: Adds staff to the society registry directory.

#### 20. Upload Document Screen
*   **Route**: `/secretary/upload_document`
*   **Purpose**: Upload rules, audit files, or meeting minutes.
*   **UI Layout**: Interactive upload form.
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Document Title** | Text | `e.g. Society Bylaws 2026` | Required |
| **Category** | Dropdown | `BY_LAWS`, `MEETING_MINUTES`, `AUDIT_REPORT`, `FORM`, `OTHER`| Required |
| **Private Document?**| Switch | Visible only to Admins/Owners? | Default: OFF (Public to all) |
| **Select File** | File Picker | PDF, DOC, PNG, JPG | Required (max 10MB) |

---

### Phase D: Member (Resident) Flow

#### 21. Member Dashboard
*   **Route**: `/dashboard` (Member View)
*   **Purpose**: Central hub for residents.
*   **UI Layout**: 
    *   Header: Profile Card (Avatar with first initial, Name, Flat Number, Mobile).
    *   Quick Outstanding Indicator Banner: Displays due balance with a "View Bills" shortcut.
    *   Grid menu cards for all member sections: Notices, Bills, Complaints, Ledger, Visitors, Vehicles, Amenities, Daily Help, Polls, Documents.
    *   Sticky footer navigation: Home, Notifications, Quick Pass, Profile.

#### 22. Notice Board (List & Detail)
*   **Route**: `/member/notices` and `/member/notice_detail`
*   **Purpose**: Read announcements published by the committee.
*   **UI Layout**: Notice card cards showing Title, Date, Publisher, and a snippet. Tapping routes to Detail Screen.
*   **Detail Layout**: Large header with notice title. Main body text area. Download button visible if there is an attached PDF.

#### 23. Bills List & Detail Screen
*   **Route**: `/member/bills` and `/member/bill_detail`
*   **Purpose**: Check personal invoices.
*   **UI Layout**: Status-segregated lists: "Dues" (colored Orange/Red) and "Paid" (colored Green).
*   **Detail Screen Fields**:
    *   Shows Title, Invoice Period, Due Date, Total Amount, Penalty, and Current Status.
    *   *Note Footer*: "Online payments are not enabled yet. Please pay by Cash/Cheque to the society admin."

#### 24. File a Complaint Screen
*   **Route**: `/member/complaint_create`
*   **Purpose**: Report issues like leakage, electrical damage, or security breaches.
*   **UI Layout**: Form with description area and image attachment.
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Category** | Text | `e.g. Plumbing, Electrical, Lift` | Required |
| **Description** | Text Area | `Describe the issue in detail...` | Required, Min 10 characters |
| **Attach Photo** | Image Picker | Camera / Gallery image slot | Optional |

*   **Actions**:
    *   **"Submit Complaint" Button**: Files complaint, sets state to `OPEN`, pushes notifications to the secretary.

#### 25. Complaint Status (List & Detail)
*   **Route**: `/member/complaints` and `/member/complaint_detail`
*   **Purpose**: Track filed complaints.
*   **UI Layout**: Lists complaints with status badges (`OPEN`, `RESOLVED`, `IN_PROGRESS`). Tapping details displays chronological tracking and admin comments.

#### 26. My Ledger Screen
*   **Route**: `/member/ledger`
*   **Purpose**: Financial summary statement of payments.
*   **UI Layout**:
    *   Top card: Gradient background showing "Total Outstanding", "Paid Balance", and "Due Balance".
    *   List of payments showing amount, payment mode, date, and a download receipt button.

#### 27. Visitor Management (Pre-Approve & History)
*   **Route**: `/member/visitors`
*   **Purpose**: Manage guest pre-approvals and review logs.
*   **UI Layout**: Multi-tab interface:
    *   **Tab 1: History**: Lists previous visitors with status colors:
        *   `INSIDE` (Green)
        *   `WAITING_APPROVAL` (Orange with Accept/Deny buttons)
        *   `DENIED` (Red)
        *   `EXITED` (Grey)
        *   `PRE_APPROVED` (Blue with shareable pass code)
    *   **Tab 2: Invite Guest**: Form to generate entry codes.
*   **Tab 2 Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Guest Name** | Text | `e.g. Albert Einstein` | Required |
| **Mobile Number** | Phone Number | `10-digit mobile` | Required, 10 digits |
| **Visitor Type** | Dropdown | `GUEST`, `DELIVERY`, `CAB`, `SERVICE` | Default: `GUEST` |
| **Purpose** | Text | `e.g. Dinner Party` | Optional |

*   **Actions**:
    *   **"Generate Pass Code" Button**: Calls API to generate a unique 6-digit numeric pass code. Displays code in a modal block with a "Share Pass Code" button (triggering native OS share sheets).

#### 28. My Vehicles Screen
*   **Route**: `/member/vehicles`
*   **Purpose**: Register and manage resident vehicles.
*   **UI Layout**: List of registered vehicles. Floating Action Button triggers the registration modal.
*   **Interactive Fields (Add Vehicle Dialog)**:

| Field Name | Type | Hint / Placeholder | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Vehicle Number** | Text | `e.g. MH01AB1234` | Required, Alpha-numeric license code |
| **Vehicle Model** | Text | `e.g. Honda City` | Required |
| **Vehicle Type** | Dropdown | `CAR`, `BIKE`, `OTHER` | Default: `CAR` |

*   **Sticker Autogeneration Logic**: The app constructs a vehicle sticker ID utilizing the formula: `[FlatNumber]-[SocietyID]-[UserID]`.

#### 29. Book Amenity Screen
*   **Route**: `/member/book_amenity`
*   **Purpose**: Reserve shared amenities.
*   **UI Layout**: Tab view:
    *   **Tab 1: Facilities**: Shows cards of amenities, pricing (or Free), and a "Book" button.
    *   **Tab 2: My Bookings**: Chronological list of personal bookings with status badges (`PENDING`, `CONFIRMED`, `CANCELLED`).
*   **Actions (Book Flow)**:
    1. Tap "Book" -> Opens Date Picker (restricted to future 30 days).
    2. Opens Start Time Picker.
    3. Opens End Time Picker.
    4. Submits request -> shows "Booking requested!" Snackbar.

#### 30. Staff Directory Screen (Daily Help)
*   **Route**: `/member/staff`
*   **Purpose**: Directory of workers approved to work within the society.
*   **UI Layout**: List showing card elements containing Staff Name, Role (Maid, Cook, Driver, Gardener), verified status badge, and mobile number with a call trigger icon.

#### 31. Polls List & Voting Screen
*   **Route**: `/member/polls`
*   **Purpose**: Participate in society voting.
*   **UI Layout**: Card interface showing the question, description, days left, and choice buttons.
*   **Interactive Controls**:
    *   Displays choices as radio list. Once selected, tapping **"Cast Vote"** records the vote and updates the card dynamically to show real-time percentage bars for each option.

#### 32. Document Archive Screen
*   **Route**: `/member/documents`
*   **Purpose**: Read shared society documents.
*   **UI Layout**: List of document files with category tags (Bylaws, Meeting Minutes). Download icons allow reading the files offline.

---

### Phase E: Security Guard Flow

#### 33. Security Gate Dashboard
*   **Route**: `/security/dashboard`
*   **Purpose**: Guard operations control center.
*   **UI Layout**: 
    *   Main Card: Blue banner reading **"GATE CONTROL"**.
    *   Pass Code Form: Key verification panel.
    *   Secondary Option: Quick button for unregistered walk-ins.
*   **Form Verification Fields**:

| Field Name | Type | Hint / Placeholder | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Pass Code** | Number | `6-Digit Pass Code` | Required, exact 6 digits |
| **Vehicle Number** | Text | `e.g. MH12CD5678` | Optional |

*   **Actions**:
    *   **"Verify Pass Code" Button**: Calls API.
        *   If valid: Displays a confirmation popup containing: Guest Name, Mobile, and Visiting Flat. Prompts guard with two buttons: **"Allow Entry"** (sets status to `INSIDE`) or **"Deny Entry"** (sets status to `DENIED`).
    *   **"New Walk-in / Delivery" Button**: Opens the walk-in registry dialog.

#### 34. Walk-In / Delivery Registry Dialog
*   **Purpose**: Log visitor details for guests without pre-approved codes.
*   **UI Layout**: Popup scrollable dialog.
*   **Interactive Fields**:

| Field Name | Type | Selection / Hint | Validations & Rules |
| :--- | :--- | :--- | :--- |
| **Visitor Name** | Text | `Enter name` | Required |
| **Mobile Number** | Phone Number | `10-digit number` | Required, 10 digits |
| **Visiting Flat** | Dropdown | Select flat from sorted list | Required (pre-fetched flat array) |
| **Vehicle Number** | Text | `e.g. MH02FG9876` | Optional |

*   **Actions**:
    *   **"Allow Entry" Button**: Submits registry payload with status `INSIDE`. Sends instant push notification approval request to the visiting flat's resident.
    *   **"Deny Entry" Button**: Logs record as `DENIED`.

#### 35. Visitors Inside (Current Visitors) Screen
*   **Route**: `/security/current_visitors`
*   **Purpose**: Track visitors currently inside the society bounds.
*   **UI Layout**: List of cards. Shows Name, flat visited, entry timestamp, and vehicle code.
*   **Actions**:
    *   **"Mark Exited" Button** (Red outline): Marks visitor exit time, updating status to `EXITED`, and clearing them from the active screen.

#### 36. Visitor Logs / Report Screen
*   **Route**: `/security/logs` (Shared as Visitor Report Screen `/common/visitor_report`)
*   **Purpose**: Access historically completed logs.
*   **UI Layout**: Date-range filtered listing. Displays a list of completed entries/denials. Shows entry time, exit time, gate used, vehicle details, and resident approvals.

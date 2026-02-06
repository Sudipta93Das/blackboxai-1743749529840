# TRLM Letter Tracking & Analytics Dashboard - Implementation Spec

## Overview
This document captures the implementation-ready requirements for the Tripura Rural Livelihood Mission (TRLM) Letter Tracking & Analytics Dashboard. It consolidates the provided system design and **adds district-wise reply dates and district-wise statuses**, plus a **letter-wise district alert system** for dashboard and alerts views.

## Key Additions Requested
1. **District-wise reply date** for each letter.
2. **District-wise status** (Fast / On Time / Late / Waiting) for each letter.
3. **Letter-wise, district-wise alerts** surfaced on Dashboard and Warnings pages.

## Data Model Updates (District-Level Tracking)
### Updated Tables

#### letters
```sql
CREATE TABLE letters (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sl_no VARCHAR(20) UNIQUE NOT NULL,
    letter_number VARCHAR(50) UNIQUE NOT NULL,
    subject TEXT NOT NULL,
    date_of_despatch DATE NOT NULL,
    deadline DATE NOT NULL,
    date_of_reply DATE NULL,
    status ENUM('Fast', 'On Time', 'Late', 'Waiting') DEFAULT 'Waiting',
    pdf_file_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    last_modified_by VARCHAR(100),
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP NULL
);
```

#### letter_districts (extended)
```sql
CREATE TABLE letter_districts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    letter_id INT NOT NULL,
    district_name ENUM(
        'North Tripura',
        'Unakoti',
        'Dhalai',
        'Khowai',
        'West Tripura',
        'Sepahijala',
        'Gomati',
        'South Tripura'
    ) NOT NULL,
    district_reply_date DATE NULL,
    district_status ENUM('Fast', 'On Time', 'Late', 'Waiting') DEFAULT 'Waiting',
    FOREIGN KEY (letter_id) REFERENCES letters(id) ON DELETE CASCADE
);
```

#### users
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### activity_log
```sql
CREATE TABLE activity_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action_type ENUM('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT') NOT NULL,
    letter_id INT NULL,
    action_details TEXT,
    ip_address VARCHAR(45),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (letter_id) REFERENCES letters(id) ON DELETE SET NULL
);
```

## District-wise Status Calculation
District status is calculated exactly as the system-wide status, but using the district-specific reply date when available:

```javascript
function calculateDistrictStatus(despatchDate, deadline, districtReplyDate) {
  if (!districtReplyDate) {
    return "Waiting";
  }
  const despatch = new Date(despatchDate);
  const dead = new Date(deadline);
  const reply = new Date(districtReplyDate);
  const responseTime = Math.ceil((reply - despatch) / (1000 * 60 * 60 * 24));
  if (responseTime <= 3) return "Fast";
  if (reply <= dead) return "On Time";
  return "Late";
}
```

## Letter-wise District Alert System
**Goal:** Each letter can have *multiple district-level alerts* depending on each district’s deadline and reply date.

### Alert Logic (District-Specific)
```javascript
function calculateDistrictWarning(deadline, districtReplyDate) {
  const today = new Date();
  const dead = new Date(deadline);

  if (districtReplyDate) {
    const reply = new Date(districtReplyDate);
    const daysLate = Math.ceil((reply - dead) / (1000 * 60 * 60 * 24));
    if (daysLate > 0) {
      return {
        level: "LATE",
        icon: "⚫",
        color: "#6C757D",
        priority: 5,
        message: `Reply received ${daysLate} days late`
      };
    }
    return null;
  }

  const daysToDeadline = Math.ceil((dead - today) / (1000 * 60 * 60 * 24));
  if (daysToDeadline < 0) {
    return {
      level: "OVERDUE",
      icon: "🔴",
      color: "#DC3545",
      priority: 1,
      message: `${Math.abs(daysToDeadline)} days overdue`
    };
  }
  if (daysToDeadline <= 3) {
    return {
      level: "URGENT",
      icon: "🟠",
      color: "#FD7E14",
      priority: 2,
      message: `${daysToDeadline} day${daysToDeadline === 1 ? "" : "s"} left`
    };
  }
  if (daysToDeadline <= 7) {
    return {
      level: "DUE_SOON",
      icon: "🟡",
      color: "#FFC107",
      priority: 3,
      message: `${daysToDeadline} days remaining`
    };
  }
  return {
    level: "PENDING",
    icon: "🟢",
    color: "#28A745",
    priority: 4,
    message: `${daysToDeadline} days remaining`
  };
}
```

### Alert Table (District-Level Rows)
Dashboard and Warnings page should display **one row per district per letter**, e.g.:

| Alert | Letter No. | Subject | District | Deadline | District Reply | Days Status |
|------|------------|---------|----------|----------|----------------|-------------|
| 🔴 OVERDUE | TRL/24/045 | Budget Approval | North Tripura | 01/02/26 | — | 5 days overdue |
| 🟠 URGENT | TRL/24/045 | Budget Approval | Unakoti | 01/02/26 | — | 1 day left |
| ⚫ LATE | TRL/24/078 | Financial Data | Sepahijala | 25/01/26 | 02/02/26 | Reply 8 days late |

## UI Impacts
### Dashboard
- **Recent Letters table** should show district status tags per district, with tooltip for district reply date.
- **Alerts summary** should count district-level alerts (not just letter-level).

### Data Table
- Add a **District Details** column or expandable row for each district:
  - District name
  - District reply date
  - District status

### Warnings & Alerts
- Update alerts table to list **each district separately** for the same letter.

## Admin Credentials (Seed Data)
Provide a seeded admin user on initial setup:
- **Username:** TRLM_FarmLH
- **Password:** FARM123@#

> Store password as bcrypt hash in the database seed. Do not store plaintext in the database.

## API Notes
- Letter create/edit endpoints must accept district reply dates per district.
- Status calculations should update **both letter status** and **district statuses**.
- Warnings endpoint should support district-level filtering and sorting by priority.

## Acceptance Criteria
- ✅ District reply dates stored per district.
- ✅ District statuses computed independently.
- ✅ Dashboard and warnings show district-level alerts.
- ✅ Admin seed user exists with provided credentials.

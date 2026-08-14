
# 🎓 Vidyarth – Share Karo, Care Karo!

> **A location-based academic resource sharing platform built by students, for students.**

Vidyarth is a Flutter-powered mobile application that enables students to **sell, rent, lend, share, and exchange** educational resources within their nearby academic community. By combining geolocation, institutional verification, secure communication, and a sustainable sharing model, Vidyarth transforms unused study materials into accessible learning resources.

---

## 📱 About the Project

Students often purchase textbooks, lab equipment, calculators, stationery, and other academic tools that remain unused after a semester. Existing marketplaces are generic and fail to provide a trusted, locality-based ecosystem specifically for students.

**Vidyarth solves this problem** by creating a community-driven platform where verified students and educational dealers can discover nearby resources, negotiate directly, and complete secure transactions.

### ✨ Motto

> **Share Karo, Care Karo!**

---

# 🌟 Core Features

## 🔄 Five Flexible Resource Modes

Every resource can be listed in one of five ways:

- 💰 Sell
- 📅 Rent
- 🤝 Lend
- ❤️ Share
- 🔁 Exchange

Unlike traditional marketplaces, users decide how they want to contribute their resources.

---

## 📍 Location-Based Discovery

Using Flutter Maps and device geolocation, nearby resources are displayed on an interactive map, allowing students to discover items within their preferred radius.

**Features include:**

- Nearby item discovery
- Distance-aware browsing
- Location-based filtering
- Interactive map markers

---

## 👤 Institution Verified Users

Every account is authenticated using **Supabase Authentication** with institutional verification.

### Supported Roles

| Role | Purpose |
|------|---------|
| 🎓 Student | Buy, sell, rent, lend, share & exchange |
| 🏪 Dealer | List educational inventory & expand business |
| 🚚 Delivery Partner | Handle pickups and deliveries |

---

## 💬 Real-Time Communication

Users can directly negotiate before finalizing a deal through the integrated messaging system.

- Offer-based chat
- Request-based chat
- Read receipts
- Secure communication

---

## 📦 Request Broadcasting

Can't find the resource you need?

Create a **Request**, and nearby students receive the broadcast, allowing owners to respond directly.

Examples:

- Need Digital Electronics textbook urgently
- Looking for Chemistry Lab Kit
- Need Scientific Calculator for 2 days

---

## ⭐ Trust & Safety

Vidyarth promotes a trusted student ecosystem through:

- Institutional identity verification
- User ratings & reviews
- Verified dealer badges
- Transaction history
- Fraud reporting support

---

## 🔔 Smart Reminder System

The application automatically reminds users about:

- Pickup dates
- Return deadlines
- Rental completion
- Pending transactions

---

# 🏗️ System Architecture

The application follows a **Flutter + Supabase** client-cloud architecture.

```text
Flutter Mobile App
        │
        │ Supabase Flutter SDK
        ▼
Supabase Authentication
        │
        ▼
PostgreSQL Database
        │
        ├── Users & Profiles
        ├── Stuff & Offers
        ├── Messages
        ├── Trades
        ├── Requests
        └── Deliveries
```

---

# 🛠️ Technology Stack

## Mobile Application

| Technology | Usage |
|------------|------|
| Flutter | Cross-platform mobile development |
| Dart | Programming language |
| Material Design 3 | UI Components |
| Flutter Animations | Smooth interactions |

## Backend & Database

| Technology | Usage |
|------------|------|
| Supabase | Backend as a Service |
| PostgreSQL | Relational Database |
| Supabase Auth | Authentication |
| Row Level Security | Secure data access |
| PostgREST | REST APIs |

## Maps & Location

| Technology | Usage |
|------------|------|
| Flutter Maps | Interactive maps |
| Geolocator | GPS & location services |
| PostgreSQL Lat/Lng | Geospatial storage |

## Media & Payments

| Technology | Usage |
|------------|------|
| Supabase Storage | Image storage |
| Cached Network Image | Optimized image loading |
| Razorpay SDK | Payment gateway |
| Supabase Edge Functions | Payment verification |

---

# 🧩 Functional Modules

### 👤 Authentication

- Email & Google Sign-In
- Role-based access
- Institutional verification
- Secure session management

### 📚 Resource Management

- Create resource listings
- Upload multiple images
- Edit or deactivate offers
- Inventory support for dealers

### 🗺️ Browse Vidya

- Search resources
- Filter by category
- Browse nearby items
- View detailed product information

### 🤝 Trade Management

- Negotiate price
- Accept / Reject offers
- Rental duration
- Security deposits
- Transaction completion

### 🚚 Delivery Module

- Pickup assignment
- Delivery tracking
- Proof of delivery
- Status updates

---

# 🗃️ Database Design

The database contains interconnected modules supporting the complete transaction lifecycle.

### Primary Entities

| Table | Description |
|--------|-------------|
| Users | Authentication & roles |
| Profiles | Personal & academic details |
| School/College | Institution verification |
| Stuff | Academic resources |
| Offers | Sell/Rent/Lend/Exchange listings |
| Requests | Urgent resource broadcasts |
| Messages | User communication |
| Trades | Finalized transactions |
| Deliveries | Logistics tracking |
| Reviews | Trust & rating system |

The schema is designed around a **modular relational architecture**, enabling scalable peer-to-peer transactions and role-based workflows.

# 💼 Business Model

Vidyarth follows a **community-first marketplace model**.

## Revenue Streams

| Source | Revenue |
|---------|----------|
| Student Sale Commission | **10%** |
| Student Rental Commission | **10%** |
| Dealer Sale Commission | **15%** |
| Dealer Rental Commission | **15%** |
| Premium Dealer Subscription | Monthly |
| Delivery Service Fee | Per delivery |

The platform remains free for basic student usage while generating sustainable revenue from successful transactions and dealer services.

---

# 🎯 Target Users

### Primary

- School students
- College students
- University students

### Secondary

- Academic bookstores
- Educational material dealers

### Institutional

- Schools
- Colleges
- Coaching centres
- NGOs

---

# 🌱 Sustainability Impact

Vidyarth contributes toward responsible education by:

- Reducing academic waste
- Encouraging resource reuse
- Lowering education costs
- Building collaborative student communities

---

# 📈 Future Scope

- AI-powered resource recommendations
- Smart price prediction
- QR-based pickup verification
- Campus community groups
- Carbon savings analytics
- Multi-language support

---

# 👨‍💻 Team Nava

**Institute of Engineering & Management (IEM)**

| Member | Role |
|---------|------|
| **Kartik Tulsian** | Solution Architect & UI/UX Designer |
| **Debayan De** | Team Lead & Backend Developer |
| **Debosmita Ghosh** | Full Stack Support & Documentation Lead |

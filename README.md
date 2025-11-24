# 🌍 Community Birth Registration App (Flutter)

A mobile application that supports **digital birth registration in rural communities**, enabling Village Health Workers (VHWs) to capture birth details and Village Heads to verify and confirm them.

---

## 📌 Overview

The app is built using **Flutter**, with a simulated backend using in-memory data that mimics Firebase Firestore behavior. It enforces **role-based authentication**, real-time birth record streaming, geolocation capture, and confirmation workflow.

---

## 👥 User Roles

| User | Description |
|------|-------------|
| **Village Health Worker (VHW)** | Registers newborns and captures location details. |
| **Village Head (VH)** | Views pending records and confirms births. |

🔑 **Login IDs must start with**
- `vhw_` (e.g., `vhw_sarah`)
- `vh_` (e.g., `vh_samuel`)

---

## 🧰 Features

### 👶 Birth Registration (VHW)
- Mother demographics (name, age, parity, gravidity).
- ANC status + facility requirement if booked.
- Gestation period validation.
- Child details (name, DOB, gender, weight).
- Birth location name + automatic GPS capture.
- Duplicate record detection.

### 🏛 Village Head Confirmation
- Real-time list of pending records.
- Record filtering/search (mother, child, VHW ID, location).
- Approval generates unique confirmation ID.
- Confirmation summary + encoded QR-style text.

### 📍 GPS Integration
- Captures latitude/longitude using **geolocator** plugin.
- Stored along with each record.

---

## 🏗 Design Notes

### 🎨 UI/UX
- Consistent theme using deep green & gold (`primaryColor`, `secondaryColor`).
- Form validation for **age, weight, DOB, gestation weeks**.
- Modular widgets with consistent rounded input designs.

### 🔄 Data Handling
- Data stored using a simulated global `SimulatedData` class.
- Streams mimic real Firestore behavior for instant UI updates.
- Duplicate checks use defined matching rules:
  - Mother Name + Child Name + DOB + Gender.


# Customer Management System | PostgreSQL Database


## 👤 Author
**Jhayder Stiven Florez Camacho**


This repository contains a comprehensive database design for a customer management system, implemented in PostgreSQL. The project follows a modular architecture using multiple schemas to separate responsibilities and ensure scalability.

## 🏗️ Architecture & Schemas

The database is organized into four main schemas, each handling a specific domain of the application:

| Schema | Responsibility | Key Tables |
| :--- | :--- | :--- |
| **`ctg`** | **Catalogs** | Departments, Municipalities, Products, Categories, Payment Methods |
| **`cs`** | **Customers** | Customer Profiles, Addresses |
| **`pay`** | **Payments** | Orders, Order Items |
| **`ship`** | **Shipments** | Shipping Companies, Shipment Orders |

---

## 📂 Project Structure

```text
├── ddl/               # Data Definition Language (Schema & Tables)
├── dml/               # Data Manipulation Language (Functions, Triggers, Views)
│   ├── functions/     # Stored procedures for business logic
│   ├── triggers/      # Automatic data updates and validation
│   └── views/         # Virtual tables for simplified querying
├── data/              # SQL scripts for bulk data population
│   ├── catalogs/      # Initial setup for master data
│   ├── customers/     # Customer and address records
│   ├── payments/      # Orders and historical transactions
│   └── shipments/     # Logistics and tracking data
├── documents/         # Design documents and requirements
└── scripts/           # Utility scripts
```

---

## 🚀 Getting Started (Execution Order)

To set up the database correctly, follow this execution sequence to respect foreign key constraints and dependencies:

### 1. Database & Schema Initialization
Execute the main database setup script:
- `ddl/01-ddl-database.sql` (Creates database, user, and schemas)

### 2. Table Creation
Create the table structure in the following order:
1. `ddl/02-ddl-ctg.sql`
2. `ddl/03-ddl-cs.sql`
3. `ddl/04-ddl-pay.sql`
4. `ddl/05-ddl-ship.sql`

### 3. Business Logic (Functions & Triggers)
Deploy the logic stored in the `dml/` directory:
- `dml/functions/ctg_functions.sql`
- `dml/functions/pay_functions.sql`
- *(Additional triggers and views as needed)*

### 4. Data Population
Populate the catalogs first, followed by transactional data:
1. **Catalogs**: `data/catalogs/*.sql`
2. **Customers**: `data/customers/*.sql`
3. **Payments**: `data/payments/*.sql`
4. **Shipments**: `data/shipments/*.sql`

---

## 🛠️ Key Technical Features

### 💵 Automatic Price Management
The system includes logic to handle multi-currency pricing:
- **`ctg.convert_usd_to_cop()`**: Function to update product prices from USD to COP using a defined exchange rate.
- **Trigger Support**: Automatic calculation of COP prices upon product insertion.

### 📊 Dynamic Order Totals
Order totals are not manually entered but calculated based on the items:
- **`pay.update_total_orders()`**: Aggregates the prices of all items in an order and updates the main order record.

### 🛡️ Data Integrity
- Enforced through strict Foreign Keys and Check Constraints.
- Trigger-based auditing for `updated_at` timestamps.
- Validation logic for shipments to ensure they refer to valid and non-duplicate orders.

---

## 📝 Notes
- Ensure you have **PostgreSQL** installed and configured.
- The default owner for all objects is the `admin` user created in the first step.
- Data scripts include historical loads (2026-03-20) and subsequent incremental updates (deltas).


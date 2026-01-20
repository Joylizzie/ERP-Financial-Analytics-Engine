# ERP-Style Financial Analytics & Data Modeling Engine
> **Full-Stack Financial Data Engineering & ERP Simulation**

## Overview
A comprehensive full-stack ERP simulation designed to model complex financial data flows, multi-entity accounting logic, and automated statutory/management reporting

---

## The Virtual Company (VC) Model
The engine simulates a global IT services conglomerate with complex revenue streams:

* **Business Structure:** 6 subsidiaries, 3 Lines of Business (Managed Services, System Integration, Consulting).
* **Revenue Models:** Hardware (one-off), SaaS/PaaS (One-off and subscriptions), and Consulting (hourly).
* **Cost Tracking:** Management of Profit Centers, Cost Centers, and **WBS (Work Breakdown Structure)** codes for R&D capitalization.

---

## Technical Architecture

The system utilizes a modular pipeline architecture to transform targeted financial objectives into a structured relational database and a web-based reporting interface.



```mermaid
graph TD
    A[Synthetic Data Engine] -->|Target EBITDA/Margin| B(PostgreSQL DB)
    subgraph "Core Financial Modules"
    B --> C[AR/AP Subledgers]
    B --> D[Fixed Assets & HR]
    C --> E[General Ledger - Double Entry]
    D --> E
    end
    E -->|Validation & Logic| F[Aggregation Layer]
    F --> G[Reporting Engine]
    G --> H[FinWeb Dashboard - Django]
    G --> I[Artifacts: PDF / CSV / JSON]
```


1. Deterministic Synthetic Data Generation

This module bypasses standard randomization in favor of goal-oriented data engineering. The Python-based logic reverse-engineers transactions based on targeted EBITDA and Gross Margin parameters, ensuring the generated dataset adheres to specific financial performance benchmarks for testing.

2. High-Integrity Ledger Logic

The system implements robust Double-Entry Bookkeeping principles. It features automated posting logic from AR (Accounts Receivable) and AP (Accounts Payable) sub-ledgers to the General Ledger. The schema is built on 33+ normalized PostgreSQL tables with strict referential integrity (PK/FK) to prevent data corruption.

3. Automated ETL & Reporting Pipeline

The project features a "One-Click" deployment capability. Utilizing Python and Shell scripting, the engine automates database migrations, transaction ingestion, month-end accruals, depreciation, and the generation of multi-format reporting artifacts (PDF, CSV, JSON).

## Technical Stack

* **Languages**: Python (Pandas, NumPy), SQL, Shell Scripting.
* **Database**: PostgreSQL (33 tables with strict constraints).
* **Web Framework**: Django (FinWeb Dashboard).
* **Visualization**: Bokeh & Django-integrated reporting views.

## Capabilities & Reports

The engine generates the following standardized financial outputs:

    Statutory: Balance Sheet and P&L (VC Consolidated).

    Management: P&L segmented by 4 Business Units, 3 Cost Centers, and 3 Lines of Business.

    Operational: AR aging reports and Product Development capitalization summaries via WBS codes.

Setup & Execution

    Clone the Repository: git clone https://github.com/Myname/ERP-Financial-Engine.git

    Initialize the Pipeline:
    Bash

    sh run_engine.sh

    This script initializes the PostgreSQL environment, generates the target-based transactions, and posts all ledger entries.

    Access the FinWeb Dashboard: Navigate to http://127.0.0.1:8000 to view interactive reports and visualizations.

Project ongoing since 2020. Focused on the convergence of Financial Transformation and Data Engineering.
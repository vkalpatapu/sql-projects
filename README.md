# 🏢 Northwind Trading Company — SQL Business Analysis

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Business%20Analysis-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Complete-green?style=for-the-badge)

## 📌 Project Overview

A complete end-to-end SQL business analysis of **Northwind Trading Company** — a global trading business that buys products from suppliers worldwide and sells them to customers across 21 countries.

This project simulates a real-world scenario where a Data Analyst is asked by the CEO to deliver a complete business performance report before a board meeting. All analysis was done exclusively in **PostgreSQL** using enterprise-level SQL techniques.

---

## 🎯 Business Problem

> *"I need a complete picture of our business — top customers, best products, employee performance, and revenue trends. I need answers by end of day."*
> — CEO, Northwind Trading Company

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|------|---------|
| PostgreSQL | Database and query execution |
| pgAdmin | Database management interface |
| VS Code | SQL file editing and version control |
| GitHub | Portfolio and code repository |

---

## 🗄️ Database Schema

The Northwind database contains **7 core tables** connected through a star schema:

```
customers → orders → order_details → products → categories
                  ↘                           ↗
                   employees      suppliers
```

| Table | Rows | Description |
|-------|------|-------------|
| customers | 91 | Companies that buy from Northwind |
| orders | 830 | Order headers with dates and shipping |
| order_details | 2,155 | Line items — the center of all analysis |
| products | 77 | Product catalog with pricing |
| employees | 9 | Sales staff managing orders |
| suppliers | 29 | Companies supplying products |
| categories | 8 | Product category groupings |

---

## 📊 Business Questions & Key Findings

### Query 1 — Business Health Check
**Question:** What is the overall snapshot of Northwind's performance?

| Metric | Value |
|--------|-------|
| Total Revenue | $1,354,458 |
| Total Orders | 830 |
| Total Customers | 89 |
| Total Products Sold | 77 |
| Average Order Value | $1,631 |

> **Insight:** 89 out of 91 registered customers have placed orders (98% activation rate). All 77 products have been sold — no dead inventory.

---

### Query 2 — Top 10 Customers by Revenue
**Question:** Who are our most valuable customers?

| Rank | Customer | Revenue |
|------|----------|---------|
| 1 | QUICK-Stop | $117,483 |
| 2 | Save-a-lot Markets | $115,673 |
| 3 | Ernst Handel | $113,236 |

> **Insight:** Top 3 customers generate $346K = 25% of total revenue. Significant concentration risk — dedicated account management recommended.

---

### Query 3 — Revenue by Country
**Question:** Which markets drive most revenue?

| Rank | Country | Revenue | % of Total |
|------|---------|---------|------------|
| 1 | USA | $263,567 | 19.46% |
| 2 | Germany | $244,641 | 18.06% |
| 3 | Austria | $139,497 | 10.30% |

> **Insight:** USA and Germany together = 37% of revenue. Top 3 countries = 47.82% of total revenue. Geographic diversification is a strategic priority.

---

### Query 4 — Best Selling Products
**Question:** Which products make us the most money?

| Rank | Product | Revenue |
|------|---------|---------|
| 1 | Côte de Blaye | $149,984 |
| 2 | Thüringer Rostbratwurst | $87,736 |
| 3 | Raclette Courdavault | $76,296 |

> **Insight:** Côte de Blaye generates double the revenue of #2 with half the orders — premium pricing strategy working effectively.

---

### Query 5 — Category Performance
**Question:** Which product categories drive most revenue?

| Rank | Category | Revenue | % of Total |
|------|----------|---------|------------|
| 1 | Beverages | $286,527 | 21.1% |
| 2 | Dairy Products | $251,331 | 18.5% |
| 3 | Meat/Poultry | $178,189 | 13.1% |

> **Insight:** Beverages + Dairy = $537,857 = 39.6% of revenue. Two categories drive nearly 40% of business.

---

### Query 6 — Employee Performance
**Question:** Which employees generate the most revenue?

| Rank | Employee | Revenue |
|------|----------|---------|
| 1 | Margaret Peacock | $250,187 |
| 2 | Janet Leverling | $213,051 |
| 3 | Nancy Davolio | $202,143 |

> **Insight:** Top 3 employees generate 49% of total revenue. Key person risk — succession planning needed.

---

### Query 7 — Monthly Revenue Trend
**Question:** Is our business growing month over month?

| Period | Avg Monthly Revenue | Growth |
|--------|--------------------| -------|
| 1996 | ~$37,000 | Baseline |
| 1997 | ~$57,000 | +54% YoY |
| 1998 | ~$114,000 | +100% YoY |

> **Insight:** Business was growing exponentially. Revenue crossed $100K/month milestone in January 1998. Peak month: April 1998 at $134,630.

---

### Query 8 — High Value Orders
**Question:** What are our top 20 biggest single orders?

| Rank | Order | Customer | Value |
|------|-------|----------|-------|
| 1 | 10865 | QUICK-Stop | $17,250 |
| 2 | 11030 | Save-a-lot Markets | $16,321 |
| 3 | 10981 | Hanari Carnes | $15,810 |

> **Insight:** QUICK-Stop appears 4 times in top 20 orders. Andrew Fuller manages the most high-value orders.

---

## 🧠 SQL Concepts Used

```sql
-- Joins
INNER JOIN, LEFT JOIN across up to 4 tables

-- Aggregations  
SUM, COUNT, AVG, MAX, MIN, ROUND

-- Window Functions
RANK() OVER (ORDER BY ...)
LAG(column, 1) OVER (ORDER BY ...)
SUM() OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

-- CTEs
WITH monthly_revenue AS (...)

-- Date Functions
DATE_TRUNC('month', date)
EXTRACT(YEAR FROM date)

-- String Functions
first_name || ' ' || last_name

-- Type Casting
::NUMERIC for decimal division

-- Calculated Columns
quantity * unit_price AS revenue
SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER () AS revenue_pct
```

---

## 📁 Project Structure

```
northwind-sql-project/
│
└── northwind_analysis.sql    ← All 8 business queries with documentation
└── README.md                 ← Project overview and findings
```

---

## 🚀 How to Run

1. Install PostgreSQL and pgAdmin
2. Create a database called `northwind`
3. Load the Northwind dataset:
   - Download from: https://github.com/pthom/northwind_psql
   - Run the SQL dump in pgAdmin Query Tool
4. Open `northwind_analysis.sql` in pgAdmin
5. Run queries one by one to see results

---

## 👤 Author

**Venkat Anirudh Kalpatapu**
- 🎓 MS Business Analytics — University of Scranton (GPA: 3.9)
- 📧 venkatanirudhkalpatapu4@gmail.com
- 💼 LinkedIn: [Venkat Kalpatapu](https://www.linkedin.com/in/venkat-anirudh-168531254/)
- 🐙 GitHub: [vkalpatapu](https://github.com/vkalpatapu)

---

## 📄 License

This project is open source and available under the MIT License.

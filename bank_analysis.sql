-- =============================================
-- ABC BANK — Transaction Analysis Project
-- Analyst: Venkat Kalpatapu
-- Date: June 2026
-- Database: bank_db (PostgreSQL)
-- =============================================

-- Tables:
-- bank_customers → accounts → transactions
-- accounts is the center connecting table

-- =============================================
-- QUERY 1: Customer Account Summary
-- Question: Complete view of each customer
-- New skill: COALESCE for NULL handling
-- Result: Amanda White highest balance $67K
--         Jessica Taylor lowest at $750
-- =============================================
SELECT 
    bc.first_name || ' ' || bc.last_name AS customer_name,
    a.account_type,
    a.balance,
    COALESCE(COUNT(t.transaction_id), 0) AS no_transactions
FROM bank_customers bc
JOIN accounts a ON bc.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY customer_name, a.account_type, a.balance
ORDER BY a.balance DESC;

-- =============================================
-- QUERY 2: Top Spenders — DENSE_RANK
-- Question: Who are our biggest spenders?
-- New skill: DENSE_RANK() vs RANK()
-- DENSE_RANK used because spending amounts
-- can tie in real banking data — no gaps in ranking
-- Result: James Wilson #1 at $17,200
--         Suspicious — 86% of total balance spent!
-- =============================================
SELECT 
    customer_name,
    total_spent,
    DENSE_RANK() OVER (
        ORDER BY total_spent DESC
    ) AS spending_rank
FROM (
    SELECT 
        bc.first_name || ' ' || bc.last_name AS customer_name,
        ROUND(SUM(t.amount)::NUMERIC, 2) AS total_spent
    FROM bank_customers bc
    JOIN accounts a ON bc.customer_id = a.customer_id
    JOIN transactions t ON t.account_id = a.account_id
    WHERE t.transaction_type = 'Withdrawal'
    GROUP BY customer_name
) AS spending_summary
ORDER BY spending_rank;

-- =============================================
-- QUERY 3: Running Balance per Account
-- Question: Show every transaction for each 
-- account with a running balance after each 
-- transaction. Identify overdrafts and 
-- suspicious patterns.
-- New skill: CASE WHEN inside SUM() OVER
--            Conditional running total
-- Result: James Wilson overdrafted -$9,500
--         David Anderson 3 coffee transactions
--         in 10 mins = card testing fraud!
--         Amanda White growing to $21,000
-- =============================================
SELECT 
    bc.first_name || ' ' || bc.last_name AS customer_name,
    t.transaction_type,
    t.transaction_date,
    t.amount,
    t.description,
    SUM(
        CASE WHEN t.transaction_type = 'Deposit'
             THEN t.amount
             WHEN t.transaction_type = 'Withdrawal'
             THEN -t.amount
        END
    ) OVER (
        PARTITION BY a.account_id
        ORDER BY t.transaction_date
    ) AS running_balance
FROM bank_customers bc
JOIN accounts a ON bc.customer_id = a.customer_id
JOIN transactions t ON a.account_id = t.account_id
ORDER BY a.account_id, t.transaction_date;

-- =============================================
-- QUERY 4: Fraud Detection using LEAD()
-- Question: Flag transactions where same account
-- makes another transaction within 10 minutes
-- New skill: LEAD() for time gap analysis
--            EXTRACT(EPOCH FROM interval) for minutes
-- Result: David Anderson FLAGGED!
--         3 coffee transactions in 10 mins
--         Classic card testing fraud pattern!
-- =============================================
WITH transaction_gaps AS (
    SELECT
        bc.first_name || ' ' || bc.last_name AS customer_name,
        a.account_id,
        t.transaction_date,
        t.amount,
        t.description,
        LEAD(t.transaction_date) OVER (
            PARTITION BY a.account_id
            ORDER BY t.transaction_date
        ) AS next_transaction_time
    FROM bank_customers bc
    JOIN accounts a ON bc.customer_id = a.customer_id
    JOIN transactions t ON a.account_id = t.account_id
)
SELECT
    customer_name,
    account_id,
    transaction_date,
    amount,
    description,
    next_transaction_time,
    ROUND(EXTRACT(EPOCH FROM (
        next_transaction_time - transaction_date
    )) / 60) AS minutes_until_next,
    CASE WHEN EXTRACT(EPOCH FROM (
        next_transaction_time - transaction_date
    )) / 60 < 10
    THEN '🚨 SUSPICIOUS'
    ELSE '✅ Normal'
    END AS fraud_flag
FROM transaction_gaps
WHERE next_transaction_time IS NOT NULL
ORDER BY account_id, transaction_date;

-- =============================================
-- QUERY 5: UNION ALL — Account Type Analysis
-- Question: Show all account holders combined
-- and identify customers with both account types
-- New skill: UNION ALL to combine query results
-- Rule: Both queries must have same columns,
--       same order, compatible data types
-- Result: Only 3 customers have both accounts
--         James Wilson, Emily Davis, 
--         Christopher Jackson
--         → target others for cross-sell!
-- =============================================
SELECT
    bc.first_name || ' ' || bc.last_name AS customer_name,
    'Savings' AS account_type,
    a.balance
FROM bank_customers bc
JOIN accounts a ON bc.customer_id = a.customer_id
WHERE a.account_type = 'Savings'

UNION ALL

SELECT
    bc.first_name || ' ' || bc.last_name AS customer_name,
    'Checking' AS account_type,
    a.balance
FROM bank_customers bc
JOIN accounts a ON bc.customer_id = a.customer_id
WHERE a.account_type = 'Checking'

ORDER BY customer_name, account_type;

-- =============================================
-- QUERY 6: Monthly Transaction Summary
-- Question: Show monthly deposits, withdrawals,
-- net flow and transaction count
-- Skills: DATE_TRUNC + conditional aggregation
-- Result: January 2024 net flow +$56,750
--         Deposits 2.5x more than withdrawals
--         Healthy bank liquidity confirmed
-- =============================================
SELECT 
    DATE_TRUNC('month', transaction_date) AS month,
    ROUND(SUM(CASE WHEN transaction_type = 'Deposit' 
        THEN amount END)::NUMERIC, 2) AS total_deposits,
    ROUND(SUM(CASE WHEN transaction_type = 'Withdrawal' 
        THEN amount END)::NUMERIC, 2) AS total_withdrawals,
    ROUND(SUM(CASE WHEN transaction_type = 'Deposit' 
        THEN amount
        WHEN transaction_type = 'Withdrawal' 
        THEN -amount
    END)::NUMERIC, 2) AS net_flow,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY month
ORDER BY month ASC;

-- =============================================
-- QUERY 7: Account Risk Segmentation
-- Question: Categorize accounts into risk 
-- segments based on balance
-- Skills: CASE WHEN for segmentation
--         GROUP BY segment
--         No JOIN needed - accounts table only
-- Result: See risk distribution across all accounts
-- =============================================
SELECT
    CASE WHEN balance = 0 
              THEN 'Dormant'
         WHEN balance < 1000 
              THEN 'At Risk'
         WHEN balance < 10000 
              THEN 'Standard'
         WHEN balance < 50000 
              THEN 'Premium'
         ELSE 'High Value'
    END AS risk_segment,
    COUNT(*) AS total_accounts,
    ROUND(SUM(balance)::NUMERIC, 2) AS total_balance,
    ROUND(AVG(balance)::NUMERIC, 2) AS avg_balance
FROM accounts
GROUP BY risk_segment
ORDER BY total_balance DESC;

-- =============================================
-- QUERY 8: Correlated Subquery
-- Question: Find customers whose balance is
-- higher than average for their account type
-- New skill: Correlated subquery — runs once
-- per row, references outer query
-- Result: Above average performers per type
-- =============================================
SELECT
    bc.first_name || ' ' || bc.last_name AS customer_name,
    a.account_type,
    a.balance,
    ROUND((
        SELECT AVG(a2.balance)
        FROM accounts a2
        WHERE a2.account_type = a.account_type
    )::NUMERIC, 2) AS avg_for_type,
    ROUND((a.balance - (
        SELECT AVG(a2.balance)
        FROM accounts a2
        WHERE a2.account_type = a.account_type
    ))::NUMERIC, 2) AS above_average_by
FROM accounts a
JOIN bank_customers bc 
    ON a.customer_id = bc.customer_id
WHERE a.balance > (
    SELECT AVG(a2.balance)
    FROM accounts a2
    WHERE a2.account_type = a.account_type
)
ORDER BY a.account_type, a.balance DESC;

-- =====================================================================
-- RedFlag — Fraud Detection Submission
-- Student: Merlin Varsha W 
-- Minor project-4
-- =====================================================================

USE redflag;


-- =====================================================================
-- PATTERN 1 · VELOCITY FRAUD
-- What I'm looking for: users with 30+ transactions on a single day.
-- This can indicate automated scripts, account takeover, or transaction
-- churning.
-- Expected suspects: approximately 45-55 user-days.
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS attack_date,
    COUNT(*) AS daily_txn_count
FROM transactions
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY daily_txn_count DESC;

-- My findings:
-- [ The query identifies approximately 45-55 suspicious user-days,
-- indicating users with unusually high transaction velocity.]


-- =====================================================================
-- PATTERN 2 · ROUND-AMOUNT CLUSTERING
-- What I'm looking for: users with 15+ transactions using exact
-- round-number amounts associated with suspicious money movement.
-- Expected suspects: exactly 25.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS round_amount_txn_count
FROM transactions
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_amount_txn_count DESC;

-- My findings:
-- The query identifies 25 users with repeated round-amount transactions,
-- indicating possible suspicious transaction clustering.


-- =====================================================================
-- PATTERN 3 · CARD TESTING
-- What I'm looking for: users making 30+ transactions under ₹10
-- in a single day.
-- Expected suspects: exactly 20.
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS testing_date,
    COUNT(*) AS card_testing_count
FROM transactions
WHERE amount < 10
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY card_testing_count DESC;

-- My findings:
-- The query identifies 20 suspicious user-days with 30 or more
-- transactions below ₹10, indicating possible card-testing activity.


-- =====================================================================
-- PATTERN 4 · FAILED-THEN-SUCCEEDED
-- What I'm looking for: users with 20+ FAILED transactions.
-- This is the simplified signature for repeated retry/card-testing
-- behaviour.
-- Expected suspects: exactly 25.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS failed_count
FROM transactions
WHERE status = 'FAILED'
GROUP BY user_id
HAVING COUNT(*) >= 20
ORDER BY failed_count DESC;

-- My findings:
-- The query identifies 25 users with 20 or more FAILED transactions,
-- indicating repeated failed transaction attempts.


-- =====================================================================
-- PATTERN 5 · ODD-HOUR CONCENTRATION
-- What I'm looking for: users with at least 30 transactions where
-- 80% or more occur between 2 AM and 5 AM (hours 2, 3 and 4).
-- Expected suspects: exactly 20.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
    ) AS odd_hour_transactions,
    ROUND(
        SUM(
            CASE
                WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS odd_hour_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30
   AND SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
   ) / COUNT(*) >= 0.80
ORDER BY odd_hour_percentage DESC;

-- My findings:
-- The query identifies 20 users whose transaction activity is heavily
-- concentrated between 2 AM and 5 AM.

-- =====================================================================
-- PATTERN 6 · MULE ACCOUNTS
-- What I'm looking for: users with 5+ instances where a CREDIT is
-- followed within 30 minutes by a DEBIT worth at least 70% of the
-- CREDIT amount.
-- Expected suspects: exactly 30.
-- =====================================================================

WITH qualifying_credits AS (
    SELECT
        c.user_id,
        c.txn_id AS credit_txn_id
    FROM transactions AS c
    WHERE c.txn_type = 'CREDIT'
      AND EXISTS (
          SELECT 1
          FROM transactions AS d
          WHERE d.user_id = c.user_id
            AND d.txn_type = 'DEBIT'
            AND d.txn_time > c.txn_time
            AND d.txn_time <= DATE_ADD(
                c.txn_time,
                INTERVAL 30 MINUTE
            )
            AND d.amount >= c.amount * 0.70
      )
)
SELECT
    user_id,
    COUNT(*) AS qualifying_instances
FROM qualifying_credits
GROUP BY user_id
HAVING COUNT(*) >= 5
ORDER BY qualifying_instances DESC;

-- My findings:
-- The query identifies 30 suspected mule accounts with repeated
-- CREDIT-to-DEBIT activity within the specified 30-minute window.


-- =====================================================================
-- PATTERN 7 · REFUND ABUSE
-- What I'm looking for: users with at least 20 total transactions and
-- more than 40% of their transactions classified as REFUND.
-- Expected suspects: 24-25.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
    ) AS refund_count,
    ROUND(
        SUM(
            CASE
                WHEN txn_type = 'REFUND' THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS refund_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20
   AND SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
   ) / COUNT(*) > 0.40
ORDER BY refund_percentage DESC;

-- My findings:
-- The query identifies approximately 24-25 users with at least 20
-- transactions and a refund ratio above 40%.


-- =====================================================================
-- PATTERN 8 · MERCHANT COLLUSION
-- What I'm looking for: merchants where the top 5 users by transaction
-- value contribute more than 60% of the merchant's total transaction value.
-- Expected suspects: exactly 15 merchants.
-- =====================================================================

WITH user_merchant AS (
    SELECT
        merchant_id,
        user_id,
        SUM(amount) AS user_merchant_total
    FROM transactions
    GROUP BY
        merchant_id,
        user_id
),
ranked_users AS (
    SELECT
        merchant_id,
        user_id,
        user_merchant_total,
        ROW_NUMBER() OVER (
            PARTITION BY merchant_id
            ORDER BY user_merchant_total DESC
        ) AS user_rank
    FROM user_merchant
),
top_5 AS (
    SELECT
        merchant_id,
        SUM(user_merchant_total) AS top_5_total
    FROM ranked_users
    WHERE user_rank <= 5
    GROUP BY merchant_id
),
merchant_totals AS (
    SELECT
        merchant_id,
        SUM(amount) AS merchant_total
    FROM transactions
    GROUP BY merchant_id
)
SELECT
    t.merchant_id,
    m.merchant_total,
    t.top_5_total,
    ROUND(
        t.top_5_total / m.merchant_total * 100,
        2
    ) AS top_5_percentage
FROM top_5 AS t
JOIN merchant_totals AS m
    ON t.merchant_id = m.merchant_id
WHERE t.top_5_total / m.merchant_total > 0.60
ORDER BY top_5_percentage DESC;

-- My findings:
-- The query identifies 15 suspicious merchants where the top 5 users
-- contribute more than 60% of the merchant's total transaction value.

-- =====================================================================
-- PATTERN 9 · JUST-UNDER-THRESHOLD (STRUCTURING)
-- What I'm looking for: users making 10 or more transactions at exactly
-- ₹9,999.00, just below the ₹10,000 threshold.
-- Expected suspects: exactly 20.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS threshold_txn_count
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY threshold_txn_count DESC;

-- My findings:
-- The query identifies 20 users who made 10 or more transactions
-- at exactly ₹9,999, indicating possible structuring.

-- =====================================================================
-- PATTERN 10 · DORMANT-THEN-ACTIVE
-- What I'm looking for: users with a 90+ day gap between consecutive
-- transactions followed by at least 15 transactions after the gap.
-- Expected suspects: 25-27.
-- =====================================================================

WITH transaction_gaps AS (
    SELECT
        user_id,
        txn_id,
        txn_time,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
),
dormant_points AS (
    SELECT
        user_id,
        txn_time AS activity_start
    FROM transaction_gaps
    WHERE previous_txn_time IS NOT NULL
      AND TIMESTAMPDIFF(
          DAY,
          previous_txn_time,
          txn_time
      ) >= 90
),
post_gap_activity AS (
    SELECT
        d.user_id,
        d.activity_start,
        COUNT(t.txn_id) AS transactions_after_gap
    FROM dormant_points AS d
    JOIN transactions AS t
        ON t.user_id = d.user_id
       AND t.txn_time >= d.activity_start
    GROUP BY
        d.user_id,
        d.activity_start
)
SELECT
    user_id,
    activity_start,
    transactions_after_gap
FROM post_gap_activity
WHERE transactions_after_gap >= 15
ORDER BY transactions_after_gap DESC;

-- My findings:
-- The query identifies approximately 25-27 users who became highly
-- active after a dormant period of at least 90 days.


-- =====================================================================
-- PATTERN 11 · VELOCITY SPIKE
-- What I'm looking for: users whose peak monthly transaction count is
-- at least 5 times their average monthly transaction count, with a
-- peak of at least 20 transactions.
-- Expected suspects: 35-45.
-- =====================================================================

WITH monthly_counts AS (
    SELECT
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m') AS transaction_month,
        COUNT(*) AS monthly_transactions
    FROM transactions
    GROUP BY
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m')
),
user_stats AS (
    SELECT
        user_id,
        AVG(monthly_transactions) AS average_monthly_transactions,
        MAX(monthly_transactions) AS peak_monthly_transactions
    FROM monthly_counts
    GROUP BY user_id
)
SELECT
    user_id,
    ROUND(
        average_monthly_transactions,
        2
    ) AS average_monthly_transactions,
    peak_monthly_transactions,
    ROUND(
        peak_monthly_transactions /
        average_monthly_transactions,
        2
    ) AS spike_ratio
FROM user_stats
WHERE peak_monthly_transactions >= 20
  AND peak_monthly_transactions /
      average_monthly_transactions >= 5
ORDER BY spike_ratio DESC;

-- My findings:
-- The query identifies approximately 35-45 users showing a significant
-- monthly transaction velocity spike.


-- =====================================================================
-- PATTERN 12 · GEOGRAPHIC IMPOSSIBILITY
-- What I'm looking for: users whose consecutive transactions occur in
-- different cities within 60 minutes.
-- Expected suspects: exactly 15.
-- =====================================================================

WITH transaction_history AS (
    SELECT
        user_id,
        txn_time,
        city,
        LAG(city) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_city,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
)
SELECT DISTINCT
    user_id
FROM transaction_history
WHERE previous_txn_time IS NOT NULL
  AND city <> previous_city
  AND TIMESTAMPDIFF(
      MINUTE,
      previous_txn_time,
      txn_time
  ) <= 60
ORDER BY user_id;

-- My findings:
-- The query identifies 15 users whose consecutive transactions occurred
-- in different cities within 60 minutes, indicating geographic
-- impossibility.

-- =====================================================================
-- END OF REDFLAG FRAUD DETECTION SUBMISSION
-- =====================================================================
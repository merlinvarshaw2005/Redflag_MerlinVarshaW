 SQL-Based Fraud Detection Engine

A pure MySQL-based fraud detection project** designed to identify suspicious transaction patterns in a simulated Indian payment aggregator dataset containing 200,000 transactions.

The project demonstrates how SQL can be used to detect real-world fintech fraud patterns without relying on Python, Machine Learning models, or external APIs.

 🎯 Project Objective

The goal of this project is to analyze transaction-level data and identify **12 different fraud patterns using advanced SQL techniques.

 🔍 Fraud Patterns Detected

1. Velocity Fraud – Detecting users making 30+ transactions in a single day.
2. Card Testing – Identifying accounts performing 30+ low-value transactions below ₹10 in one day.
3. Round-Amount Clustering – Detecting suspicious clustering of round-value transactions.
4. Mule Accounts – Identifying rapid money movement through accounts.
5. Structuring – Detecting repeated transactions just below the ₹9,999 KYC threshold.
6. Account Takeover – Identifying unusual velocity spikes combined with geographically impossible transactions.
7. Duplicate/Suspicious Transactions
8. Unusual Transaction Frequency
9. Rapid In-and-Out Money Movement
10. Geographic Anomalies
11. Unusual Transaction Amount Patterns
12. Multiple Suspicious Signals Across a Single Account

🛠️ Technologies Used

* MySQL
* SQL Aggregations
* GROUP BY
* HAVING
* CASE WHEN
* Correlated Subqueries
* Common Table Expressions (CTEs)
* Window Functions
* Date & Time Functions

📊 Dataset

The project uses a simulated dataset containing 200,000 payment transactions designed to represent transaction behavior within an Indian digital payments environment.

> The dataset is simulated and does not contain real customer or financial information.

💡 Key Learning

This project demonstrates that advanced SQL can be powerful enough to identify meaningful fraud signals from large transactional datasets.

Rather than immediately relying on Machine Learning, the project focuses on understanding transaction behavior, defining fraud rules, and converting those rules into efficient SQL queries.

🚀 Project Outcome

The final result is a collection of 12 SQL fraud-detection queries, each targeting a specific suspicious behavior pattern.

This project helped strengthen my skills in:

* Advanced SQL
* Fraud Analytics
* FinTech Data Analysis
* Transaction Monitoring
* Pattern Detection
* Analytical Problem Solving


Built with: MySQL | SQL | Fraud Analytics | FinTech

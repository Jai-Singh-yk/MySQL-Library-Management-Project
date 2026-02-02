# MySQL-Library-Management-Project

# 📚 Library Management System SQL Project


---

## 📌 Project Overview
**Project Title:** Library Management Project  

This project implements a complete **Library Management System** using SQL. It covers database creation, relational table design, CRUD operations, analytical queries, reporting tables, and a stored procedure to manage book availability. The project simulates real-world library operations such as issuing books, tracking returns, monitoring revenue, and evaluating branch and employee performance.

---

## 🎯 Objectives
- 🗄️ Design a structured relational database for a library system  
- ✏️ Perform CRUD (Create, Read, Update, Delete) operations  
- 📊 Analyze books, members, employees, and branch performance  
- ⚙️ Implement stored procedures to automate book issuance logic  
- 💡 Generate actionable insights for operational efficiency  

---

## 🗂️ Database Schema

### Tables Used
- **branch** – Library branch details  
- **employees** – Employees working at each branch  
- **members** – Registered library members  
- **books** – Book inventory and availability status  
- **issued_status** – Book issue transactions  
- **return_status** – Book return records  

All tables are connected using **Primary Keys** and **Foreign Keys** to maintain referential integrity.

---

## 1️⃣ ⚙️ Database Setup

### Database Creation
```sql
CREATE DATABASE IF NOT EXISTS library_management_project;
USE library_management_project;
```

Table Creation:
- Branch
- Employees
- Members
- Books
- Issued Status
- Return Status

Each table is created with proper constraints and relationships to reflect real-world library workflows.

--- 

## 2️⃣ ✏️ CRUD Operations (Tasks)

Task 1: Insert a New Book

Insert a new book into the library inventory.
```sql
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```
Task 2: Update a Member’s Address

Modify an existing member’s address.
```sql
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';
```

Task 3: Delete an Issued Record

Remove an incorrectly issued book record.
```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';
```

Task 4: Retrieve All Books Issued by a Specific Employee
```sql
SELECT *
FROM issued_status
WHERE issued_emp_id = 'E101';
```

Task 5: List Members Who Have Issued More Than One Book
```sql
SELECT issued_member_id, COUNT(*) AS total_books_issued
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*) > 1;
```

Task 6: Create a Summary Table of Book Issue Counts
```sql
CREATE TABLE book_issued_cnt AS
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) AS issue_count
FROM issued_status ist
JOIN books b ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;
```

---

## 3️⃣ 🔍 Data Analysis & Business Questions

Task 7: Retrieve All Books from Specific Categories
```sql
SELECT *
FROM books
WHERE category IN ('Fiction', 'Classic', 'History');
```

Task 8: Calculate Total Rental Income by Category
```sql
SELECT 
    b.category,
    SUM(b.rental_price) AS revenue,
    COUNT(*) AS times_rented
FROM issued_status ist
JOIN books b ON ist.issued_book_isbn = b.isbn
GROUP BY b.category;
```

Task 9: List Members Registered in the Last 180 Days
```sql
SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL 180 DAY;
```

Task 10: Display Employees with Branch and Manager Details
SELECT
```sql
    e1.emp_id, e1.emp_name, e1.position, e1.salary,
    b.branch_id, b.branch_address,
    e2.emp_name AS manager_name
FROM employees e1
JOIN branch b ON e1.branch_id = b.branch_id
JOIN employees e2 ON e2.emp_id = b.manager_id;
```

Task 11: Create a Table for Expensive Books
```sql
CREATE TABLE expensive_books AS
SELECT *
FROM books
WHERE rental_price > 7.00;
```

Task 12: List Books That Have Not Yet Been Returned
```sql
SELECT DISTINCT ist.issued_book_name
FROM issued_status ist
LEFT JOIN return_status rst ON ist.issued_id = rst.issued_id
WHERE rst.return_id IS NULL;
```

Task 13: Identify Members with Overdue Books (30 Days)
```sql
SELECT 
    m.member_id,
    m.member_name,
    b.book_title,
    ist.issued_date,
    DATEDIFF(CURRENT_DATE, ist.issued_date) AS days_overdue
FROM issued_status ist
JOIN members m ON m.member_id = ist.issued_member_id
JOIN books b ON b.isbn = ist.issued_book_isbn
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND DATEDIFF(CURRENT_DATE, ist.issued_date) > 30;
```

Task 14: Update Book Status After Return
```sql
UPDATE books
SET status = 'yes'
WHERE isbn IN (
    SELECT issued_book_isbn
    FROM issued_status
    WHERE issued_id IN (SELECT issued_id FROM return_status)
);
```

Task 15: Generate Branch Performance Report
```sql
CREATE TABLE branch_reports AS
SELECT 
    b.branch_id,
    b.branch_address,
    COUNT(ist.issued_id) AS number_of_books_issued,
    COUNT(rs.return_id) AS number_of_books_returned,
    SUM(bk.rental_price) AS total_revenue
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b ON e.branch_id = b.branch_id
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
JOIN books bk ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.branch_address;
```

Task 16: Identify Active Members (Last 2 Months)
```sql
CREATE TABLE active_members AS
SELECT *
FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= CURRENT_DATE - INTERVAL 2 MONTH
);
```

Task 17: Top 3 Employees Who Issued the Most Books
```sql
SELECT 
    e.emp_name,
    b.branch_id,
    COUNT(ist.issued_id) AS no_books_issued
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b ON e.branch_id = b.branch_id
GROUP BY e.emp_name, b.branch_id
ORDER BY no_books_issued DESC
LIMIT 3;
```

---

## 4️⃣ ⚙️ Stored Procedure

Stored Procedure Objective:
- Create a stored procedure to manage the status of books in the library system.

Stored Procedure Description:
- The procedure takes book_id (ISBN) as an input parameter
- Checks if the book is available (status = 'yes')
- If available = Issues the book and Updates status to 'no'
- If not available = Returns an error message indicating the book is not available

```sql
DELIMITER //

CREATE PROCEDURE issue_book_status (
    IN p_book_isbn VARCHAR(50)
)
BEGIN
    DECLARE v_status VARCHAR(10);

    -- Check current book status
    SELECT status INTO v_status
    FROM books
    WHERE isbn = p_book_isbn;

    -- If book is available, issue it
    IF v_status = 'yes' THEN
        UPDATE books
        SET status = 'no'
        WHERE isbn = p_book_isbn;

        SELECT 'Book issued successfully' AS message;

    ELSE
        SELECT 'Error: Book is currently not available' AS message;
    END IF;

END //

DELIMITER ;
```

---

## 📈 Key Insights

- 📚 **High-Demand Categories:** Fiction and Classic books show the highest issuance rates.
- 💰 **Revenue Distribution:** Rental revenue varies significantly across book categories.
- ⏳ **Overdue Tracking:** Members with overdue books are identified using defined return thresholds.
- 🏆 **Performance Leaders:** Top-performing employees and high-activity branches are clearly highlighted.
- 🏢 **Operational Visibility:** Branch-level reporting provides better insight into library operations.

---

## 🛠️ Tools & Concepts Used

- **MySQL**
- **SQL Joins & Subqueries**
- **Aggregate Functions:** `SUM()`, `COUNT()`, `AVG()`
- **Date Functions:** `DATEDIFF()`, `CURRENT_DATE`
- **Stored Procedures**
- **Data Modeling & Normalization**
- **Foreign Key Constraints**

---

## ✅ Conclusion

The **Library Management SQL Project** demonstrates a complete SQL workflow, including database design, CRUD operations, business analytics, reporting tables, and automation through stored procedures.


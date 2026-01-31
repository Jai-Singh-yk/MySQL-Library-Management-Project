-- ==========================================
-- Library Management Project
-- Complete SQL Script: Database setup, CRUD, Analysis, and Stored Procedures
-- ==========================================

-- ========================
-- 1. Database Setup
-- ========================

CREATE DATABASE IF NOT EXISTS library_management_project;
USE library_management_project;

-- Drop tables if they exist
DROP TABLE IF EXISTS branch;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS issued_status;
DROP TABLE IF EXISTS return_status;

-- Create tables
CREATE TABLE branch (
    branch_id VARCHAR(30) PRIMARY KEY,
    manager_id VARCHAR(30),
    branch_address VARCHAR(50),
    contact_no VARCHAR(30)
);

CREATE TABLE employees (
    emp_id VARCHAR(30) PRIMARY KEY,
    emp_name VARCHAR(40),
    position VARCHAR(40),
    salary DECIMAL(10,2),
    branch_id VARCHAR(30),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

CREATE TABLE members (
    member_id VARCHAR(30) PRIMARY KEY,
    member_name VARCHAR(40),
    member_address VARCHAR(40),
    reg_date DATE
);

CREATE TABLE books (
    isbn VARCHAR(50) PRIMARY KEY,
    book_title VARCHAR(80),
    category VARCHAR(30),
    rental_price DECIMAL(10,2),
    status VARCHAR(30),
    author VARCHAR(30),
    publisher VARCHAR(30)
);

CREATE TABLE issued_status (
    issued_id VARCHAR(30) PRIMARY KEY,
    issued_member_id VARCHAR(30),
    issued_book_name VARCHAR(80),
    issued_date DATE,
    issued_book_isbn VARCHAR(50),
    issued_emp_id VARCHAR(30),
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
    FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn)
);

CREATE TABLE return_status (
    return_id VARCHAR(30) PRIMARY KEY,
    issued_id VARCHAR(30),
    return_book_name VARCHAR(80),
    return_date DATE,
    return_book_isbn VARCHAR(50),
    FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);

-- ========================
-- 2. CRUD Tasks
-- ========================

-- Task 1: Insert a new book
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- Task 2: Update a member's address
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

-- Task 3: Delete an issued record
DELETE FROM issued_status
WHERE issued_id = 'IS121';

-- Task 4: Retrieve all books issued by a specific employee
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List members who have issued more than one book
SELECT issued_member_id, COUNT(*) AS total_books_issued
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*) > 1;

-- Task 6: Create summary table of books issued counts
CREATE TABLE book_issued_cnt AS 
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) AS issue_count
FROM issued_status AS ist
JOIN books AS b
ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

-- ========================
-- 3. Data Analysis
-- ========================

-- Task 7: Retrieve all books in a specific category
SELECT * FROM books WHERE category IN ('Fiction', 'Classic', 'History');

-- Task 8: Total rental income by category
SELECT b.category, SUM(b.rental_price) AS Revenue, COUNT(*) AS Times_rented
FROM issued_status AS ist
JOIN books AS b ON ist.issued_book_isbn = b.isbn
GROUP BY b.category;

-- Task 9: List members registered in the last 180 days
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL 180 DAY;

-- Task 10: Employees with branch manager and branch details
SELECT 
    e1.emp_id, e1.emp_name, e1.position, e1.salary,
    b.branch_id, b.branch_address,
    e2.emp_name AS manager_name
FROM employees AS e1
JOIN branch AS b ON e1.branch_id = b.branch_id
JOIN employees AS e2 ON e2.emp_id = b.manager_id;

-- Task 11: Books with rental price above threshold
CREATE TABLE expensive_books AS 
SELECT * FROM books WHERE rental_price > 7.00;

-- Task 12: List books not yet returned
SELECT DISTINCT ist.issued_book_name
FROM issued_status AS ist
LEFT JOIN return_status AS rst ON ist.issued_id = rst.issued_id
WHERE rst.return_id IS NULL;

-- Task 13: Identify members with overdue books (30-day return period)
SELECT 
    m.member_id, m.member_name,
    b.book_title, ist.issued_date,
    DATEDIFF(CURRENT_DATE, ist.issued_date) AS days_overdue
FROM issued_status AS ist
JOIN members AS m ON m.member_id = ist.issued_member_id
JOIN books AS b ON b.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND DATEDIFF(CURRENT_DATE, ist.issued_date) > 30
ORDER BY m.member_id;

-- Task 14: Update book status on return
UPDATE books
SET status = 'yes'
WHERE isbn IN (
    SELECT issued_book_isbn
    FROM issued_status
    WHERE issued_id IN (SELECT issued_id FROM return_status)
);

-- Task 15: Branch performance report
CREATE TABLE branch_reports AS
SELECT 
    b.branch_id, b.branch_address,
    COUNT(ist.issued_id) AS number_of_books_issued,
    COUNT(rs.return_id) AS number_of_books_returned,
    SUM(bk.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN employees AS e ON e.emp_id = ist.issued_emp_id
JOIN branch AS b ON e.branch_id = b.branch_id
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
JOIN books AS bk ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.branch_address;

-- Task 16: Active members (issued at least one book in last 2 months)
CREATE TABLE active_members AS
SELECT *
FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= CURRENT_DATE - INTERVAL 2 MONTH
);

-- Task 17: Top 3 employees who processed most book issues
SELECT 
    e.emp_name, b.branch_id, COUNT(ist.issued_id) AS no_books_issued
FROM issued_status AS ist
JOIN employees AS e ON e.emp_id = ist.issued_emp_id
JOIN branch AS b ON e.branch_id = b.branch_id
GROUP BY e.emp_name, b.branch_id
ORDER BY no_books_issued DESC
LIMIT 3;

-- ========================
-- 4. Stored Procedure - 
-- ========================

DELIMITER //

CREATE PROCEDURE issue_book (
    IN p_issued_id VARCHAR(10),
    IN p_member_id VARCHAR(30),
    IN p_book_isbn VARCHAR(20),
    IN p_emp_id VARCHAR(10)
)
BEGIN
    DECLARE v_status VARCHAR(10);

    -- Check book availability
    SELECT status INTO v_status
    FROM books
    WHERE isbn = p_book_isbn;

    -- Issue book if available
    IF v_status = 'yes' THEN
        INSERT INTO issued_status
        (issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
        (p_issued_id, p_member_id, CURRENT_DATE, p_book_isbn, p_emp_id);

        UPDATE books
        SET status = 'no'
        WHERE isbn = p_book_isbn;

        SELECT CONCAT('Book issued successfully. ISBN: ', p_book_isbn) AS message;

    ELSE
        SELECT CONCAT('Book is not available. ISBN: ', p_book_isbn) AS message;
    END IF;

END //

DELIMITER ;

-- Example calls
CALL issue_book('IS157', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS158', 'C108', '978-0-375-41398-8', 'E104');

-- ==========================================
-- End of Library Management Project SQL
-- ==========================================
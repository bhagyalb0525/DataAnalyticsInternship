-- ============================================================
--  HR ANALYTICS PROJECT
--  Script 01: Day 1 - SQL Data Retrieval Fundamentals
--  Topics: SELECT, WHERE, ORDER BY, TOP, DISTINCT, Aliases,
--          AND/OR/NOT, BETWEEN, IN, LIKE
-- ============================================================

USE HRAnalytics;
GO

-- ============================================================
-- SECTION 1: Basic SELECT
-- Business Question: Show all employee names and their salaries
-- ============================================================

-- All columns (avoid in production, good for exploration)
SELECT * FROM Employees;

-- Specific columns only (best practice)
SELECT
    EmployeeID,
    FirstName,
    LastName,
    Salary
FROM Employees;

-- ============================================================
-- SECTION 2: Aliases (AS keyword)
-- Makes column names readable in reports
-- ============================================================

SELECT
    EmployeeID                          AS [Employee ID],
    FirstName + ' ' + LastName          AS [Full Name],
    Salary / 12                         AS [Monthly Salary],
    DATEDIFF(YEAR, HireDate, GETDATE()) AS [Years at Company]
FROM Employees;

-- ============================================================
-- SECTION 3: WHERE clause - Filter rows
-- Business Question: Show only active employees
-- ============================================================

SELECT
    FirstName + ' ' + LastName  AS [Full Name],
    DepartmentID,
    Salary
FROM Employees
WHERE Attrition = 0;   -- 0 = still working

-- ============================================================
-- SECTION 4: AND / OR / NOT operators
-- Business Question: Find active female employees in Engineering (DepartmentID = 2)
-- ============================================================

SELECT
    FirstName + ' ' + LastName AS [Full Name],
    Gender,
    DepartmentID,
    Salary
FROM Employees
WHERE Attrition = 0
  AND Gender    = 'F'
  AND DepartmentID = 2;

-- Business Question: Find employees in Sales OR Marketing who left
SELECT
    FirstName + ' ' + LastName AS [Full Name],
    DepartmentID,
    TerminationDate
FROM Employees
WHERE Attrition = 1
  AND (DepartmentID = 3 OR DepartmentID = 4);

-- NOT example: all employees NOT in Support
SELECT
    FirstName + ' ' + LastName AS [Full Name],
    DepartmentID
FROM Employees
WHERE NOT DepartmentID = 6;

-- ============================================================
-- SECTION 5: ORDER BY
-- Business Question: List top earners
-- ============================================================

SELECT
    FirstName + ' ' + LastName AS [Full Name],
    DepartmentID,
    Salary
FROM Employees
ORDER BY Salary DESC;

-- Multiple sort columns
SELECT
    FirstName + ' ' + LastName AS [Full Name],
    DepartmentID,
    PerformanceScore,
    Salary
FROM Employees
ORDER BY DepartmentID ASC, PerformanceScore DESC;

-- ============================================================
-- SECTION 6: TOP - Limit result rows
-- Business Question: Who are the top 5 highest paid employees?
-- ============================================================

SELECT TOP 5
    FirstName + ' ' + LastName AS [Full Name],
    Salary
FROM Employees
ORDER BY Salary DESC;

-- TOP 10 PERCENT
SELECT TOP 10 PERCENT
    FirstName + ' ' + LastName AS [Full Name],
    Salary
FROM Employees
ORDER BY Salary DESC;

-- ============================================================
-- SECTION 7: DISTINCT - Remove duplicates
-- Business Question: What unique work modes exist?
-- ============================================================

SELECT DISTINCT WorkMode    FROM Employees;
SELECT DISTINCT Gender      FROM Employees;
SELECT DISTINCT JobSatisfaction FROM Employees ORDER BY JobSatisfaction;

-- Distinct on multiple columns
SELECT DISTINCT
    DepartmentID,
    WorkMode
FROM Employees
ORDER BY DepartmentID;

-- ============================================================
-- SECTION 8: BETWEEN
-- Business Question: Find employees with salary between 6L and 12L
-- ============================================================

SELECT
    FirstName + ' ' + LastName AS [Full Name],
    Salary
FROM Employees
WHERE Salary BETWEEN 600000 AND 1200000
ORDER BY Salary;

-- Date range
SELECT
    FirstName + ' ' + LastName AS [Full Name],
    HireDate
FROM Employees
WHERE HireDate BETWEEN '2019-01-01' AND '2021-12-31'
ORDER BY HireDate;

-- ============================================================
-- SECTION 9: IN operator
-- Business Question: Filter employees from specific departments
-- ============================================================

SELECT
    FirstName + ' ' + LastName AS [Full Name],
    DepartmentID,
    WorkMode
FROM Employees
WHERE DepartmentID IN (2, 4, 7)   -- Engineering, Marketing, Product
ORDER BY DepartmentID;

-- IN with text
SELECT
    FirstName + ' ' + LastName AS [Full Name],
    WorkMode
FROM Employees
WHERE WorkMode IN ('Remote', 'Hybrid')
ORDER BY WorkMode;

-- ============================================================
-- SECTION 10: LIKE - Pattern matching
-- Business Question: Find employees whose last name starts with 'S'
-- ============================================================

SELECT
    FirstName,
    LastName
FROM Employees
WHERE LastName LIKE 'S%';

-- Ends with 'a'
SELECT FirstName, LastName FROM Employees WHERE FirstName LIKE '%a';

-- Contains 'ar'
SELECT FirstName, LastName FROM Employees WHERE FirstName LIKE '%ar%';

-- ============================================================
-- DAY 1 CHALLENGE QUERIES
-- Try solving these yourself first, then check answers below
-- ============================================================

-- CHALLENGE 1:
-- Find all female employees hired after 2020 with salary above 7 lakhs
-- who are currently active. Sort by salary descending.

SELECT
    FirstName + ' ' + LastName AS [Full Name],
    HireDate,
    Salary
FROM Employees
WHERE Gender = 'F'
  AND HireDate > '2020-01-01'
  AND Salary > 700000
  AND Attrition = 0
ORDER BY Salary DESC;


-- CHALLENGE 2:
-- List top 5 employees by performance score who work remotely.

SELECT TOP 5
    FirstName + ' ' + LastName AS [Full Name],
    PerformanceScore,
    WorkMode
FROM Employees
WHERE WorkMode = 'Remote'
ORDER BY PerformanceScore DESC, Salary DESC;


-- CHALLENGE 3:
-- Find employees whose names contain 'raj' (case-insensitive)

SELECT
    FirstName + ' ' + LastName AS [Full Name],
    DepartmentID
FROM Employees
WHERE FirstName LIKE '%raj%' OR LastName LIKE '%raj%';

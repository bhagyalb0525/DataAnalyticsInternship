-- ============================================================
--  HR ANALYTICS PROJECT
--  Script 02: Day 2 - Joins and Aggregations
--  Topics: INNER/LEFT/RIGHT/FULL JOIN, GROUP BY, HAVING,
--          COUNT, SUM, AVG, MIN, MAX
-- ============================================================

USE HRAnalytics;
GO

-- ============================================================
-- SECTION 1: INNER JOIN
-- Returns only matching rows in BOTH tables
-- Business Question: Show each employee with their department name
-- ============================================================

SELECT
    E.EmployeeID,
    E.FirstName + ' ' + E.LastName  AS [Full Name],
    D.DepartmentName,
    E.Salary
FROM Employees E
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
ORDER BY D.DepartmentName;

-- Three-table join: Employees + Departments + JobRoles
SELECT
    E.FirstName + ' ' + E.LastName  AS [Full Name],
    D.DepartmentName,
    J.JobTitle,
    J.JobLevel,
    E.Salary
FROM Employees E
INNER JOIN Departments D  ON E.DepartmentID = D.DepartmentID
INNER JOIN JobRoles    J  ON E.JobRoleID    = J.JobRoleID
ORDER BY D.DepartmentName, E.Salary DESC;

-- ============================================================
-- SECTION 2: LEFT JOIN
-- Returns ALL rows from left table + matches from right
-- Business Question: Show all employees even if no performance review
-- ============================================================

SELECT
    E.FirstName + ' ' + E.LastName  AS [Full Name],
    PR.ReviewDate,
    PR.ReviewScore
FROM Employees E
LEFT JOIN PerformanceReviews PR ON E.EmployeeID = PR.EmployeeID
ORDER BY E.EmployeeID;

-- Find employees who NEVER had a review
SELECT
    E.FirstName + ' ' + E.LastName  AS [Full Name],
    E.DepartmentID
FROM Employees E
LEFT JOIN PerformanceReviews PR ON E.EmployeeID = PR.EmployeeID
WHERE PR.ReviewID IS NULL;

-- ============================================================
-- SECTION 3: RIGHT JOIN
-- Returns ALL rows from right table + matches from left
-- Business Question: All departments even if no employees assigned
-- ============================================================

SELECT
    D.DepartmentName,
    COUNT(E.EmployeeID) AS [Employee Count]
FROM Employees E
RIGHT JOIN Departments D ON E.DepartmentID = D.DepartmentID
GROUP BY D.DepartmentName;

-- ============================================================
-- SECTION 4: FULL JOIN
-- Returns ALL rows from both tables
-- ============================================================

SELECT
    E.FirstName + ' ' + E.LastName  AS [Full Name],
    D.DepartmentName
FROM Employees   E
FULL JOIN Departments D ON E.DepartmentID = D.DepartmentID;

-- ============================================================
-- SECTION 5: Aggregate Functions
-- COUNT, SUM, AVG, MIN, MAX
-- ============================================================

-- Total number of employees
SELECT COUNT(*) AS [Total Employees] FROM Employees;

-- Active vs Attrited
SELECT
    CASE WHEN Attrition = 1 THEN 'Left' ELSE 'Active' END AS [Status],
    COUNT(*) AS [Count]
FROM Employees
GROUP BY Attrition;

-- Total salary bill
SELECT SUM(Salary) AS [Total Salary Bill] FROM Employees WHERE Attrition = 0;

-- Average salary
SELECT AVG(Salary) AS [Average Salary] FROM Employees WHERE Attrition = 0;

-- Min and max salary
SELECT
    MIN(Salary) AS [Lowest Salary],
    MAX(Salary) AS [Highest Salary],
    AVG(Salary) AS [Average Salary]
FROM Employees
WHERE Attrition = 0;

-- ============================================================
-- SECTION 6: GROUP BY
-- Business Question: Department-wise employee count and avg salary
-- ============================================================

SELECT
    D.DepartmentName,
    COUNT(E.EmployeeID)     AS [Headcount],
    AVG(E.Salary)           AS [Avg Salary],
    MIN(E.Salary)           AS [Min Salary],
    MAX(E.Salary)           AS [Max Salary],
    SUM(E.Salary)           AS [Total Salary Bill]
FROM Employees E
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
WHERE E.Attrition = 0
GROUP BY D.DepartmentName
ORDER BY [Headcount] DESC;

-- Group by job level
SELECT
    J.JobLevel,
    COUNT(E.EmployeeID) AS [Count],
    AVG(E.Salary)       AS [Avg Salary],
    AVG(E.PerformanceScore) AS [Avg Performance]
FROM Employees E
INNER JOIN JobRoles J ON E.JobRoleID = J.JobRoleID
WHERE E.Attrition = 0
GROUP BY J.JobLevel
ORDER BY [Avg Salary] DESC;

-- Gender breakdown by department
SELECT
    D.DepartmentName,
    E.Gender,
    COUNT(*) AS [Count]
FROM Employees E
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
GROUP BY D.DepartmentName, E.Gender
ORDER BY D.DepartmentName, E.Gender;

-- ============================================================
-- SECTION 7: HAVING - Filter aggregated groups
-- Difference from WHERE: HAVING filters AFTER grouping
-- Business Question: Departments with avg salary above 8 lakhs
-- ============================================================

SELECT
    D.DepartmentName,
    AVG(E.Salary) AS [Avg Salary]
FROM Employees E
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
WHERE E.Attrition = 0
GROUP BY D.DepartmentName
HAVING AVG(E.Salary) > 800000
ORDER BY [Avg Salary] DESC;

-- Departments with more than 5 employees
SELECT
    D.DepartmentName,
    COUNT(*) AS [Employee Count]
FROM Employees E
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
WHERE E.Attrition = 0
GROUP BY D.DepartmentName
HAVING COUNT(*) > 5;

-- ============================================================
-- SECTION 8: Business Reports (combining all Day 2 skills)
-- ============================================================

-- REPORT 1: Attrition Rate by Department
SELECT
    D.DepartmentName,
    COUNT(E.EmployeeID)                                             AS [Total Employees],
    SUM(CAST(E.Attrition AS INT))                                   AS [Attrited],
    COUNT(E.EmployeeID) - SUM(CAST(E.Attrition AS INT))            AS [Active],
    CAST(SUM(CAST(E.Attrition AS INT)) * 100.0
         / COUNT(E.EmployeeID) AS DECIMAL(5,2))                    AS [Attrition %]
FROM Employees E
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
GROUP BY D.DepartmentName
ORDER BY [Attrition %] DESC;

-- REPORT 2: Job Role Salary Summary
SELECT
    J.JobTitle,
    J.JobLevel,
    COUNT(E.EmployeeID)     AS [Headcount],
    AVG(E.Salary)           AS [Current Avg Salary],
    J.MinSalary             AS [Band Min],
    J.MaxSalary             AS [Band Max]
FROM Employees E
INNER JOIN JobRoles J ON E.JobRoleID = J.JobRoleID
WHERE E.Attrition = 0
GROUP BY J.JobTitle, J.JobLevel, J.MinSalary, J.MaxSalary
ORDER BY [Current Avg Salary] DESC;

-- REPORT 3: Training Participation
SELECT
    D.DepartmentName,
    COUNT(DISTINCT TR.EmployeeID)       AS [Trained Employees],
    COUNT(TR.TrainingID)                AS [Total Trainings],
    AVG(TR.Score)                       AS [Avg Training Score],
    SUM(TR.DurationHours)               AS [Total Hours Invested]
FROM TrainingRecords TR
INNER JOIN Employees   E ON TR.EmployeeID   = E.EmployeeID
INNER JOIN Departments D ON E.DepartmentID  = D.DepartmentID
GROUP BY D.DepartmentName
ORDER BY [Total Trainings] DESC;

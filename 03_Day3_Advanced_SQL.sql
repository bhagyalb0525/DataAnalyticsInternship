-- ============================================================
--  HR ANALYTICS PROJECT
--  Script 03: Day 3 - Advanced SQL for Analytics
--  Topics: Date/String Functions, CASE, Subqueries, CTEs, Recursive CTE
-- ============================================================

USE HRAnalytics;
GO

-- ============================================================
-- SECTION 1: Date and Time Functions
-- ============================================================

SELECT
    EmployeeID,
    FirstName + ' ' + LastName          AS [Full Name],
    DateOfBirth,
    DATEDIFF(YEAR, DateOfBirth, GETDATE())  AS [Age],
    HireDate,
    DATEDIFF(YEAR, HireDate, GETDATE())     AS [Tenure (Years)],
    YEAR(HireDate)                          AS [Year Joined],
    MONTH(HireDate)                         AS [Month Joined],
    DATENAME(MONTH, HireDate)               AS [Month Name]
FROM Employees
WHERE Attrition = 0
ORDER BY HireDate;

-- Employees hired in a specific quarter
SELECT
    FirstName + ' ' + LastName AS [Full Name],
    HireDate,
    DATEPART(QUARTER, HireDate) AS [Quarter Joined]
FROM Employees
WHERE YEAR(HireDate) = 2020
ORDER BY HireDate;

-- ============================================================
-- SECTION 2: String Functions
-- ============================================================

SELECT
    UPPER(FirstName)                        AS [Upper First],
    LOWER(LastName)                         AS [Lower Last],
    LEN(FirstName + ' ' + LastName)         AS [Name Length],
    LEFT(FirstName, 3)                      AS [Name Code],
    SUBSTRING(FirstName, 1, 1) + '.' +
        LEFT(LastName, 1) + '.'             AS [Initials],
    REPLACE(WorkMode, '-', ' ')             AS [Work Mode],
    TRIM(LastName)                          AS [Trimmed Name]
FROM Employees;

-- Generate email addresses
SELECT
    FirstName + ' ' + LastName             AS [Full Name],
    LOWER(FirstName) + '.' +
    LOWER(LastName) + '@company.com'       AS [Email]
FROM Employees
WHERE Attrition = 0;

-- ============================================================
-- SECTION 3: CASE Statements
-- Transform data into categories
-- Business Question: Categorise salary into bands
-- ============================================================

SELECT
    FirstName + ' ' + LastName AS [Full Name],
    Salary,
    CASE
        WHEN Salary < 400000   THEN 'Band 1 - Entry'
        WHEN Salary < 700000   THEN 'Band 2 - Junior'
        WHEN Salary < 1000000  THEN 'Band 3 - Mid'
        WHEN Salary < 1500000  THEN 'Band 4 - Senior'
        ELSE                        'Band 5 - Lead/Manager'
    END AS [Salary Band],
    CASE PerformanceScore
        WHEN 1 THEN 'Needs Improvement'
        WHEN 2 THEN 'Below Average'
        WHEN 3 THEN 'Meets Expectations'
        WHEN 4 THEN 'Above Average'
        WHEN 5 THEN 'Outstanding'
    END AS [Performance Label],
    CASE
        WHEN Attrition = 1 THEN 'Ex-Employee'
        ELSE 'Active'
    END AS [Status]
FROM Employees
ORDER BY Salary DESC;

-- CASE in aggregate context: count by salary band
SELECT
    CASE
        WHEN Salary < 400000   THEN 'Band 1 - Entry'
        WHEN Salary < 700000   THEN 'Band 2 - Junior'
        WHEN Salary < 1000000  THEN 'Band 3 - Mid'
        WHEN Salary < 1500000  THEN 'Band 4 - Senior'
        ELSE                        'Band 5 - Lead/Manager'
    END AS [Salary Band],
    COUNT(*) AS [Employee Count],
    AVG(Salary) AS [Avg Salary in Band]
FROM Employees
WHERE Attrition = 0
GROUP BY
    CASE
        WHEN Salary < 400000   THEN 'Band 1 - Entry'
        WHEN Salary < 700000   THEN 'Band 2 - Junior'
        WHEN Salary < 1000000  THEN 'Band 3 - Mid'
        WHEN Salary < 1500000  THEN 'Band 4 - Senior'
        ELSE                        'Band 5 - Lead/Manager'
    END
ORDER BY MIN(Salary);

-- ============================================================
-- SECTION 4: Subqueries
-- A query nested inside another query
-- Business Question: Find employees earning above company average
-- ============================================================

-- Subquery in WHERE
SELECT
    FirstName + ' ' + LastName AS [Full Name],
    Salary
FROM Employees
WHERE Salary > (SELECT AVG(Salary) FROM Employees WHERE Attrition = 0)
  AND Attrition = 0
ORDER BY Salary DESC;

-- Subquery in SELECT (scalar)
SELECT
    FirstName + ' ' + LastName AS [Full Name],
    Salary,
    (SELECT AVG(Salary) FROM Employees WHERE Attrition = 0) AS [Company Avg],
    Salary - (SELECT AVG(Salary) FROM Employees WHERE Attrition = 0) AS [Diff from Avg]
FROM Employees
WHERE Attrition = 0
ORDER BY Salary DESC;

-- Subquery in FROM (derived table)
SELECT
    DeptSummary.DepartmentID,
    DeptSummary.AvgSalary
FROM (
    SELECT DepartmentID, AVG(Salary) AS AvgSalary
    FROM Employees
    WHERE Attrition = 0
    GROUP BY DepartmentID
) AS DeptSummary
WHERE DeptSummary.AvgSalary > 800000;

-- EXISTS: departments that have at least one high performer (score = 5)
SELECT D.DepartmentName
FROM Departments D
WHERE EXISTS (
    SELECT 1
    FROM Employees E
    WHERE E.DepartmentID = D.DepartmentID
      AND E.PerformanceScore = 5
      AND E.Attrition = 0
);

-- ============================================================
-- SECTION 5: Common Table Expressions (CTE)
-- Cleaner, reusable, readable alternative to subqueries
-- Business Question: Attrition analysis using CTE
-- ============================================================

-- Simple CTE
WITH ActiveEmployees AS (
    SELECT
        E.*,
        D.DepartmentName,
        J.JobTitle,
        J.JobLevel
    FROM Employees E
    INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
    INNER JOIN JobRoles    J ON E.JobRoleID    = J.JobRoleID
    WHERE E.Attrition = 0
)
SELECT
    DepartmentName,
    COUNT(*)       AS [Headcount],
    AVG(Salary)    AS [Avg Salary],
    AVG(PerformanceScore * 1.0) AS [Avg Performance]
FROM ActiveEmployees
GROUP BY DepartmentName
ORDER BY [Avg Salary] DESC;

-- Multiple CTEs: Attrition risk report
WITH AttritionStats AS (
    SELECT
        DepartmentID,
        COUNT(*) AS Total,
        SUM(CAST(Attrition AS INT)) AS Attrited
    FROM Employees
    GROUP BY DepartmentID
),
DeptRisk AS (
    SELECT
        D.DepartmentName,
        S.Total,
        S.Attrited,
        CAST(S.Attrited * 100.0 / S.Total AS DECIMAL(5,2)) AS [Attrition Rate %],
        CASE
            WHEN S.Attrited * 100.0 / S.Total >= 25 THEN 'HIGH'
            WHEN S.Attrited * 100.0 / S.Total >= 10 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS [Risk Level]
    FROM AttritionStats S
    INNER JOIN Departments D ON S.DepartmentID = D.DepartmentID
)
SELECT * FROM DeptRisk
ORDER BY [Attrition Rate %] DESC;

-- ============================================================
-- SECTION 6: Recursive CTE
-- Used to represent hierarchies (who reports to whom)
-- Build a simple manager → team hierarchy
-- ============================================================

-- First let's see the manager concept
-- (In our data, managers are employees with specific job roles)

WITH ManagerHierarchy AS (
    -- Anchor: Top-level managers (JobLevel = 'Senior' or 'Lead')
    SELECT
        E.EmployeeID,
        E.FirstName + ' ' + E.LastName  AS [Name],
        J.JobTitle,
        J.JobLevel,
        E.DepartmentID,
        0                                AS [Level],
        CAST(E.FirstName AS VARCHAR(200)) AS [Hierarchy Path]
    FROM Employees E
    INNER JOIN JobRoles J ON E.JobRoleID = J.JobRoleID
    WHERE J.JobLevel IN ('Lead', 'Senior')
      AND E.Attrition = 0

    UNION ALL

    -- Recursive: Employees under those managers (same department)
    SELECT
        E.EmployeeID,
        E.FirstName + ' ' + E.LastName  AS [Name],
        J.JobTitle,
        J.JobLevel,
        E.DepartmentID,
        H.[Level] + 1,
        CAST(H.[Hierarchy Path] + ' > ' + E.FirstName AS VARCHAR(200))
    FROM Employees E
    INNER JOIN JobRoles       J ON E.JobRoleID    = J.JobRoleID
    INNER JOIN ManagerHierarchy H ON E.DepartmentID = H.DepartmentID
                                  AND J.JobLevel    = 'Entry'
                                  AND H.[Level]     = 0
    WHERE E.Attrition = 0
)
SELECT
    [Level],
    [Name],
    JobTitle,
    JobLevel,
    DepartmentID,
    [Hierarchy Path]
FROM ManagerHierarchy
ORDER BY DepartmentID, [Level];

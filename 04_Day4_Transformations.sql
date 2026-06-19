-- ============================================================
--  HR ANALYTICS PROJECT
--  Script 04: Day 4 - Data Transformation Techniques
--  Topics: PIVOT, UNPIVOT, Temp Tables, Views, JSON basics
-- ============================================================

USE HRAnalytics;
GO

-- ============================================================
-- SECTION 1: Temporary Tables
-- Created in TempDB, deleted when session ends
-- Good for staging data for multiple operations
-- ============================================================

-- Create a staging temp table with cleaned employee data
DROP TABLE IF EXISTS #EmployeeSummary;

SELECT
    E.EmployeeID,
    E.FirstName + ' ' + E.LastName      AS FullName,
    D.DepartmentName,
    J.JobTitle,
    J.JobLevel,
    E.Salary,
    E.PerformanceScore,
    E.Attrition,
    E.WorkMode,
    DATEDIFF(YEAR, E.HireDate, GETDATE()) AS TenureYears,
    DATEDIFF(YEAR, E.DateOfBirth, GETDATE()) AS Age,
    CASE
        WHEN E.Salary < 400000   THEN 'Band 1 - Entry'
        WHEN E.Salary < 700000   THEN 'Band 2 - Junior'
        WHEN E.Salary < 1000000  THEN 'Band 3 - Mid'
        WHEN E.Salary < 1500000  THEN 'Band 4 - Senior'
        ELSE                          'Band 5 - Lead/Mgr'
    END AS SalaryBand
INTO #EmployeeSummary
FROM Employees E
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
INNER JOIN JobRoles    J ON E.JobRoleID    = J.JobRoleID;

-- Use the temp table
SELECT * FROM #EmployeeSummary ORDER BY Salary DESC;

-- Query temp table multiple times without re-joining
SELECT
    DepartmentName,
    COUNT(*) AS Headcount,
    AVG(Salary) AS AvgSalary
FROM #EmployeeSummary
WHERE Attrition = 0
GROUP BY DepartmentName;

SELECT
    SalaryBand,
    COUNT(*) AS Count
FROM #EmployeeSummary
GROUP BY SalaryBand
ORDER BY MIN(Salary);

-- ============================================================
-- SECTION 2: PIVOT
-- Converts rows into columns (great for cross-tab reports)
-- Business Question: Count employees by department and work mode (cross-tab)
-- ============================================================

SELECT
    DepartmentName,
    [Remote],
    [Hybrid],
    [On-site]
FROM (
    SELECT
        D.DepartmentName,
        E.WorkMode
    FROM Employees E
    INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
    WHERE E.Attrition = 0
) AS SourceData
PIVOT (
    COUNT(WorkMode)
    FOR WorkMode IN ([Remote], [Hybrid], [On-site])
) AS PivotTable
ORDER BY DepartmentName;

-- PIVOT: Performance score distribution by department
SELECT
    DepartmentName,
    [1] AS [Score 1],
    [2] AS [Score 2],
    [3] AS [Score 3],
    [4] AS [Score 4],
    [5] AS [Score 5]
FROM (
    SELECT
        D.DepartmentName,
        E.PerformanceScore
    FROM Employees E
    INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
) AS SourceData
PIVOT (
    COUNT(PerformanceScore)
    FOR PerformanceScore IN ([1],[2],[3],[4],[5])
) AS PivotTable
ORDER BY DepartmentName;

-- ============================================================
-- SECTION 3: UNPIVOT
-- Converts columns back into rows
-- ============================================================

-- First create a small summary to UNPIVOT
DROP TABLE IF EXISTS #DeptMetrics;

SELECT
    D.DepartmentName,
    CAST(AVG(E.Salary) AS DECIMAL(10,2))              AS AvgSalary,
    CAST(AVG(E.PerformanceScore * 1.0) AS DECIMAL(5,2)) AS AvgPerformance,
    CAST(AVG(E.JobSatisfaction * 1.0) AS DECIMAL(5,2))  AS AvgSatisfaction
INTO #DeptMetrics
FROM Employees E
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
WHERE E.Attrition = 0
GROUP BY D.DepartmentName;

SELECT * FROM #DeptMetrics;

-- Now UNPIVOT to see metrics as rows
SELECT
    DepartmentName,
    MetricName,
    MetricValue
FROM #DeptMetrics
UNPIVOT (
    MetricValue FOR MetricName IN (AvgSalary, AvgPerformance, AvgSatisfaction)
) AS UnpivotResult
ORDER BY DepartmentName, MetricName;

-- ============================================================
-- SECTION 4: Views
-- Stored virtual tables - reusable query definitions
-- ============================================================

-- View 1: Active Employee Master View (the most-used view in analytics)
GO
CREATE OR ALTER VIEW vw_ActiveEmployees AS
SELECT
    E.EmployeeID,
    E.FirstName + ' ' + E.LastName              AS FullName,
    E.Gender,
    DATEDIFF(YEAR, E.DateOfBirth, GETDATE())     AS Age,
    D.DepartmentName,
    J.JobTitle,
    J.JobLevel,
    E.Salary,
    E.PerformanceScore,
    E.JobSatisfaction,
    E.WorkMode,
    E.EducationLevel,
    E.MaritalStatus,
    E.HireDate,
    DATEDIFF(YEAR, E.HireDate, GETDATE())        AS TenureYears,
    E.TrainingHoursPerYear,
    CASE
        WHEN E.Salary < 400000   THEN 'Band 1'
        WHEN E.Salary < 700000   THEN 'Band 2'
        WHEN E.Salary < 1000000  THEN 'Band 3'
        WHEN E.Salary < 1500000  THEN 'Band 4'
        ELSE                          'Band 5'
    END AS SalaryBand
FROM Employees   E
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
INNER JOIN JobRoles    J ON E.JobRoleID    = J.JobRoleID
WHERE E.Attrition = 0;
GO

-- View 2: Attrition Summary View
CREATE OR ALTER VIEW vw_AttritionSummary AS
WITH AttritionData AS (
    SELECT
        D.DepartmentName,
        E.Gender,
        J.JobLevel,
        E.Attrition,
        E.Salary,
        E.PerformanceScore,
        E.JobSatisfaction,
        E.YearsAtCompany
    FROM Employees E
    INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
    INNER JOIN JobRoles    J ON E.JobRoleID    = J.JobRoleID
)
SELECT
    DepartmentName,
    Gender,
    JobLevel,
    COUNT(*)                                        AS TotalEmployees,
    SUM(CAST(Attrition AS INT))                    AS AttritionCount,
    CAST(SUM(CAST(Attrition AS INT)) * 100.0
         / COUNT(*) AS DECIMAL(5,2))               AS AttritionRate,
    AVG(CASE WHEN Attrition = 0 THEN Salary END)   AS AvgSalaryActive,
    AVG(PerformanceScore * 1.0)                    AS AvgPerformance,
    AVG(JobSatisfaction  * 1.0)                    AS AvgSatisfaction,
    AVG(YearsAtCompany   * 1.0)                    AS AvgTenure
FROM AttritionData
GROUP BY DepartmentName, Gender, JobLevel;
GO

-- View 3: Training Effectiveness View
CREATE OR ALTER VIEW vw_TrainingEffectiveness AS
SELECT
    D.DepartmentName,
    E.FirstName + ' ' + E.LastName AS EmployeeName,
    J.JobTitle,
    TR.TrainingName,
    TR.CompletionDate,
    TR.DurationHours,
    TR.Score,
    CASE
        WHEN TR.Score >= 90 THEN 'Excellent'
        WHEN TR.Score >= 75 THEN 'Good'
        WHEN TR.Score >= 60 THEN 'Average'
        ELSE 'Needs Improvement'
    END AS Performance
FROM TrainingRecords TR
INNER JOIN Employees   E ON TR.EmployeeID  = E.EmployeeID
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
INNER JOIN JobRoles    J ON E.JobRoleID    = J.JobRoleID;
GO

-- Now use the views
SELECT * FROM vw_ActiveEmployees ORDER BY Salary DESC;

SELECT
    DepartmentName,
    AttritionRate,
    TotalEmployees
FROM vw_AttritionSummary
ORDER BY AttritionRate DESC;

SELECT
    DepartmentName,
    AVG(Score) AS AvgScore,
    COUNT(*)   AS TrainingCount
FROM vw_TrainingEffectiveness
GROUP BY DepartmentName;

-- ============================================================
-- SECTION 5: JSON Output (SQL Server feature)
-- Export data as JSON for API/web consumption
-- ============================================================

-- JSON auto mode
SELECT TOP 5
    EmployeeID,
    FirstName + ' ' + LastName AS Name,
    Salary
FROM Employees
FOR JSON AUTO;

-- JSON with path (custom keys)
SELECT TOP 5
    EmployeeID        AS [employee.id],
    FirstName         AS [employee.firstName],
    LastName          AS [employee.lastName],
    Salary            AS [compensation.annual]
FROM Employees
FOR JSON PATH;
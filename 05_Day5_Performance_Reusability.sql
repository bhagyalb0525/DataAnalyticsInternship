-- ============================================================
--  HR ANALYTICS PROJECT
--  Script 05: Day 5 - SQL Performance and Reusability
--  Topics: Stored Procedures, Functions, Transactions,
--          TRY-CATCH, Indexes, Execution Plans
-- ============================================================

USE HRAnalytics;
GO

-- ============================================================
-- SECTION 1: Stored Procedures
-- Pre-compiled SQL that accepts parameters
-- Professionals use these instead of raw queries
-- ============================================================

-- Procedure 1: Get all employees in a department with filters
CREATE OR ALTER PROCEDURE usp_GetDepartmentEmployees
    @DepartmentName VARCHAR(50),
    @ActiveOnly     BIT = 1          -- default: show active employees
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        E.EmployeeID,
        E.FirstName + ' ' + E.LastName  AS FullName,
        E.Gender,
        J.JobTitle,
        J.JobLevel,
        E.Salary,
        E.PerformanceScore,
        E.WorkMode,
        DATEDIFF(YEAR, E.HireDate, GETDATE()) AS TenureYears
    FROM Employees E
    INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
    INNER JOIN JobRoles    J ON E.JobRoleID    = J.JobRoleID
    WHERE D.DepartmentName = @DepartmentName
      AND (@ActiveOnly = 0 OR E.Attrition = 0)
    ORDER BY E.Salary DESC;
END;
GO

-- Run the procedure
EXEC usp_GetDepartmentEmployees @DepartmentName = 'Engineering';
EXEC usp_GetDepartmentEmployees @DepartmentName = 'Sales', @ActiveOnly = 0;

-- Procedure 2: HR Attrition Report by filters
CREATE OR ALTER PROCEDURE usp_AttritionReport
    @StartDate      DATE = NULL,
    @EndDate        DATE = NULL,
    @DepartmentID   INT  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        D.DepartmentName,
        J.JobLevel,
        E.Gender,
        COUNT(*)                                      AS TotalEmployees,
        SUM(CAST(E.Attrition AS INT))                AS Attrited,
        CAST(SUM(CAST(E.Attrition AS INT)) * 100.0
             / NULLIF(COUNT(*),0) AS DECIMAL(5,2))   AS [Attrition%],
        AVG(E.Salary)                                AS AvgSalary,
        AVG(E.JobSatisfaction * 1.0)                 AS AvgSatisfaction
    FROM Employees E
    INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
    INNER JOIN JobRoles    J ON E.JobRoleID    = J.JobRoleID
    WHERE
        (@StartDate    IS NULL OR E.HireDate     >= @StartDate)
      AND (@EndDate    IS NULL OR E.HireDate     <= @EndDate)
      AND (@DepartmentID IS NULL OR E.DepartmentID = @DepartmentID)
    GROUP BY D.DepartmentName, J.JobLevel, E.Gender
    ORDER BY [Attrition%] DESC;
END;
GO

EXEC usp_AttritionReport;
EXEC usp_AttritionReport @DepartmentID = 2;
EXEC usp_AttritionReport @StartDate = '2019-01-01', @EndDate = '2021-12-31';

-- ============================================================
-- SECTION 2: Scalar Functions
-- Returns a single value
-- ============================================================

-- Function: Calculate attrition risk score for an employee
CREATE OR ALTER FUNCTION fn_AttritionRiskScore
(
    @PerformanceScore   TINYINT,
    @JobSatisfaction    TINYINT,
    @YearsAtCompany     TINYINT
)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @Score INT = 0;

    -- Low satisfaction adds risk
    IF @JobSatisfaction <= 2  SET @Score = @Score + 3;
    IF @JobSatisfaction = 3   SET @Score = @Score + 1;

    -- Low performance adds risk
    IF @PerformanceScore <= 2 SET @Score = @Score + 2;

    -- New employees are higher risk
    IF @YearsAtCompany <= 2   SET @Score = @Score + 2;

    RETURN CASE
        WHEN @Score >= 5 THEN 'HIGH'
        WHEN @Score >= 3 THEN 'MEDIUM'
        ELSE                  'LOW'
    END;
END;
GO

-- Use the function
SELECT
    FirstName + ' ' + LastName  AS FullName,
    PerformanceScore,
    JobSatisfaction,
    YearsAtCompany,
    dbo.fn_AttritionRiskScore(PerformanceScore, JobSatisfaction, YearsAtCompany)
                                AS [Attrition Risk]
FROM Employees
WHERE Attrition = 0
ORDER BY
    CASE dbo.fn_AttritionRiskScore(PerformanceScore, JobSatisfaction, YearsAtCompany)
        WHEN 'HIGH'   THEN 1
        WHEN 'MEDIUM' THEN 2
        ELSE               3
    END;

-- ============================================================
-- SECTION 3: Table-Valued Function (TVF)
-- Returns a result set (like a parameterized view)
-- ============================================================

CREATE OR ALTER FUNCTION fn_GetSalaryBandEmployees
(
    @BandMin DECIMAL(10,2),
    @BandMax DECIMAL(10,2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        E.EmployeeID,
        E.FirstName + ' ' + E.LastName  AS FullName,
        D.DepartmentName,
        J.JobTitle,
        E.Salary,
        E.PerformanceScore
    FROM Employees E
    INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID
    INNER JOIN JobRoles    J ON E.JobRoleID    = J.JobRoleID
    WHERE E.Salary BETWEEN @BandMin AND @BandMax
      AND E.Attrition = 0
);
GO

-- Use the TVF
SELECT * FROM dbo.fn_GetSalaryBandEmployees(600000, 1000000) ORDER BY Salary DESC;
SELECT * FROM dbo.fn_GetSalaryBandEmployees(1000000, 2000000) ORDER BY Salary DESC;

-- ============================================================
-- SECTION 4: Transactions
-- Ensures all steps succeed or none do (ACID)
-- Example: Salary hike + history log in one atomic operation
-- ============================================================

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @EmployeeID INT    = 1001;
    DECLARE @HikePercent FLOAT = 10.0;
    DECLARE @OldSalary DECIMAL(10,2);
    DECLARE @NewSalary DECIMAL(10,2);

    -- Get current salary
    SELECT @OldSalary = Salary FROM Employees WHERE EmployeeID = @EmployeeID;
    SET @NewSalary = @OldSalary * (1 + @HikePercent / 100);

    -- Update employee salary
    UPDATE Employees
    SET Salary = @NewSalary
    WHERE EmployeeID = @EmployeeID;

    -- Log salary history
    INSERT INTO SalaryHistory (EmployeeID, EffectiveDate, OldSalary, NewSalary, ChangeReason)
    VALUES (@EmployeeID, GETDATE(), @OldSalary, @NewSalary, 'Annual Hike');

    COMMIT TRANSACTION;
    PRINT 'Salary updated and history logged successfully.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

-- ============================================================
-- SECTION 5: TRY...CATCH Error Handling
-- ============================================================

CREATE OR ALTER PROCEDURE usp_TransferEmployee
    @EmployeeID    INT,
    @NewDeptID     INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY

        -- Validate employee exists
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @EmployeeID)
            THROW 50001, 'Employee not found.', 1;

        -- Validate department exists
        IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID = @NewDeptID)
            THROW 50002, 'Department not found.', 1;

        -- Update department
        UPDATE Employees
        SET DepartmentID = @NewDeptID
        WHERE EmployeeID = @EmployeeID;

        COMMIT TRANSACTION;
        PRINT 'Employee ' + CAST(@EmployeeID AS VARCHAR) + ' transferred successfully.';

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT
            ERROR_NUMBER()    AS ErrorNumber,
            ERROR_MESSAGE()   AS ErrorMessage,
            ERROR_SEVERITY()  AS Severity;
    END CATCH;
END;
GO

-- Test the procedure
EXEC usp_TransferEmployee @EmployeeID = 1001, @NewDeptID = 3;
EXEC usp_TransferEmployee @EmployeeID = 9999, @NewDeptID = 1;   -- Should error
EXEC usp_TransferEmployee @EmployeeID = 1001, @NewDeptID = 99;  -- Should error

-- ============================================================
-- SECTION 6: Indexes - Speed up queries
-- ============================================================

-- Check current query with no index (look at execution plan in SSMS)
SELECT * FROM Employees WHERE DepartmentID = 2 AND Attrition = 0;

-- Create Non-Clustered Index on commonly filtered columns
CREATE NONCLUSTERED INDEX IX_Employees_Dept_Attrition
ON Employees (DepartmentID, Attrition)
INCLUDE (FirstName, LastName, Salary, PerformanceScore);

-- Create index for date-based queries
CREATE NONCLUSTERED INDEX IX_Employees_HireDate
ON Employees (HireDate)
INCLUDE (EmployeeID, DepartmentID, Salary);

-- Create index for salary range queries
CREATE NONCLUSTERED INDEX IX_Employees_Salary
ON Employees (Salary DESC)
WHERE Attrition = 0;   -- Filtered index

-- Run same query again - compare execution plan (should show Index Seek now)
SELECT * FROM Employees WHERE DepartmentID = 2 AND Attrition = 0;

-- ============================================================
-- SECTION 7: Useful system queries (professionals use daily)
-- ============================================================

-- See all tables in the database
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';

-- See all views
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS;

-- See all stored procedures
SELECT name FROM sys.procedures ORDER BY name;

-- Check index usage stats
SELECT
    OBJECT_NAME(i.object_id) AS TableName,
    i.name                   AS IndexName,
    i.type_desc,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s
    ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE OBJECT_NAME(i.object_id) = 'Employees';

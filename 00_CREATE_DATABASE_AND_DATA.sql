-- ============================================================
--  HR ANALYTICS PROJECT
--  Script 00: Database Creation + Sample Data
--  Run this FIRST before any other script
-- ============================================================

USE master;
GO

-- Drop and recreate the database cleanly
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'HRAnalytics')
BEGIN
    ALTER DATABASE HRAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE HRAnalytics;
END
GO

CREATE DATABASE HRAnalytics;
GO

USE HRAnalytics;
GO

-- ============================================================
-- TABLE 1: Departments
-- ============================================================
CREATE TABLE Departments (
    DepartmentID    INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName  VARCHAR(50) NOT NULL,
    Location        VARCHAR(50),
    ManagerID       INT NULL    -- references Employees, set after insert
);

-- ============================================================
-- TABLE 2: JobRoles
-- ============================================================
CREATE TABLE JobRoles (
    JobRoleID   INT PRIMARY KEY IDENTITY(1,1),
    JobTitle    VARCHAR(100) NOT NULL,
    JobLevel    VARCHAR(20),   -- Entry / Mid / Senior / Lead
    MinSalary   DECIMAL(10,2),
    MaxSalary   DECIMAL(10,2)
);

-- ============================================================
-- TABLE 3: Employees  (Fact + master table)
-- ============================================================
CREATE TABLE Employees (
    EmployeeID          INT PRIMARY KEY IDENTITY(1001,1),
    FirstName           VARCHAR(50),
    LastName            VARCHAR(50),
    Gender              CHAR(1),           -- M / F
    DateOfBirth         DATE,
    HireDate            DATE,
    TerminationDate     DATE NULL,         -- NULL = still active
    DepartmentID        INT REFERENCES Departments(DepartmentID),
    JobRoleID           INT REFERENCES JobRoles(JobRoleID),
    Salary              DECIMAL(10,2),
    PerformanceScore    TINYINT,           -- 1 to 5
    Attrition           BIT DEFAULT 0,    -- 1 = left the company
    EducationLevel      VARCHAR(30),
    MaritalStatus       VARCHAR(20),
    WorkMode            VARCHAR(20),       -- Remote / Hybrid / On-site
    YearsAtCompany      TINYINT,
    TrainingHoursPerYear SMALLINT,
    JobSatisfaction     TINYINT           -- 1 to 5
);

-- ============================================================
-- TABLE 4: PerformanceReviews
-- ============================================================
CREATE TABLE PerformanceReviews (
    ReviewID        INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID      INT REFERENCES Employees(EmployeeID),
    ReviewDate      DATE,
    ReviewScore     TINYINT,      -- 1 to 5
    ReviewerNotes   VARCHAR(255)
);

-- ============================================================
-- TABLE 5: TrainingRecords
-- ============================================================
CREATE TABLE TrainingRecords (
    TrainingID      INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID      INT REFERENCES Employees(EmployeeID),
    TrainingName    VARCHAR(100),
    CompletionDate  DATE,
    DurationHours   SMALLINT,
    Score           DECIMAL(5,2)  -- 0 to 100
);

-- ============================================================
-- TABLE 6: SalaryHistory
-- ============================================================
CREATE TABLE SalaryHistory (
    HistoryID       INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID      INT REFERENCES Employees(EmployeeID),
    EffectiveDate   DATE,
    OldSalary       DECIMAL(10,2),
    NewSalary       DECIMAL(10,2),
    ChangeReason    VARCHAR(50)   -- Promotion / Annual Hike / Adjustment
);

GO

-- ============================================================
-- SEED DATA: Departments
-- ============================================================
INSERT INTO Departments (DepartmentName, Location) VALUES
('Human Resources',   'Mumbai'),
('Engineering',       'Bangalore'),
('Sales',             'Delhi'),
('Marketing',         'Bangalore'),
('Finance',           'Mumbai'),
('Customer Support',  'Hyderabad'),
('Product',           'Bangalore'),
('Operations',        'Chennai');

-- ============================================================
-- SEED DATA: JobRoles
-- ============================================================
INSERT INTO JobRoles (JobTitle, JobLevel, MinSalary, MaxSalary) VALUES
('HR Executive',             'Entry',  300000,  550000),
('HR Manager',               'Senior', 700000, 1200000),
('Software Engineer',        'Mid',    600000, 1200000),
('Senior Software Engineer', 'Senior', 1000000,1800000),
('Tech Lead',                'Lead',   1500000,2500000),
('Sales Executive',          'Entry',  350000,  650000),
('Sales Manager',            'Senior', 800000, 1400000),
('Marketing Analyst',        'Entry',  400000,  750000),
('Marketing Manager',        'Senior', 900000, 1500000),
('Finance Analyst',          'Mid',    550000, 1000000),
('Finance Manager',          'Senior', 1000000,1700000),
('Support Specialist',       'Entry',  280000,  500000),
('Product Manager',          'Senior', 1200000,2200000),
('Operations Analyst',       'Mid',    450000,  900000),
('Data Analyst',             'Mid',    600000, 1100000);

-- ============================================================
-- SEED DATA: Employees (50 employees)
-- ============================================================
INSERT INTO Employees
(FirstName, LastName, Gender, DateOfBirth, HireDate, TerminationDate,
 DepartmentID, JobRoleID, Salary, PerformanceScore, Attrition,
 EducationLevel, MaritalStatus, WorkMode, YearsAtCompany, TrainingHoursPerYear, JobSatisfaction)
VALUES
-- Engineering
('Arjun',    'Sharma',    'M','1992-03-15','2018-06-01',NULL,           2, 3, 920000,4,0,'Bachelor','Married',  'Hybrid',   7,40,4),
('Priya',    'Nair',      'F','1995-07-22','2020-01-15',NULL,           2, 3, 850000,5,0,'Master',  'Single',   'Remote',   5,55,5),
('Karan',    'Mehta',     'M','1990-11-03','2016-03-10',NULL,           2, 4,1350000,4,0,'Master',  'Married',  'Hybrid',   9,30,4),
('Sneha',    'Kulkarni',  'F','1993-08-19','2019-08-20',NULL,           2, 4,1250000,3,0,'Bachelor','Single',   'Remote',   6,45,3),
('Rahul',    'Verma',     'M','1988-05-12','2014-11-05',NULL,           2, 5,1900000,5,0,'Master',  'Married',  'On-site',  11,20,4),
('Anita',    'Singh',     'F','1996-02-28','2021-04-01','2023-09-30',   2, 3, 750000,2,1,'Bachelor','Single',   'Remote',   2,60,2),
('Vikram',   'Reddy',     'M','1991-09-14','2017-07-18',NULL,           2, 4,1100000,4,0,'Bachelor','Married',  'Hybrid',   8,35,4),
('Divya',    'Pillai',    'F','1994-12-05','2020-06-15',NULL,           2, 3, 880000,4,0,'Master',  'Single',   'Remote',   5,50,4),
('Rohan',    'Joshi',     'M','1997-04-17','2022-01-10',NULL,           2, 3, 700000,3,0,'Bachelor','Single',   'Hybrid',   3,65,3),
('Kavya',    'Rao',       'F','1993-06-23','2018-09-01','2022-12-31',   2, 4,1150000,2,1,'Master',  'Married',  'Hybrid',   4,40,2),

-- Sales
('Amit',     'Gupta',     'M','1989-01-10','2015-04-01',NULL,           3, 6, 580000,5,0,'Bachelor','Married',  'On-site',  10,25,5),
('Pooja',    'Sharma',    'F','1994-05-16','2019-06-01','2023-03-31',   3, 6, 450000,2,1,'Bachelor','Single',   'On-site',  4, 30,2),
('Sandeep',  'Kumar',     'M','1987-08-25','2013-02-14',NULL,           3, 7,1100000,4,0,'Master',  'Married',  'Hybrid',   12,15,4),
('Riya',     'Patel',     'F','1995-11-30','2020-10-05',NULL,           3, 6, 520000,4,0,'Bachelor','Single',   'On-site',  5, 28,4),
('Suresh',   'Yadav',     'M','1990-03-07','2017-01-20','2023-06-30',   3, 6, 490000,1,1,'Diploma', 'Married',  'On-site',  6, 20,1),
('Nisha',    'Jain',      'F','1992-07-14','2018-03-01',NULL,           3, 7,1050000,5,0,'Master',  'Single',   'Hybrid',   7, 18,5),
('Deepak',   'Mishra',    'M','1991-04-22','2016-08-10',NULL,           3, 6, 560000,3,0,'Bachelor','Married',  'On-site',  9, 22,3),

-- Marketing
('Lakshmi',  'Iyer',      'F','1993-09-18','2019-02-01',NULL,           4, 8, 680000,4,0,'Master',  'Married',  'Remote',   6, 50,4),
('Nikhil',   'Bose',      'M','1996-01-29','2021-07-15',NULL,           4, 8, 580000,3,0,'Bachelor','Single',   'Hybrid',   4, 45,3),
('Swati',    'Agarwal',   'F','1990-06-03','2015-09-01',NULL,           4, 9,1300000,5,0,'Master',  'Married',  'Hybrid',   10,20,5),
('Rajesh',   'Tiwari',    'M','1988-12-11','2014-05-06','2022-08-31',   4, 8, 650000,2,1,'Bachelor','Married',  'On-site',  8, 30,2),
('Meena',    'Choudhary', 'F','1995-03-25','2020-11-01',NULL,           4, 8, 620000,4,0,'Master',  'Single',   'Remote',   5, 55,4),

-- Finance
('Anil',     'Kapoor',    'M','1985-07-07','2010-01-04',NULL,           5,10, 900000,4,0,'Master',  'Married',  'On-site',  15,15,4),
('Sunita',   'Roy',       'F','1992-10-13','2018-07-09',NULL,           5,10, 820000,5,0,'Master',  'Married',  'Hybrid',   7, 30,5),
('Gaurav',   'Saxena',    'M','1994-02-17','2020-03-01',NULL,           5,10, 750000,3,0,'Bachelor','Single',   'Remote',   5, 40,3),
('Preethi',  'Das',       'F','1991-05-28','2017-11-15','2023-01-31',   5,10, 770000,2,1,'Master',  'Single',   'Hybrid',   5, 35,2),
('Manish',   'Tomar',     'M','1987-09-02','2013-06-01',NULL,           5,11,1450000,5,0,'Master',  'Married',  'On-site',  12,10,5),

-- HR
('Rekha',    'Menon',     'F','1986-04-19','2011-08-01',NULL,           1, 2,1000000,5,0,'Master',  'Married',  'On-site',  14,12,5),
('Vivek',    'Srivastava','M','1993-11-06','2019-05-20',NULL,           1, 1, 420000,3,0,'Bachelor','Single',   'Hybrid',   6, 35,3),
('Ananya',   'Chatterjee','F','1996-08-11','2021-09-01','2023-11-30',   1, 1, 380000,2,1,'Bachelor','Single',   'Remote',   2, 50,2),

-- Customer Support
('Sunil',    'Pandey',    'M','1991-02-14','2017-10-01',NULL,           6,12, 390000,3,0,'Diploma', 'Married',  'On-site',  7, 25,3),
('Geetha',   'Krishnan',  'F','1994-07-30','2020-04-01',NULL,           6,12, 360000,4,0,'Bachelor','Single',   'On-site',  5, 30,4),
('Harish',   'Naidu',     'M','1989-12-20','2015-06-15','2022-05-31',   6,12, 340000,1,1,'Diploma', 'Married',  'On-site',  7, 20,1),
('Asha',     'Thomas',    'F','1995-05-09','2021-01-15',NULL,           6,12, 350000,4,0,'Bachelor','Married',  'On-site',  4, 35,4),

-- Product
('Kartik',   'Bhatia',    'M','1990-08-14','2016-10-01',NULL,           7,13,1800000,5,0,'Master',  'Married',  'Remote',   9, 25,5),
('Neha',     'Malhotra',  'F','1993-03-22','2019-01-07',NULL,           7,13,1600000,4,0,'Master',  'Single',   'Hybrid',   6, 30,4),
('Aakash',   'Shah',      'M','1992-06-18','2018-04-01',NULL,           7,13,1750000,4,0,'Master',  'Married',  'Remote',   7, 20,4),
('Ishaan',   'Goswami',   'M','1997-01-05','2022-06-01','2024-01-31',   7,13,1400000,2,1,'Master',  'Single',   'Hybrid',   2, 40,2),

-- Operations
('Ramesh',   'Yadav',     'M','1988-10-31','2014-03-01',NULL,           8,14, 720000,3,0,'Bachelor','Married',  'On-site',  11,20,3),
('Seema',    'Agarwal',   'F','1992-04-16','2018-12-01',NULL,           8,14, 680000,4,0,'Bachelor','Single',   'Hybrid',   7, 30,4),
('Tushar',   'Joshi',     'M','1995-09-27','2021-03-15',NULL,           8,14, 580000,3,0,'Diploma', 'Single',   'On-site',  4, 40,3),
('Pallavi',  'Nanda',     'F','1990-01-19','2016-07-01','2022-10-31',   8,14, 640000,2,1,'Bachelor','Married',  'On-site',  6, 25,2),

-- Additional Data Analysts across departments
('Varun',    'Khanna',    'M','1993-05-11','2019-07-01',NULL,           2,15, 980000,4,0,'Master',  'Single',   'Remote',   6, 55,4),
('Shruti',   'Bansal',    'F','1995-12-08','2021-08-01',NULL,           4,15, 820000,3,0,'Bachelor','Single',   'Remote',   4, 60,3),
('Dev',      'Kapoor',    'M','1991-07-22','2017-05-01',NULL,           5,15, 870000,5,0,'Master',  'Married',  'Hybrid',   8, 35,5),
('Tanvi',    'Malviya',   'F','1996-10-04','2022-03-01',NULL,           3,15, 720000,3,0,'Bachelor','Single',   'On-site',  3, 50,3),
('Mohit',    'Rastogi',   'M','1989-03-17','2015-11-01','2023-07-31',   6,15, 750000,2,1,'Bachelor','Married',  'Hybrid',   8, 30,2);

GO

-- ============================================================
-- SEED DATA: PerformanceReviews
-- ============================================================
INSERT INTO PerformanceReviews (EmployeeID, ReviewDate, ReviewScore, ReviewerNotes) VALUES
(1001,'2022-12-15',4,'Consistently delivers on time. Good team player.'),
(1001,'2023-12-15',4,'Improved documentation practices this year.'),
(1002,'2022-12-20',5,'Exceptional technical skills. Promoted recommended.'),
(1002,'2023-12-20',5,'Best performer in team. Leadership potential.'),
(1003,'2022-12-18',4,'Strong delivery. Needs to improve communication.'),
(1003,'2023-12-18',4,'Solid year. Led migration project successfully.'),
(1004,'2023-12-10',3,'Average performance. Needs upskilling in cloud.'),
(1005,'2022-12-22',5,'Outstanding. Leads by example. Highly recommended.'),
(1005,'2023-12-22',5,'Delivered 3 major products on time.'),
(1006,'2022-12-14',2,'Below expectations. Frequent absences noted.'),
(1011,'2022-12-17',5,'Top sales closer. Exceeded target by 40%.'),
(1011,'2023-12-17',5,'Exceptional client relationships.'),
(1013,'2022-12-19',4,'Strong manager, good pipeline management.'),
(1016,'2022-12-20',5,'Excellent manager. Team morale high.'),
(1018,'2022-12-16',4,'Creative campaigns, good ROI tracking.'),
(1020,'2022-12-21',5,'Exceptional strategy and execution.'),
(1020,'2023-12-21',5,'Awarded best marketing campaign of the year.'),
(1023,'2022-12-13',4,'Reliable, good financial modelling skills.'),
(1024,'2022-12-14',5,'Best analyst in the team.'),
(1027,'2022-12-22',5,'Strong finance manager. Drove cost savings of 12%.'),
(1028,'2022-12-12',5,'Best HR manager. Low attrition under her watch.'),
(1035,'2022-12-18',5,'Best product manager. Launched 2 products in 2022.'),
(1035,'2023-12-18',5,'Vision and execution both outstanding.'),
(1036,'2022-12-19',4,'Strong roadmap ownership.'),
(1039,'2022-12-15',3,'Solid operations support.'),
(1044,'2022-12-20',4,'Great data skills, proactive insights.'),
(1046,'2023-12-10',5,'Driven insights that impacted revenue.'),
(1047,'2023-12-12',3,'Good but needs mentoring in advanced analytics.');

GO

-- ============================================================
-- SEED DATA: TrainingRecords
-- ============================================================
INSERT INTO TrainingRecords (EmployeeID, TrainingName, CompletionDate, DurationHours, Score) VALUES
(1001,'Advanced SQL','2022-03-15',16,88.5),
(1001,'Azure Cloud Fundamentals','2023-05-20',24,92.0),
(1002,'Python for Data Science','2022-06-10',32,97.5),
(1002,'Machine Learning Basics','2023-02-18',40,95.0),
(1003,'Agile Project Management','2022-09-05',16,84.0),
(1004,'Cloud Architecture','2023-07-14',24,72.5),
(1005,'Leadership Excellence','2022-11-20',16,96.5),
(1005,'System Design','2023-03-08',32,98.0),
(1011,'Sales Negotiation Mastery','2022-04-12',24,95.0),
(1013,'B2B Sales Strategy','2022-08-22',16,88.0),
(1016,'Digital Marketing Mastery','2022-07-18',24,91.0),
(1018,'SEO and Analytics','2023-04-10',16,86.5),
(1020,'Marketing Leadership','2022-10-05',20,98.0),
(1023,'Financial Modelling','2022-05-14',32,90.0),
(1024,'Power BI for Finance','2023-01-25',16,94.0),
(1027,'Executive Finance Strategy','2022-09-30',20,97.0),
(1028,'HR Leadership Development','2022-06-15',24,99.0),
(1029,'Recruitment & Talent','2023-08-10',16,82.0),
(1031,'Customer Excellence','2022-11-11',16,88.0),
(1032,'CRM Tools','2023-02-20',12,91.0),
(1035,'Product Strategy','2022-07-05',24,98.5),
(1035,'Agile for Product Managers','2023-06-15',20,96.0),
(1036,'UX for Product Managers','2022-08-30',16,90.0),
(1039,'Operations Fundamentals','2022-04-18',24,80.5),
(1044,'Advanced Analytics','2023-09-20',32,93.0),
(1046,'Power BI Advanced','2022-12-10',24,96.5),
(1047,'SQL for Analysts','2023-03-28',16,85.0),
(1048,'Python for Analysts','2023-08-15',24,88.0);

GO

-- ============================================================
-- SEED DATA: SalaryHistory
-- ============================================================
INSERT INTO SalaryHistory (EmployeeID, EffectiveDate, OldSalary, NewSalary, ChangeReason) VALUES
(1001,'2020-04-01', 750000,  820000, 'Annual Hike'),
(1001,'2022-04-01', 820000,  920000, 'Promotion'),
(1002,'2021-04-01', 700000,  780000, 'Annual Hike'),
(1002,'2023-04-01', 780000,  850000, 'Annual Hike'),
(1003,'2020-04-01',1100000, 1200000, 'Annual Hike'),
(1003,'2022-04-01',1200000, 1350000, 'Promotion'),
(1005,'2020-04-01',1600000, 1750000, 'Annual Hike'),
(1005,'2022-01-01',1750000, 1900000, 'Promotion'),
(1011,'2020-04-01', 480000,  530000, 'Annual Hike'),
(1011,'2022-04-01', 530000,  580000, 'Annual Hike'),
(1013,'2020-04-01', 950000, 1050000, 'Annual Hike'),
(1013,'2022-04-01',1050000, 1100000, 'Adjustment'),
(1020,'2019-04-01',1100000, 1200000, 'Annual Hike'),
(1020,'2021-04-01',1200000, 1300000, 'Promotion'),
(1023,'2020-04-01', 750000,  820000, 'Annual Hike'),
(1023,'2022-04-01', 820000,  900000, 'Promotion'),
(1027,'2019-04-01',1200000, 1350000, 'Annual Hike'),
(1027,'2022-04-01',1350000, 1450000, 'Promotion'),
(1028,'2019-04-01', 850000,  950000, 'Annual Hike'),
(1028,'2022-04-01', 950000, 1000000, 'Promotion'),
(1035,'2020-04-01',1500000, 1650000, 'Annual Hike'),
(1035,'2022-04-01',1650000, 1800000, 'Promotion'),
(1036,'2021-04-01',1400000, 1520000, 'Annual Hike'),
(1036,'2023-04-01',1520000, 1600000, 'Annual Hike'),
(1039,'2020-04-01', 600000,  660000, 'Annual Hike'),
(1039,'2022-04-01', 660000,  720000, 'Annual Hike'),
(1044,'2021-04-01', 850000,  920000, 'Annual Hike'),
(1044,'2023-04-01', 920000,  980000, 'Annual Hike'),
(1046,'2021-04-01', 720000,  800000, 'Annual Hike'),
(1046,'2023-04-01', 800000,  870000, 'Promotion');

GO

PRINT '✅ Database HRAnalytics created successfully with all tables and data!';
PRINT 'You can now run the day-wise SQL scripts.';

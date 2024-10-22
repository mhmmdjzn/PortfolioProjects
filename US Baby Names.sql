DROP SCHEMA IF EXISTS baby_names_db;
CREATE SCHEMA baby_names_db;
USE baby_names_db;


-- Create new table names

 CREATE TABLE names (
 State CHAR(2),
 Gender CHAR(1),
 Year INT,
 Name VARCHAR(45),
 Births INT);
  

-- Create new table regions

 CREATE TABLE regions (
 State CHAR(2),
 Region VARCHAR(45));


-- Import names from CSV

BULK INSERT names
FROM 'C:\Users\Work\Documents\BabyNames\names_data.csv'
WITH
(
	FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 0
);


-- Import regions from CSV

BULK INSERT regions
FROM 'C:\Users\Work\Documents\BabyNames\regions.csv'
WITH
(
	FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 0
);


-- Top 10 most liked names in the United States for 30 years (1980 - 2009)

SELECT TOP 10 Name, Gender, SUM(Births) AS TotalBirths
FROM dbo.names
GROUP BY Name, Gender
ORDER BY TotalBirths DESC;


-- Top 10 Most popular male name

SELECT TOP 10 Name, SUM(Births) AS TotalBirths
FROM dbo.names
WHERE Gender = 'M'
GROUP BY Name
ORDER BY TotalBirths DESC;


-- Top 10 most liked female names ending in "a" in 2004

SELECT TOP 10 Name, SUM(Births) AS TotalBirths
FROM dbo.names
WHERE Gender = 'F' AND Name LIKE '%a' AND Year = 2004
GROUP BY Name
ORDER BY TotalBirths DESC;


-- Top 10 most popular female names starting with "S" from 1999 to 2002

SELECT TOP 10 Name, SUM(Births) AS TotalBirths
FROM dbo.names
WHERE Gender = 'F' AND Name LIKE 'S%' AND Year BETWEEN 1999 AND 2002
GROUP BY Name
ORDER BY TotalBirths DESC;


-- The most popular male names by year

WITH RankedNames AS (
	SELECT 
		Year,
		Name,
		SUM(Births) AS TotalBirths,
		ROW_NUMBER() OVER (PARTITION BY Year ORDER BY SUM(Births) DESC) AS Rank
	FROM dbo.names
	WHERE Gender = 'M'
	GROUP BY Year, Name
)

SELECT Year, Name, TotalBirths
FROM RankedNames
WHERE Rank = 1
ORDER BY Year ASC;


-- Total births in each region

SELECT 
	dbo.regions.Region,
	SUM(Births) AS TotalBirths
FROM dbo.names
INNER JOIN dbo.regions
ON dbo.names.State = dbo.regions.State
GROUP BY dbo.regions.Region
ORDER BY TotalBirths DESC;


-- Total births for each name in each region

SELECT 
	dbo.regions.Region,
	Name,
	SUM(Births) AS TotalBirths
FROM dbo.names
INNER JOIN dbo.regions
ON dbo.names.State = dbo.regions.State
GROUP BY dbo.regions.Region,Name
ORDER BY TotalBirths DESC;


-- Total births with the name 'David' in each region

SELECT 
	dbo.regions.Region,
	SUM(Births) AS TotalBirths
FROM dbo.names
INNER JOIN dbo.regions
ON dbo.names.State = dbo.regions.State
WHERE Name = 'David'
GROUP BY dbo.regions.Region,Name
ORDER BY TotalBirths DESC;


-- Average number of births per year for each name

SELECT
	Name,
	SUM(Births)/COUNT(DISTINCT YEAR) AS Average
FROM dbo.names
GROUP BY Name
ORDER BY Average DESC;


-- The most frequently given female name in the Pacific region

SELECT Name, SUM(Births) AS TotalBirths
FROM dbo.names
INNER JOIN dbo.regions
ON dbo.names.State = dbo.regions.State
WHERE dbo.regions.Region = 'Pacific' AND Gender = 'F'
GROUP BY dbo.regions.Region,Name
ORDER BY TotalBirths DESC;


-- Number of male and female births each year

SELECT 
    Year,
    SUM(CASE WHEN Gender = 'M' THEN Births ELSE 0 END) AS Male_Births,
    SUM(CASE WHEN Gender = 'F' THEN Births ELSE 0 END) AS Female_Births,
	SUM(Births) AS TotalBirth
FROM dbo.names
GROUP BY Year
ORDER BY Year;


-- Name variations from year to year

SELECT 
    Year, COUNT(DISTINCT Name) AS TotalName
FROM dbo.names
GROUP BY Year
ORDER BY Year;


-- The combination of name and year with the highest number of births

SELECT 
	Year,
	Name,
	SUM(Births) AS TotalBirths
FROM dbo.names
GROUP BY Year,Name
ORDER BY TotalBirths DESC;


-- The most consistent name in terms of number of births over the last 5 years

SELECT Name, SUM(Births) AS TotalBirths
FROM dbo.names
WHERE Year BETWEEN (SELECT MAX(Year) FROM dbo.names) - 4 AND (SELECT MAX(Year) FROM dbo.names)
GROUP BY Name
ORDER BY TotalBirths DESC;


-- Comparison of the number of male and female births in the New England region

SELECT 
    SUM(CASE WHEN Gender = 'M' THEN Births ELSE 0 END) AS Male_Births,
    SUM(CASE WHEN Gender = 'F' THEN Births ELSE 0 END) AS Female_Births
FROM dbo.names
INNER JOIN dbo.regions
ON dbo.regions.State = dbo.names.State
WHERE dbo.regions.Region = 'New_England'


-- Names has more than 20,000 births in 1999

WITH RankedNames AS (
	SELECT 
		Year,
		Name,
		SUM(Births) AS TotalBirths
	FROM dbo.names
	WHERE Gender = 'M'
	GROUP BY Year, Name
)

SELECT Name AS TotalNames
FROM RankedNames
WHERE TotalBirths >= 20000 AND Year = 1999


-- Percentage increase or decrease in the number of births with the name Jim from year to year

WITH NameBirths AS (
    SELECT 
        Year,
        SUM(Births) AS TotalBirths
    FROM dbo.names
    WHERE Name = 'Jim'
    GROUP BY Year
)
SELECT 
    Year,
    TotalBirths,
    LAG(TotalBirths, 1) OVER (ORDER BY Year) AS PreviousYearBirths,
    CASE 
        WHEN LAG(TotalBirths, 1) OVER (ORDER BY Year) IS NOT NULL THEN
            CAST(ROUND(((TotalBirths - LAG(TotalBirths, 1) OVER (ORDER BY Year)) * 100.0 / LAG(TotalBirths, 1) OVER (ORDER BY Year)), 2) AS DECIMAL(5 ,2))
        ELSE
            NULL
    END AS PercentageChange
FROM NameBirths
ORDER BY Year; 


-- New names have emerged in the last year

WITH LastYears AS (
    SELECT DISTINCT Name, SUM(Births) AS TotalBirths
    FROM dbo.names
    WHERE Year >= (SELECT MAX(Year) FROM dbo.names) - 1 
	GROUP BY Name
),
PreviousYears AS (
    SELECT DISTINCT Name
    FROM dbo.names
    WHERE Year < (SELECT MAX(Year) FROM dbo.names) - 1
)

SELECT Name, TotalBirths
FROM LastYears
WHERE Name NOT IN (SELECT Name FROM PreviousYears)
ORDER BY TotalBirths DESC;


-- Top 5 female name that experienced the biggest decline in popularity in 1994

WITH PreviousYearData AS (
    SELECT
        Year,
        Name,
        SUM(Births) AS TotalBirths,
        LAG(SUM(Births)) OVER (PARTITION BY Name ORDER BY Year) AS PreviousYearBirths
    FROM dbo.names
    WHERE Gender = 'F'
    GROUP BY Year, Name
)

SELECT TOP 5
    Name,
    TotalBirths AS BirthsIn1994,
    PreviousYearBirths AS BirthsIn1993,
    (PreviousYearBirths - TotalBirths) AS PopularityDrop
FROM PreviousYearData
WHERE Year = 1994
ORDER BY PopularityDrop DESC;


-- Top 5 male name experienced the highest increase in popularity in 1991

WITH PreviousYearData AS (
    SELECT
        Year,
        Name,
        SUM(Births) AS TotalBirths,
        LAG(SUM(Births)) OVER (PARTITION BY Name ORDER BY Year) AS PreviousYearBirths
    FROM dbo.names
    WHERE Gender = 'M'
    GROUP BY Year, Name
)

SELECT TOP 5
    Name,
    TotalBirths AS BirthsIn1991,
    PreviousYearBirths AS BirthsIn1990,
    (TotalBirths - PreviousYearBirths) AS PopularityIncrease
FROM PreviousYearData
WHERE Year = 1991
ORDER BY PopularityIncrease DESC;




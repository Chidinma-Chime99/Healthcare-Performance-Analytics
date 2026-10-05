--HEALTHCARE PERFORMANCE ANALYTICS
--Author: Chime Chidinma Sylvia
--Description: Multi-Table Data Exploration and Insights

--Creating a database
CREATE DATABASE Healthcare_Capstone;

--Utilizing the database
USE Healthcare_Capstone;

--Handling missing or inconsistent data
SELECT * FROM FactTable
WHERE Payment IS NULL
OR GrossCharge IS NULL
OR CPTUnits IS NULL;

--Removing duplicates
SELECT DimpatientPK, COUNT(*) AS duplicate
FROM Dimpatient
GROUP BY dimPatientPK
HAVING COUNT(*) > 1;

--Standardizing state format

--Finding the count of unique state

SELECT COUNT(DISTINCT State) AS Uniquestate
FROM dimpatient

--Getting the unique state
SELECT DISTINCT State
FROM Dimpatient
ORDER BY State

--Standardizing the state format
SELECT State AS State_Abbreviation,
CASE State 
    WHEN 'AL' THEN 'Alabama'
    WHEN 'AZ' THEN 'Arizona'
    WHEN 'FL' THEN 'Florida'
    WHEN 'IA' THEN 'Iowa'
    WHEN 'IL' THEN 'Illinois'
    WHEN 'IN' THEN 'Indiana'
    WHEN 'KS' THEN 'Kansas'
    WHEN 'MA' THEN 'Massachusetts'
    WHEN 'ME' THEN 'Maine'
    WHEN 'MS' THEN 'Mississippi'
    WHEN 'MT' THEN 'Montana'
    WHEN 'NH' THEN 'New Hampshire'
    WHEN 'NY' THEN 'New York'
    WHEN 'OH' THEN 'Ohio'
    WHEN 'OK' THEN 'Oklahoma'
    WHEN 'PA' THEN 'Pennsylvania'
    WHEN 'TX' THEN 'Texas'
    WHEN 'WV' THEN 'West Virginia'
    ELSE 'Unknown'
END AS State_Fullname
FROM Dimpatient;
    
--Finding out the total number of physicians
SELECT COUNT(DISTINCT dimPhysicianPK) AS Total_Physicians
FROM DimPhyscian

--Finding the minimum and maximum age of patients
SELECT MIN (PatientAge) AS Minimumage
FROM Dimpatient

SELECT MAX (PatientAge) AS Maximumage
FROM Dimpatient

--Sorting the healthcare providers by their specialty
SELECT dimPhysicianPK,ProviderName,ProviderSpecialty
FROM DimPhyscian
ORDER BY ProviderSpecialty

--Sorting the patients by Age and Gender
SELECT PatientGender, PatientAge
FROM Dimpatient
WHERE PatientGender = 'Female' AND PatientAge < 50

--Finding Revenue by Location
SELECT locationName,
SUM (FactTable.Payment) AS Totalrevenue
FROM FactTable
JOIN DimLocation ON FactTable.dimLocationPK = DimLocation.dimLocationPK
GROUP BY DimLocation.LocationName

--Finding the high performing physicians
SELECT DimPhyscian.ProviderSpecialty,
SUM(FactTable.CPTUnits) AS Proceduresdone
FROM FactTable
JOIN DimPhyscian ON FactTable.dimPhysicianPK = DimPhyscian.dimPhysicianPK
GROUP BY DimPhyscian.ProviderSpecialty
HAVING SUM(FactTable.CPTUnits) > 100

--Joining patients and their bill info
SELECT Dimpatient.FirstName,Dimpatient.LastName,
FactTable.Payment
FROM FactTable
JOIN Dimpatient ON FactTable.dimPatientPK = Dimpatient.dimPatientPK

--Joining physician and their procedure
SELECT DimPhyscian.ProviderName, dimCptCode.CptDesc
FROM FactTable
JOIN DimPhyscian ON FactTable.dimPhysicianPK = DimPhyscian.dimPhysicianPK
JOIN dimCptCode ON FactTable.dimCPTCodePK = dimCptCode.dimCPTCodePK

--Which Insurance type drives most hospital visits
WITH CTE_InsuranceVisits AS (
     SELECT DimPayer.PayerName,
     COUNT(FactTable.FactTablePK) AS Totalvisits
     FROM FactTable
     JOIN DimPayer ON FactTable.dimPayerPK = DimPayer.dimPayerPK
     GROUP BY DimPayer.PayerName)
SELECT * FROM CTE_InsuranceVisits
ORDER BY Totalvisits DESC

--Finding above average revenue Physicians
SELECT *
FROM (
      SELECT dimPhysicianPK,
      SUM (Payment) AS Revenue
      FROM FactTable
      GROUP BY dimPhysicianPK) T 
WHERE Revenue >
        (SELECT AVG(Payment) FROM FactTable)

--Ranking Physicians by revenue
SELECT dimphysicianPK, 
SUM(Payment) AS Revenue,
RANK() OVER (ORDER BY SUM(Payment) DESC) AS Revenuerank
FROM FactTable
GROUP BY dimPhysicianPK

--Running revenue total
SELECT dimDate.[Date],
SUM (FactTable.Payment) AS dailyrevenue,
SUM(SUM(FactTable.Payment))
OVER (ORDER BY dimDate.[Date]) AS Runningtotal
FROM FactTable
JOIN dimDate ON FactTable.dimDateServicePK = dimDate.dimDatePostPK
GROUP BY dimDate.[Date];

--Male vs Female cost comparison
SELECT Dimpatient.PatientGender,
SUM (FactTable.payment) AS totalCost
FROM FactTable
JOIN dimPatient ON FactTable.dimPatientPK = dimpatient.dimpatientPK
GROUP BY dimpatient.patientgender

--Financial Performance Analysis
SELECT SUM(GrossCharge) AS Grosscharges,
SUM(Payment) AS Payments,
SUM(Adjustment) AS Adjustments,
SUM(AR) AS AccountsReceivable
FROM FactTable

--RESEARCH QUESTIONS

--Which insurer contributes most to outstanding receivables?
SELECT DimPayer.PayerName AS Insurance_type,
SUM(FactTable.AR) Total_amt_owed
FROM FactTable
JOIN DimPayer ON FactTable.dimPayerPK = DimPayer.dimPayerPK
GROUP BY DimPayer.PayerName
ORDER BY Total_amt_owed DESC

--Most Productive Physicians
SELECT TOP 5
DimPhyscian.ProviderName,
SUM(FactTable.CPTUnits) AS TotalProcedures
FROM FactTable
JOIN DimPhyscian ON FactTable.dimPhysicianPK = DimPhyscian.dimPhysicianPK
GROUP BY DimPhyscian.ProviderName
ORDER BY TotalProcedures DESC

--Specialty performing most procedures
SELECT TOP 5 DimPhyscian.ProviderSpecialty,
SUM(FactTable.CPTUnits) AS Procedures
FROM FactTable
JOIN DimPhyscian ON FactTable.dimPhysicianPK =DimPhyscian.dimPhysicianPK
GROUP BY DimPhyscian.ProviderSpecialty
ORDER BY Procedures DESC;

--Location handling most patients
SELECT TOP 5
DimLocation.LocationName,
COUNT(DISTINCT FactTable.dimPatientPK) AS Patients
FROM FactTable
JOIN DimLocation ON FactTable.dimLocationPK = DimLocation.dimLocationPK
GROUP BY DimLocation.LocationName
ORDER BY Patients DESC


--KEY PERFORMANCE INDICATORS

--Total Patients
SELECT COUNT(DISTINCT dimPatientPK) AS Total_Patients
FROM Dimpatient

--Total Physicians
SELECT COUNT(DISTINCT dimPhysicianPK) AS Total_Physicians
FROM DimPhyscian

--Gross Charges
SELECT SUM(GrossCharge) AS GrossCharges
FROM FactTable

--Total Revenue
SELECT SUM(Payment) AS Total_Revenue
FROM FactTable

--Creating one master table
SELECT dimDate.MonthYear,
DimLocation.LocationName,
DimPayer.PayerName,
DimPhyscian.ProviderName,
DimPhyscian.ProviderSpecialty,
FactTable.CPTUnits,
FactTable.GrossCharge,
FactTable.Payment,
FactTable.Adjustment,
FactTable.AR
FROM FactTable JOIN DimLocation ON FactTable.dimLocationPK = DimLocation.dimLocationPK
JOIN DimPayer ON FactTable.dimPayerPK = DimPayer.dimPayerPK
JOIN DimPhyscian ON FactTable.dimPhysicianPK = DimPhyscian.dimPhysicianPK
JOIN dimDate ON FactTable.dimDateServicePK = dimDate.dimDatePostPK
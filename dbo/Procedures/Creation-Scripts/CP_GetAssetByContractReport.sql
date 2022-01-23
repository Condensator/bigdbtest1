SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CP_GetAssetByContractReport]
(
@CommencementDateFrom DATETIMEOFFSET=NULL
,@CommencementDateTo DATETIMEOFFSET=NULL
,@MaturityDateFrom DATETIMEOFFSET=NULL
,@MaturityDateTo DATETIMEOFFSET=NULL
,@FromSequenceNumber NVARCHAR(40)=NULL
,@ToSequenceNumber NVARCHAR(40)=NULL
,@CustomerNumber NVARCHAR(500)=NULL
,@CustomerName NVARCHAR(500)=NULL
,@ContractBookingStatus VARCHAR(40)=NULL
,@IsCommencementUpToDate NVARCHAR(1)=NULL
,@IsMaturityUpToDate NVARCHAR(1)=NULL
,@AssetUDF1 NVARCHAR(40)=NULL
,@AssetUDF2 NVARCHAR(40)=NULL
,@AssetUDF3 NVARCHAR(40)=NULL
,@AssetUDF4 NVARCHAR(40)=NULL
,@AssetUDF5 NVARCHAR(40)=NULL
,@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
DECLARE @Sql NVARCHAR(MAX)
DECLARE @SequenceNumber_Condition NVARCHAR(1000)
DECLARE @LeaseCommencementDate_Condition NVARCHAR(1000)
DECLARE @LeaseMaturityDate_Condition NVARCHAR(1000)
DECLARE @LoanCommencementDate_Condition NVARCHAR(1000)
DECLARE @LoanMaturityDate_Condition NVARCHAR(1000)
SET @Sql =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH CTE_Contracts
AS
(
SELECT
C.Id AS ContractId
,C.SequenceNumber
,C.ContractType
,CASE WHEN LeaseCustomer.Id IS NOT NULL THEN LeaseCustomer.PartyNumber ELSE LoanCustomer.PartyNumber END AS CustomerNumber
,CASE WHEN LeaseCustomer.Id IS NOT NULL THEN LeaseCustomer.PartyName ELSE LoanCustomer.PartyName END AS CustomerName
FROM  Contracts C
LEFT JOIN LeaseFinances Lease ON C.Id = Lease.ContractId
LEFT JOIN Parties LeaseCustomer ON Lease.CustomerId = LeaseCustomer.Id
LEFT JOIN LoanFinances Loan ON C.Id= Loan.ContractId
LEFT JOIN Parties LoanCustomer ON Loan.CustomerId = LoanCustomer.Id
LEFT JOIN ContractAssumptionHistories AssumptionHistory ON C.Id = AssumptionHistory.ContractId AND AssumptionHistory.IsActive=1
LEFT JOIN Parties AssumptionParty ON AssumptionHistory.CustomerId = AssumptionParty.Id
WHERE ((LeaseCustomer.PartyNumber = @CustomerNumber OR
LoanCustomer.PartyNumber = @CustomerNumber) OR AssumptionParty.PartyNumber = @CustomerNumber)
SequenceNumber_Condition
),
CTE_LeaseContractsCurrent
AS
(
SELECT
C.ContractId
,C.SequenceNumber
,C.ContractType
,C.CustomerNumber
,C.CustomerName
FROM CTE_Contracts C
JOIN LeaseFinances Lease ON C.ContractId = Lease.ContractId
WHERE Lease.IsCurrent=1
),
CTE_LeaseContractsAssumed
AS
(
SELECT
C.ContractId
,C.SequenceNumber
,C.ContractType
,C.CustomerNumber
,C.CustomerName
FROM CTE_Contracts C
JOIN LeaseFinances Lease ON C.ContractId = Lease.ContractId
WHERE Lease.IsCurrent=0
AND C.CustomerNumber <> @CustomerNumber
),
CTE_AllLeaseContracts
AS
(
SELECT * FROM CTE_LeaseContractsCurrent
UNION SELECT * FROM CTE_LeaseContractsAssumed
),
CTE_LeaseContracts
AS
(
SELECT DISTINCT
C.ContractId  AS Id
,C.SequenceNumber
,C.ContractType
,C.CustomerNumber
,C.CustomerName
,Lease.Id AS LeaseFinanceId
,Lease.BookingStatus AS Status
,LeaseDetail.TermInMonths  AS Term
,LeaseDetail.CommencementDate AS CommencementDate
,LeaseDetail.MaturityDate AS MaturityDate
FROM CTE_AllLeaseContracts C
JOIN LeaseFinances Lease ON C.ContractId = Lease.ContractId
JOIN LeaseFinanceDetails LeaseDetail ON Lease.Id = LeaseDetail.Id
WHERE
(Lease.IsCurrent =1 OR C.CustomerNumber <> @CustomerNumber )
AND (@ContractBookingStatus IS NULL OR @ContractBookingStatus =''_'' OR @ContractBookingStatus=Lease.BookingStatus)
LeaseCommencementDate_Condition
LeaseMaturityDate_Condition
),
CTE_LoanContractsCurrent
AS
(
SELECT
C.ContractId
,C.SequenceNumber
,C.ContractType
,C.CustomerNumber
,C.CustomerName
FROM CTE_Contracts C
JOIN LoanFinances Loan ON Loan.ContractId = C.ContractId
WHERE Loan.IsCurrent=1
),
CTE_LoanContractsAssumed
AS
(
SELECT
C.ContractId
,C.SequenceNumber
,C.ContractType
,C.CustomerNumber
,C.CustomerName
FROM CTE_Contracts C
JOIN LoanFinances Loan ON Loan.ContractId = C.ContractId
WHERE Loan.IsCurrent=0
AND C.CustomerNumber <> @CustomerNumber
),
CTE_AllLoanContracts
AS
(
SELECT * FROM CTE_LoanContractsCurrent
UNION SELECT * FROM CTE_LoanContractsAssumed
),
CTE_LoanContracts
AS
(
SELECT DISTINCT
C.ContractId AS Id
,C.SequenceNumber
,C.ContractType
,C.CustomerNumber
,C.CustomerName
,Loan.Id AS LoanFinanceId
,Loan.Status AS Status
,Loan.Term  AS Term
,Loan.CommencementDate AS CommencementDate
,Loan.MaturityDate AS MaturityDate
FROM CTE_AllLoanContracts C
JOIN LoanFinances Loan ON Loan.ContractId = C.ContractId
WHERE (Loan.IsCurrent =1 OR C.CustomerNumber <> @CustomerNumber )
AND  (@ContractBookingStatus IS NULL OR @ContractBookingStatus =''_'' OR @ContractBookingStatus=Loan.Status)
LoanCommencementDate_Condition
LoanMaturityDate_Condition
),
CTE_ContractsLease
AS
(
SELECT
Asset.Id AS AssetId
,Asset.ParentAssetId AS ParentAssetId
,Asset.Status AS Status
,Manuf.Name AS Manufacturer
,AssetType.Name AS AssetType
,Asset.Description AS Description
,Asset.Alias AS AssetAlias
,Asset.ModelYear
,Location.AddressLine1 +
(CASE WHEN Location.AddressLine2 IS NOT NULL THEN '', ''+ Location.AddressLine2 ELSE '''' END)+
(CASE WHEN Location.Division IS NOT NULL THEN '', ''+ Location.Division ELSE ''''END)+
(CASE WHEN Location.City IS NOT NULL THEN '', ''+ Location.City ELSE '''' END)+
'', ''+ Location.PostalCode AS Location
,State.LongName AS State
,Country.LongName AS Country
,Lease.SequenceNumber
,UDF.UDF1Value
,UDF.UDF2Value
,UDF.UDF3Value
,UDF.UDF4Value
,UDF.UDF5Value
FROM CTE_LeaseContracts Lease
JOIN LeaseAssets LeaseAsset ON Lease.LeaseFinanceId= LeaseAsset.LeaseFinanceId
JOIN Assets Asset ON  LeaseAsset.AssetId=Asset.Id
JOIN AssetTypes AssetType ON Asset.TypeId = AssetType.Id
LEFT JOIN AssetLocations AssetLocation ON AssetLocation.AssetId=Asset.Id
LEFT JOIN Locations Location ON Location.Id=AssetLocation.LocationId
LEFT JOIN States State ON Location.StateId=State.Id
LEFT JOIN Countries Country ON State.CountryId=Country.Id
LEFT JOIN Manufacturers Manuf ON Asset.ManufacturerId = Manuf.Id
LEFT JOIN UDFValueAssignmentForParties UDF ON Asset.Id= UDF.EntityId
WHERE (LeaseAsset.IsActive=1 OR (Lease.Status=''FullyPaidOff''))
AND AssetType.IsActive=1
AND (Lease.Status=''FullyPaidOff''
OR ((AssetLocation.IsCurrent IS NULL OR AssetLocation.IsCurrent=1)
AND (AssetLocation.IsActive IS NULL OR AssetLocation.IsActive=1)
AND (Location.IsActive IS NULL OR Location.IsActive=1)
AND (Location.ApprovalStatus IS NULL OR Location.ApprovalStatus=''Approved'')
AND (State.IsActive IS NULL OR State.IsActive=1)
AND (Country.IsActive IS NULL OR Country.IsActive=1)
AND (Manuf.IsActive IS NULL OR Manuf.IsActive=1)))
AND (@AssetUDF1 IS NULL OR (UDF.UDF1Value LIKE REPLACE(@AssetUDF1,''*'',''%'') AND UDF.IsActive=1  AND UDF.EntityType=''Asset'' ))
AND (@AssetUDF2 IS NULL OR (UDF.UDF2Value LIKE REPLACE(@AssetUDF2,''*'',''%'') AND UDF.IsActive=1 AND UDF.EntityType=''Asset''))
AND (@AssetUDF3 IS NULL OR (UDF.UDF3Value LIKE REPLACE(@AssetUDF3,''*'',''%'') AND UDF.IsActive=1 AND UDF.EntityType=''Asset''))
AND (@AssetUDF4 IS NULL OR (UDF.UDF4Value LIKE REPLACE(@AssetUDF4,''*'',''%'') AND UDF.IsActive=1 AND UDF.EntityType=''Asset''))
AND (@AssetUDF5 IS NULL OR (UDF.UDF5Value LIKE REPLACE(@AssetUDF5,''*'',''%'') AND UDF.IsActive=1 AND UDF.EntityType=''Asset''))
),
CTE_ContractsLoan
AS
(
SELECT
Asset.Id AS AssetId
,Asset.ParentAssetId AS ParentAssetId
,Asset.Status AS Status
,Manuf.Name AS Manufacturer
,AssetType.Name AS AssetType
,Asset.Description AS Description
,Asset.Alias AS AssetAlias
,Asset.ModelYear
,Location.AddressLine1 +
(CASE WHEN Location.AddressLine2 IS NOT NULL THEN '', ''+ Location.AddressLine2 ELSE '''' END)+
(CASE WHEN Location.Division IS NOT NULL THEN '', ''+ Location.Division ELSE ''''END)+
(CASE WHEN Location.City IS NOT NULL THEN '', ''+ Location.City ELSE '''' END)+
'', ''+ Location.PostalCode AS Location
,State.LongName AS State
,Country.LongName AS Country
,Loan.SequenceNumber
,UDF.UDF1Value
,UDF.UDF2Value
,UDF.UDF3Value
,UDF.UDF4Value
,UDF.UDF5Value
FROM CTE_LoanContracts Loan
JOIN CollateralAssets LoanAsset ON Loan.LoanFinanceId= LoanAsset.LoanFinanceId
JOIN Assets Asset ON  LoanAsset.AssetId=Asset.Id
JOIN AssetTypes AssetType ON Asset.TypeId = AssetType.Id
LEFT JOIN AssetLocations AssetLocation ON AssetLocation.AssetId=Asset.Id
LEFT JOIN Locations Location ON Location.Id=AssetLocation.LocationId
LEFT JOIN States State ON Location.StateId=State.Id
LEFT JOIN Countries Country ON State.CountryId=Country.Id
LEFT JOIN Manufacturers Manuf ON Asset.ManufacturerId = Manuf.Id
LEFT JOIN UDFValueAssignmentForParties UDF ON Asset.Id= UDF.EntityId
WHERE LoanAsset.IsActive=1
AND AssetType.IsActive=1
AND (AssetLocation.IsCurrent IS NULL OR AssetLocation.IsCurrent=1)
AND (AssetLocation.IsActive IS NULL OR AssetLocation.IsActive=1)
AND (Location.IsActive IS NULL OR Location.IsActive=1)
AND (Location.ApprovalStatus IS NULL OR Location.ApprovalStatus=''Approved'')
AND (State.IsActive IS NULL OR State.IsActive=1)
AND (Country.IsActive IS NULL OR Country.IsActive=1)
AND (Manuf.IsActive IS NULL OR Manuf.IsActive=1)
AND (@AssetUDF1 IS NULL OR (UDF.UDF1Value LIKE REPLACE(@AssetUDF1,''*'',''%'') AND UDF.IsActive=1  AND UDF.EntityType=''Asset'' ))
AND (@AssetUDF2 IS NULL OR (UDF.UDF2Value LIKE REPLACE(@AssetUDF2,''*'',''%'') AND UDF.IsActive=1 AND UDF.EntityType=''Asset''))
AND (@AssetUDF3 IS NULL OR (UDF.UDF3Value LIKE REPLACE(@AssetUDF3,''*'',''%'') AND UDF.IsActive=1 AND UDF.EntityType=''Asset''))
AND (@AssetUDF4 IS NULL OR (UDF.UDF4Value LIKE REPLACE(@AssetUDF4,''*'',''%'') AND UDF.IsActive=1 AND UDF.EntityType=''Asset''))
AND (@AssetUDF5 IS NULL OR (UDF.UDF5Value LIKE REPLACE(@AssetUDF5,''*'',''%'') AND UDF.IsActive=1 AND UDF.EntityType=''Asset''))
),
CTE_ContractDetails
AS
(
SELECT * FROM CTE_LeaseContracts
UNION SELECT * FROM CTE_LoanContracts
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM ((SELECT DISTINCT AssetId FROM CTE_ContractsLease) UNION (SELECT DISTINCT AssetId FROM CTE_ContractsLoan) ) A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
),
CTE_AssetDetail
AS
(
SELECT CTE_ContractsLease.*,CTE_AssetSerialNumberDetails.SerialNumber FROM CTE_ContractsLease
LEFT JOIN CTE_AssetSerialNumberDetails ON CTE_ContractsLease.AssetId = CTE_AssetSerialNumberDetails.AssetId
UNION 
SELECT CTE_ContractsLoan.*,CTE_AssetSerialNumberDetails.SerialNumber FROM CTE_ContractsLoan
LEFT JOIN CTE_AssetSerialNumberDetails ON CTE_ContractsLoan.AssetId = CTE_AssetSerialNumberDetails.AssetId
)
Select
DISTINCT
C.CustomerNumber
,C.CustomerName
,C.ContractType
,C.SequenceNumber
,C.CommencementDate
,C.MaturityDate
--,C.Status AS ContractBookingStatus
,CA.AssetId
,CA.ParentAssetId
,CA.AssetAlias
,CA.SerialNumber
,CA.Status
,CA.Manufacturer
,CA.AssetType
,CA.ModelYear
,CA.Location
,CA.State
,CA.Country
,CA.Description
,CA.UDF1Value AS AssetUDF1
,CA.UDF2Value AS AssetUDF2
,CA.UDF3Value AS AssetUDF3
,CA.UDF4Value AS AssetUDF4
,CA.UDF5Value AS AssetUDF5
FROM
CTE_ContractDetails C
LEFT JOIN CTE_AssetDetail CA ON C.SequenceNumber = CA.SequenceNumber
WHERE (@AssetUDF1 IS NULL OR CA.AssetId IS NOT NULL)
AND (@AssetUDF2 IS NULL OR CA.AssetId IS NOT NULL)
AND (@AssetUDF3 IS NULL OR CA.AssetId IS NOT NULL)
AND (@AssetUDF4 IS NULL OR CA.AssetId IS NOT NULL)
AND (@AssetUDF5 IS NULL OR CA.AssetId IS NOT NULL)
'
IF (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND @FromSequenceNumber <> '' AND @ToSequenceNumber <> '')
SET @SequenceNumber_Condition =  'AND C.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber '
ELSE IF(@FromSequenceNumber IS NOT NULL AND @FromSequenceNumber <> '')
SET @SequenceNumber_Condition =  'AND C.SequenceNumber = @FromSequenceNumber '
ELSE IF(@ToSequenceNumber IS NOT NULL AND @ToSequenceNumber <> '')
SET @SequenceNumber_Condition =  'AND C.SequenceNumber = @ToSequenceNumber '
ELSE
SET @SequenceNumber_Condition =  ''
IF (@CommencementDateFrom IS NOT NULL AND @CommencementDateTo IS NOT NULL AND @CommencementDateFrom <> '' AND @CommencementDateTo <> '')
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate BETWEEN CAST(@CommencementDateFrom AS DATE) AND CAST(@CommencementDateTo AS DATE)'
ELSE IF(@CommencementDateFrom IS NOT NULL AND @CommencementDateFrom <> '')
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate = CAST(@CommencementDateFrom AS DATE)'
ELSE IF(@CommencementDateTo IS NOT NULL AND @CommencementDateTo <> '')
IF(@IsCommencementUpToDate = '1')
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate <= CAST(@CommencementDateTo AS DATE) '
ELSE
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate = CAST(@CommencementDateTo AS DATE) '
ELSE
SET @LeaseCommencementDate_Condition =  ''
IF (@CommencementDateFrom IS NOT NULL AND @CommencementDateTo IS NOT NULL)
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate BETWEEN CAST(@CommencementDateFrom AS DATE) AND CAST(@CommencementDateTo AS DATE)'
ELSE IF(@CommencementDateFrom IS NOT NULL AND @CommencementDateFrom <> '')
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate = CAST(@CommencementDateFrom AS DATE) '
ELSE IF(@CommencementDateTo IS NOT NULL AND @CommencementDateTo <> '')
IF(@IsCommencementUpToDate = '1')
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate <= CAST(@CommencementDateTo AS DATE) '
ELSE
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate = CAST(@CommencementDateTo AS DATE) '
ELSE
SET @LoanCommencementDate_Condition =  ''
IF (@MaturityDateFrom IS NOT NULL AND @MaturityDateTo IS NOT NULL)
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate BETWEEN CAST(@MaturityDateFrom AS DATE) AND CAST(@MaturityDateTo AS DATE) '
ELSE IF(@MaturityDateFrom IS NOT NULL AND @MaturityDateFrom <> '')
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate = CAST(@MaturityDateFrom AS DATE)'
ELSE IF(@MaturityDateTo IS NOT NULL AND @MaturityDateTo <> '')
IF(@IsMaturityUpToDate = '1')
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate <= CAST(@MaturityDateTo AS DATE) '
ELSE
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate = CAST(@MaturityDateTo AS DATE) '
ELSE
SET @LeaseMaturityDate_Condition =  ''
IF (@MaturityDateFrom IS NOT NULL AND @MaturityDateTo IS NOT NULL)
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate BETWEEN CAST(@MaturityDateFrom AS DATE) AND CAST(@MaturityDateTo AS DATE) '
ELSE IF(@MaturityDateFrom IS NOT NULL AND @MaturityDateFrom <> '')
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate = CAST(@MaturityDateFrom AS DATE)'
ELSE IF(@MaturityDateTo IS NOT NULL AND @MaturityDateTo <> '')
IF(@IsMaturityUpToDate = '1')
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate <= CAST(@MaturityDateTo AS DATE) '
ELSE
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate = CAST(@MaturityDateTo AS DATE) '
ELSE
SET @LoanMaturityDate_Condition =  ''
SET @Sql =  REPLACE(@Sql, 'SequenceNumber_Condition', @SequenceNumber_Condition);
SET @Sql =  REPLACE(@Sql, 'LeaseCommencementDate_Condition', @LeaseCommencementDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LeaseMaturityDate_Condition', @LeaseMaturityDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LoanCommencementDate_Condition', @LoanCommencementDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LoanMaturityDate_Condition', @LoanMaturityDate_Condition);
EXEC sp_executesql @Sql,N'
@CommencementDateFrom DATETIMEOFFSET=NULL
,@CommencementDateTo DATETIMEOFFSET=NULL
,@MaturityDateFrom DATETIMEOFFSET=NULL
,@MaturityDateTo DATETIMEOFFSET=NULL
,@FromSequenceNumber VARCHAR(40)=NULL
,@ToSequenceNumber VARCHAR(40)=NULL
,@CustomerNumber VARCHAR(500)=NULL
,@CustomerName NVARCHAR(500)=NULL
,@ContractBookingStatus VARCHAR(40)=NULL
,@IsCommencementUpToDate NVARCHAR(1)=NULL
,@IsMaturityUpToDate NVARCHAR(1)=NULL
,@AssetUDF1 NVARCHAR(40)=NULL
,@AssetUDF2 NVARCHAR(40)=NULL
,@AssetUDF3 NVARCHAR(40)=NULL
,@AssetUDF4 NVARCHAR(40)=NULL
,@AssetUDF5 NVARCHAR(40)=NULL
,@AssetMultipleSerialNumberType NVARCHAR(10)'
,@CommencementDateFrom
,@CommencementDateTo
,@MaturityDateFrom
,@MaturityDateTo
,@FromSequenceNumber
,@ToSequenceNumber
,@CustomerNumber
,@CustomerName
,@ContractBookingStatus
,@IsCommencementUpToDate
,@IsMaturityUpToDate
,@AssetUDF1
,@AssetUDF2
,@AssetUDF3
,@AssetUDF4
,@AssetUDF5
,@AssetMultipleSerialNumberType

GO

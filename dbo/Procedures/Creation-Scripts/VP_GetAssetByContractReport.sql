SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[VP_GetAssetByContractReport]
(
@CommencementDateFrom DATE=NULL
,@CommencementDateTo DATE=NULL
,@MaturityDateFrom DATE=NULL
,@MaturityDateTo DATE=NULL
,@FromSequenceNumber NVARCHAR(40)=NULL
,@ToSequenceNumber NVARCHAR(40)=NULL
,@CustomerNumber NVARCHAR(500)=NULL
,@CustomerName NVARCHAR(500)=NULL
,@ContractBookingStatus VARCHAR(40)=NULL
,@ProgramVendorNumber NVARCHAR(1000)=NULL
,@DealerOrDistributorNumber VARCHAR(1000)=NULL
,@IsProgramVendor NVARCHAR(1)=NULL
,@IsCommencementUpToDate NVARCHAR(1)=NULL
,@IsMaturityUpToDate NVARCHAR(1)=NULL
,@AssetUDF1 NVARCHAR(40)=NULL
,@AssetUDF2 NVARCHAR(40)=NULL
,@AssetUDF3 NVARCHAR(40)=NULL
,@AssetUDF4 NVARCHAR(40)=NULL
,@AssetUDF5 NVARCHAR(40)=NULL
,@IsDealerFilterAppliedExternally NVARCHAR(1) = NULL
,@ProgramName NVARCHAR(40) = NULL
,@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
DECLARE @Sql NVARCHAR(MAX)
DECLARE @SequenceNumber_Condition NVARCHAR(1000)
DECLARE @LeaseCommencementDate_Condition NVARCHAR(1000)
DECLARE @LeaseMaturityDate_Condition NVARCHAR(1000)
DECLARE @LoanCommencementDate_Condition NVARCHAR(1000)
DECLARE @LoanMaturityDate_Condition NVARCHAR(1000)
DECLARE @ORIGINATIONWHERECONDITION NVARCHAR(1000)
DECLARE @PROGRAMWHERECONDITION NVARCHAR(40)
SET @Sql =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH CTE_AssumptionDetails AS
(
SELECT
ContractId,
MIN(Id) Id
FROM Assumptions WHERE Status = ''Approved''
Group BY
ContractId
)
,CTE_Contracts
AS
(
SELECT
C.Id AS ContractId
,C.SequenceNumber
,C.ContractType
,CASE WHEN CA.VendorId IS NULL THEN OriginationSource.PartyName ELSE Vendor.PartyName END AS ProgramVendor
FROM  Contracts C
JOIN CreditApprovedStructures CPS ON C.CreditApprovedStructureId =CPS.Id
JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
JOIN CreditApplications CA ON CA.Id = Opp.Id
JOIN Parties OriginationSource ON OriginationSource.Id = Opp.OriginationSourceId
LEFT JOIN Parties Vendor ON Vendor.Id = CA.VendorId
LEFT JOIN ContractThirdPartyRelationships ContractTP ON C.Id= ContractTP.ContractId
LEFT JOIN CustomerThirdPartyRelationships CustomerTP ON ContractTP.ThirdPartyRelationshipId = CustomerTP.Id
WHERE C.Status NOT IN (''FullyPaidOff'',''Inactive'',''Cancelled'',''Terminated'')
AND
(
ORIGINATIONWHERECONDITION
SequenceNumber_Condition
)
OR
(
CustomerTP.ThirdPartyId = CASE WHEN @IsProgramVendor = ''1'' THEN (SELECT Id from Parties where PartyNumber = @ProgramVendorNumber)
ELSE (SELECT Id from Parties where PartyNumber = @DealerOrDistributorNumber )
END
AND CustomerTP.IsActive = 1 AND ContractTP.IsActive = 1 AND CustomerTP.RelationshipType = ''VendorRecourse''
)
),
CTE_LeaseContracts
AS
(
SELECT DISTINCT
C.ContractId  AS Id
,C.SequenceNumber
,C.ContractType
,C.ProgramVendor
,CASE WHEN AP.PartyNumber IS NULL THEN CusParty.PartyNumber ELSE AP.PartyNumber END AS CustomerNumber
,CASE WHEN AP.PartyName IS NULL THEN CusParty.PartyName ELSE AP.PartyName END AS CustomerName
,Lease.Id AS LeaseFinanceId
,Lease.BookingStatus AS Status
,LeaseDetail.TermInMonths  AS Term
,LeaseDetail.CommencementDate AS CommencementDate
,LeaseDetail.MaturityDate AS MaturityDate
,Programs.Name AS ProgramName
FROM CTE_Contracts C
JOIN LeaseFinances Lease ON C.ContractId = Lease.ContractId
LEFT JOIN ContractOriginations ON Lease.ContractOriginationId=ContractOriginations.Id
LEFT JOIN Programs ON ContractOriginations.ProgramId=Programs.Id
JOIN Parties CusParty ON Lease.CustomerId = CusParty.Id
JOIN LeaseFinanceDetails LeaseDetail ON Lease.Id = LeaseDetail.Id
LEFT JOIN CTE_AssumptionDetails CAD ON CAD.ContractId = C.ContractId
LEFT JOIN Assumptions A ON CAD.Id = A.Id
LEFT JOIN Parties AP ON AP.Id = A.OriginalCustomerId
WHERE Lease.IsCurrent=1
AND (@ContractBookingStatus IS NULL OR @ContractBookingStatus =''_'' OR @ContractBookingStatus=Lease.BookingStatus)
AND (@CustomerNumber IS NULL OR (CASE WHEN AP.PartyNumber IS NULL THEN CusParty.PartyNumber ELSE AP.PartyNumber END) LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName  IS NULL OR (CASE WHEN AP.PartyNumber IS NULL THEN CusParty.PartyName ELSE AP.PartyNumber END) LIKE REPLACE(@CustomerName ,''*'',''%''))
LeaseCommencementDate_Condition
LeaseMaturityDate_Condition
PROGRAMWHERECONDITION
),
CTE_LoanContracts
AS
(
SELECT DISTINCT
C.ContractId AS Id
,C.SequenceNumber
,C.ContractType
,C.ProgramVendor
,CASE WHEN AP.PartyNumber IS NULL THEN CusParty.PartyNumber ELSE AP.PartyNumber END AS CustomerNumber
,CASE WHEN AP.PartyName IS NULL THEN CusParty.PartyName ELSE AP.PartyName END AS CustomerName
,Loan.Id AS LoanFinanceId
,Loan.Status AS Status
,Loan.Term  AS Term
,Loan.CommencementDate AS CommencementDate
,Loan.MaturityDate AS MaturityDate
,Programs.Name  AS ProgramName
FROM CTE_Contracts C
JOIN LoanFinances Loan ON Loan.ContractId = C.ContractId
LEFT JOIN ContractOriginations ON Loan.ContractOriginationId=ContractOriginations.Id
LEFT JOIN Programs ON ContractOriginations.ProgramId=Programs.Id
JOIN Parties CusParty ON Loan.CustomerId=CusParty.Id
LEFT JOIN CTE_AssumptionDetails CAD ON CAD.ContractId = C.ContractId
LEFT JOIN Assumptions A ON CAD.Id = A.Id
LEFT JOIN Parties AP ON AP.Id = A.OriginalCustomerId
WHERE Loan.IsCurrent=1
AND (@ContractBookingStatus IS NULL OR @ContractBookingStatus =''_'' OR @ContractBookingStatus=Loan.Status)
AND (@CustomerNumber IS NULL OR (CASE WHEN AP.PartyNumber IS NULL THEN CusParty.PartyNumber ELSE AP.PartyNumber END) LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName  IS NULL OR (CASE WHEN AP.PartyNumber IS NULL THEN CusParty.PartyName ELSE AP.PartyNumber END) LIKE REPLACE(@CustomerName ,''*'',''%''))
LoanCommencementDate_Condition
LoanMaturityDate_Condition
PROGRAMWHERECONDITION
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
LEFT JOIN AssetLocations AssetLocation ON AssetLocation.AssetId=Asset.Id AND AssetLocation.IsCurrent=1 AND AssetLocation.IsActive=1
LEFT JOIN Locations Location ON Location.Id=AssetLocation.LocationId AND Location.IsActive=1 AND Location.ApprovalStatus=''Approved''
LEFT JOIN States State ON Location.StateId=State.Id AND State.IsActive=1
LEFT JOIN Countries Country ON State.CountryId=Country.Id AND Country.IsActive=1
LEFT JOIN Manufacturers Manuf ON Asset.ManufacturerId = Manuf.Id AND Manuf.IsActive = 1
LEFT JOIN UDFs UDF ON Asset.Id= UDF.AssetId AND UDF.IsActive = 1
WHERE LeaseAsset.IsActive=1 AND AssetType.IsActive=1
AND (@AssetUDF1 IS NULL OR UDF.UDF1Value LIKE REPLACE(@AssetUDF1,''*'',''%''))
AND (@AssetUDF2 IS NULL OR UDF.UDF2Value LIKE REPLACE(@AssetUDF2,''*'',''%''))
AND (@AssetUDF3 IS NULL OR UDF.UDF3Value LIKE REPLACE(@AssetUDF3,''*'',''%''))
AND (@AssetUDF4 IS NULL OR UDF.UDF4Value LIKE REPLACE(@AssetUDF4,''*'',''%''))
AND (@AssetUDF5 IS NULL OR UDF.UDF5Value LIKE REPLACE(@AssetUDF5,''*'',''%''))
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
LEFT JOIN AssetLocations AssetLocation ON AssetLocation.AssetId=Asset.Id AND AssetLocation.IsCurrent=1 AND AssetLocation.IsActive=1
LEFT JOIN Locations Location ON Location.Id=AssetLocation.LocationId AND Location.IsActive=1 AND Location.ApprovalStatus=''Approved''
LEFT JOIN States State ON Location.StateId=State.Id AND State.IsActive=1
LEFT JOIN Countries Country ON State.CountryId=Country.Id AND Country.IsActive=1
LEFT JOIN Manufacturers Manuf ON Asset.ManufacturerId = Manuf.Id AND Manuf.IsActive=1
LEFT JOIN UDFs UDF ON Asset.Id= UDF.AssetId AND UDF.IsActive = 1
WHERE LoanAsset.IsActive=1 AND AssetType.IsActive=1
AND (@AssetUDF1 IS NULL OR UDF.UDF1Value LIKE REPLACE(@AssetUDF1,''*'',''%''))
AND (@AssetUDF2 IS NULL OR UDF.UDF2Value LIKE REPLACE(@AssetUDF2,''*'',''%''))
AND (@AssetUDF3 IS NULL OR UDF.UDF3Value LIKE REPLACE(@AssetUDF3,''*'',''%''))
AND (@AssetUDF4 IS NULL OR UDF.UDF4Value LIKE REPLACE(@AssetUDF4,''*'',''%''))
AND (@AssetUDF5 IS NULL OR UDF.UDF5Value LIKE REPLACE(@AssetUDF5,''*'',''%''))
),
CTE_ContractDetails
AS
(
SELECT * FROM CTE_LeaseContracts
UNION SELECT * FROM CTE_LoanContracts
),
CTE_AssetDetail
AS
(
SELECT * FROM CTE_ContractsLease
UNION SELECT * FROM CTE_ContractsLoan
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM (SELECT DISTINCT AssetId FROM CTE_AssetDetail ) A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)
Select
C.CustomerNumber
,C.CustomerName
,C.ContractType
,C.ProgramVendor
,C.ProgramName
,C.SequenceNumber
,C.CommencementDate
,C.MaturityDate
,C.Status AS ContractBookingStatus
,CA.AssetId
,CA.ParentAssetId
,CA.AssetAlias
,ASN.SerialNumber
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
JOIN CTE_AssetDetail CA ON C.SequenceNumber = CA.SequenceNumber
LEFT JOIN CTE_AssetSerialNumberDetails ASN on CA.AssetId = ASN.AssetId
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
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate <= @CommencementDateTo '
ELSE
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate = @CommencementDateTo '
ELSE
SET @LeaseCommencementDate_Condition =  ''
IF (@CommencementDateFrom IS NOT NULL AND @CommencementDateTo IS NOT NULL)
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate BETWEEN CAST(@CommencementDateFrom AS DATE) AND CAST(@CommencementDateTo AS DATE)'
ELSE IF(@CommencementDateFrom IS NOT NULL AND @CommencementDateFrom <> '')
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate = CAST(@CommencementDateFrom AS DATE) '
ELSE IF(@CommencementDateTo IS NOT NULL AND @CommencementDateTo <> '')
IF(@IsCommencementUpToDate = '1')
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate <= @CommencementDateTo '
ELSE
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate = @CommencementDateTo '
ELSE
SET @LoanCommencementDate_Condition =  ''
IF (@MaturityDateFrom IS NOT NULL AND @MaturityDateTo IS NOT NULL)
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate BETWEEN CAST(@MaturityDateFrom AS DATE) AND CAST(@MaturityDateTo AS DATE) '
ELSE IF(@MaturityDateFrom IS NOT NULL AND @MaturityDateFrom <> '')
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate = CAST(@MaturityDateFrom AS DATE)'
ELSE IF(@MaturityDateTo IS NOT NULL AND @MaturityDateTo <> '')
IF(@IsMaturityUpToDate = '1')
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate <= @MaturityDateTo '
ELSE
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate = @MaturityDateTo '
ELSE
SET @LeaseMaturityDate_Condition =  ''
IF (@MaturityDateFrom IS NOT NULL AND @MaturityDateTo IS NOT NULL)
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate BETWEEN CAST(@MaturityDateFrom AS DATE) AND CAST(@MaturityDateTo AS DATE) '
ELSE IF(@MaturityDateFrom IS NOT NULL AND @MaturityDateFrom <> '')
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate = CAST(@MaturityDateFrom AS DATE)'
ELSE IF(@MaturityDateTo IS NOT NULL AND @MaturityDateTo <> '')
IF(@IsMaturityUpToDate = '1')
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate <= @MaturityDateTo '
ELSE
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate = @MaturityDateTo '
ELSE
SET @LoanMaturityDate_Condition =  ''
IF (@ProgramName IS NOT NULL AND @ProgramName <> '')
SET @PROGRAMWHERECONDITION =  'AND Programs.Name =''@ProgramName'''
ELSE
SET @PROGRAMWHERECONDITION =  ''
IF(@IsProgramVendor = '0')
SET @ORIGINATIONWHERECONDITION = '(@DealerOrDistributorNumber IS NULL OR @DealerOrDistributorNumber =''''
OR (OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributorNumber,'',''))
AND (@ProgramVendorNumber IS NULL OR @ProgramVendorNumber =''''  OR
Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'','')))))'
ELSE
IF(@IsDealerFilterAppliedExternally = '0')
SET @ORIGINATIONWHERECONDITION = '
(OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributorNumber,'',''))
AND Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
OR (OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
))'
ELSE
SET @ORIGINATIONWHERECONDITION = '
(OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributorNumber,'',''))
AND Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
OR ((@DealerOrDistributorNumber IS NULL OR @DealerOrDistributorNumber ='''')
AND (@ProgramVendorNumber IS NULL OR @ProgramVendorNumber =''''
OR OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
OR  Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))))
)'
SET @Sql =  REPLACE(@Sql, 'SequenceNumber_Condition', @SequenceNumber_Condition);
SET @Sql =  REPLACE(@Sql, 'LeaseCommencementDate_Condition', @LeaseCommencementDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LeaseMaturityDate_Condition', @LeaseMaturityDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LoanCommencementDate_Condition', @LoanCommencementDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LoanMaturityDate_Condition', @LoanMaturityDate_Condition);
SET @Sql =  REPLACE(@Sql, 'ORIGINATIONWHERECONDITION', @ORIGINATIONWHERECONDITION);
SET @Sql =  REPLACE(@Sql, 'PROGRAMWHERECONDITION', @PROGRAMWHERECONDITION);
EXEC sp_executesql @Sql,N'
@CommencementDateFrom DATE=NULL
,@CommencementDateTo DATE=NULL
,@MaturityDateFrom DATE=NULL
,@MaturityDateTo DATE=NULL
,@FromSequenceNumber VARCHAR(40)=NULL
,@ToSequenceNumber VARCHAR(40)=NULL
,@CustomerNumber VARCHAR(500)=NULL
,@CustomerName NVARCHAR(500)=NULL
,@ContractBookingStatus VARCHAR(40)=NULL
,@ProgramVendorNumber NVARCHAR(1000)=NULL
,@DealerOrDistributorNumber VARCHAR(1000)=NULL
,@IsProgramVendor NVARCHAR(1)=NULL
,@IsCommencementUpToDate NVARCHAR(1)=NULL
,@IsMaturityUpToDate NVARCHAR(1)=NULL
,@AssetUDF1 NVARCHAR(40)=NULL
,@AssetUDF2 NVARCHAR(40)=NULL
,@AssetUDF3 NVARCHAR(40)=NULL
,@AssetUDF4 NVARCHAR(40)=NULL
,@AssetUDF5 NVARCHAR(40)=NULL
,@IsDealerFilterAppliedExternally NVARCHAR(1) = NULL
,@ProgramName NVARCHAR(40)=NULL
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
,@ProgramVendorNumber
,@DealerOrDistributorNumber
,@IsProgramVendor
,@IsCommencementUpToDate
,@IsMaturityUpToDate
,@AssetUDF1
,@AssetUDF2
,@AssetUDF3
,@AssetUDF4
,@AssetUDF5
,@IsDealerFilterAppliedExternally
,@ProgramName
,@AssetMultipleSerialNumberType

GO

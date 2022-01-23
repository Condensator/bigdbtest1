SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CP_GetContractDetailsForContractReport]
(
@CommencementDateFrom DATETIMEOFFSET=NULL
,@CommencementDateTo DATETIMEOFFSET=NULL
,@MaturityDateFrom DATETIMEOFFSET=NULL
,@MaturityDateTo DATETIMEOFFSET=NULL
,@FromSequenceNumber NVARCHAR(40)=NULL
,@ToSequenceNumber NVARCHAR(40)=NULL
,@CustomerNumber NVARCHAR(500)=NULL
,@ContractBookingStatus VARCHAR(40)=NULL
,@IsCommencementUpToDate NVARCHAR(1)=NULL
,@IsMaturityUpToDate NVARCHAR(1)=NULL
,@SortBy NVARCHAR(50) = NULL
,@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
DECLARE @Sql NVARCHAR(MAX)
DECLARE @SequenceNumber_Condition NVARCHAR(1000)
DECLARE @LeaseCommencementDate_Condition NVARCHAR(1000)
DECLARE @LeaseMaturityDate_Condition NVARCHAR(1000)
DECLARE @LoanCommencementDate_Condition NVARCHAR(1000)
DECLARE @LoanMaturityDate_Condition NVARCHAR(1000)
DECLARE @OrderBy_Condition NVARCHAR(1000)
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
,CASE WHEN LoanCustomer.Id IS NOT NULL THEN LeaseCustomer.PartyName ELSE LoanCustomer.PartyName END AS CustomerName
FROM  Contracts C
LEFT JOIN LeaseFinances Lease ON C.Id = Lease.ContractId
LEFT JOIN Parties LeaseCustomer ON Lease.CustomerId = LeaseCustomer.Id
LEFT JOIN LoanFinances Loan ON C.Id= Loan.ContractId
LEFT JOIN Parties LoanCustomer ON Loan.CustomerId = LoanCustomer.Id
LEFT JOIN ContractAssumptionHistories AssumptionHistory ON C.Id = AssumptionHistory.ContractId AND AssumptionHistory.IsActive=1
LEFT JOIN Parties AssumptionParty ON AssumptionHistory.CustomerId = AssumptionParty.Id
WHERE ((LeaseCustomer.PartyNumber = @CustomerNumber OR
LoanCustomer.PartyNumber = @CustomerNumber) OR AssumptionParty.PartyNumber = @CustomerNumber)
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
CTE_LeaseContractsFirst
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
,Lease.ApprovalStatus  AS ApprovalStatus
,LeaseDetail.TermInMonths  AS Term
,LeaseDetail.PaymentFrequency AS PaymentFrequency
,LeaseDetail.NumberOfPayments AS TotalNumberofPayments
,LeaseDetail.NumberOfInceptionPayments AS NumberofInceptiomPayments
,(LeaseDetail.NumberOfPayments -  LeaseDetail.NumberOfInceptionPayments) AS RemainingNumberofPayments
,LeaseDetail.IsAdvance AS Advance
,LeaseDetail.CommencementDate AS CommencementDate
,LeaseDetail.MaturityDate AS MaturityDate
,LeaseDetail.CommencementDate  AS FirstPaymentDate
,LeaseDetail.InceptionPayment_Currency AS TotalCost_Currency
,STUFF((SELECT distinct '','' + P.InvoiceNumber FROM .PayableInvoices P WHERE C.ContractId= P.ContractId
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') InvoiceNumber
FROM CTE_AllLeaseContracts C
JOIN LeaseFinances Lease ON C.ContractId = Lease.ContractId
LEFT JOIN LeaseFinanceDetails LeaseDetail ON Lease.Id = LeaseDetail.Id
WHERE (Lease.IsCurrent=1 OR C.CustomerNumber <> @CustomerNumber)
AND (@ContractBookingStatus IS NULL OR @ContractBookingStatus=Lease.BookingStatus)
LeaseCommencementDate_Condition
LeaseMaturityDate_Condition
),
CTE_LeaseAssetTotalCost
AS
(
SELECT
Lease.LeaseFinanceId
,SUM(LeaseAsset.NBV_Amount) AS TotalCost_Amount
FROM CTE_LeaseContractsFirst Lease
JOIN LeaseAssets LeaseAsset ON Lease.LeaseFinanceId=LeaseAsset.LeaseFinanceId
GROUP BY Lease.LeaseFinanceId
),
CTE_LeaseContracts
AS
(
SELECT
Lease.Id
,Lease.SequenceNumber
,Lease.ContractType
,Lease.CustomerNumber
,Lease.CustomerName
,Lease.Status
,Lease.ApprovalStatus
,Lease.Term
,Lease.PaymentFrequency
,Lease.TotalNumberofPayments
,Lease.NumberofInceptiomPayments
,Lease.RemainingNumberofPayments
,Lease.Advance
,Lease.CommencementDate
,Lease.MaturityDate
,Lease.FirstPaymentDate
,Lease.TotalCost_Currency
,LeaseTotal.TotalCost_Amount
,Lease. InvoiceNumber
FROM CTE_LeaseContractsFirst Lease
JOIN CTE_LeaseAssetTotalCost LeaseTotal ON Lease.LeaseFinanceId= LeaseTotal.LeaseFinanceId
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
,Loan.Status AS Status
,Loan.ApprovalStatus  AS ApprovalStatus
,Loan.Term  AS Term
,Loan.PaymentFrequency AS PaymentFrequency
,Loan.NumberOfPayments AS TotalNumberofPayments
,0 AS NumberofInceptiomPayments
,0 AS RemainingNumberofPayments
,NULL AS Advance
,Loan.CommencementDate AS CommencementDate
,Loan.MaturityDate AS MaturityDate
,Loan.FirstPaymentDate  AS FirstPaymentDate
,Loan.LoanAmount_Currency AS TotalCost_Currency
,Loan.LoanAmount_Amount AS TotalCost_Amount
,STUFF((SELECT distinct '',''+ P.InvoiceNumber FROM .PayableInvoices P WHERE C.ContractId= P.ContractId
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') InvoiceNumber
FROM CTE_AllLoanContracts C
JOIN LoanFinances Loan ON Loan.ContractId = C.ContractId
WHERE (Loan.IsCurrent=1 OR C.CustomerNumber <> @CustomerNumber)
AND (@ContractBookingStatus IS NULL OR @ContractBookingStatus=Loan.Status)
LoanCommencementDate_Condition
LoanMaturityDate_Condition
),
CTE_DistinctPayableContractsLease
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
,PayableInvoice.InvoiceNumber As InvoiceNumber
,PayableInvoiceAsset.AcquisitionCost_Amount+PayableInvoiceAsset.OtherCost_Amount As AssetAmount
,(Location.AddressLine1 +
(CASE WHEN Location.AddressLine2 IS NOT NULL THEN '', ''+ Location.AddressLine2 ELSE '''' END)+
(CASE WHEN Location.City IS NOT NULL THEN '','' + Location.City ELSE '''' END) +
'', ''+ States.LongName + '', ''+ Countries.ShortName) AS Location
,C.SequenceNumber
,PayableInvoiceAsset.PayableInvoiceId PayableInvoiceAssetPayableInvoiceId
,PayableInvoice.Id PayableInvoiceId
FROM Contracts C
INNER JOIN LeaseFinances Lease ON C.Id=Lease.ContractId AND Lease.IsCurrent = 1
INNER JOIN LeaseFinanceDetails LeaseDetail ON Lease.Id = LeaseDetail.Id
INNER JOIN LeaseAssets LeaseAsset ON Lease.Id= LeaseAsset.LeaseFinanceId AND (LeaseAsset.IsActive = 1 OR Lease.BookingStatus=''FullyPaidOff'')
INNER JOIN Assets Asset ON  LeaseAsset.AssetId=Asset.Id
INNER JOIN AssetTypes AssetType ON Asset.TypeId = AssetType.Id
INNER JOIN PayableInvoices PayableInvoice ON PayableInvoice.ContractId =C.Id
INNER JOIN PayableInvoiceAssets PayableInvoiceAsset ON PayableInvoiceAsset.AssetId=Asset.Id
AND PayableInvoiceAsset.PayableInvoiceId = PayableInvoice.Id AND PayableInvoiceAsset.IsActive = 1
LEFT JOIN AssetLocations AssetLocation ON AssetLocation.AssetId=Asset.Id AND AssetLocation.IsCurrent=1
LEFT JOIN Locations Location ON Location.Id=AssetLocation.LocationId
LEFT JOIN States ON Location.StateId = States.Id
LEFT JOIN Countries ON States.CountryId = Countries.Id
LEFT JOIN Manufacturers Manuf ON Asset.ManufacturerId = Manuf.Id
LEFT JOIN LeaseFundings LeaseFunding ON LeaseFunding.LeaseFinanceId=Lease.Id
SequenceNumber_Condition
LeaseCommencementDate_Condition
LeaseMaturityDate_Condition
)
,CTE_AllContractsLease
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
,PayableInvoice.InvoiceNumber As InvoiceNumber
,PayableInvoiceAsset.AcquisitionCost_Amount+PayableInvoiceAsset.OtherCost_Amount As AssetAmount
,(Location.AddressLine1 +
(CASE WHEN Location.AddressLine2 IS NOT NULL THEN '', ''+ Location.AddressLine2 ELSE '''' END)+
(CASE WHEN Location.City IS NOT NULL THEN '','' + Location.City ELSE '''' END) +
'', ''+ States.LongName + '', ''+ Countries.ShortName) AS Location
,C.SequenceNumber
,PayableInvoiceAsset.PayableInvoiceId PayableInvoiceAssetPayableInvoiceId
,PayableInvoice.Id PayableInvoiceId
FROM Contracts C
JOIN LeaseFinances Lease ON C.Id=Lease.ContractId AND Lease.IsCurrent = 1
INNER JOIN LeaseFinanceDetails LeaseDetail ON Lease.Id = LeaseDetail.Id
LEFT JOIN LeaseAssets LeaseAsset ON Lease.Id= LeaseAsset.LeaseFinanceId AND (LeaseAsset.IsActive = 1 OR Lease.BookingStatus=''FullyPaidOff'')
LEFT JOIN Assets Asset ON  LeaseAsset.AssetId=Asset.Id
LEFT JOIN AssetTypes AssetType ON Asset.TypeId = AssetType.Id
LEFT JOIN AssetLocations AssetLocation ON AssetLocation.AssetId=Asset.Id AND AssetLocation.IsCurrent=1
LEFT JOIN Locations Location ON Location.Id=AssetLocation.LocationId
LEFT JOIN States ON Location.StateId = States.Id
LEFT JOIN Countries ON States.CountryId = Countries.Id
LEFT JOIN Manufacturers Manuf ON Asset.ManufacturerId = Manuf.Id
LEFT JOIN PayableInvoiceAssets PayableInvoiceAsset ON PayableInvoiceAsset.AssetId=Asset.Id AND PayableInvoiceAsset.IsActive = 1
LEFT JOIN LeaseFundings LeaseFunding ON LeaseFunding.LeaseFinanceId=Lease.Id
LEFT JOIN PayableInvoices PayableInvoice ON PayableInvoice.ContractId =C.Id
SequenceNumber_Condition
LeaseCommencementDate_Condition
LeaseMaturityDate_Condition
),
CTE_ContractsLease
AS
(
SELECT * FROM CTE_AllContractsLease AC
WHERE (NOT EXISTS (SELECT * FROM CTE_DistinctPayableContractsLease WHERE SequenceNumber = AC.SequenceNumber AND InvoiceNumber = AC.InvoiceNumber))
AND (AC.PayableInvoiceAssetPayableInvoiceId = AC.PayableInvoiceId)
UNION
SELECT * FROM CTE_DistinctPayableContractsLease AC WHERE (AC.PayableInvoiceAssetPayableInvoiceId = AC.PayableInvoiceId)
),
CTE_DistinctPayableContractsLoan
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
,PayableInvoice.InvoiceNumber AS InvoiceNumber
,LoanAsset.AcquisitionCost_Amount As AssetAmount
,(Location.AddressLine1 +
(CASE WHEN Location.AddressLine2 IS NOT NULL THEN '', ''+ Location.AddressLine2 ELSE '''' END)+
(CASE WHEN Location.City IS NOT NULL THEN '','' + Location.City ELSE '''' END) +
'', ''+ States.LongName + '', ''+ Countries.ShortName) AS Location
,C.SequenceNumber
,PayableInvoiceAsset.PayableInvoiceId PayableInvoiceAssetPayableInvoiceId
,PayableInvoice.Id PayableInvoiceId
FROM Contracts C
JOIN LoanFinances Loan ON C.Id= Loan.ContractId AND Loan.IsCurrent = 1
LEFT JOIN CollateralAssets LoanAsset ON Loan.Id= LoanAsset.LoanFinanceId AND LoanAsset.IsActive = 1
LEFT JOIN Assets Asset ON  LoanAsset.AssetId=Asset.Id
LEFT JOIN AssetTypes AssetType ON Asset.TypeId = AssetType.Id
LEFT JOIN AssetLocations AssetLocation ON AssetLocation.AssetId=Asset.Id AND AssetLocation.IsCurrent=1
LEFT JOIN Locations Location ON Location.Id=AssetLocation.LocationId
LEFT JOIN States ON Location.StateId = States.Id
LEFT JOIN Countries ON States.CountryId = Countries.Id
LEFT JOIN Manufacturers Manuf ON Asset.ManufacturerId = Manuf.Id
LEFT JOIN PayableInvoiceAssets PayableInvoiceAsset ON PayableInvoiceAsset.AssetId=Asset.Id AND PayableInvoiceAsset.IsActive = 1
LEFT JOIN LoanFundings LoanFunding ON LoanFunding.LoanFinanceId=Loan.Id
LEFT JOIN PayableInvoices PayableInvoice ON PayableInvoice.ContractId = C.Id AND PayableInvoiceAsset.PayableInvoiceId = PayableInvoice.Id
SequenceNumber_Condition
AND PayableInvoice.InvoiceNumber IS NOT NULL
LoanCommencementDate_Condition
LoanMaturityDate_Condition
),
CTE_AllContractsLoan
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
,PayableInvoice.InvoiceNumber AS InvoiceNumber
,LoanAsset.AcquisitionCost_Amount As AssetAmount
,(Location.AddressLine1 +
(CASE WHEN Location.AddressLine2 IS NOT NULL THEN '', ''+ Location.AddressLine2 ELSE '''' END)+
(CASE WHEN Location.City IS NOT NULL THEN '','' + Location.City ELSE '''' END) +
'', ''+ States.LongName + '', ''+ Countries.ShortName) AS Location
,C.SequenceNumber
,PayableInvoiceAsset.PayableInvoiceId PayableInvoiceAssetPayableInvoiceId
,PayableInvoice.Id PayableInvoiceId
FROM Contracts C
JOIN LoanFinances Loan ON C.Id= Loan.ContractId AND Loan.IsCurrent = 1
LEFT JOIN CollateralAssets LoanAsset ON Loan.Id= LoanAsset.LoanFinanceId AND LoanAsset.IsActive = 1
LEFT JOIN Assets Asset ON  LoanAsset.AssetId=Asset.Id
LEFT JOIN AssetTypes AssetType ON Asset.TypeId = AssetType.Id
LEFT JOIN AssetLocations AssetLocation ON AssetLocation.AssetId=Asset.Id AND AssetLocation.IsCurrent=1
LEFT JOIN Locations Location ON Location.Id=AssetLocation.LocationId
LEFT JOIN States ON Location.StateId = States.Id
LEFT JOIN Countries ON States.CountryId = Countries.Id
LEFT JOIN Manufacturers Manuf ON Asset.ManufacturerId = Manuf.Id
LEFT JOIN PayableInvoiceAssets PayableInvoiceAsset ON PayableInvoiceAsset.AssetId=Asset.Id
LEFT JOIN LoanFundings LoanFunding ON LoanFunding.LoanFinanceId=Loan.Id
LEFT JOIN PayableInvoices PayableInvoice ON PayableInvoice.ContractId = C.Id
SequenceNumber_Condition
LoanCommencementDate_Condition
LoanMaturityDate_Condition
),
CTE_ContractsLoan
AS
(
SELECT * FROM CTE_AllContractsLoan AC
WHERE (NOT EXISTS (SELECT * FROM CTE_DistinctPayableContractsLoan WHERE SequenceNumber = AC.SequenceNumber))
UNION
SELECT * FROM CTE_DistinctPayableContractsLoan AC WHERE (AC.PayableInvoiceId = AC.PayableInvoiceAssetPayableInvoiceId)
),
CTE_ContractDetails
AS
(
SELECT * FROM CTE_LeaseContracts
UNION
SELECT * FROM CTE_LoanContracts
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
SELECT
CTE_ContractsLease.AssetId
,ParentAssetId
,CTE_AssetSerialNumberDetails.SerialNumber
,Status
,Manufacturer
,AssetType
,Description
,AssetAlias
,InvoiceNumber
,AssetAmount
,Location
,SequenceNumber
FROM CTE_ContractsLease
LEFT JOIN CTE_AssetSerialNumberDetails ON CTE_ContractsLease.AssetId = CTE_AssetSerialNumberDetails.AssetId
UNION
SELECT
CTE_ContractsLoan.AssetId
,ParentAssetId
,CTE_AssetSerialNumberDetails.SerialNumber
,Status
,Manufacturer
,AssetType
,Description
,AssetAlias
,InvoiceNumber
,AssetAmount
,Location
,SequenceNumber
FROM CTE_ContractsLoan
LEFT JOIN CTE_AssetSerialNumberDetails ON CTE_ContractsLoan.AssetId = CTE_AssetSerialNumberDetails.AssetId
)
Select DISTINCT
C.CustomerNumber AS CustomerNumber
,C.CustomerName AS CustomerName
,C.SequenceNumber AS SequenceNumber
,C.CommencementDate AS CommencementDate
,C.MaturityDate AS MaturityDate
,C.TotalCost_Currency AS ContractCurrency
,CA.InvoiceNumber AS InvoiceNumber
,CA.AssetAlias AS AssetAlias
,CA.SerialNumber AS Serial#
,CA.AssetAmount AssetAmount
,CA.Location AS Location
,CA.Description AS Description
FROM
CTE_ContractDetails C
LEFT JOIN CTE_AssetDetail CA
ON C.SequenceNumber = CA.SequenceNumber
AND CA.InvoiceNumber IS NOT NULL
SequenceNumber_Condition
OrderByCondition
'
IF (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND @FromSequenceNumber <> '' AND @ToSequenceNumber <> '')
SET @SequenceNumber_Condition =  'WHERE C.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber '
ELSE IF(@FromSequenceNumber IS NOT NULL AND @FromSequenceNumber <> '')
SET @SequenceNumber_Condition =  'WHERE C.SequenceNumber = @FromSequenceNumber '
ELSE IF(@ToSequenceNumber IS NOT NULL AND @ToSequenceNumber <> '')
SET @SequenceNumber_Condition =  'WHERE C.SequenceNumber = @ToSequenceNumber '
ELSE
SET @SequenceNumber_Condition =  'WHERE C.SequenceNumber =  C.SequenceNumber '
IF (@CommencementDateFrom IS NOT NULL AND @CommencementDateTo IS NOT NULL AND @CommencementDateFrom <> '' AND @CommencementDateTo <> '')
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate BETWEEN CAST(@CommencementDateFrom AS DATE) AND CAST(@CommencementDateTo AS DATE)'
ELSE IF(@CommencementDateFrom IS NOT NULL AND @CommencementDateFrom <> '')
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate =  CAST(@CommencementDateFrom AS DATE)'
ELSE IF(@CommencementDateTo IS NOT NULL AND @CommencementDateTo <> '')
IF(@IsCommencementUpToDate = '1')
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate <= CAST(@CommencementDateTo AS DATE)'
ELSE
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate = CAST(@CommencementDateTo AS DATE)'
ELSE
SET @LeaseCommencementDate_Condition =  ''
IF (@CommencementDateFrom IS NOT NULL AND @CommencementDateTo IS NOT NULL AND @CommencementDateFrom <> '' AND @CommencementDateTo <> '')
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate BETWEEN  CAST(@CommencementDateFrom AS DATE) AND CAST(@CommencementDateTo AS DATE)'
ELSE IF(@CommencementDateFrom IS NOT NULL AND @CommencementDateFrom <> '')
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate =  CAST(@CommencementDateFrom AS DATE)'
ELSE IF(@CommencementDateTo IS NOT NULL AND @CommencementDateTo <> '')
IF(@IsCommencementUpToDate = '1')
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate <= CAST(@CommencementDateTo AS DATE)'
ELSE
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate = CAST(@CommencementDateTo AS DATE)'
ELSE
SET @LoanCommencementDate_Condition =  ''
IF (@MaturityDateFrom IS NOT NULL AND @MaturityDateTo IS NOT NULL AND @MaturityDateFrom <> '' AND @MaturityDateTo <> '')
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate BETWEEN CAST(@MaturityDateFrom AS DATE) AND CAST(@MaturityDateTo AS DATE)'
ELSE IF(@MaturityDateFrom IS NOT NULL AND @MaturityDateFrom <> '')
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate = CAST(@MaturityDateFrom AS DATE)'
ELSE IF(@MaturityDateTo IS NOT NULL AND @MaturityDateTo <> '')
IF(@IsMaturityUpToDate = '1')
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate <= CAST(@MaturityDateTo AS DATE)'
ELSE
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate = CAST(@MaturityDateTo AS DATE)'
ELSE
SET @LeaseMaturityDate_Condition =  ''
IF (@MaturityDateFrom IS NOT NULL AND @MaturityDateTo IS NOT NULL AND @MaturityDateFrom <> '' AND @MaturityDateTo <> '')
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate BETWEEN CAST(@MaturityDateFrom AS DATE) AND CAST(@MaturityDateTo AS DATE)'
ELSE IF(@MaturityDateFrom IS NOT NULL AND @MaturityDateFrom <> '')
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate = CAST(@MaturityDateFrom AS DATE)'
ELSE IF(@MaturityDateTo IS NOT NULL AND @MaturityDateTo <> '')
IF(@IsMaturityUpToDate = '1')
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate <= CAST(@MaturityDateTo AS DATE)'
ELSE
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate = CAST(@MaturityDateTo AS DATE) '
ELSE
SET @LoanMaturityDate_Condition =  ''
IF(@SortBy IS Null)
SET @OrderBy_Condition = ''
ELSE IF (@SortBy = 'CommencementDate:Asc')
SET @OrderBy_Condition = 'order by C.CommencementDate'
ELSE IF (@SortBy = 'CommencementDate:Desc')
SET @OrderBy_Condition = 'order by C.CommencementDate DESC'
ELSE IF (@SortBy = 'MaturityDate:Asc')
SET @OrderBy_Condition = 'order by C.MaturityDate'
ELSE IF (@SortBy = 'MaturityDate:Desc')
SET @OrderBy_Condition = 'order by C.MaturityDate DESC'
SET @Sql =  REPLACE(@Sql, 'SequenceNumber_Condition', @SequenceNumber_Condition);
SET @Sql =  REPLACE(@Sql, 'LeaseCommencementDate_Condition', @LeaseCommencementDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LeaseMaturityDate_Condition', @LeaseMaturityDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LoanCommencementDate_Condition', @LoanCommencementDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LoanMaturityDate_Condition', @LoanMaturityDate_Condition);
SET @Sql =  REPLACE(@Sql, 'OrderByCondition', @OrderBy_Condition);;
EXEC sp_executesql @Sql,N'
@CommencementDateFrom DATETIMEOFFSET=NULL
,@CommencementDateTo DATETIMEOFFSET=NULL
,@MaturityDateFrom DATETIMEOFFSET=NULL
,@MaturityDateTo  DATETIMEOFFSET=NULL
,@FromSequenceNumber VARCHAR(40)=NULL
,@ToSequenceNumber VARCHAR(40)=NULL
,@CustomerNumber VARCHAR(500)=NULL
,@ContractBookingStatus VARCHAR(40)=NULL
,@SortBy VARCHAR(50)=NULL
,@AssetMultipleSerialNumberType NVARCHAR(10)'
,@CommencementDateFrom
,@CommencementDateTo
,@MaturityDateFrom
,@MaturityDateTo
,@FromSequenceNumber
,@ToSequenceNumber
,@CustomerNumber
,@ContractBookingStatus
,@SortBy
,@AssetMultipleSerialNumberType

GO

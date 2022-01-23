SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[VP_GetContractDetailsForContractReport]
(
@CommencementDateFrom DATE=NULL
,@CommencementDateTo DATE=NULL
,@MaturityDateFrom DATE=NULL
,@MaturityDateTo DATE=NULL
,@FromSequenceNumber NVARCHAR(40)=NULL
,@ToSequenceNumber NVARCHAR(40)=NULL
,@CustomerNumber NVARCHAR(500)=NULL
,@ContractBookingStatus VARCHAR(40)=NULL
,@ProgramVendorNumber NVARCHAR(1000)=NULL
,@DealerOrDistributorNumber VARCHAR(1000)=NULL
,@IsProgramVendor NVARCHAR(1)=NULL
,@IsCommencementUpToDate NVARCHAR(1)=NULL
,@IsMaturityUpToDate NVARCHAR(1)=NULL
,@SortBy Nvarchar(25)= NULL
,@IsDealerFilterAppliedExternally NVARCHAR(1) = NULL
,@ProgramName NVARCHAR(40)=NULL
,@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
DECLARE @Sql NVARCHAR(MAX)
DECLARE @SequenceNumber_Condition NVARCHAR(1000)
DECLARE @ORIGINATIONWHERECONDITION NVARCHAR(1000)
DECLARE @LeaseCommencementDate_Condition NVARCHAR(1000)
DECLARE @LeaseMaturityDate_Condition NVARCHAR(1000)
DECLARE @LoanCommencementDate_Condition NVARCHAR(1000)
DECLARE @LoanMaturityDate_Condition NVARCHAR(1000)
DECLARE @SORTBY_CONDITION NVARCHAR(1000)
DECLARE @ProgramName_Condition NVARCHAR(1000)
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
,CASE WHEN AP.PartyNumber IS NULL THEN CustParty.PartyNumber ELSE AP.PartyNumber END AS CustomerNumber
,CASE WHEN AP.PartyName IS NULL THEN CustParty.PartyName ELSE AP.PartyName END AS CustomerName
,Opp.Number AS CreditApplication
,CASE WHEN CA.VendorId IS NULL THEN OriginationSource.PartyName ELSE Vendor.PartyName END AS ProgramVendor
FROM  Contracts C
JOIN CreditApprovedStructures CPS ON C.CreditApprovedStructureId =CPS.Id
JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
JOIN CreditApplications CA ON CA.Id = Opp.Id
JOIN dbo.Customers Cust  ON Opp.CustomerId = Cust.Id
JOIN Parties CustParty ON Cust.Id= CustParty.Id
JOIN Parties OriginationSource ON OriginationSource.Id = Opp.OriginationSourceId
LEFT JOIN Parties Vendor ON Vendor.Id = CA.VendorId
LEFT JOIN ContractThirdPartyRelationships ContractTP ON C.Id= ContractTP.ContractId
LEFT JOIN CustomerThirdPartyRelationships CustomerTP ON ContractTP.ThirdPartyRelationshipId = CustomerTP.Id
LEFT JOIN CTE_AssumptionDetails CAD ON CAD.ContractId = C.Id
LEFT JOIN Assumptions A ON CAD.Id = A.Id
LEFT JOIN Parties AP ON AP.Id = A.OriginalCustomerId
WHERE ((@CustomerNumber IS NULL OR @CustomerNumber=  (CASE WHEN AP.PartyNumber IS NULL THEN CustParty.PartyNumber ELSE AP.PartyNumber END))
ORIGINATIONWHERECONDITION)
OR (CustomerTP.ThirdPartyId = CASE WHEN @IsProgramVendor = ''1'' THEN (SELECT Id from Parties where PartyNumber = @ProgramVendorNumber)
ELSE (SELECT Id from Parties where PartyNumber = @DealerOrDistributorNumber )
END
AND CustomerTP.IsActive = 1 AND ContractTP.IsActive = 1 AND CustomerTP.RelationshipType = ''VendorRecourse'')
),
CTE_LeaseContractsFirst
AS
(
SELECT DISTINCT
C.ContractId  AS Id
,C.SequenceNumber
,C.ContractType
,C.CreditApplication
,C.ProgramVendor
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
,program.Name AS ProgramName
FROM CTE_Contracts C
JOIN LeaseFinances Lease ON C.ContractId = Lease.ContractId AND Lease.IsCurrent = 1
LEFT JOIN LeaseFinanceDetails LeaseDetail ON Lease.Id = LeaseDetail.Id
LEFT JOIN ContractOriginations contractorigination ON Lease.ContractOriginationId = contractorigination.Id
LEFT JOIN Programs program ON contractorigination.ProgramId = program.Id
WHERE Lease.IsCurrent=1
AND (@ContractBookingStatus IS NULL OR @ContractBookingStatus=Lease.BookingStatus)
LeaseCommencementDate_Condition
LeaseMaturityDate_Condition
ProgramName_Condition
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
,Lease.CreditApplication
,Lease.ProgramVendor
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
,Lease.ProgramName
FROM CTE_LeaseContractsFirst Lease
JOIN CTE_LeaseAssetTotalCost LeaseTotal ON Lease.LeaseFinanceId= LeaseTotal.LeaseFinanceId
),
CTE_LoanContracts
AS
(
SELECT DISTINCT
C.ContractId AS Id
,C.SequenceNumber
,C.ContractType
,C.CreditApplication
,C.ProgramVendor
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
,program.Name AS ProgramName
FROM CTE_Contracts C
JOIN LoanFinances Loan ON Loan.ContractId = C.ContractId AND Loan.IsCurrent = 1
LEFT JOIN ContractOriginations contractorigination ON Loan.ContractOriginationId = contractorigination.Id
LEFT JOIN Programs program ON contractorigination.ProgramId = program.Id
WHERE Loan.IsCurrent=1
AND (@ContractBookingStatus IS NULL OR (CASE WHEN @ContractBookingStatus = ''Inactive'' THEN ''Cancelled'' ELSE @ContractBookingStatus END) = Loan.Status)
LoanCommencementDate_Condition
LoanMaturityDate_Condition
ProgramName_Condition
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
,program.Name AS ProgramName
FROM Contracts C
INNER JOIN LeaseFinances Lease ON C.Id=Lease.ContractId AND Lease.IsCurrent = 1
INNER JOIN LeaseAssets LeaseAsset ON Lease.Id= LeaseAsset.LeaseFinanceId AND LeaseAsset.IsActive = 1
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
LEFT JOIN ContractOriginations contractorigination ON Lease.ContractOriginationId = contractorigination.Id
LEFT JOIN Programs program ON contractorigination.ProgramId = program.Id
SequenceNumber_Condition
ProgramName_Condition
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
,program.Name AS ProgramName
FROM Contracts C
JOIN LeaseFinances Lease ON C.Id=Lease.ContractId AND Lease.IsCurrent = 1
LEFT JOIN LeaseAssets LeaseAsset ON Lease.Id= LeaseAsset.LeaseFinanceId AND LeaseAsset.IsActive = 1
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
LEFT JOIN ContractOriginations contractorigination ON Lease.ContractOriginationId = contractorigination.Id
LEFT JOIN Programs program ON contractorigination.ProgramId = program.Id
SequenceNumber_Condition
ProgramName_Condition
),
CTE_ContractsLease
AS
(
SELECT * FROM CTE_AllContractsLease AC
WHERE (NOT EXISTS (SELECT * FROM CTE_DistinctPayableContractsLease WHERE SequenceNumber = AC.SequenceNumber AND InvoiceNumber = AC.InvoiceNumber))
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
,program.Name AS ProgramName
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
LEFT JOIN ContractOriginations contractorigination ON Loan.ContractOriginationId = contractorigination.Id
LEFT JOIN Programs program ON contractorigination.ProgramId = program.Id
SequenceNumber_Condition
ProgramName_Condition
AND PayableInvoice.InvoiceNumber IS NOT NULL
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
,program.Name AS ProgramName
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
LEFT JOIN ContractOriginations contractorigination ON Loan.ContractOriginationId = contractorigination.Id
LEFT JOIN Programs program ON contractorigination.ProgramId = program.Id
SequenceNumber_Condition
ProgramName_Condition
),
CTE_ContractsLoan
AS
(
SELECT * FROM CTE_AllContractsLoan AC
WHERE (NOT EXISTS (SELECT * FROM CTE_DistinctPayableContractsLoan WHERE SequenceNumber = AC.SequenceNumber AND InvoiceNumber = AC.InvoiceNumber))
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
FROM ((SELECT AssetId FROM CTE_ContractsLease) UNION (SELECT AssetId FROM CTE_ContractsLoan) ) A
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
Select
CD.CustomerNumber AS CustomerNumber
,CD.CustomerName AS CustomerName
,CD.SequenceNumber AS SequenceNumber
,CD.CommencementDate AS CommencementDate
,CD.MaturityDate AS MaturityDate
,CD.TotalCost_Currency AS ContractCurrency
,CA.InvoiceNumber AS InvoiceNumber
,CASE WHEN CD.Status = ''FullyPaidOff'' OR CD.Status = ''Terminated'' OR CD.Status = ''Cancelled'' OR CD.Status = ''Inactive'' THEN NULL ELSE CA.AssetAlias END AS AssetAlias
,CASE WHEN CD.Status = ''FullyPaidOff'' OR CD.Status = ''Terminated'' OR CD.Status = ''Cancelled'' OR CD.Status = ''Inactive'' THEN NULL ELSE CA.SerialNumber END AS Serial#
,CASE WHEN CD.Status = ''FullyPaidOff'' OR CD.Status = ''Terminated'' OR CD.Status = ''Cancelled'' OR CD.Status = ''Inactive'' THEN NULL ELSE CA.AssetAmount END AssetAmount
,CASE WHEN CD.Status = ''FullyPaidOff'' OR CD.Status = ''Terminated'' OR CD.Status = ''Cancelled'' OR CD.Status = ''Inactive'' THEN NULL ELSE CA.Location END AS Location
,CASE WHEN CD.Status = ''FullyPaidOff'' OR CD.Status = ''Terminated'' OR CD.Status = ''Cancelled'' OR CD.Status = ''Inactive'' THEN NULL ELSE CA.Description END AS Description
,CD.ProgramName
FROM
CTE_ContractDetails CD
JOIN CTE_AssetDetail CA ON CD.SequenceNumber = CA.SequenceNumber
AND (CA.InvoiceNumber IS NOT NULL OR (CD.Status = ''Cancelled'' OR CD.Status = ''Inactive''))
SortByCondition
'
IF (@ProgramName IS NOT NULL)
SET @ProgramName_Condition = 'AND program.Name = @ProgramName '
ELSE
SET @ProgramName_Condition = ''
IF (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND @FromSequenceNumber <> '' AND @ToSequenceNumber <> '')
SET @SequenceNumber_Condition =  'WHERE C.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber '
ELSE IF(@FromSequenceNumber IS NOT NULL AND @FromSequenceNumber <> '')
SET @SequenceNumber_Condition =  'WHERE C.SequenceNumber = @FromSequenceNumber '
ELSE IF(@ToSequenceNumber IS NOT NULL AND @ToSequenceNumber <> '')
SET @SequenceNumber_Condition =  'WHERE C.SequenceNumber = @ToSequenceNumber '
ELSE
SET @SequenceNumber_Condition =  'WHERE C.SequenceNumber =  C.SequenceNumber '
IF(@SortBy IS Null)
SET @SORTBY_CONDITION = ''
ELSE IF (@SortBy = 'CommencementDate:Asc')
SET @SORTBY_CONDITION = 'order by CD.CommencementDate'
ELSE IF (@SortBy = 'CommencementDate:Desc')
SET @SORTBY_CONDITION = 'order by CD.CommencementDate DESC'
ELSE IF (@SortBy = 'MaturityDate:Asc')
SET @SORTBY_CONDITION = 'order by CD.MaturityDate'
ELSE IF (@SortBy = 'MaturityDate:Desc')
SET @SORTBY_CONDITION = 'order by CD.MaturityDate DESC'
IF (@CommencementDateFrom IS NOT NULL AND @CommencementDateTo IS NOT NULL AND @CommencementDateFrom <> '' AND @CommencementDateTo <> '')
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate BETWEEN @CommencementDateFrom AND @CommencementDateTo '
ELSE IF(@CommencementDateFrom IS NOT NULL AND @CommencementDateFrom <> '')
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate = @CommencementDateFrom '
ELSE IF(@CommencementDateTo IS NOT NULL AND @CommencementDateTo <> '')
IF(@IsCommencementUpToDate = '1')
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate <= @CommencementDateTo '
ELSE
SET @LeaseCommencementDate_Condition =  'AND LeaseDetail.CommencementDate = @CommencementDateTo '
ELSE
SET @LeaseCommencementDate_Condition =  ''
IF (@CommencementDateFrom IS NOT NULL AND @CommencementDateTo IS NOT NULL AND @CommencementDateFrom <> '' AND @CommencementDateTo <> '')
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate BETWEEN @CommencementDateFrom AND @CommencementDateTo '
ELSE IF(@CommencementDateFrom IS NOT NULL AND @CommencementDateFrom <> '')
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate = @CommencementDateFrom '
ELSE IF(@CommencementDateTo IS NOT NULL AND @CommencementDateTo <> '')
IF(@IsCommencementUpToDate = '1')
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate <= @CommencementDateTo '
ELSE
SET @LoanCommencementDate_Condition =  'AND Loan.CommencementDate = @CommencementDateTo '
ELSE
SET @LoanCommencementDate_Condition =  ''
IF (@MaturityDateFrom IS NOT NULL AND @MaturityDateTo IS NOT NULL AND @MaturityDateFrom <> '' AND @MaturityDateTo <> '')
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate BETWEEN @MaturityDateFrom AND @MaturityDateTo '
ELSE IF(@MaturityDateFrom IS NOT NULL AND @MaturityDateFrom <> '')
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate = @MaturityDateFrom '
ELSE IF(@MaturityDateTo IS NOT NULL AND @MaturityDateTo <> '')
IF(@IsMaturityUpToDate = '1')
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate <= @MaturityDateTo '
ELSE
SET @LeaseMaturityDate_Condition =  'AND LeaseDetail.MaturityDate = @MaturityDateTo '
ELSE
SET @LeaseMaturityDate_Condition =  ''
IF (@MaturityDateFrom IS NOT NULL AND @MaturityDateTo IS NOT NULL AND @MaturityDateFrom <> '' AND @MaturityDateTo <> '')
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate BETWEEN @MaturityDateFrom AND @MaturityDateTo '
ELSE IF(@MaturityDateFrom IS NOT NULL AND @MaturityDateFrom <> '')
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate = @MaturityDateFrom '
ELSE IF(@MaturityDateTo IS NOT NULL AND @MaturityDateTo <> '')
IF(@IsMaturityUpToDate = '1')
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate <= @MaturityDateTo '
ELSE
SET @LoanMaturityDate_Condition =  'AND Loan.MaturityDate = @MaturityDateTo '
ELSE
SET @LoanMaturityDate_Condition =  ''
IF(@IsProgramVendor = '0')
SET @ORIGINATIONWHERECONDITION = 'AND (@DealerOrDistributorNumber IS NULL OR @DealerOrDistributorNumber =''''
OR (OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributorNumber,'',''))
AND (@ProgramVendorNumber IS NULL OR @ProgramVendorNumber =''''  OR
Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'','')))))'
ELSE
IF(@IsDealerFilterAppliedExternally = '0')
SET @ORIGINATIONWHERECONDITION = '
AND (OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributorNumber,'',''))
AND Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
OR (OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
))'
ELSE
SET @ORIGINATIONWHERECONDITION = '
AND (OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributorNumber,'',''))
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
SET @Sql =  REPLACE(@Sql, 'SortByCondition', @SORTBY_CONDITION);
SET @Sql =  REPLACE(@Sql, 'ProgramName_Condition' , @ProgramName_Condition)
EXEC sp_executesql @Sql,N'
@CommencementDateFrom DATE=NULL
,@CommencementDateTo DATE=NULL
,@MaturityDateFrom DATE=NULL
,@MaturityDateTo DATE=NULL
,@FromSequenceNumber NVARCHAR(40)=NULL
,@ToSequenceNumber NVARCHAR(40)=NULL
,@CustomerNumber NVARCHAR(500)=NULL
,@ContractBookingStatus VARCHAR(40)=NULL
,@ProgramVendorNumber NVARCHAR(1000)=NULL
,@DealerOrDistributorNumber VARCHAR(1000)=NULL
,@IsProgramVendor NVARCHAR(1)=NULL
,@IsCommencementUpToDate NVARCHAR(1)=NULL
,@IsMaturityUpToDate NVARCHAR(1)=NULL
,@SortBy Nvarchar(25)= NULL
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
,@ContractBookingStatus
,@ProgramVendorNumber
,@DealerOrDistributorNumber
,@IsProgramVendor
,@IsCommencementUpToDate
,@IsMaturityUpToDate
,@SortBy
,@IsDealerFilterAppliedExternally
,@ProgramName
,@AssetMultipleSerialNumberType

GO

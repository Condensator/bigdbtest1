SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetContractDetailsForReport]
(
@CommencementDateFrom DATETIMEOFFSET=NULL,
@CommencementDateTo DATETIMEOFFSET=NULL,
@MaturityDateFrom DATETIMEOFFSET=NULL,
@MaturityDateTo DATETIMEOFFSET=NULL
)
AS
DECLARE @Sql NVARCHAR(MAX)
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
,CustParty.PartyNumber AS CustomerNumber
,CustParty.PartyName AS CustomerName
,Opp.Number AS CreditApplication
,Party.PartyName AS ProgramVendor
FROM  Contracts C
JOIN CreditApprovedStructures CPS ON C.CreditApprovedStructureId =CPS.Id
JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
JOIN dbo.Customers Cust  ON Opp.CustomerId = Cust.Id
JOIN Parties CustParty ON Cust.Id= CustParty.Id
JOIN CreditApplications CApp ON Opp.Id= CApp.Id
JOIN Parties Party ON CApp.VendorId= Party.Id OR Opp.OriginationSourceId = Party.Id
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
,STUFF((SELECT distinct '','' + P.InvoiceNumber FROM PayableInvoices P WHERE C.ContractId= P.ContractId
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') InvoiceNumber
FROM CTE_Contracts C
JOIN LeaseFinances Lease ON C.ContractId = Lease.ContractId
JOIN LeaseFinanceDetails LeaseDetail ON Lease.Id = LeaseDetail.Id
WHERE (@CommencementDateFrom IS NULL OR  @CommencementDateFrom <= LeaseDetail.CommencementDate)
AND (@CommencementDateTo IS NULL OR  @CommencementDateTo >= LeaseDetail.CommencementDate)
AND (@MaturityDateFrom IS NULL OR  @MaturityDateFrom <= LeaseDetail.MaturityDate)
AND (@MaturityDateTo IS NULL OR  @MaturityDateTo >= LeaseDetail.MaturityDate)
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
,STUFF((SELECT distinct '',''+ P.InvoiceNumber FROM PayableInvoices P WHERE C.ContractId= P.ContractId
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') InvoiceNumber
FROM CTE_Contracts C
JOIN LoanFinances Loan ON Loan.ContractId = C.ContractId
WHERE (@CommencementDateFrom IS NULL OR  @CommencementDateFrom <= Loan.CommencementDate)
AND (@CommencementDateTo IS NULL OR  @CommencementDateTo >= Loan.CommencementDate)
AND (@MaturityDateFrom IS NULL OR  @MaturityDateFrom <= Loan.MaturityDate)
AND (@MaturityDateTo IS NULL OR  @MaturityDateTo >= Loan.MaturityDate)
)
SELECT * FROM CTE_LeaseContracts
UNION SELECT * FROM CTE_LoanContracts'
EXEC sp_executesql @Sql,N'
@CommencementDateFrom DATETIMEOFFSET=NULL,
@CommencementDateTo DATETIMEOFFSET=NULL,
@MaturityDateFrom DATETIMEOFFSET=NULL,
@MaturityDateTo  DATETIMEOFFSET=NULL'
,@CommencementDateFrom
,@CommencementDateTo
,@MaturityDateFrom
,@MaturityDateTo

GO

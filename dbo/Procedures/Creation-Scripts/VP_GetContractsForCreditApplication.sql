SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetContractsForCreditApplication]
(
@CurrentVendorId BIGINT,
@IsProgramVendor BIT,
@CustomerNumber NVARCHAR(40)
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH CTE_LeaseContracts
AS
(
SELECT
DISTINCT
C.Id AS ContractId
,C.SequenceNumber
,C.ContractType
,LFD.CommencementDate
,LFD.MaturityDate
FROM  Contracts C
JOIN LeaseFinances Lease ON C.Id =Lease.ContractId
JOIN LeaseFinanceDetails LFD ON Lease.Id=LFD.Id
JOIN ContractOriginations LeaseCO ON Lease.ContractOriginationId = LeaseCO.Id
JOIN OriginationSourceTypes LeaseOST ON LeaseCO.OriginationSourceTypeId=LeaseOST.Id
JOIN Parties Party ON Lease.CustomerId=Party.Id
WHERE C.SyndicationType = 'None'
AND LeaseOST.Name ='Vendor'
AND LeaseCO.OriginationSourceId = @CurrentVendorId
AND Party.PartyNumber=@CustomerNumber
AND LeaseOST.IsActive=1
AND Lease.BookingStatus='Commenced'
AND Lease.ApprovalStatus='Approved'
AND Lease.IsCurrent=1
AND C.Status = 'Commenced'
),
CTE_LoanContracts
AS
(
SELECT
DISTINCT
C.Id AS ContractId
,C.SequenceNumber
,C.ContractType
,Loan.CommencementDate
,Loan.MaturityDate
FROM  Contracts C
JOIN LoanFinances Loan ON C.Id = Loan.ContractId
JOIN ContractOriginations LoanCO ON Loan.ContractOriginationId=LoanCO.Id
JOIN OriginationSourceTypes LoanOST ON LoanCO.OriginationSourceTypeId=LoanOST.Id
JOIN Parties Party ON Loan.CustomerId=Party.Id
WHERE C.SyndicationType = 'None'
AND LoanOST.Name ='Vendor'
AND LoanCO.OriginationSourceId = @CurrentVendorId
AND Party.PartyNumber=@CustomerNumber
AND LoanOST.IsActive=1
AND Loan.Status='Commenced'
AND loan.ApprovalStatus='Approved'
AND Loan.IsCurrent=1
AND C.Status = 'Commenced'
)
SELECT * FROM CTE_LeaseContracts
UNION ALL
SELECT * FROM CTE_LoanContracts

GO

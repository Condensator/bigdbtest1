SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetLoanContractForPostScheduleFundingJob]
(
@LegalEntityIds LegalEntityIdCollection Readonly,
@ContractID BIGINT = NULL,
@CustomerID BIGINT = NULL,
@ComputedProcessThroughDate DATETIME
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #IntermediateTable  (
ContractId BIGINT
,CustomerId BIGINT
,LegalEntityId BIGINT
,LoanFinanceId BIGINT
,PayableId BIGINT
)

INSERT INTO #IntermediateTable(ContractId, CustomerId, LegalEntityId, LoanFinanceId, PayableId)
SELECT lf.ContractId, lf.CustomerId, lf.LegalEntityId, lf.Id, payable.Id
FROM LoanFinances lf
INNER JOIN Contracts con ON lf.ContractId = con.Id
INNER JOIN Customers cus ON lf.CustomerId = cus.Id
INNER JOIN LegalEntities le ON lf.LegalEntityId = le.Id
INNER JOIN @LegalEntityIds LEId ON le.Id = LEId.LegalEntityId
INNER JOIN Payables payable ON lf.ContractId = payable.EntityId AND payable.EntityType = 'CT'
LEFT JOIN TransactionInstances trans ON lf.Id = trans.EntityId AND trans.EntityName = 'LoanFinance'
WHERE (trans.Id IS NULL OR trans.Status != 'OnHold')
AND lf.IsCurrent = 1
AND lf.ApprovalStatus != 'Pending'
AND lf.ApprovalStatus != 'Rejected'
AND lf.Status != 'Terminated'
AND (con.SyndicationType != '_' AND con.SyndicationType != 'None')
AND (payable.SourceTable = 'SyndicatedAR' OR payable.SourceTable = 'IndirectAR')
AND payable.Status = 'Pending'
AND payable.DueDate <= @ComputedProcessThroughDate
AND (@ContractID IS NULL OR lf.ContractId = @ContractID)
AND (@CustomerID IS NULL OR lf.CustomerId = @CustomerID)

;WITH CTE_AllDRFromSystem
AS
(
SELECT drp.PayableId FROM DisbursementRequestPayables drp
INNER JOIN DisbursementRequests dr ON drp.DisbursementRequestId = dr.Id
WHERE drp.IsActive = 1
AND dr.Status != 'Inactive'
AND drp.PayableId IN (SELECT PayableId FROM #IntermediateTable WHERE PayableId IS NOT NULL)
)

DELETE FROM #IntermediateTable WHERE PayableId IN (SELECT PayableId FROM CTE_AllDRFromSystem)

INSERT INTO #IntermediateTable(ContractId, CustomerId, LegalEntityId, LoanFinanceId)
SELECT lf.ContractId,  lf.CustomerId, lf.LegalEntityId, lf.Id
FROM LoanFinances lf
INNER JOIN Contracts con ON lf.ContractId = con.Id
INNER JOIN Customers cus ON lf.CustomerId = cus.Id
INNER JOIN LegalEntities le ON lf.LegalEntityId = le.Id
INNER JOIN @LegalEntityIds LEId ON le.Id = LEId.LegalEntityId
INNER JOIN LoanFundings loanFunding ON lf.Id = loanFunding.LoanFinanceId
INNER JOIN PayableInvoices funding ON loanFunding.FundingId = funding.Id
LEFT JOIN TransactionInstances trans ON lf.Id = trans.EntityId AND trans.EntityName = 'LoanFinance'
lEFT JOIN CreditApprovedStructures ON 	con.CreditApprovedStructureId=CreditApprovedStructures.Id
lEFT JOIN CreditProfiles ON CreditApprovedStructures.CreditProfileId=CreditProfiles.Id
lEFT JOIN CreditApplications ON CreditProfiles.OpportunityId=CreditApplications.Id
LEFT JOIN vendors programVendors on CreditApplications.VendorId= programVendors.Id
LEFT JOIN Vendors ON CreditProfiles.OriginationSourceId=Vendors.Id
WHERE (trans.Id IS NULL OR trans.Status != 'OnHold')
--AND (CreditProfiles.Id IS NULL OR CreditProfiles.Status='FutureFundingReserved')
AND lf.IsCurrent = 1
AND lf.ApprovalStatus != 'Pending'
AND lf.ApprovalStatus != 'Rejected'
AND lf.Status != 'Terminated'
AND ((loanFunding.IsApproved = 1  AND funding.DueDate <= @ComputedProcessThroughDate)
OR (con.CreditApprovedStructureId IS NOT NULL
AND loanFunding.IsApproved=0
AND CreditProfiles.Status='FutureFundingReserved'
and ((Vendors.VendorProgramType='ProgramVendor' and DATEADD(DD,Vendors.FundingApprovalLeadDays,@ComputedProcessThroughDate)>=funding.DueDate )
or(Vendors.VendorProgramType='DealerOrDistributor' and DATEADD(DD,isnull(programVendors.FundingApprovalLeadDays,0),@ComputedProcessThroughDate)>=funding.DueDate ) )))
AND loanFunding.Type = 'FutureScheduled' AND loanFunding.IsActive = 1
AND (@ContractID IS NULL OR lf.ContractId = @ContractID)
AND (@CustomerID IS NULL OR lf.CustomerId = @CustomerID)

SELECT ContractId, CustomerId, LegalEntityId, LoanFinanceId
FROM #IntermediateTable
GROUP BY ContractId, CustomerId, LegalEntityId, LoanFinanceId

DROP TABLE #IntermediateTable
END

GO

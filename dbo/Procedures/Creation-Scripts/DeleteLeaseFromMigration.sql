SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeleteLeaseFromMigration]
AS
BEGIN
SET NOCOUNT ON
SELECT l.R_LeaseFinanceId Id  , l.R_ContractId ContractId
INTO #LeaseFinanceIds
FROM stgLease l WHERE l.IsMigrated = 0 AND l.IsFailed = 1
AND l.R_LeaseFinanceId IS NOT NULL
ALTER TABLE LeaseFinances NOCHECK CONSTRAINT ELeaseFinance_TaxExemptRule
ALTER TABLE LeaseFinances NOCHECK CONSTRAINT ELeaseFinance_ContractOrigination
ALTER TABLE ContractOriginationServicingDetails NOCHECK CONSTRAINT EContractOriginationServicingDetail_ServicingDetail
DECLARE @DeleteRecord bigint;
---TaxExemptRules--
SET  @DeleteRecord = (SELECT lf.TaxExemptRuleId FROM #LeaseFinanceIds lfi
JOIN dbo.LeaseFinances lf ON lfi.Id = lf.Id);
--UPDATE dbo.LeaseFinances set LeaseFinances.TaxExemptRuleId = 0 FROM #LeaseFinanceIds lfi WHERE lfi.Id = dbo.LeaseFinances.Id;
DELETE dbo.TaxExemptRules WHERE ID = @DeleteRecord;
SET @DeleteRecord = 0;
---TaxExemptRules--
---ServicingDetails--
SELECT cosd.ServicingDetailId into #ServicingDetailToDelete FROM #LeaseFinanceIds lfi
JOIN dbo.LeaseFinances lf ON lfi.Id = lf.Id
JOIN dbo.ContractOriginations co ON lf.ContractOriginationId = co.Id
JOIN dbo.ContractOriginationServicingDetails cosd ON cosd.ContractOriginationId = co.Id
--UPDATE ContractOriginationServicingDetails SET ServicingDetailId = 0 FROM #LeaseFinanceIds lfi
--JOIN dbo.LeaseFinances lf ON lfi.Id = lf.Id
--JOIN dbo.ContractOriginations co ON lf.ContractOriginationId = co.Id
--WHERE ContractOriginationServicingDetails.ContractOriginationId = co.Id
DELETE dbo.ServicingDetails FROM #ServicingDetailToDelete temp WHERE temp.ServicingDetailId = dbo.ServicingDetails.Id
---ServicingDetails--
--DELETE dbo.ContractOriginations FROM #LeaseFinanceIds lfi
--JOIN dbo.LeaseFinances lf ON lfi.Id = lf.Id
--WHERE lf.ContractOriginationId = dbo.ContractOriginations.Id
---ContractOriginations--
SET  @DeleteRecord = (SELECT lf.ContractOriginationId FROM #LeaseFinanceIds lfi
JOIN dbo.LeaseFinances lf ON lfi.Id = lf.Id);
--UPDATE dbo.LeaseFinances set LeaseFinances.ContractOriginationId = 0 FROM #LeaseFinanceIds lfi WHERE lfi.Id = dbo.LeaseFinances.Id;
DELETE dbo.ContractOriginations WHERE ID = @DeleteRecord;
SET @DeleteRecord = 0;
---ContractOriginations--
DELETE dbo.InterestRateDetails FROM #LeaseFinanceIds lfi
JOIN dbo.LeaseInterestRates lir ON lfi.Id = lir.LeaseFinanceDetailId
WHERE lir.InterestRateDetailId = dbo.InterestRateDetails.Id
DELETE LeaseBlendedItems FROM #LeaseFinanceIds lfi WHERE lfi.Id = LeaseBlendedItems.LeaseFinanceId
DELETE dbo.BlendedItems FROM #LeaseFinanceIds lfi
JOIN dbo.LeaseBlendedItems lbi ON lfi.Id = lbi.LeaseFinanceId
WHERE lbi.BlendedItemId = dbo.BlendedItems.Id
DELETE dbo.LeaseFinances FROM #LeaseFinanceIds lfi WHERE lfi.Id = dbo.LeaseFinances.Id
DELETE dbo.ContractBankAccountPaymentThresholds FROM #LeaseFinanceIds lfi WHERE lfi.ContractId = dbo.ContractBankAccountPaymentThresholds.ContractId
DELETE dbo.ContractBillings FROM #LeaseFinanceIds lfi WHERE lfi.ContractId = dbo.ContractBillings.Id
DELETE dbo.ContractContacts FROM #LeaseFinanceIds lfi WHERE lfi.ContractId = dbo.ContractContacts.ContractId
DELETE dbo.ContractThirdPartyRelationships FROM #LeaseFinanceIds lfi WHERE lfi.ContractId = dbo.ContractThirdPartyRelationships.ContractId
DELETE dbo.EmployeesAssignedToContracts FROM #LeaseFinanceIds lfi WHERE lfi.ContractId = dbo.EmployeesAssignedToContracts.ContractId
DELETE dbo.ContractLateFees FROM #LeaseFinanceIds lfi WHERE lfi.ContractId = dbo.ContractLateFees.Id
DELETE dbo.Contracts FROM #LeaseFinanceIds lfi WHERE lfi.ContractId = dbo.Contracts.Id
ALTER TABLE LeaseFinances CHECK CONSTRAINT ELeaseFinance_TaxExemptRule
ALTER TABLE LeaseFinances CHECK CONSTRAINT ELeaseFinance_ContractOrigination
ALTER TABLE ContractOriginationServicingDetails CHECK CONSTRAINT EContractOriginationServicingDetail_ServicingDetail
drop table #LeaseFinanceIds;
drop table #ServicingDetailToDelete;
COMMIT TRANSACTION;
END

GO

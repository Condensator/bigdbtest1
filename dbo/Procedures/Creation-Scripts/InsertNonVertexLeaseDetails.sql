SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexLeaseDetails]
(
@NoneSyndicationType NVARCHAR(100),
@JobStepInstanceId BIGINT
)
AS
BEGIN
WITH CTE_DistinctContractIds AS
(
SELECT DISTINCT ContractId
FROM SalesTaxReceivableDetailExtract WHERE IsVertexSupported =0  AND InvalidErrorCode IS NULL  AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO NonVertexLeaseDetailExtract
([ContractId],[IsContractCapitalizeUpfront],[LeaseFinanceId],[IsCountryTaxExempt],[IsStateTaxExempt],
[IsCountyTaxExempt],[IsCityTaxExempt],[IsLease],[CommencementDate],[ClassificationContractType],
[NumberOfInceptionPayments],[IsSyndicated],[JobStepInstanceId],[SalesTaxRemittanceMethod])
SELECT
DC.ContractId
,LFD.CapitalizeUpfrontSalesTax
,LF.Id AS LeaseFinanceId
,TE.IsCountryTaxExempt
,TE.IsStateTaxExempt
,TE.IsCountyTaxExempt
,TE.IsCityTaxExempt
,1 AS IsLease
,LFD.CommencementDate
,LFD.LeaseContractType
,LFD.NumberOfInceptionPayments
,CASE WHEN C.SyndicationType = @NoneSyndicationType THEN 0 ELSE 1 END
,@JobStepInstanceId
,REPLACE(C.SalesTaxRemittanceMethod, 'Based','')
FROM CTE_DistinctContractIds DC
INNER JOIN Contracts C ON DC.ContractId = C.Id
INNER JOIN LeaseFinances LF ON DC.ContractId = LF.ContractId  AND LF.IsCurrent = 1
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
INNER JOIN TaxExemptRules TE ON LF.TaxExemptRuleId = TE.Id;
WITH CTE_DistinctContractIds AS
(
SELECT DISTINCT ContractId
FROM SalesTaxReceivableDetailExtract WHERE IsVertexSupported =0  AND InvalidErrorCode IS NULL AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO NonVertexLeaseDetailExtract
([ContractId],[IsContractCapitalizeUpfront],[LeaseFinanceId],[IsCountryTaxExempt],[IsStateTaxExempt],
[IsCountyTaxExempt],[IsCityTaxExempt],[IsLease],[CommencementDate],[ClassificationContractType],
[NumberOfInceptionPayments],[IsSyndicated],[JobStepInstanceId],[SalesTaxRemittanceMethod])
SELECT
DC.ContractId,
0 AS IsContractCapitalizeUpfront,
LF.Id AS LeaseFinanceId,
0 AS IsCountryTaxExempt,
0 AS IsStateTaxExempt,
0 AS IsCountyExempt,
0 AS IsCityTaxExempt,
0 AS IsLease,
LF.CommencementDate,
'_' AS ClassificationContractType,
0 AS NumberOfInceptionPayments,
CASE WHEN C.SyndicationType = @NoneSyndicationType THEN 0 ELSE 1 END,
@JobStepInstanceId,
REPLACE(C.SalesTaxRemittanceMethod, 'Based','')
FROM CTE_DistinctContractIds DC
INNER JOIN Contracts C ON DC.ContractId = C.Id
INNER JOIN LoanFinances LF ON DC.ContractId = LF.ContractId AND LF.IsCurrent = 1
END

GO

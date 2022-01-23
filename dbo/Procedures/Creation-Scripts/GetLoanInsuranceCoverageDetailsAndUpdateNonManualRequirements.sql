SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GetLoanInsuranceCoverageDetailsAndUpdateNonManualRequirements]
(
@LoanFinanceId BIGINT,
@TotalInvestmentAmount Decimal(16,2)
)
AS
BEGIN
SET NOCOUNT ON;
Set transaction Isolation level Read Uncommitted;
CREATE TABLE #CoverageTypeDetails
(
CoverageTypeId BIGINT,
PerOccuranceAmount DECIMAL(16,2),
PerOccurrenceDeductible DECIMAL(16,2),
AggregateAmount DECIMAL(16,2),
AggregateDeductible DECIMAL(16,2),
CoverageIsActive BIT
);
WITH AssetDetails as
(
SELECT ATY.* FROM CollateralAssets CA
JOIN  Assets A ON CA.AssetId = A.Id
JOIN AssetTypes ATY ON A.TypeId = ATY.Id
WHERE CA.LoanFinanceId = @LoanFinanceId AND CA.IsActive = 1 AND ATY.IsActive = 1
),
TemplateDetails as
(
SELECT IT.Id as InsuranceTemplateID , ITD.AssetTypeId FROM InsuranceTemplateDetails ITD
JOIN InsuranceTemplates IT ON ITD.InsuranceTemplateId = IT.Id
WHERE ITD.OwnershipStatus = 'Loan' AND IT.IsActive = 1 AND ITD.IsActive = 1
)
SELECT
CoverageTypeId = ICD.CoverageTypeConfigId,
AggregateAmount = ICD.AggregateAmount_Amount,
AggregateDeductible = ICD.AggregateDeductible_Amount,
PerOccurrenceDeductible = ICD.PerOccurrenceDeductible_Amount ,
PerOccurrenceAmount = CASE WHEN ICD.IsContractAmount = 1 THEN  @TotalInvestmentAmount ELSE ICD.PerOccurrenceAmount_Amount END,
CoverageIsActive = ICD.IsActive
INTO #CoverageTypeDetailsDummy
FROM CoverageTypeConfigs CTC
JOIN InsuranceCoverageDetails ICD ON CTC.Id = ICD.CoverageTypeConfigId
JOIN TemplateDetails TD ON ICD.InsuranceTemplateId = TD.InsuranceTemplateID
JOIN AssetDetails AD ON TD.AssetTypeId = AD.Id
INSERT INTO #CoverageTypeDetails (CoverageTypeId , PerOccuranceAmount , PerOccurrenceDeductible , AggregateAmount , AggregateDeductible , CoverageIsActive )
SELECT
CoverageTypeId,
MAX(PerOccurrenceAmount),
MAX(PerOccurrenceDeductible),
MAX(AggregateAmount),
MAX(AggregateDeductible),
MAX(0+CoverageIsActive)
FROM #CoverageTypeDetailsDummy WHERE CoverageIsActive = 1 GROUP BY CoverageTypeId
UPDATE LoanInsuranceRequirements
Set
IsActive = 0,
Status = 'Inactive',
PerOccurrenceAmount_Amount = 0.00,
PerOccurrenceDeductible_Amount = 0.00,
AggregateAmount_Amount = 0.00,
AggregateDeductible_Amount = 0.00
WHERE LoanFinanceId = @LoanFinanceId AND IsManual = 0 AND CoverageTypeConfigId NOT IN (Select CoverageTypeId from #CoverageTypeDetails)
Select * from #CoverageTypeDetails
Drop table #CoverageTypeDetails
Drop table #CoverageTypeDetailsDummy
END

GO

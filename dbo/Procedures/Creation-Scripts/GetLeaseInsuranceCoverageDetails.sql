SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetLeaseInsuranceCoverageDetails]
(
@LeaseFinanceId BIGINT,
@AssetTypeDetails AssetTypeDetails READONLY,
@OwnershipStatusValuesLienholder NVARCHAR(50),
@OwnershipStatusValuesBeneficialOwner NVARCHAR(50),
@OwnershipStatusValuesOwner NVARCHAR(30),
@InsuranceOwnershipStatusValuesLeaseLienholder NVARCHAR(50),
@InsuranceOwnershipStatusValuesLeaseOwner NVARCHAR(30),
@InvestmentWithCapitalization DECIMAL(16,2)
)
AS
BEGIN
SET NOCOUNT ON;  
SELECT * INTO #AssetTypeDetails FROM @AssetTypeDetails;
SELECT
DISTINCT(IT.Id)
INTO #InsuranceTemplateIds
FROM #AssetTypeDetails A
JOIN AssetTypes AT on A.Id  =  AT.Id
JOIN InsuranceTemplateDetails ITD ON AT.Id  =  ITD.AssetTypeId
JOIN InsuranceTemplates IT ON ITD.InsuranceTemplateId  =  IT.Id
WHERE AT.IsActive = 1 
AND ITD.IsActive = 1
AND IT.IsActive = 1
AND
(
(A.OwnershipStatus = @OwnershipStatusValuesLienholder AND ITD.OwnershipStatus = @InsuranceOwnershipStatusValuesLeaseLienholder)
OR
(A.OwnershipStatus IN (@OwnershipStatusValuesBeneficialOwner,@OwnershipStatusValuesOwner,'_') AND ITD.OwnershipStatus = @InsuranceOwnershipStatusValuesLeaseOwner)
);
CREATE TABLE #CoverageTypeDetails
(
CoverageTypeId BIGINT,
PerOccuranceAmount DECIMAL(16,2),
PerOccurrenceDeductible DECIMAL(16,2),
AggregateAmount DECIMAL(16,2),
AggregateDeductible DECIMAL(16,2),
CoverageIsActive BIT
);
INSERT INTO #CoverageTypeDetails
SELECT DISTINCT ICD.CoverageTypeConfigId, 0.0, 0.0, 0.0, 0.0, 0
FROM #InsuranceTemplateIds IT
JOIN InsuranceCoverageDetails ICD ON IT.Id = ICD.InsuranceTemplateId
LEFT JOIN InsuranceCoverageDetails AICD ON ICD.Id = AICD.Id and AICD.IsActive = 1
GROUP BY ICD.CoverageTypeConfigId
HAVING ISNULL(COUNT(AICD.Id),0) = 0;
SELECT
CoverageTypeConfigId = ICD.CoverageTypeConfigId,
PerOccuranceAmount =  CASE WHEN ICD.IsContractAmount = 1 THEN @InvestmentWithCapitalization ELSE ICD.PerOccurrenceAmount_Amount END,
PerOccurrenceDeductible = ISNULL(ICD.PerOccurrenceDeductible_Amount ,0.0),
AggregateAmount         = ISNULL(ICD.AggregateAmount_Amount,0.0),
AggregateDeductible     = ISNULL(ICD.AggregateDeductible_Amount,0.0)
INTO #ActiveCoverageTypeDetails
FROM #InsuranceTemplateIds IT
JOIN InsuranceCoverageDetails ICD ON IT.Id = ICD.InsuranceTemplateId AND ICD.IsActive = 1;
INSERT INTO #CoverageTypeDetails
SELECT CoverageTypeConfigId, MAX(PerOccuranceAmount),MAX(PerOccurrenceDeductible),MAX(AggregateAmount),MAX(AggregateDeductible), 1
FROM #ActiveCoverageTypeDetails
GROUP BY CoverageTypeConfigId;
SELECT * FROM #CoverageTypeDetails;
DROP TABLE #InsuranceTemplateIds;
DROP TABLE #ActiveCoverageTypeDetails;
DROP TABLE #CoverageTypeDetails;
END

GO

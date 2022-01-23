SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateLeaseTaxAssessmentDetailsFromAssumption]
(
@AssumptionId BIGINT,
@LeaseFinanceId BIGINT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET)
AS
BEGIN
SET NOCOUNT ON;

DECLARE  @LocationTaxAssessmentDetailMapping TABLE 
(
NewTaxAssessmentDetailId BIGINT,
NewLocationId BIGINT,
AssetTypeId BIGINT,
IsDummy BIT
)

UPDATE LeaseTaxAssessmentDetails
SET IsActive = 0,UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
WHERE LeaseFinanceId = @LeaseFinanceId;

    MERGE INTO [LeaseTaxAssessmentDetails]
    USING
    (
		SELECT  [ATAD].[SalesTaxRate],
		[ATAD].[SalesTaxAmount_Amount],
		[ATAD].[OtherBasisTypesAvailable],
		[ATAD].[UpfrontTaxMode],
		[ATAD].[IsActive],
		[ATAD].[TaxBasisTypeId],
		[ATAD].[LocationId],
		[ATAD].[AssetTypeId],
		[ATAD].[SalesTaxAmount_Currency],
		[ATAD].IsDummy,
		[ATAD].TaxCodeId,
		[ATAD].TaxTypeId
		FROM AssumptionTaxAssessmentDetails [ATAD]
		Where [ATAD].AssumptionId = @AssumptionId and [ATAD].IsActive = 1
	) AS ATAD
	ON 1=0
	WHEN NOT MATCHED 
	THEN 
INSERT 
([SalesTaxRate]
,[SalesTaxAmount_Amount]
,[SalesTaxAmount_Currency]
,[OtherBasisTypesAvailable]
,[UpfrontTaxMode]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[TaxBasisTypeId]
,[LocationId]
,[AssetTypeId]
,[LeaseFinanceId]
,[Exemption]
,[PrepaidUpfrontTax_Amount]
,[PrepaidUpfrontTax_Currency]
,[UpfrontTaxPayable_Amount]
,[UpfrontTaxPayable_Currency]
,[TaxCodeId]
,[TaxTypeId])
VALUES([ATAD].[SalesTaxRate],
[ATAD].[SalesTaxAmount_Amount],
[ATAD].[SalesTaxAmount_Currency],
[ATAD].[OtherBasisTypesAvailable],
[ATAD].[UpfrontTaxMode],
[ATAD].[IsActive],
@UpdatedById,
@UpdatedTime,
[ATAD].[TaxBasisTypeId],
[ATAD].[LocationId],
[ATAD].[AssetTypeId],
@LeaseFinanceId,
'NULL',
'0.00',
[ATAD].[SalesTaxAmount_Currency],
'0.00',
[ATAD].[SalesTaxAmount_Currency],
[ATAD].[TaxCodeId],
[ATAD].[TaxTypeId]
)
OUTPUT INSERTED.Id,INSERTED.LocationId,INSERTED.AssetTypeId,ATAD.IsDummy INTO @LocationTaxAssessmentDetailMapping;


UPDATE  LA
SET LeaseTaxAssessmentDetailId = LTDM.NewTaxAssessmentDetailId
FROM LeaseAssets LA
INNER JOIN Assets AST
ON LA.AssetId = AST.Id
INNER JOIN AssetLocations ALC
ON AST.Id = ALC.AssetId AND ALC.IsActive = 1
INNER JOIN @LocationTaxAssessmentDetailMapping LTDM
ON ALC.LocationId = LTDM.NewLocationId AND AST.TypeId = LTDM.AssetTypeId
WHERE LA.LeaseFinanceId = @LeaseFinanceId AND LA.IsActive = 1 AND LTDM.IsDummy=0
END;

GO

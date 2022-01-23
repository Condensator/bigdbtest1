SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateTaxBasisTypeForAssetLocation]
(
@TaxBasisType nvarchar(4),
@AssetId bigint,
@CreatedById bigint,
@CreatedTime datetime
)
AS
BEGIN
SET NOCOUNT ON;
Create table #AssetLocation
(
UpfrontTaxMode nvarchar(4)
,IsFLStampTaxExempt bit
,LocationId bigint
,AssetId bigint
,ReciprocityAmount_Amount decimal(16,2)
,ReciprocityAmount_Currency varchar(3)
,LienCredit_Amount decimal(16,2)
,LienCredit_Currency varchar(3)
)
Insert INTO #AssetLocation
select EffectiveFromDate,UpfrontTaxMode,IsFLStampTaxExempt,LocationId,AssetId,ReciprocityAmount_Amount,ReciprocityAmount_Currency,
LienCredit_Amount,LienCredit_Currency from AssetLocations where AssetId=@AssetId and IsCurrent=1 and IsActive=1
update AssetLocations set IsActive=0,IsCurrent=0 where AssetId=@AssetId and IsCurrent=1 and IsActive=1
INSERT INTO AssetLocations
(
EffectiveFromDate
,IsCurrent
,TaxBasisType
,UpfrontTaxMode
,IsActive
,LocationId
,AssetId
,IsFLStampTaxExempt
,CreatedById
,CreatedTime
,LienCredit_Amount
,LienCredit_Currency
,ReciprocityAmount_Amount
,ReciprocityAmount_Currency
,UpfrontTaxAssessedInLegacySystem)
SELECT
AssetRecords.EffectiveFromDate
,1
,@TaxBasisType
,AssetRecords.UpfrontTaxMode
,1
,AssetRecords.LocationId
,AssetRecords.AssetId
,AssetRecords.IsFLStampTaxExempt
,@CreatedById
,@CreatedTime
,AssetRecords.LienCredit_Amount
,AssetRecords.LienCredit_Currency
,AssetRecords.ReciprocityAmount_Amount
,AssetRecords.ReciprocityAmount_Currency
,CAST(0 AS BIT)
FROM
#AssetLocation as AssetRecords
END

GO

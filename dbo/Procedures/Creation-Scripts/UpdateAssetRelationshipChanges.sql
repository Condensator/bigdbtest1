SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateAssetRelationshipChanges]
(
@assetsToUpdateRelationship AssetRelationshipUpdateTempTable READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
MERGE Assets AS Asset
USING @assetsToUpdateRelationship AS AssetDetail
ON (Asset.Id = AssetDetail.AssetId)
WHEN MATCHED THEN
UPDATE SET
Asset.ParentAssetId = AssetDetail.ParentAssetId,
Asset.UpdatedById = AssetDetail.UpdatedById,
Asset.UpdatedTime = AssetDetail.UpdatedTime
;
Update Assets set IsParent = 1 where Id in (select ParentAssetId from @assetsToUpdateRelationship)
CREATE TABLE #AssetLocationsTemp
(
[EffectiveFromDate] [date] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[UpfrontTaxMode] [nvarchar](6) NULL,
[TaxBasisType] [nvarchar](5) NULL,
[IsFLStampTaxExempt] [bit] NOT NULL,
[ReciprocityAmount_Amount] [decimal](16, 2) NOT NULL,
[ReciprocityAmount_Currency] [nvarchar](3) NOT NULL,
[LienCredit_Amount] [decimal](16, 2) NOT NULL,
[LienCredit_Currency] [nvarchar](3) NOT NULL,
[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
[IsActive] [bit] NOT NULL,
[LocationId] [bigint] NOT NULL,
[AssetId] [bigint] NOT NULL,
[UpdatedById] [bigint] NULL,
[UpdatedTime] [datetimeoffset](7) NULL,
[CreatedById] [bigint] NOT NULL,
[CreatedTime] [datetimeoffset](7) NOT NULL
)
UPDATE AssetLocations SET [IsCurrent] = 0, [IsActive] = 0 WHERE AssetId IN
(SELECT ChildAssetInfo.[AssetId] FROM @assetsToUpdateRelationship AS ChildAssetInfo)
INSERT INTO #AssetLocationsTemp
(
[EffectiveFromDate], [IsCurrent], [UpfrontTaxMode], [TaxBasisType], [IsFLStampTaxExempt], [ReciprocityAmount_Amount], [ReciprocityAmount_Currency],
[LienCredit_Amount], [LienCredit_Currency], [UpfrontTaxAssessedInLegacySystem], [IsActive], [LocationId], [AssetId], [UpdatedById], [UpdatedTime], [CreatedById], [CreatedTime]
)
SELECT
[EffectiveFromDate], [IsCurrent], [UpfrontTaxMode], [TaxBasisType], [IsFLStampTaxExempt], [ReciprocityAmount_Amount], [ReciprocityAmount_Currency],
[LienCredit_Amount], [LienCredit_Currency], [UpfrontTaxAssessedInLegacySystem], [IsActive], [LocationId], ChildAssetInfo.[AssetId], ParentAssetLocation.[UpdatedById], ParentAssetLocation.[UpdatedTime], ChildAssetInfo.[UpdatedById], ChildAssetInfo.[UpdatedTime]
FROM
[dbo].[AssetLocations] AS ParentAssetLocation CROSS JOIN @assetsToUpdateRelationship AS ChildAssetInfo
WHERE
ParentAssetLocation.[AssetId] = ChildAssetInfo.[ParentAssetId] AND [IsActive] = 1
MERGE
AssetLocations AS AssetLocation
USING #AssetLocationsTemp AS AssetDetail
ON (AssetLocation.[AssetId] = AssetDetail.[AssetId] AND AssetLocation.[LocationId] = AssetDetail.[LocationId])
WHEN MATCHED THEN UPDATE SET
AssetLocation.[EffectiveFromDate] = AssetDetail.[EffectiveFromDate],
AssetLocation.[IsCurrent] = AssetDetail.[IsCurrent],
AssetLocation.[UpfrontTaxMode] = AssetDetail.[UpfrontTaxMode],
AssetLocation.[TaxBasisType] = AssetDetail.[TaxBasisType],
AssetLocation.[IsFLStampTaxExempt] = AssetDetail.[IsFLStampTaxExempt],
AssetLocation.[ReciprocityAmount_Amount] = AssetDetail.[ReciprocityAmount_Amount],
AssetLocation.[ReciprocityAmount_Currency] = AssetDetail.[ReciprocityAmount_Currency],
AssetLocation.[LienCredit_Amount] = AssetDetail.[LienCredit_Amount],
AssetLocation.[LienCredit_Currency] = AssetDetail.[LienCredit_Currency],
AssetLocation.[UpfrontTaxAssessedInLegacySystem] = AssetDetail.[UpfrontTaxAssessedInLegacySystem],
AssetLocation.[IsActive] = AssetDetail.[IsActive],
AssetLocation.[UpdatedById] = AssetDetail.[UpdatedById],
AssetLocation.[UpdatedTime] = AssetDetail.[UpdatedTime]
WHEN NOT MATCHED BY TARGET THEN
INSERT
(
[EffectiveFromDate], [IsCurrent], [UpfrontTaxMode], [TaxBasisType], [IsFLStampTaxExempt], [ReciprocityAmount_Amount], [ReciprocityAmount_Currency],
[LienCredit_Amount], [LienCredit_Currency], [UpfrontTaxAssessedInLegacySystem], [IsActive], [LocationId], [AssetId], [CreatedById], [CreatedTime]
)
VALUES
(
AssetDetail.[EffectiveFromDate], AssetDetail.[IsCurrent], AssetDetail.[UpfrontTaxMode], AssetDetail.[TaxBasisType],
AssetDetail.[IsFLStampTaxExempt], AssetDetail.[ReciprocityAmount_Amount], AssetDetail.[ReciprocityAmount_Currency],
AssetDetail.[LienCredit_Amount], AssetDetail.[LienCredit_Currency], AssetDetail.[UpfrontTaxAssessedInLegacySystem], AssetDetail.[IsActive], AssetDetail.[LocationId], AssetDetail.[AssetId],
AssetDetail.[CreatedById], AssetDetail.[CreatedTime]
);
;
DROP TABLE #AssetLocationsTemp;
END

GO

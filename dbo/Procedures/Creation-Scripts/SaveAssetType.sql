SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetType]
(
 @val [dbo].[AssetType] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[AssetTypes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[AssetCategoryId]=S.[AssetCategoryId],[AssetClassCodeId]=S.[AssetClassCodeId],[BookDepreciationTemplateId]=S.[BookDepreciationTemplateId],[CapitalCostAllowanceClassId]=S.[CapitalCostAllowanceClassId],[CostTypeId]=S.[CostTypeId],[DeactivationDate]=S.[DeactivationDate],[Description]=S.[Description],[EconomicLifeInMonths]=S.[EconomicLifeInMonths],[EquipmentClass]=S.[EquipmentClass],[ExcludeFrom90PercentTest]=S.[ExcludeFrom90PercentTest],[ExemptProperty]=S.[ExemptProperty],[FlatFeeParameter]=S.[FlatFeeParameter],[IRSClassCode]=S.[IRSClassCode],[IsActive]=S.[IsActive],[IsCollateralTracking]=S.[IsCollateralTracking],[IsElectronicallyDelivered]=S.[IsElectronicallyDelivered],[IsEligibleForFPI]=S.[IsEligibleForFPI],[IsHighRisk]=S.[IsHighRisk],[IsInsuranceRequired]=S.[IsInsuranceRequired],[IsPermissibleMassRange]=S.[IsPermissibleMassRange],[IsQualifiedTechnicalEquipment]=S.[IsQualifiedTechnicalEquipment],[IsRoadTaxApplicable]=S.[IsRoadTaxApplicable],[IsSoft]=S.[IsSoft],[IsTrailer]=S.[IsTrailer],[Name]=S.[Name],[PortfolioId]=S.[PortfolioId],[PricingGroupId]=S.[PricingGroupId],[ProductId]=S.[ProductId],[ReviewFrequency]=S.[ReviewFrequency],[RoadTaxType]=S.[RoadTaxType],[Serialized]=S.[Serialized],[TaxExemptRuleId]=S.[TaxExemptRuleId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[AssetCategoryId],[AssetClassCodeId],[BookDepreciationTemplateId],[CapitalCostAllowanceClassId],[CostTypeId],[CreatedById],[CreatedTime],[DeactivationDate],[Description],[EconomicLifeInMonths],[EquipmentClass],[ExcludeFrom90PercentTest],[ExemptProperty],[FlatFeeParameter],[IRSClassCode],[IsActive],[IsCollateralTracking],[IsElectronicallyDelivered],[IsEligibleForFPI],[IsHighRisk],[IsInsuranceRequired],[IsPermissibleMassRange],[IsQualifiedTechnicalEquipment],[IsRoadTaxApplicable],[IsSoft],[IsTrailer],[Name],[PortfolioId],[PricingGroupId],[ProductId],[ReviewFrequency],[RoadTaxType],[Serialized],[TaxExemptRuleId])
    VALUES (S.[ActivationDate],S.[AssetCategoryId],S.[AssetClassCodeId],S.[BookDepreciationTemplateId],S.[CapitalCostAllowanceClassId],S.[CostTypeId],S.[CreatedById],S.[CreatedTime],S.[DeactivationDate],S.[Description],S.[EconomicLifeInMonths],S.[EquipmentClass],S.[ExcludeFrom90PercentTest],S.[ExemptProperty],S.[FlatFeeParameter],S.[IRSClassCode],S.[IsActive],S.[IsCollateralTracking],S.[IsElectronicallyDelivered],S.[IsEligibleForFPI],S.[IsHighRisk],S.[IsInsuranceRequired],S.[IsPermissibleMassRange],S.[IsQualifiedTechnicalEquipment],S.[IsRoadTaxApplicable],S.[IsSoft],S.[IsTrailer],S.[Name],S.[PortfolioId],S.[PricingGroupId],S.[ProductId],S.[ReviewFrequency],S.[RoadTaxType],S.[Serialized],S.[TaxExemptRuleId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

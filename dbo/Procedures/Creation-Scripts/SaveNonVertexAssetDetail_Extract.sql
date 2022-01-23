SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonVertexAssetDetail_Extract]
(
 @val [dbo].[NonVertexAssetDetail_Extract] READONLY
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
MERGE [dbo].[NonVertexAssetDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[CityTaxTypeId]=S.[CityTaxTypeId],[ContractId]=S.[ContractId],[CountyTaxTypeId]=S.[CountyTaxTypeId],[IsCityTaxExempt]=S.[IsCityTaxExempt],[IsCountryTaxExempt]=S.[IsCountryTaxExempt],[IsCountyTaxExempt]=S.[IsCountyTaxExempt],[IsStateTaxExempt]=S.[IsStateTaxExempt],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseAssetId]=S.[LeaseAssetId],[PreviousSalesTaxRemittanceResponsibility]=S.[PreviousSalesTaxRemittanceResponsibility],[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate]=S.[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate],[SalesTaxRemittanceResponsibility]=S.[SalesTaxRemittanceResponsibility],[StateTaxTypeId]=S.[StateTaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CityTaxTypeId],[ContractId],[CountyTaxTypeId],[CreatedById],[CreatedTime],[IsCityTaxExempt],[IsCountryTaxExempt],[IsCountyTaxExempt],[IsStateTaxExempt],[JobStepInstanceId],[LeaseAssetId],[PreviousSalesTaxRemittanceResponsibility],[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate],[SalesTaxRemittanceResponsibility],[StateTaxTypeId])
    VALUES (S.[AssetId],S.[CityTaxTypeId],S.[ContractId],S.[CountyTaxTypeId],S.[CreatedById],S.[CreatedTime],S.[IsCityTaxExempt],S.[IsCountryTaxExempt],S.[IsCountyTaxExempt],S.[IsStateTaxExempt],S.[JobStepInstanceId],S.[LeaseAssetId],S.[PreviousSalesTaxRemittanceResponsibility],S.[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate],S.[SalesTaxRemittanceResponsibility],S.[StateTaxTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

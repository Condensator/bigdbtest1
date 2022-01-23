SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVertexAssetDetail_Extract]
(
 @val [dbo].[VertexAssetDetail_Extract] READONLY
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
MERGE [dbo].[VertexAssetDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetCatalogNumber]=S.[AssetCatalogNumber],[AssetId]=S.[AssetId],[AssetSerialOrVIN]=S.[AssetSerialOrVIN],[AssetType]=S.[AssetType],[AssetUsageCondition]=S.[AssetUsageCondition],[ContractId]=S.[ContractId],[ContractTypeName]=S.[ContractTypeName],[GrossVehicleWeight]=S.[GrossVehicleWeight],[IsElectronicallyDelivered]=S.[IsElectronicallyDelivered],[IsSKU]=S.[IsSKU],[JobStepInstanceId]=S.[JobStepInstanceId],[PreviousSalesTaxRemittanceResponsibility]=S.[PreviousSalesTaxRemittanceResponsibility],[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate]=S.[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate],[SaleLeasebackCode]=S.[SaleLeasebackCode],[SalesTaxExemptionLevel]=S.[SalesTaxExemptionLevel],[SalesTaxRemittanceResponsibility]=S.[SalesTaxRemittanceResponsibility],[TitleTransferCode]=S.[TitleTransferCode],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Usage]=S.[Usage]
WHEN NOT MATCHED THEN
	INSERT ([AssetCatalogNumber],[AssetId],[AssetSerialOrVIN],[AssetType],[AssetUsageCondition],[ContractId],[ContractTypeName],[CreatedById],[CreatedTime],[GrossVehicleWeight],[IsElectronicallyDelivered],[IsSKU],[JobStepInstanceId],[PreviousSalesTaxRemittanceResponsibility],[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate],[SaleLeasebackCode],[SalesTaxExemptionLevel],[SalesTaxRemittanceResponsibility],[TitleTransferCode],[Usage])
    VALUES (S.[AssetCatalogNumber],S.[AssetId],S.[AssetSerialOrVIN],S.[AssetType],S.[AssetUsageCondition],S.[ContractId],S.[ContractTypeName],S.[CreatedById],S.[CreatedTime],S.[GrossVehicleWeight],S.[IsElectronicallyDelivered],S.[IsSKU],S.[JobStepInstanceId],S.[PreviousSalesTaxRemittanceResponsibility],S.[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate],S.[SaleLeasebackCode],S.[SalesTaxExemptionLevel],S.[SalesTaxRemittanceResponsibility],S.[TitleTransferCode],S.[Usage])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetMeasures]
(
 @val [dbo].[AssetMeasures] READONLY
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
MERGE [dbo].[AssetMeasures] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccumulatedAssetImpairmentAmountFinanceComponent]=S.[AccumulatedAssetImpairmentAmountFinanceComponent],[AccumulatedAssetImpairmentAmountLeaseComponent]=S.[AccumulatedAssetImpairmentAmountLeaseComponent],[AccumulatedFixedTermDepreciationAmountLeaseComponent]=S.[AccumulatedFixedTermDepreciationAmountLeaseComponent],[AccumulatedInventoryDepreciationAmountFinanceComponent]=S.[AccumulatedInventoryDepreciationAmountFinanceComponent],[AccumulatedInventoryDepreciationAmountLeaseComponent]=S.[AccumulatedInventoryDepreciationAmountLeaseComponent],[AccumulatedNBVImpairmentAmountFinanceComponent]=S.[AccumulatedNBVImpairmentAmountFinanceComponent],[AccumulatedNBVImpairmentAmountLeaseComponent]=S.[AccumulatedNBVImpairmentAmountLeaseComponent],[AccumulatedOTPDepreciationAmountFinanceComponent]=S.[AccumulatedOTPDepreciationAmountFinanceComponent],[AccumulatedOTPDepreciationAmountLeaseComponent]=S.[AccumulatedOTPDepreciationAmountLeaseComponent],[AcquisitionCostFinanceComponent]=S.[AcquisitionCostFinanceComponent],[AcquisitionCostLeaseComponent]=S.[AcquisitionCostLeaseComponent],[AssetImpairmentFinanceComponent]=S.[AssetImpairmentFinanceComponent],[AssetImpairmentLeaseComponent]=S.[AssetImpairmentLeaseComponent],[AssetValue]=S.[AssetValue],[CurrentNBVAmountFinanceComponent]=S.[CurrentNBVAmountFinanceComponent],[CurrentNBVAmountLeaseComponent]=S.[CurrentNBVAmountLeaseComponent],[DatePlacedInInventory]=S.[DatePlacedInInventory],[DatePlacedOffInventory]=S.[DatePlacedOffInventory],[NBVImpairment]=S.[NBVImpairment],[RemainingEconomicLife]=S.[RemainingEconomicLife],[ResidualImpairmentAmountFinanceComponent]=S.[ResidualImpairmentAmountFinanceComponent],[ResidualImpairmentAmountLeaseComponent]=S.[ResidualImpairmentAmountLeaseComponent],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccumulatedAssetImpairmentAmountFinanceComponent],[AccumulatedAssetImpairmentAmountLeaseComponent],[AccumulatedFixedTermDepreciationAmountLeaseComponent],[AccumulatedInventoryDepreciationAmountFinanceComponent],[AccumulatedInventoryDepreciationAmountLeaseComponent],[AccumulatedNBVImpairmentAmountFinanceComponent],[AccumulatedNBVImpairmentAmountLeaseComponent],[AccumulatedOTPDepreciationAmountFinanceComponent],[AccumulatedOTPDepreciationAmountLeaseComponent],[AcquisitionCostFinanceComponent],[AcquisitionCostLeaseComponent],[AssetImpairmentFinanceComponent],[AssetImpairmentLeaseComponent],[AssetValue],[CreatedById],[CreatedTime],[CurrentNBVAmountFinanceComponent],[CurrentNBVAmountLeaseComponent],[DatePlacedInInventory],[DatePlacedOffInventory],[Id],[NBVImpairment],[RemainingEconomicLife],[ResidualImpairmentAmountFinanceComponent],[ResidualImpairmentAmountLeaseComponent])
    VALUES (S.[AccumulatedAssetImpairmentAmountFinanceComponent],S.[AccumulatedAssetImpairmentAmountLeaseComponent],S.[AccumulatedFixedTermDepreciationAmountLeaseComponent],S.[AccumulatedInventoryDepreciationAmountFinanceComponent],S.[AccumulatedInventoryDepreciationAmountLeaseComponent],S.[AccumulatedNBVImpairmentAmountFinanceComponent],S.[AccumulatedNBVImpairmentAmountLeaseComponent],S.[AccumulatedOTPDepreciationAmountFinanceComponent],S.[AccumulatedOTPDepreciationAmountLeaseComponent],S.[AcquisitionCostFinanceComponent],S.[AcquisitionCostLeaseComponent],S.[AssetImpairmentFinanceComponent],S.[AssetImpairmentLeaseComponent],S.[AssetValue],S.[CreatedById],S.[CreatedTime],S.[CurrentNBVAmountFinanceComponent],S.[CurrentNBVAmountLeaseComponent],S.[DatePlacedInInventory],S.[DatePlacedOffInventory],S.[Id],S.[NBVImpairment],S.[RemainingEconomicLife],S.[ResidualImpairmentAmountFinanceComponent],S.[ResidualImpairmentAmountLeaseComponent])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

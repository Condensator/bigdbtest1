SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateAssetValueHistoryFromLeaseExtensionARUpdate](@AssetValueHistories ASSETVALUE READONLY,
@UpdatedById         BIGINT,
@UpdatedTime         DATETIMEOFFSET)
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO [dbo].[AssetValueHistories]
([SourceModule],
[SourceModuleId],
[IncomeDate],
[Value_Amount],
[Value_Currency],
[Cost_Amount],
[Cost_Currency],
[NetValue_Amount],
[NetValue_Currency],
[BeginBookValue_Amount],
[BeginBookValue_Currency],
[EndBookValue_Amount],
[EndBookValue_Currency],
[IsAccounted],
[IsSchedule],
[IsCleared],
[AssetId],
[CreatedById],
[CreatedTime],
[AdjustmentEntry],
[IsLessorOwned]
)
SELECT [SourceModule],
[SourceModuleId],
[IncomeDate],
[Value],
[Currency],
[Cost],
[Currency],
[NetValue],
[Currency],
[BeginBookValue],
[Currency],
[EndBookValue],
[Currency],
[IsAccounted],
[IsSchedule],
[IsCleared],
[AssetId],
@UpdatedById,
@UpdatedTime,
0,
1
FROM @AssetValueHistories;
END;

GO

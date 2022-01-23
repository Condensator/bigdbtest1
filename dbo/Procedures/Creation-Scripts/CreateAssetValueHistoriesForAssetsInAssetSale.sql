SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateAssetValueHistoriesForAssetsInAssetSale]
(
	@AssetSaleId BIGINT,
	@SourceModule NVARCHAR(50),
	@TransactionDate DATETIME,
	@PostDate DATETIME,
	@AssetIdsForAssetValueHistory NVARCHAR(MAX),
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #Assets
(
    Id BIGINT, 
    AcquisitionCost_Amount decimal(16,2),
	AcquisitionCost_Currency nvarchar(3),
	IsLeaseComponent BIT
)

INSERT INTO #Assets
SELECT AST.AssetId,AST.NetValue_Amount,AST.NetValue_Currency,A.IsLeaseComponent 
FROM AssetSalesTradeIns AST
JOIN Assets A ON AST.AssetId = A.Id
WHERE AST.AssetSaleId = @AssetSaleId
AND AST.AssetId IN (SELECT Id FROM ConvertCSVToBigIntTable(@AssetIdsForAssetValueHistory,','))

INSERT INTO AssetValueHistories
(
    [AssetId]
	,[SourceModule]
    ,[SourceModuleId]
    ,[IncomeDate]
    ,[Value_Amount]
	,[Value_Currency]
    ,[Cost_Amount]
	,[Cost_Currency]
    ,[NetValue_Amount]
	,[NetValue_Currency]
    ,[BeginBookValue_Amount]
	,[BeginBookValue_Currency]
    ,[EndBookValue_Amount]
	,[EndBookValue_Currency]
    ,[IsAccounted]
	,[IsSchedule]
	,[IsCleared]
	,[PostDate]
    ,[CreatedById]
    ,[CreatedTime]
	,[AdjustmentEntry]
	,[IsLessorOwned]
	,[IsLeaseComponent]
)
SELECT 
	Id
	,@SourceModule
	,@AssetSaleId
	,@TransactionDate
	,AcquisitionCost_Amount
	,AcquisitionCost_Currency
	,AcquisitionCost_Amount
	,AcquisitionCost_Currency
	,AcquisitionCost_Amount
	,AcquisitionCost_Currency
	,AcquisitionCost_Amount
	,AcquisitionCost_Currency
	,AcquisitionCost_Amount
	,AcquisitionCost_Currency
	,1
	,1
	,1
	,@PostDate
	,@UpdatedById
	,@UpdatedTime
	,0
	,1
	,IsLeaseComponent
FROM #Assets  

END

GO

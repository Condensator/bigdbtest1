SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateAssetValueHistoriesForAssetsInLoan]
(
	@LoanFinanceId BIGINT,
	@SourceModule NVARCHAR(50),
	@CommencementDate DATETIME,
	@PostDate DATETIME,
	@AssetIdsForAssetValueHistory NVARCHAR(MAX),
	@AssetIdsForUpdateAssetValueHistory NVARCHAR(MAX),
	@ToUpdate bit,
	@UpdatedById BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
create table #Assets
(
    Id BIGINT, 
    AcquisitionCost_Amount decimal(16,2),
	AcquisitionCost_Currency nvarchar(3),
	Cost decimal(16,2),
	EndBookValue decimal(16,2)
)

INSERT INTO #Assets
SELECT CA.AssetId,CA.AcquisitionCost_Amount,CA.AcquisitionCost_Currency,COALESCE(AH.Cost_Amount,CA.AcquisitionCost_Amount),COALESCE(AH.EndBookValue_Amount,CA.AcquisitionCost_Amount)
FROM CollateralAssets CA
LEFT JOIN (Select MAX(Id) Id,AssetId  from  AssetValueHistories WHERE IsLessorOwned = 1 Group By AssetId)TempAH
on CA.AssetId=TempAH.AssetId
Left JOIN AssetValueHistories AH on TempAH.Id=AH.Id
WHERE CA.LoanFinanceId = @LoanFinanceId
AND CA.AssetId IN (SELECT Id FROM ConvertCSVToBigIntTable(@AssetIdsForAssetValueHistory,','))

IF(@ToUpdate = 1)

BEGIN

UPDATE AssetValueHistories SET [IsAccounted] = 0 , [IsSchedule] = 0 , [IsCleared] = 0 , UpdatedById = @UpdatedById , UpdatedTime = @UpdatedTime WHERE AssetValueHistories.AssetId in (SELECT Id FROM ConvertCSVToBigIntTable(@AssetIdsForUpdateAssetValueHistory,','))

END

UPDATE AssetValueHistories SET [IsAccounted] = 0 , [IsSchedule] = 0 , [IsCleared] = 0 , UpdatedById = @UpdatedById , UpdatedTime = @UpdatedTime WHERE AssetValueHistories.AssetId in (SELECT Id FROM ConvertCSVToBigIntTable(@AssetIdsForAssetValueHistory,','))

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
	,@LoanFinanceId
	,@CommencementDate
	,AcquisitionCost_Amount
	,AcquisitionCost_Currency
	,Cost
	,AcquisitionCost_Currency
	,AcquisitionCost_Amount
	,AcquisitionCost_Currency
	,EndBookValue
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
	,0
FROM #Assets  

END


GO

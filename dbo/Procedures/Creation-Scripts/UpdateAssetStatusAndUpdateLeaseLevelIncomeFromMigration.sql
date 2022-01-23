SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateAssetStatusAndUpdateLeaseLevelIncomeFromMigration]
(
	@UserId BIGINT,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@ProcessedRecords BIGINT OUTPUT,
	@FailedRecords BIGINT OUTPUT,
	@ToolIdentifier INT
)
AS
BEGIN
SET NOCOUNT ON;  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
ALTER TABLE ReceivableDetails CHECK CONSTRAINT EReceivable_ReceivableDetails
SET @ProcessedRecords = 0;
SET @FailedRecords = 0;
 CREATE TABLE #AssetDetails  
	(  
		AssetId BIGINT NOT NULL PRIMARY  KEY,
		LeaseFinanceId BigInt,
		ContractId BigInt,
		SyndicationType NVArchar(16),
		AssetStatus NVArchar(16),
		AsOfDate Date 
	)
 CREATE TABLE #AssetIdsForAssetHistory
	(  
		AssetId BIGINT NOT NULL PRIMARY  KEY
	)    
SELECT R_LeaseFinanceId LeaseFinanceId, Id AS IntermediateLeaseId INTO #Leases
FROM stgLease
WHERE IsMigrated = 1 AND IsFailed = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL) AND R_LeaseFinanceId IS NOT NULL
 INSERT INTO #AssetDetails  
 SELECT  
   Asset.Id   
  ,LeaseAsset.LeaseFinanceId
  ,LeaseFinance.ContractId
  ,Contracts.SyndicationType
  ,''
  ,LeaseFinanceDetail.CommencementDate AsOfDate
 FROM Assets Asset  
 INNER JOIN LeaseAssets LeaseAsset ON Asset.Id = LeaseAsset.AssetId  
 INNER JOIN LeaseFinances LeaseFinance ON LeaseAsset.LeaseFinanceId = LeaseFinance.Id And LeaseAsset.IsActive = 1
 INNER JOIN #Leases LF ON LeaseFinance.Id = LF.LeaseFinanceId
 INNER JOIN LeaseFinanceDetails LeaseFinanceDetail ON LeaseFinance.Id = LeaseFinanceDetail.Id 
 INNER JOIN Contracts ON LeaseFinance.ContractId = Contracts.Id
 UPDATE #AssetDetails SET AssetStatus = (CASE WHEN SyndicationType = 'FullSale' THEN 'InvestorLeased' ELSE 'Leased' END)
 UPDATE Assets SET IsOnCommencedLease = 1, Status = #AssetDetails.AssetStatus, UpdatedTime = @CreatedTime, UpdatedById = @UserId  
 FROM Assets INNER JOIN #AssetDetails ON Assets.Id = #AssetDetails.AssetId  
INSERT INTO #AssetIdsForAssetHistory 
(AssetId)
SELECT
a.Id
FROM Assets a
INNER JOIN #AssetDetails ad ON a.Id = ad.AssetId  
LEFT JOIN AssetHistories ah ON a.Id = ah.AssetId AND Reason = 'StatusChange' AND SourceModule = 'LeaseBooking'
WHERE ah.Id IS NULL
 INSERT INTO AssetHistories  
  ([Reason]  
  ,[AsOfDate]  
  ,[AcquisitionDate]  
  ,[Status]  
  ,[FinancialType]  
  ,[SourceModule]  
  ,[SourceModuleId]  
  ,[CreatedById]  
  ,[CreatedTime]  
  ,[UpdatedById]  
  ,[UpdatedTime]  
  ,[CustomerId]  
  ,[ParentAssetId]  
  ,[LegalEntityId]  
  ,[ContractId]  
  ,[AssetId]  
  ,[IsReversed])  
 SELECT  
   'StatusChange'
  ,#AssetDetails.AsOfDate  
  ,Assets.AcquisitionDate  
  ,Assets.Status  
  ,Assets.FinancialType  
  ,'LeaseBooking'  
  ,#AssetDetails.ContractId  
  ,@UserId 
  ,@CreatedTime
  ,NULL  
  ,NULL  
  ,Assets.CustomerId  
  ,Assets.ParentAssetId  
  ,Assets.LegalEntityId  
  ,#AssetDetails.ContractId  
  ,Assets.Id  
  ,0  
 FROM Assets  
 INNER JOIN #AssetDetails ON Assets.Id = #AssetDetails.AssetId 
 INNER JOIN #AssetIdsForAssetHistory ON Assets.Id = #AssetIdsForAssetHistory.AssetId 

SELECT aa.id AS IntermediateAssetId INTO #Lease FROM #Leases a
INNER JOIN stgLease aa ON a.LeaseFinanceId = aa.R_LeaseFinanceId 

SELECT @ProcessedRecords = ISNULL(Count(*),0) from #Lease  

CREATE TABLE #CreatedProcessingLogsForLease   
(  
 [Id] bigint NOT NULL  
);  
MERGE stgProcessingLog AS ProcessingLog  
USING (SELECT IntermediateAssetId AS Id FROM #Lease)AS ProcessedRecords  
ON (1 = 0)  
WHEN NOT MATCHED THEN  
INSERT  
 (  
     stagingRootEntityId  
    ,CreatedById  
    ,CreatedTime  
    ,ModuleIterationStatusId  
 )  
VALUES  
 (  
     Id  
    ,@UserId  
    ,@CreatedTime  
    ,@ModuleIterationStatusId  
 )  
OUTPUT  Inserted.Id INTO #CreatedProcessingLogsForLease;  

INSERT INTO stgProcessingLogDetail  
(  
    Message  
   ,Type  
   ,CreatedById  
   ,CreatedTime   
   ,ProcessingLogId  
)  
SELECT  
    'Successful'  
   ,'Information'  
   ,@UserId  
   ,@CreatedTime  
   ,Id  
FROM  
 #CreatedProcessingLogsForLease

DROP TABLE #AssetDetails
DROP TABLE #AssetIdsForAssetHistory
DROP TABLE #Leases
DROP TABLE #CreatedProcessingLogsForLease
DROP TABLE #Lease
END

GO

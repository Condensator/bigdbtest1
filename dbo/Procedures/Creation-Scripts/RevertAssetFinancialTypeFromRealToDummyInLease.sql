SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[RevertAssetFinancialTypeFromRealToDummyInLease]
(
@SourceModule NVARCHAR(25),
@ContractId BIGINT,
@LeaseFinanceId BIGINT,
@RealFinancialType NVARCHAR(20),
@DummyFinancialType NVARCHAR(20),
@AssetHistoryReasonStatusChange NVARCHAR(15),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON


CREATE TABLE #AssetDetails
(
AssetId BIGINT,
)
INSERT INTO #AssetDetails
SELECT
A.Id
FROM [LeaseAssets] LA
JOIN [Assets] A ON LA.AssetId = A.Id
WHERE LA.IsActive = 0
AND A.FinancialType = @RealFinancialType
AND LA.IsCollateralOnLoan = 1
AND LA.LeaseFinanceId = @LeaseFinanceId
UPDATE A
SET
FInancialType = @DummyFinancialType,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM [Assets] A
JOIN #AssetDetails AD ON A.Id = AD.AssetId


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
,[IsReversed]
,[PropertyTaxReportCodeId])
SELECT
@AssetHistoryReasonStatusChange
,(SELECT TOP 1 AsOfDate FROM AssetHistories WHERE AssetId = AD.AssetId AND FinancialType=@RealFinancialType ORDER BY ID DESC)
,A.AcquisitionDate
,A.Status
,@DummyFinancialType
,@SourceModule
,@ContractId
,@CreatedById
,@CreatedTime
,NULL
,NULL
,A.CustomerId
,A.ParentAssetId
,A.LegalEntityId
,@ContractId
,A.Id
,0
,A.PropertyTaxReportCodeId
FROM #AssetDetails AD
JOIN Assets A on AD.AssetId = A.Id
SET NOCOUNT OFF
END

GO

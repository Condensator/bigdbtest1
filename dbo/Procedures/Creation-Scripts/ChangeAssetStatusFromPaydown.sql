SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ChangeAssetStatusFromPaydown]
(
@AssetDetails AssetTableTypeForPayDown READONLY,
@FinanceId BIGINT,
@PreviousSequenceNumber NVARCHAR(40),
@ContractId BIGINT,
@EffectiveDate DATETIMEOFFSET = NULL,
@AssetHistoryReason NVARCHAR(15),
@AssetHistoryReasonForReportCode NVARCHAR(15)=NULL,
@PaydownReason NVARCHAR(34),
@Module NVARCHAR(20),
@PaydownId BIGINT,
@CreatedById BIGINT,
@CurrentTime DATETIMEOFFSET,
@IsCollateralPaidOff BIT,
@ErrorAssetCount INT OUT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @SyndicationType NVARCHAR(32) = (SELECT SyndicationType FROM Contracts WHERE Id = @ContractId)
CREATE TABLE #ChangedAssets
(
AssetId BIGINT,
AsOfDate DATETIMEOFFSET,
AssetStatus NVARCHAR(20),
CreateNewHistory BIT,
ContractId BIGINT,
)

IF(@PaydownReason = 'CollateralRelease' OR @PaydownReason = 'Repossession' OR @PaydownReason = 'Casualty')
INSERT INTO #ChangedAssets
(AssetId
,AsOfDate
,AssetStatus
,CreateNewHistory
,ContractId)
SELECT
CA.AssetId,
@EffectiveDate,
A.Status,
0,
@ContractId
FROM CollateralAssets CA
INNER JOIN @AssetDetails AD ON AD.AssetId = CA.AssetId
INNER JOIN Assets A On CA.AssetId = A.Id
WHERE CA.LoanFinanceId = @FinanceId
AND CA.IsActive = 1
ELSE
INSERT INTO #ChangedAssets
(AssetId
,AsOfDate
,AssetStatus
,CreateNewHistory
,ContractId)
SELECT
CA.AssetId,
@EffectiveDate,
A.Status,
0,
@ContractId
FROM CollateralAssets CA
INNER JOIN Assets A On CA.AssetId = A.Id
WHERE CA.LoanFinanceId = @FinanceId
AND CA.IsActive = 1
AND A.Status = 'CollateralOnLoan'

UPDATE Assets SET
STATUS = CASE WHEN ((@IsCollateralPaidOff = 1 OR @PaydownReason = 'FullPaydown') AND @SyndicationType = 'None') THEN 'Collateral'
WHEN (@SyndicationType = 'ParticipatedSale' AND @PaydownReason = 'Repossession') THEN (SELECT AD.AssetStatus FROM @AssetDetails AD WHERE AD.AssetId = C.AssetId)
WHEN (@SyndicationType <> 'None') THEN 'Scrap'
WHEN @PaydownReason  = 'CollateralRelease' THEN (SELECT AD.AssetStatus FROM @AssetDetails AD WHERE AD.AssetId = C.AssetId)
WHEN @PaydownReason  = 'Repossession' THEN (SELECT AD.AssetStatus FROM @AssetDetails AD WHERE AD.AssetId = C.AssetId)
WHEN @PaydownReason  = 'Casualty' THEN (SELECT AD.AssetStatus FROM @AssetDetails AD WHERE AD.AssetId = C.AssetId)
ELSE NULL END
,UpdatedById = @CreatedById
,UpdatedTime = @CurrentTime
,PreviousSequenceNumber = @PreviousSequenceNumber
FROM #ChangedAssets C Inner Join dbo.Assets A on C.AssetId =A.Id and C.AssetStatus = A.Status
INSERT INTO [dbo].[AssetHistories]
([Reason]
,[AsOfDate]
,[AcquisitionDate]
,[Status]
,[FinancialType]
,[SourceModule]
,[SourceModuleId]
,[CreatedById]
,[CreatedTime]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[AssetId]
,[IsReversed]
,[PropertyTaxReportCodeId] )
SELECT @AssetHistoryReason
,C.AsOfDate
,[AcquisitionDate]
,A.Status
,[FinancialType]
,@Module
,@PaydownId
,@CreatedById
,@CurrentTime
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[AssetId]
,0
,A.PropertyTaxReportCodeId
FROM #ChangedAssets C
JOIN Assets A on C.AssetId =A.Id
WHERE C.CreateNewHistory = 0

END

GO

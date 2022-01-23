SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ChangeAssetStatusFromPaydownReversal]
(
@AssetDetails assettabletypeforpaydownreversal readonly,
@FinanceId BIGINT,
@ContractId BIGINT,
@EffectiveDate DATETIMEOFFSET = NULL,
@AssetHistoryReason NVARCHAR(15),
@AssetHistoryReasonForReportCode NVARCHAR(15),
@PaydownReason                   NVARCHAR(34),
@Module                          NVARCHAR(20),
@PaydownId                       BIGINT,
@CreatedById                     BIGINT,
@CurrentTime                     DATETIMEOFFSET,
@IsCollateralPaidOff             BIT,
@ErrorAssetCount                 INT out
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION isolation level READ uncommitted;
CREATE TABLE #changedassets
(
assetid          BIGINT,
asofdate         DATETIMEOFFSET,
assetstatus      NVARCHAR(20),
createnewhistory BIT,
contractid       BIGINT
)


IF(@PaydownReason = 'CollateralRelease' OR @PaydownReason = 'Repossession' OR @PaydownReason = 'Casualty')
INSERT INTO #changedassets
(
assetid,
asofdate,
assetstatus,
createnewhistory,
contractid
)
SELECT CA.AssetId,
@EffectiveDate,
A.assetstatus,
0,
@ContractId
FROM   collateralassets CA
INNER JOIN @AssetDetails A
ON CA.AssetId = A.assetid
WHERE  CA.LoanFinanceId = @FinanceId
--AND CA.IsActive = 1
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
AND CA.IsActive = 1;

UPDATE assets
SET    Status = 'CollateralOnLoan' ,
UpdatedById = @CreatedById,
UpdatedTime = @CurrentTime
FROM   #changedassets C
INNER JOIN dbo.assets A
ON C.assetid = A.Id
AND C.assetstatus = A.Status
UPDATE CollateralAssets
SET   IsActive=1,
UpdatedById = @CreatedById,
UpdatedTime = @CurrentTime
FROM CollateralAssets
INNER JOIN #changedassets C ON CollateralAssets.AssetId = C.AssetId
INNER JOIN @AssetDetails A
ON C.AssetId = A.assetid
INSERT INTO [dbo].[assethistories]
(
[reason],
[asofdate],
[acquisitiondate],
[status],
[financialtype],
[sourcemodule],
[sourcemoduleid],
[createdbyid],
[createdtime],
[customerid],
[parentassetid],
[legalentityid],
[assetid],
[ContractId],
[IsReversed],
[PropertyTaxReportCodeId]
)
SELECT
@AssetHistoryReason,
C.asofdate,
[acquisitiondate],
A.status,
[financialtype],
@Module,
@PaydownId,
@CreatedById,
@CurrentTime,
[customerid],
[parentassetid],
[legalentityid],
[assetid],
@ContractId,
0,
A.PropertyTaxReportCodeId
FROM   #changedassets C
JOIN assets A
ON C.assetid = A.id
WHERE  C.createnewhistory = 0

END

GO

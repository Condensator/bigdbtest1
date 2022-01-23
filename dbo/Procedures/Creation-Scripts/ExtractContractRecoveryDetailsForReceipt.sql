SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ExtractContractRecoveryDetailsForReceipt]
(
@WriteDownStatusValues_Approved						NVARCHAR(8),
@CreatedById										BIGINT,
@CreatedTime										DATETIMEOFFSET,
@JobStepInstanceId									BIGINT
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
;WITH CTE_ChargeOffContractIds AS
(
SELECT ContractId AS Id
FROM ReceiptReceivableDetails_Extract
WHERE JobStepInstanceId = @JobStepInstanceId
AND IsChargeoffReceivable = 1
GROUP BY ContractId
)
SELECT
ChargeOffs.ContractId,
SUM(ChargeOffs.ChargeOffAmount_Amount * ~ChargeOffs.IsRecovery) TotalChargeOffAmount,
SUM(ChargeOffs.ChargeOffAmount_Amount * ChargeOffs.IsRecovery) TotalRecoveryAmount,
SUM(ChargeOffs.LeaseComponentAmount_Amount * ~ChargeOffs.IsRecovery) TotalLeaseComponentChargeOffAmount,
SUM(ChargeOffs.NonLeaseComponentAmount_Amount * ~ChargeOffs.IsRecovery) TotalNonLeaseComponentChargeOffAmount,
SUM(ChargeOffs.LeaseComponentAmount_Amount * ChargeOffs.IsRecovery) TotalLeaseComponentRecoveryAmount,
SUM(ChargeOffs.NonLeaseComponentAmount_Amount * ChargeOffs.IsRecovery) TotalNonLeaseComponentRecoveryAmount,
SUM(ChargeOffs.LeaseComponentGain_Amount * ChargeOffs.IsRecovery) TotalLeaseComponentGainAmount,
SUM(ChargeOffs.NonLeaseComponentGain_Amount * ChargeOffs.IsRecovery) TotalNonLeaseComponentGainAmount,
MIN(ChargeOffs.Id) ChargeOffId
INTO #ChargeOffDetails
FROM CTE_ChargeOffContractIds C
INNER JOIN ChargeOffs ON C.Id = ChargeOffs.ContractId
WHERE ChargeOffs.Status = @WriteDownStatusValues_Approved AND ChargeOffs.IsActive = 1
GROUP BY ChargeOffs.ContractId
INSERT INTO [dbo].[ReceiptContractRecoveryDetails_Extract]
([ContractId]
,[CreatedById]
,[CreatedTime]
,[ContractType]
,[ChargeOffId]
,[TotalChargeOffAmount]
,[TotalRecoveryAmount]
,[ChargeOffReasonCodeConfigId]
,[NetInvestmentWithBlended]
,[ChargeOffGLTemplateId]
,[WriteDownId]
,[TotalWriteDownAmount]
,[TotalRecoveryAmountForWriteDown]
,[NetWriteDown]
,[WriteDownGLTemplateId]
,[RecoveryGLTemplateId]
,[RecoveryReceivableCodeId]
,[WriteDownDate]
,[WriteDownReason]
,[LeaseFinanceId]
,[LoanFinanceId]
,[JobStepInstanceId]
,[TotalLeaseComponentChargeOffAmount]
,[TotalNonLeaseComponentChargeOffAmount]
,[TotalLeaseComponentRecoveryAmount]
,[TotalNonLeaseComponentRecoveryAmount]
,[TotalLeaseComponentGainAmount]
,[TotalNonLeaseComponentGainAmount])
SELECT
ChargeOffs.ContractId,
@CreatedById,
@CreatedTime,
ChargeOffs.ContractType,
ChargeOffs.Id ChargeOffId,
ChargeOffs.ChargeOffAmount_Amount TotalChargeOffAmount,
ISNULL(#ChargeOffDetails.TotalRecoveryAmount,0.00) TotalRecoveryAmount,
ChargeOffReasonCodeConfigId,
ChargeOffs.NetInvestmentWithBlended_Amount NetInvestmentWithBlended,
ChargeOffs.GLTemplateId [ChargeOffGLTemplateId],
NULL [WriteDownId],
0 [TotalWriteDownAmount],
0 [TotalRecoveryAmountForWriteDown],
0 [NetWriteDown],
NULL [WriteDownGLTemplateId],
NULL [RecoveryGLTemplateId],
NULL [RecoveryReceivableCodeId],
NULL [WriteDownDate],
NULL [WriteDownReason],
NULL [LeaseFinanceId],
NULL [LoanFinanceId],
@JobStepInstanceId [JobStepInstanceId]
,[TotalLeaseComponentChargeOffAmount]
,[TotalNonLeaseComponentChargeOffAmount]
,[TotalLeaseComponentRecoveryAmount]
,[TotalNonLeaseComponentRecoveryAmount]
,[TotalLeaseComponentGainAmount]
,[TotalNonLeaseComponentGainAmount]
FROM #ChargeOffDetails
JOIN ChargeOffs ON ChargeOffs.Id = #ChargeOffDetails.ChargeOffId
INSERT INTO [dbo].[ReceiptContractRecoveryAssetDetails_Extract]
([CreatedById]
,[CreatedTime]
,[ContractId]
,[AssetId]
,[ChargeOffId]
,[NetWriteDownForChargeOff]
,[NetInvestmentWithBlended]
,[WriteDownId]
,[TotalWriteDownAmount]
,[JobStepInstanceId])
SELECT
@CreatedById,
@CreatedTime,
ReceiptContract.ContractId,
ChargeOffAssetDetails.AssetId,
ReceiptContract.ChargeOffId,
ChargeOffAssetDetails.NetWritedown_Amount [NetWriteDownForChargeOff],
ChargeOffAssetDetails.NetInvestmentWithBlended_Amount [NetInvestmentWithBlended],
NULL [WriteDownId],
0 [TotalWriteDownAmount],
@JobStepInstanceId
FROM ReceiptContractRecoveryDetails_Extract AS ReceiptContract
JOIN ChargeOffAssetDetails ON ReceiptContract.ChargeOffId = ChargeOffAssetDetails.ChargeOffId AND ChargeOffAssetDetails.IsActive = 1
WHERE ReceiptContract.JobStepInstanceId = @JobStepInstanceId
;WITH CTE_WrittenDownContractIds AS
(
SELECT ContractId AS Id
FROM ReceiptReceivableDetails_Extract
WHERE JobStepInstanceId = @JobStepInstanceId
AND IsWritedownReceivable = 1
GROUP BY ContractId
)
SELECT
WD.Id AS WriteDownId
,WD.IsRecovery
,WD.WriteDownDate
,WD.WriteDownAmount_Amount
,WD.RecoveryGLTemplateId
,WD.RecoveryReceivableCodeId
,WD.GLTemplateId
,WD.WriteDownReason
,WD.ContractId
,WD.ReceiptId
,C.ContractType
INTO #WriteDownInfo
FROM CTE_WrittenDownContractIds CT
INNER JOIN WriteDowns WD ON CT.Id = WD.ContractId AND WD.Status = @WriteDownStatusValues_Approved
INNER JOIN Contracts C ON WD.ContractId = C.Id
SELECT
WDI.ContractId
,SUM(WDI.WriteDownAmount_Amount * ~WDI.IsRecovery) AS TotalWriteDownAmount
,SUM(WDI.WriteDownAmount_Amount * WDI.IsRecovery) AS TotalRecoveryAmount
,MAX(WDI.WriteDownId * ~WDI.IsRecovery) AS LatestWriteDownId
INTO #WriteDownGroupedInfo
FROM #WriteDownInfo WDI
GROUP BY WDI.ContractId;
;WITH ContractNetWriteDown AS
(
SELECT
WDI.ContractId
,SUM(WDI.WriteDownAmount_Amount) AS NetWriteDown
FROM #WriteDownInfo WDI
JOIN #WriteDownGroupedInfo WDGI ON WDI.ContractId = WDGI.ContractId
WHERE WDI.WriteDownId <= WDGI.LatestWriteDownId
GROUP BY WDI.ContractId
)
INSERT INTO [dbo].[ReceiptContractRecoveryDetails_Extract]
([ContractId]
,[CreatedById]
,[CreatedTime]
,[ContractType]
,[ChargeOffId]
,[TotalChargeOffAmount]
,[TotalRecoveryAmount]
,[ChargeOffReasonCodeConfigId]
,[NetInvestmentWithBlended]
,[ChargeOffGLTemplateId]
,[WriteDownId]
,[TotalWriteDownAmount]
,[TotalRecoveryAmountForWriteDown]
,[NetWriteDown]
,[WriteDownGLTemplateId]
,[RecoveryGLTemplateId]
,[RecoveryReceivableCodeId]
,[WriteDownDate]
,[WriteDownReason]
,[LeaseFinanceId]
,[LoanFinanceId]
,[JobStepInstanceId])
SELECT
WDI.ContractId
,@CreatedById
,@CreatedTime
,WDI.ContractType
,NULL [ChargeOffId]
,0 [TotalChargeOffAmount]
,0 [TotalRecoveryAmount]
,NULL [ChargeOffReasonCodeConfigId]
,0 [NetInvestmentWithBlended]
,NULL [ChargeOffGLTemplateId]
,WDI.WriteDownId
,WDGI.TotalWriteDownAmount
,WDGI.TotalRecoveryAmount
,CNWD.NetWriteDown
,WDI.GLTemplateId
,WDI.RecoveryGLTemplateId
,WDI.RecoveryReceivableCodeId
,WDI.WriteDownDate
,WDI.WriteDownReason
,LeaseFinances.Id LeaseFinanceId
,LoanFinances.Id LoanFinanceId
,@JobStepInstanceId
FROM #WriteDownGroupedInfo WDGI
JOIN #WriteDownInfo WDI ON WDGI.LatestWriteDownId = WDI.WriteDownId
JOIN ContractNetWriteDown CNWD ON WDI.ContractId = CNWD.ContractId
LEFT JOIN LeaseFinances ON WDI.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
LEFT JOIN LoanFinances ON WDI.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
INSERT INTO [dbo].[ReceiptContractRecoveryAssetDetails_Extract]
([CreatedById]
,[CreatedTime]
,[ContractId]
,[AssetId]
,[ChargeOffId]
,[NetWriteDownForChargeOff]
,[NetInvestmentWithBlended]
,[WriteDownId]
,[TotalWriteDownAmount]
,[LeaseComponentWriteDownAmount]
,[NonLeaseComponentWriteDownAmount]
,[JobStepInstanceId])
SELECT
@CreatedById,
@CreatedTime,
ReceiptContract.ContractId,
WDAD.AssetId,
NULL ChargeOffId,
0 [NetWriteDownForChargeOff],
0 [NetInvestmentWithBlended],
ReceiptContract.WriteDownId [WriteDownId],
WDAD.WriteDownAmount_Amount [TotalWriteDownAmount],
WDAD.LeaseComponentWriteDownAmount_Amount [LeaseComponentWriteDownAmount],
WDAD.NonLeaseComponentWriteDownAmount_Amount [NonLeaseComponentWriteDownAmount],
@JobStepInstanceId
FROM ReceiptContractRecoveryDetails_Extract AS ReceiptContract
JOIN WriteDownAssetDetails WDAD ON ReceiptContract.WriteDownId = WDAD.WriteDownId
WHERE WDAD.IsActive =1
AND ReceiptContract.JobStepInstanceId = @JobStepInstanceId
DROP TABLE #WriteDownGroupedInfo
DROP TABLE #WriteDownInfo
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetSecurityDepositAllocationsForPayoff]
(
@ContractId BIGINT,
@CustomerId BIGINT,
@SecurityDepositContractType NVARCHAR(3),
@SecurityDepositCustomerType NVARCHAR(3),
@ContractEntityType NVARCHAR(11),
@UnallocatedEntityType NVARCHAR(11),
@PayoffCurrency NVARCHAR(3),
@LegalEntityId BIGINT,
@SecurityDepositAllocationIds SecurityDepositAllocationIdInfo READONLY,
@ForSecurityDepositAllocationsOnly BIT,
@ReceiptPosted NVARCHAR(20),
@ReceiptCompleted NVARCHAR(20),
@ReceiptNonCash NVARCHAR(30),
@ReceiptNonAccrualNonDSLNonCash NVARCHAR(30)
)
AS
BEGIN
SELECT * INTO #SecurityDepositAllocationIds FROM @SecurityDepositAllocationIds
CREATE TABLE #DepositAllocationInfo
(
SecurityDepositAllocationId BIGINT,
AvailableAmount DECIMAL(16,2),
SecurityDepositId BIGINT,
ContractId BIGINT,
EntityType NVARCHAR(20),
AllocationType NVARCHAR(20),
IsSecurityDepositActive BIT,
IsAllocationActive BIT
)
If @ForSecurityDepositAllocationsOnly = 1
BEGIN
INSERT INTO #DepositAllocationInfo
SELECT
SAD.Id,
CASE WHEN SAD.EntityType = @UnallocatedEntityType THEN SD.Amount_Amount ELSE SAD.Amount_Amount END,
SAD.SecurityDepositId,
SAD.ContractId,
SD.EntityType,
SAD.EntityType,
SD.IsActive,
SAD.IsActive
FROM SecurityDepositAllocations SAD
JOIN #SecurityDepositAllocationIds SDI ON SAD.Id = SDI.ID
JOIN SecurityDeposits SD ON SAD.SecurityDepositId = SD.Id
END
ELSE
BEGIN
INSERT INTO #DepositAllocationInfo
SELECT
SAD.Id,
CASE WHEN SAD.EntityType = @UnallocatedEntityType THEN SD.Amount_Amount ELSE SAD.Amount_Amount END,
SAD.SecurityDepositId,
SAD.ContractId,
SD.EntityType,
SAD.EntityType,
SD.IsActive,
SAD.IsActive
FROM
SecurityDepositAllocations SAD
JOIN SecurityDeposits SD ON SAD.SecurityDepositId = SD.Id
JOIN Receivables R ON SD.ReceivableId = R.Id
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
LEFT JOIN ReceivableTaxDetails RTD ON RD.Id = RTD.ReceivableDetailId AND RTD.IsActive =  1
WHERE RD.EffectiveBalance_Amount = 0
AND RD.IsTaxAssessed=1
AND (RTD.Id IS NULL OR RTD.EffectiveBalance_Amount=0)
AND ((SAD.EntityType = @UnallocatedEntityType AND SD.EntityType = @SecurityDepositCustomerType AND SD.CustomerId = @CustomerId) OR
(SAD.EntityType = @ContractEntityType AND SAD.ContractId = @ContractId))
AND SAD.Amount_Currency = @PayoffCurrency
AND SD.IsActive =1 AND SAD.IsActive=1 AND R.IsActive=1 AND RD.IsActive=1
END
SELECT
SecurityDepositAllocationId = SAD.SecurityDepositAllocationId,
AllocatedAmount = SUM(OSAD.Amount_Amount)
INTO #OtherAllocationsInfo
FROM #DepositAllocationInfo SAD
JOIN SecurityDepositAllocations OSAD ON SAD.SecurityDepositId = OSAD.SecurityDepositId
WHERE
SAD.AllocationType = @UnallocatedEntityType
AND OSAD.Id != SAD.SecurityDepositAllocationId
AND OSAD.IsActive = 1
GROUP BY
SAD.SecurityDepositAllocationId
SELECT
SecurityDepositAllocationId = SDA.SecurityDepositAllocationId,
AmountWaived = RARD.AmountApplied_Amount
INTO #AmountWaivedInfo
FROM #DepositAllocationInfo SDA
JOIN SecurityDeposits SD ON SDA.SecurityDepositId = SD.ID
JOIN Receivables R ON SD.ReceivableId = R.Id
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceiptApplicationReceivableDetails RARD ON RARD.ReceivableDetailId = RD.Id
JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
JOIN Receipts RC ON RA.ReceiptId = RC.Id
WHERE
(RC.ReceiptClassification = @ReceiptNonCash OR RC.ReceiptClassification = @ReceiptNonAccrualNonDSLNonCash)
AND RC.Status IN (@ReceiptPosted,@ReceiptCompleted)
AND RD.IsActive = 1
AND RARD.IsActive = 1
AND (SDA.AllocationType = @UnallocatedEntityType OR	SD.EntityType = @SecurityDepositContractType)
AND SD.IsActive = 1
SELECT
DI.SecurityDepositAllocationId,
SUM(SDP.TransferToIncome_Amount + SDP.TransferToReceipt_Amount) AS AppliedAmount
INTO #DepositApplicationInfo
FROM SecurityDepositApplications SDP
JOIN #DepositAllocationInfo DI ON SDP.SecurityDepositId=DI.SecurityDepositId
WHERE
(DI.AllocationType = @UnallocatedEntityType AND SDP.ContractId IS NULL)
OR
(DI.AllocationType = @ContractEntityType AND SDP.ContractId = @ContractId)
AND
SDP.IsActive =1
GROUP
BY DI.SecurityDepositAllocationId
SELECT
SDA.SecurityDepositId AS SecurityDepositId,
SDA.SecurityDepositAllocationId AS SecurityDepositAllocationId,
SDA.EntityType AS EntityType,
SDA.AllocationType AS AllocationType,
SDA.AvailableAmount - SUM(ISNULL(OA.AllocatedAmount,0.0)) - SUM(ISNUll(AW.AmountWaived,0.0)) - ISNULL(SUM(DP.AppliedAmount),0.0) AS AvailableAmount,
SDA.IsSecurityDepositActive,
SDA.IsAllocationActive
FROM
#DepositAllocationInfo SDA
LEFT JOIN #OtherAllocationsInfo OA ON SDA.SecurityDepositAllocationId = OA.SecurityDepositAllocationId
LEFT JOIN #AmountWaivedInfo AW ON SDA.SecurityDepositAllocationId = AW.SecurityDepositAllocationId
LEFT JOIN #DepositApplicationInfo DP ON SDA.SecurityDepositAllocationId = DP.SecurityDepositAllocationId
GROUP BY
SDA.SecurityDepositAllocationId,
SDA.EntityType,
SDA.AllocationType,
SDA.AvailableAmount,
SDA.SecurityDepositId,
SDA.IsSecurityDepositActive,
SDA.IsAllocationActive
DROP TABLE #DepositAllocationInfo,
#DepositApplicationInfo,
#SecurityDepositAllocationIds,
#AmountWaivedInfo,
#OtherAllocationsInfo
END

GO

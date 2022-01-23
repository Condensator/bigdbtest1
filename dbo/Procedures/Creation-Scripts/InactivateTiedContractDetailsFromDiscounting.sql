SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InactivateTiedContractDetailsFromDiscounting]
(
@DiscountingFinanceId BIGINT,
@IsFromPaydown BIT,
@DiscountingContractId DiscountingContractIdsForTiedContractDetailsInactivation READONLY,
@UserId BIGINT,
@ModificationTime DATETIMEOFFSET
)
AS
BEGIN
IF(@IsFromPaydown = 1)
BEGIN
SELECT DiscountingContractId = DiscountingContractId INTO #SelectedDiscountingContracts FROM @DiscountingContractId
UPDATE [RAPD]
SET IsActive = 0,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM ReceiptApplicationPayableDetails [RAPD]
JOIN TiedContractPaymentDetails [TPD] ON [RAPD].TiedContractPaymentDetailId = [TPD].Id AND [TPD].IsActive = 1
JOIN DiscountingRepaymentSchedules [DRP] ON [TPD].DiscountingRepaymentScheduleId = [DRP].Id AND [DRP].IsActive = 1
JOIN DiscountingContracts DC ON DC.DiscountingFinanceId = DRP.DiscountingFinanceId AND DC.IsActive = 1
JOIN #SelectedDiscountingContracts DCT ON DC.Id = DCT.DiscountingContractId
WHERE [DRP].DiscountingFinanceId = @DiscountingFinanceId
AND [RAPD].IsActive = 1
UPDATE [RAPD]
SET IsActive = 0,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM ReceiptApplicationPayableDetails [RAPD]
JOIN DiscountingContracts [DC] ON [RAPD].DiscountingContractId = [DC].Id AND [DC].IsActive = 1
JOIN #SelectedDiscountingContracts DCT ON DC.Id = DCT.DiscountingContractId
WHERE [DC].DiscountingFinanceId = @DiscountingFinanceId
AND [RAPD].IsActive = 1
DROP TABLE #SelectedDiscountingContracts
END
ELSE
BEGIN
UPDATE [RAPD]
SET IsActive = 0,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM ReceiptApplicationPayableDetails [RAPD]
JOIN TiedContractPaymentDetails [TPD] ON [RAPD].TiedContractPaymentDetailId = [TPD].Id AND [TPD].IsActive = 1
JOIN DiscountingRepaymentSchedules [DRP] ON [TPD].DiscountingRepaymentScheduleId = [DRP].Id AND [DRP].IsActive = 1
WHERE [DRP].DiscountingFinanceId = @DiscountingFinanceId
AND [RAPD].IsActive = 1
UPDATE [RAPD]
SET IsActive = 0,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM ReceiptApplicationPayableDetails [RAPD]
JOIN DiscountingContracts [DC] ON [RAPD].DiscountingContractId = [DC].Id AND [DC].IsActive = 1
WHERE [DC].DiscountingFinanceId = @DiscountingFinanceId
AND [RAPD].IsActive = 1
END
IF(@IsFromPaydown = 0)
BEGIN
UPDATE [TPD]
SET IsActive = 0,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM TiedContractPaymentDetails [TPD]
JOIN DiscountingRepaymentSchedules [DRP] ON [TPD].DiscountingRepaymentScheduleId = [DRP].Id AND [DRP].IsActive = 1
WHERE [DRP].DiscountingFinanceId = @DiscountingFinanceId
AND [TPD].IsActive = 1
END
END

GO

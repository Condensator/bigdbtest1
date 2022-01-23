SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateDiscountingContractReceivables]
(
@ServicingDetailsForReceivableUpdation ServicingDetailsForReceivableUpdation READONLY,
@DiscountingFinanceId BIGINT,
@DiscountingContractId DiscountingContractIdsForReceivableUpdation READONLY,
@UserId BIGINT,
@ModificationTime DateTimeOffset,
@IsFromPaydown BIT
)
AS
BEGIN
IF(@IsFromPaydown = 1)
BEGIN
SELECT DiscountingContractId = DiscountingContractId INTO #SelectedDiscountingContracts FROM @DiscountingContractId
UPDATE Receivables
SET IsCollected = TiedReceivables.IsCollected,
RemitToId = TiedReceivables.ContractRemitToId,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM Receivables
JOIN (SELECT R.Id,C.RemitToId ContractRemitToId,ServicingDetailsForReceivableUpdation.* FROM Receivables R
JOIN TiedContractPaymentDetails PD ON R.PaymentScheduleId = PD.PaymentScheduleId AND R.EntityId = PD.ContractId AND PD.IsActive=1
JOIN DiscountingRepaymentSchedules DRP ON PD.DiscountingRepaymentScheduleId = DRP.Id AND DRP.IsActive=1
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId AND RD.IsActive=1
JOIN Contracts C ON R.EntityId = C.Id
JOIN DiscountingContracts DC ON DC.ContractId = c.Id AND DC.IsActive = 1
JOIN #SelectedDiscountingContracts DCT ON DC.Id = DCT.DiscountingContractId
JOIN @ServicingDetailsForReceivableUpdation ServicingDetailsForReceivableUpdation ON ServicingDetailsForReceivableUpdation.DiscountingFinanceId=DRP.DiscountingFinanceId 
WHERE DRP.DiscountingFinanceId = @DiscountingFinanceId
AND DRP.DueDate >= ServicingDetailsForReceivableUpdation.FromDate AND DRP.DueDate <= ServicingDetailsForReceivableUpdation.ToDate
AND R.EntityType = 'CT'
--AND RD.BilledStatus <> 'Invoiced'
AND R.IsActive=1) AS TiedReceivables ON Receivables.Id = TiedReceivables.Id
DROP TABLE #SelectedDiscountingContracts
END
ELSE
BEGIN
UPDATE Receivables
SET IsCollected = TiedReceivables.IsCollected,
RemitToId = CASE WHEN TiedReceivables.IsCollected = 0 THEN TiedReceivables.RemitToId ELSE TiedReceivables.ContractRemitToId END,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM Receivables
JOIN (SELECT R.Id,C.RemitToId ContractRemitToId,ServicingDetailsForReceivableUpdation.* FROM Receivables R
JOIN TiedContractPaymentDetails PD ON R.PaymentScheduleId = PD.PaymentScheduleId AND R.EntityId = PD.ContractId AND PD.IsActive=1
JOIN DiscountingRepaymentSchedules DRP ON PD.DiscountingRepaymentScheduleId = DRP.Id AND DRP.IsActive=1
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId AND RD.IsActive=1
JOIN Contracts C ON R.EntityId = C.Id
JOIN @ServicingDetailsForReceivableUpdation ServicingDetailsForReceivableUpdation ON ServicingDetailsForReceivableUpdation.DiscountingFinanceId=DRP.DiscountingFinanceId
WHERE DRP.DiscountingFinanceId = @DiscountingFinanceId
AND DRP.DueDate >= ServicingDetailsForReceivableUpdation.FromDate AND DRP.DueDate <= ServicingDetailsForReceivableUpdation.ToDate
AND R.EntityType = 'CT'
AND RD.BilledStatus <> 'Invoiced'
AND R.IsActive=1) AS TiedReceivables ON Receivables.Id = TiedReceivables.Id
END
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE[dbo].[UpdateDiscountingGLTransferContractDetails]
(
@DiscountingGLTransferContractDetails DiscountingGLTransferContractDetails READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE [DS] SET [DS].[PaymentScheduleId] = [DRS_NEW].[Id],[DS].[UpdatedById]=@UpdatedById, [DS].[UpdatedTime]= @UpdatedTime
FROM [dbo].[DiscountingSundries] [DS]
JOIN @DiscountingGLTransferContractDetails [GLT] ON [GLT].DiscountingId = [DS].DiscountingId
JOIN [dbo].[Sundries] [S] on [DS].Id  = [S].Id AND [S].IsActive=1
JOIN [dbo].DiscountingFinances [DF] ON [GLT].DiscountingId = [DF].DiscountingId AND [DF].IsCurrent=1
JOIN [dbo].[DiscountingRepaymentSchedules] [DRS_OLD] ON [DS].[PaymentScheduleId] = [DRS_OLD].[Id]
JOIN [dbo].[DiscountingRepaymentSchedules] [DRS_NEW] ON [DRS_OLD].[StartDate] = [DRS_NEW].[StartDate] AND [DRS_OLD].[EndDate] = [DRS_NEW].[EndDate] AND [DRS_OLD].[PaymentType] = [DRS_NEW].[PaymentType]
WHERE
[DRS_OLD].[IsActive] = 1
AND [DRS_NEW].[IsActive] = 1
AND [DRS_OLD].[DiscountingFinanceId] = [GLT].DiscountingFinanceId
AND [DRS_NEW].[DiscountingFinanceId] = [DF].Id
UPDATE [TCPD] SET [TCPD].DiscountingRepaymentScheduleId = [DRP_NEW].[Id],[TCPD].[UpdatedById]=@UpdatedById, [TCPD].[UpdatedTime]= @UpdatedTime
FROM [dbo].[TiedContractPaymentDetails] [TCPD]
JOIN DiscountingRepaymentSchedules [DRP_OLD] ON [TCPD].DiscountingRepaymentScheduleId = [DRP_OLD].Id AND [TCPD].[IsActive] = 1
JOIN DiscountingFinances [DF] ON [DRP_OLD].DiscountingFinanceId = [DF].[Id] AND DF.IsCurrent=1 AND [DF].ApprovalStatus = 'Approved'
JOIN @DiscountingGLTransferContractDetails [GLT] ON [GLT].DiscountingId = [DF].DiscountingId
JOIN [dbo].[DiscountingRepaymentSchedules] [DRP_NEW] ON [DRP_OLD].[StartDate] = [DRP_NEW].[StartDate] AND [DRP_OLD].[EndDate] = [DRP_NEW].[EndDate] AND [DRP_OLD].[PaymentType] = [DRP_NEW].[PaymentType]
WHERE
[DRP_OLD].[IsActive] = 1
AND [DRP_NEW].[IsActive] = 1
AND [DRP_OLD].[DiscountingFinanceId] = [GLT].DiscountingFinanceId
AND [DRP_NEW].[DiscountingFinanceId] = [DF].Id
UPDATE RAPD
SET RAPD.TiedContractPaymentDetailId = TPD_NEW.Id  
FROM [dbo].[DiscountingRepaymentSchedules] [DRP_OLD] 
	JOIN [dbo].[DiscountingRepaymentSchedules] [DRP_NEW] ON [DRP_OLD].[PaymentNumber] = [DRP_NEW].[PaymentNumber] AND [DRP_OLD].[PaymentType] = [DRP_NEW].[PaymentType] 
	JOIN DiscountingFinances [DF] ON [DRP_NEW].DiscountingFinanceId = [DF].[Id] AND DF.IsCurrent=1 AND [DF].ApprovalStatus = 'Approved' 
	JOIN @DiscountingGLTransferContractDetails [GLT] ON [GLT].DiscountingFinanceId = DRP_OLD.DiscountingFinanceId
    JOIN [dbo].[TiedContractPaymentDetails] [TPD_OLD] ON [DRP_OLD].[Id] = [TPD_OLD].[DiscountingRepaymentScheduleId] AND [TPD_OLD].IsActive = 1
	JOIN [dbo].[TiedContractPaymentDetails] [TPD_NEW] ON [TPD_OLD].[PaymentScheduleId] = [TPD_NEW].[PaymentScheduleId] AND [DRP_NEW].[Id] = [TPD_NEW].[DiscountingRepaymentScheduleId] AND [TPD_NEW].IsActive = 1
    JOIN [dbo].[ReceiptApplicationPayableDetails] [RAPD] ON [RAPD].[TiedContractPaymentDetailId] = [TPD_OLD].[Id] AND [RAPD].IsActive = 1
		WHERE 
		[DRP_OLD].[DiscountingFinanceId] =[GLT].DiscountingFinanceId 
		AND [DRP_NEW].[DiscountingFinanceId] =df.Id
		AND [DRP_OLD].[IsActive] = 1 
		AND [DRP_NEW].[IsActive] = 1 
IF EXISTS(SELECT DiscountingId FROM @DiscountingGLTransferContractDetails WHERE LineOfBusinessId IS NOT NULL)
BEGIN
UPDATE DiscountingFinances SET LineofBusinessId = GLTransferInfo.LineOfBusinessId, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM DiscountingFinances
JOIN @DiscountingGLTransferContractDetails GLTransferInfo ON DiscountingFinances.DiscountingId = GLTransferInfo.DiscountingId AND GLTransferInfo.LineOfBusinessId IS NOT NULL
AND DiscountingFinances.IsCurrent=1
END
IF EXISTS(SELECT DiscountingId FROM @DiscountingGLTransferContractDetails WHERE CostCenterId IS NOT NULL)
BEGIN
UPDATE DiscountingFinances SET CostCenterId = GLTransferInfo.CostCenterId, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM DiscountingFinances
JOIN @DiscountingGLTransferContractDetails GLTransferInfo ON DiscountingFinances.DiscountingId = GLTransferInfo.DiscountingId AND GLTransferInfo.CostCenterId IS NOT NULL
AND DiscountingFinances.IsCurrent=1
END
IF EXISTS(SELECT DiscountingId FROM @DiscountingGLTransferContractDetails WHERE RemitToId IS NOT NULL)
BEGIN
UPDATE DiscountingFinances SET DiscountingProceedsRemitToId = GLTransferInfo.RemitToId, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM DiscountingFinances
JOIN @DiscountingGLTransferContractDetails GLTransferInfo ON DiscountingFinances.DiscountingId = GLTransferInfo.DiscountingId AND GLTransferInfo.RemitToId IS NOT NULL
AND DiscountingFinances.IsCurrent=1
END
UPDATE Receivables
SET LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE Receivables.LegalEntityId END
,RemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE Receivables.RemitToId END
,TaxRemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE Receivables.TaxRemitToId END
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM Receivables
JOIN @DiscountingGLTransferContractDetails GLTransferInfo ON Receivables.EntityId = GLTransferInfo.DiscountingId AND Receivables.EntityType = 'DT'
WHERE Receivables.IsActive=1
UPDATE Payables
SET Payables.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE Payables.LegalEntityId END
,Payables.RemitToId = CASE WHEN  GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE Payables.RemitToId END
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM
Payables
JOIN @DiscountingGLTransferContractDetails GLTransferInfo ON Payables.EntityType = 'DT' AND Payables.EntityId = GLTransferInfo.DiscountingId
UPDATE Sundries
SET LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE Sundries.LegalEntityId END
--,PayableRemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL AND PayableRemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE PayableRemitToId END
,ReceivableRemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL AND ReceivableRemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE Sundries.ReceivableRemitToId END
,InstrumentTypeId = GLTransferInfo.InstrumentTypeId
,LineofBusinessId = GLTransferInfo.LineOfBusinessId
,CostCenterId = GLTransferInfo.CostCenterId
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
,BranchId = CASE WHEN GLTransferInfo.BranchId IS NOT NULL THEN GLTransferInfo.BranchId ELSE Sundries.BranchId END
FROM Sundries
JOIN DiscountingSundries ON Sundries.Id = DiscountingSundries.Id
JOIN @DiscountingGLTransferContractDetails GLTransferInfo ON DiscountingSundries.DiscountingId = GLTransferInfo.DiscountingId AND Sundries.EntityType = 'DT'
WHERE IsActive = 1
UPDATE DR
SET DR.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE DR.LegalEntityId END
, DR.UpdatedById = @UpdatedById
, DR.UpdatedTime = @UpdatedTime
FROM DisbursementRequests DR
JOIN DisbursementRequestPayables DRP ON DR.Id = DRP.DisbursementRequestId
JOIN Payables P ON DRP.PayableId = P.Id
JOIN @DiscountingGLTransferContractDetails GLTransferInfo ON P.EntityType = 'DT' AND P.EntityId = GLTransferInfo.DiscountingId
WHERE
DRP.IsActive = 1
UPDATE TP
SET TP.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE TP.LegalEntityId END
--, TP.RemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE TP.RemitToId END
, TP.UpdatedById = @UpdatedById
, TP.UpdatedTime = @UpdatedTime
FROM TreasuryPayables TP
JOIN TreasuryPayableDetails TPD ON TP.Id = TPD.TreasuryPayableId
JOIN Payables P ON TPD.PayableId = P.Id
JOIN @DiscountingGLTransferContractDetails GLTransferInfo ON P.EntityType = 'DT' AND P.EntityId = GLTransferInfo.DiscountingId
WHERE TPD.IsActive = 1
UPDATE PV
SET PV.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE PV.LegalEntityId END
, UpdatedById = @UpdatedById
, UpdatedTime = @UpdatedTime
FROM PaymentVouchers PV
JOIN PaymentVoucherDetails PVD ON PV.Id = PVD.PaymentVoucherId
JOIN TreasuryPayables TP ON PVD.TreasuryPayableId = TP.Id
JOIN TreasuryPayableDetails TPD ON TP.Id = TPD.TreasuryPayableId
JOIN Payables P ON TPD.PayableId = P.Id
LEFT JOIN @DiscountingGLTransferContractDetails GLTransferInfo ON P.EntityType = 'DT' AND EntityId = GLTransferInfo.DiscountingId
WHERE TPD.IsActive = 1
SET NOCOUNT OFF;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE[dbo].[UpdateGLTransferContractDetails]
(
@GLTransferContractDetails GLTransferContractDetails READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
IF EXISTS(SELECT ContractId FROM @GLTransferContractDetails WHERE ContractType = 'Lease')
BEGIN

UPDATE LIS SET LIS.LeaseFinanceId = GLT.NewFinanceId , LIS.UpdatedById = @UpdatedById, LIS.UpdatedTime = @UpdatedTime  
FROM LeaseIncomeSchedules LIS  
INNER JOIN LeaseFinances LF ON LF.Id = LIS.LeaseFinanceId  
INNER JOIN @GLTransferContractDetails GLT ON LF.ContractId = GLT.ContractId
WHERE LIS.IncomeDate > GLT.IncomeDate

UPDATE LFRI SET LFRI.LeaseFinanceId = GLT.NewFinanceId, LFRI.UpdatedById = @UpdatedById, LFRI.UpdatedTime = @UpdatedTime  
FROM LeaseFloatRateIncomes LFRI  
INNER JOIN LeaseFinances LF ON LFRI.LeaseFinanceId = LF.Id  
INNER JOIN @GLTransferContractDetails GLT ON LF.ContractId = GLT.ContractId
WHERE LFRI.IncomeDate > GLT.IncomeDate  

UPDATE BIS SET BIS.LeaseFinanceId = GLT.NewFinanceId, BIS.UpdatedById = @UpdatedById, BIS.UpdatedTime = @UpdatedTime  
FROM BlendedIncomeSchedules BIS   
INNER JOIN LeaseFinances LF ON BIS.LeaseFinanceId = LF.Id  
INNER JOIN @GLTransferContractDetails GLT ON LF.ContractId = GLT.ContractId
WHERE BIS.IncomeDate > GLT.IncomeDate

UPDATE [R] SET [R].[PaymentScheduleId] = [LP_NEW].[Id],[R].[UpdatedById]=@UpdatedById, [R].[UpdatedTime]= @UpdatedTime
FROM [dbo].[Receivables] [R]
JOIN @GLTransferContractDetails [GLT] ON [GLT].ContractId = [R].EntityId AND [R].[EntityType] = 'CT' AND [GLT].ContractType = 'Lease' AND [R].[IsActive] = 1
JOIN [dbo].LeaseFinances [LF] ON [GLT].ContractId = [LF].ContractId AND [LF].IsCurrent=1
JOIN [dbo].[ReceivableCodes] [RC] ON [R].[ReceivableCodeId] = [RC].[Id]
JOIN [dbo].[ReceivableTypes] [RT] ON [RC].[ReceivableTypeId] = [RT].[Id]
JOIN [dbo].[LeasePaymentSchedules] [LP_OLD] ON [R].[PaymentScheduleId] = [LP_OLD].[Id]
JOIN [dbo].[LeasePaymentSchedules] [LP_NEW] ON [LP_OLD].[StartDate] = [LP_NEW].[StartDate] AND [LP_OLD].[EndDate] = [LP_NEW].[EndDate] AND [LP_OLD].[PaymentType] = [LP_NEW].[PaymentType]
WHERE
[LP_OLD].[IsActive] = 1
AND [LP_NEW].[IsActive] = 1
AND [LP_OLD].[LeaseFinanceDetailId] = [GLT].LeaseFinanceId
AND [LP_NEW].[LeaseFinanceDetailId] = [LF].Id
UPDATE [TCPD] SET [TCPD].[PaymentScheduleId] = [LP_NEW].[Id],[TCPD].[UpdatedById]=@UpdatedById, [TCPD].[UpdatedTime]= @UpdatedTime
FROM [dbo].[TiedContractPaymentDetails] [TCPD]
JOIN @GLTransferContractDetails [GLT] ON [GLT].ContractId = [TCPD].ContractId AND [GLT].ContractType = 'Lease' AND [TCPD].[IsActive] = 1
JOIN DiscountingRepaymentSchedules [DRP] ON [TCPD].DiscountingRepaymentScheduleId = [DRP].Id
JOIN DiscountingFinances [DF] ON [DRP].DiscountingFinanceId = [DF].Id AND [DF].IsCurrent=1 AND [DF].ApprovalStatus = 'Approved'
JOIN [dbo].LeaseFinances [LF] ON [GLT].ContractId = [LF].ContractId AND [LF].IsCurrent=1
JOIN [dbo].[LeasePaymentSchedules] [LP_OLD] ON [TCPD].[PaymentScheduleId] = [LP_OLD].[Id]
JOIN [dbo].[LeasePaymentSchedules] [LP_NEW] ON [LP_OLD].[StartDate] = [LP_NEW].[StartDate] AND [LP_OLD].[EndDate] = [LP_NEW].[EndDate] AND [LP_OLD].[PaymentType] = [LP_NEW].[PaymentType]
WHERE
[LP_OLD].[IsActive] = 1
AND [LP_NEW].[IsActive] = 1
AND [LP_OLD].[LeaseFinanceDetailId] = [GLT].LeaseFinanceId
AND [LP_NEW].[LeaseFinanceDetailId] = [LF].Id
END
IF EXISTS(SELECT ContractId FROM @GLTransferContractDetails WHERE ContractType = 'Loan' OR ContractType = 'ProgressLoan')
BEGIN

UPDATE LIS SET LIS.LoanFinanceId = GLT.NewFinanceId , LIS.UpdatedById = @UpdatedById, LIS.UpdatedTime = @UpdatedTime  
FROM LoanIncomeSchedules LIS  
INNER JOIN LoanFinances LF ON LIS.LoanFinanceId = LF.Id  
INNER JOIN @GLTransferContractDetails GLT ON LF.ContractId = GLT.ContractId
WHERE LIS.IncomeDate > GLT.IncomeDate

UPDATE BIS SET BIS.LoanFinanceId = GLT.NewFinanceId , BIS.UpdatedById = @UpdatedById, BIS.UpdatedTime = @UpdatedTime  
FROM BlendedIncomeSchedules BIS  
JOIN LoanFinances LF ON BIS.LoanFinanceId = LF.Id  
JOIN @GLTransferContractDetails GLT ON LF.ContractId = GLT.ContractId
WHERE BIS.IncomeDate > GLT.IncomeDate 

UPDATE [R] SET [R].[PaymentScheduleId] = [LP_NEW].[Id], [R].[UpdatedById]=@UpdatedById, [R].[UpdatedTime]= @UpdatedTime
FROM [dbo].[Receivables] [R]
JOIN @GLTransferContractDetails [GLT] ON [GLT].ContractId = [R].EntityId AND [R].[EntityType] = 'CT' AND (ContractType = 'Loan' OR ContractType = 'ProgressLoan') AND [R].[IsActive] = 1
JOIN [dbo].LoanFinances [LF] ON [GLT].ContractId = [LF].ContractId AND [LF].IsCurrent=1
JOIN [dbo].[ReceivableCodes] [RC] ON [R].[ReceivableCodeId] = [RC].[Id]
JOIN [dbo].[ReceivableTypes] [RT] ON [RC].[ReceivableTypeId] = [RT].[Id]
JOIN [dbo].[LoanPaymentSchedules] [LP_OLD] ON [R].[PaymentScheduleId] = [LP_OLD].[Id]
JOIN [dbo].[LoanPaymentSchedules] [LP_NEW] ON (([LP_OLD].[StartDate] = [LP_NEW].[StartDate] AND [LP_OLD].[EndDate] = [LP_NEW].[EndDate]) OR
([LP_OLD].[PaymentType] = 'DownPayment' AND [LP_NEW].[PaymentType] = 'DownPayment')) AND [LP_OLD].[PaymentType] = [LP_NEW].[PaymentType]
WHERE
[LP_OLD].[IsActive] = 1
AND [LP_NEW].[IsActive] = 1
AND [LP_OLD].[LoanFinanceId] = [GLT].LoanFinanceId
AND [LP_NEW].[LoanFinanceId] = [LF].Id
UPDATE [TCPD] SET [TCPD].[PaymentScheduleId] = [LP_NEW].[Id],[TCPD].[UpdatedById]=@UpdatedById, [TCPD].[UpdatedTime]= @UpdatedTime
FROM [dbo].[TiedContractPaymentDetails] [TCPD]
JOIN @GLTransferContractDetails [GLT] ON [GLT].ContractId = [TCPD].ContractId AND (ContractType = 'Loan' OR ContractType = 'ProgressLoan') AND [TCPD].[IsActive] = 1
JOIN DiscountingRepaymentSchedules [DRP] ON [TCPD].DiscountingRepaymentScheduleId = [DRP].Id
JOIN DiscountingFinances [DF] ON [DRP].DiscountingFinanceId = [DF].Id AND [DF].IsCurrent=1 AND [DF].ApprovalStatus = 'Approved'
JOIN [dbo].LoanFinances [LF] ON [GLT].ContractId = [LF].ContractId AND [LF].IsCurrent=1
JOIN [dbo].[LoanPaymentSchedules] [LP_OLD] ON [TCPD].[PaymentScheduleId] = [LP_OLD].[Id]
JOIN [dbo].[LoanPaymentSchedules] [LP_NEW] ON (([LP_OLD].[StartDate] = [LP_NEW].[StartDate] AND [LP_OLD].[EndDate] = [LP_NEW].[EndDate]) OR
([LP_OLD].[PaymentType] = 'DownPayment' AND [LP_NEW].[PaymentType] = 'DownPayment')) AND [LP_OLD].[PaymentType] = [LP_NEW].[PaymentType]
WHERE
[LP_OLD].[IsActive] = 1
AND [LP_NEW].[IsActive] = 1
AND [LP_OLD].[LoanFinanceId] = [GLT].LoanFinanceId
AND [LP_NEW].[LoanFinanceId] = [LF].Id
END
IF EXISTS(SELECT ContractId FROM @GLTransferContractDetails WHERE LineOfBusinessId IS NOT NULL)
BEGIN
UPDATE Contracts SET LineofBusinessId = GLTransferInfo.LineOfBusinessId, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM Contracts
JOIN @GLTransferContractDetails GLTransferInfo ON Contracts.Id = GLTransferInfo.ContractId AND GLTransferInfo.LineOfBusinessId IS NOT NULL
END
IF EXISTS(SELECT ContractId FROM @GLTransferContractDetails WHERE CostCenterId IS NOT NULL)
BEGIN
UPDATE Contracts SET CostCenterId = GLTransferInfo.CostCenterId, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM Contracts
JOIN @GLTransferContractDetails GLTransferInfo ON Contracts.Id = GLTransferInfo.ContractId AND GLTransferInfo.CostCenterId IS NOT NULL
END
IF EXISTS(SELECT ContractId FROM @GLTransferContractDetails WHERE RemitToId IS NOT NULL)
BEGIN
UPDATE Contracts SET RemitToId = GLTransferInfo.RemitToId, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM Contracts
JOIN @GLTransferContractDetails GLTransferInfo ON Contracts.Id = GLTransferInfo.ContractId AND GLTransferInfo.RemitToId IS NOT NULL
END
IF EXISTS(SELECT ContractId FROM @GLTransferContractDetails WHERE LeaseFinanceId IS NOT NULL)
BEGIN
UPDATE pi SET pi.LegalEntityId = GLTransferInfo.LegalEntityId,pi.[UpdatedById]=@UpdatedById, pi.[UpdatedTime]= @UpdatedTime
FROM PayableInvoices pi
JOIN LeaseFundings lf2 ON lf2.FundingId = pi.Id AND lf2.IsActive = 1
JOIN LeaseFinances lf ON lf.Id = lf2.LeaseFinanceId
JOIN @GLTransferContractDetails GLTransferInfo ON lf.Id = GLTransferInfo.LeaseFinanceId
WHERE
GLTransferInfo.ContractType = 'Lease' AND IsLegalEntityChanged = 1
UPDATE A
SET A.LegalEntityId = GLTransferInfo.LegalEntityId
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM Assets A
INNER JOIN LeaseAssets la ON la.AssetId = A.Id AND la.IsActive = 1
INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId
INNER JOIN @GLTransferContractDetails GLTransferInfo ON lf.Id = GLTransferInfo.LeaseFinanceId
WHERE
GLTransferInfo.ContractType = 'Lease' AND IsLegalEntityChanged = 1
UPDATE LA
SET IsActive = 0
, UpdatedById = @UpdatedById
, UpdatedTime = @UpdatedTime
FROM LeaseAssets LA
INNER JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
INNER JOIN @GLTransferContractDetails GLTransferInfo ON LF.Id = GLTransferInfo.LeaseFinanceId
WHERE
GLTransferInfo.ContractType = 'Lease'
UPDATE LIR
SET IsActive = 0
, UpdatedById = @UpdatedById
, UpdatedTime = @UpdatedTime
FROM LeaseInsuranceRequirements LIR
INNER JOIN LeaseFinances LF ON LIR.LeaseFinanceId = LF.Id
INNER JOIN @GLTransferContractDetails GLTransferInfo ON LF.Id = GLTransferInfo.LeaseFinanceId
WHERE
GLTransferInfo.ContractType = 'Lease'
UPDATE LF
SET IsActive = 0
, UpdatedById = @UpdatedById
, UpdatedTime = @UpdatedTime
FROM LeaseFundings LF
INNER JOIN LeaseFinances finance ON LF.LeaseFinanceId = finance.Id
INNER JOIN @GLTransferContractDetails GLTransferInfo ON finance.Id = GLTransferInfo.LeaseFinanceId
WHERE
GLTransferInfo.ContractType = 'Lease'
END
IF EXISTS(SELECT ContractId FROM @GLTransferContractDetails WHERE LoanFinanceId IS NOT NULL)
BEGIN
UPDATE a SET a.LegalEntityId = GLTransferInfo.LegalEntityId, a.UpdatedById = @UpdatedById, a.UpdatedTime= @UpdatedTime
FROM Assets a
JOIN CollateralAssets ca ON ca.AssetId = a.Id AND ca.IsActive = 1
JOIN LoanFinances lf ON lf.Id = ca.LoanFinanceId
JOIN @GLTransferContractDetails GLTransferInfo ON lf.Id = GLTransferInfo.LoanFinanceId
WHERE
(ContractType = 'Loan' OR ContractType = 'ProgressLoan') AND GLTransferInfo.IsLegalEntityChanged=1
UPDATE pi SET pi.LegalEntityId = GLTransferInfo.LegalEntityId, pi.UpdatedById = @UpdatedById, pi.UpdatedTime= @UpdatedTime
FROM PayableInvoices pi
JOIN LoanFundings lf2 ON lf2.FundingId = pi.Id AND lf2.IsActive = 1
JOIN LoanFinances lf ON lf.Id = lf2.LoanFinanceId
JOIN @GLTransferContractDetails GLTransferInfo ON lf.Id = GLTransferInfo.LoanFinanceId
WHERE
(GLTransferInfo.ContractType = 'Loan' OR GLTransferInfo.ContractType = 'ProgressLoan') AND GLTransferInfo.IsLegalEntityChanged=1
UPDATE LF
SET IsActive = 0
, UpdatedById = @UpdatedById
, UpdatedTime = @UpdatedTime
FROM LoanFundings LF
INNER JOIN LoanFinances finance ON LF.LoanFinanceId = finance.Id
INNER JOIN @GLTransferContractDetails GLTransferInfo ON finance.Id = GLTransferInfo.LoanFinanceId
WHERE
(GLTransferInfo.ContractType = 'Loan' OR GLTransferInfo.ContractType = 'ProgressLoan')
UPDATE LIR
SET IsActive = 0
, UpdatedById = @UpdatedById
, UpdatedTime = @UpdatedTime
FROM LoanInsuranceRequirements LIR
INNER JOIN LoanFinances LF ON LIR.LoanFinanceId = LF.Id
INNER JOIN @GLTransferContractDetails GLTransferInfo ON LF.Id = GLTransferInfo.LoanFinanceId
WHERE
(GLTransferInfo.ContractType = 'Loan' OR GLTransferInfo.ContractType = 'ProgressLoan')
END
UPDATE Receivables
SET LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE Receivables.LegalEntityId END
,RemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE Receivables.RemitToId END
,TaxRemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE Receivables.TaxRemitToId END
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM Receivables
JOIN @GLTransferContractDetails GLTransferInfo ON Receivables.EntityId = GLTransferInfo.ContractId AND Receivables.EntityType = 'CT'
WHERE Receivables.IsActive=1
UPDATE Payables
SET Payables.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE Payables.LegalEntityId END
		--,RemitToId = CASE WHEN (RemitToId IS NOT NULL AND GLTransferInfo.RemitToId IS NOT NULL) THEN GLTransferInfo.RemitToId ELSE RemitToId END
		,UpdatedById = @UpdatedById
		,UpdatedTime = @UpdatedTime
FROM 
	Payables 
	JOIN @GLTransferContractDetails GLTransferInfo ON ((Payables.EntityType = 'CT' AND Payables.EntityId = GLTransferInfo.ContractId)) 

UPDATE Payables
SET Payables.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE Payables.LegalEntityId END
		--,RemitToId = CASE WHEN (RemitToId IS NOT NULL AND GLTransferInfo.RemitToId IS NOT NULL) THEN GLTransferInfo.RemitToId ELSE RemitToId END
		,UpdatedById = @UpdatedById
		,UpdatedTime = @UpdatedTime
FROM 
	Payables 
	JOIN PayableInvoices Invoice ON EntityId = Invoice.Id AND EntityType = 'PI'
	JOIN @GLTransferContractDetails GLTransferInfo ON (Invoice.ContractId = GLTransferInfo.ContractId)

UPDATE SecurityDeposits
SET LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE SecurityDeposits.LegalEntityId END
, RemitToId = CASE When GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE SecurityDeposits.RemitToId END
, InstrumentTypeId = GLTransferInfo.InstrumentTypeId
, LineofBusinessId = GLTransferInfo.LineOfBusinessId
, CostCenterId = GLTransferInfo.CostCenterId
, UpdatedById = @UpdatedById
, UpdatedTime = @UpdatedTime
FROM SecurityDeposits
JOIN @GLTransferContractDetails GLTransferInfo ON SecurityDeposits.ContractId = GLTransferInfo.ContractId AND SecurityDeposits.EntityType = 'CT'
WHERE IsActive = 1
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
JOIN @GLTransferContractDetails GLTransferInfo ON Sundries.ContractId = GLTransferInfo.ContractId AND Sundries.EntityType = 'CT'
WHERE IsActive = 1
UPDATE SundryRecurrings
SET LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE SundryRecurrings.LegalEntityId END
--,PayableRemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL AND PayableRemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE PayableRemitToId END
,ReceivableRemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL AND ReceivableRemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE SundryRecurrings.ReceivableRemitToId END
,InstrumentTypeId = GLTransferInfo.InstrumentTypeId
,LineofBusinessId = GLTransferInfo.LineOfBusinessId
,CostCenterId = GLTransferInfo.CostCenterId
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
,BranchId = CASE WHEN GLTransferInfo.BranchId IS NOT NULL THEN GLTransferInfo.BranchId ELSE SundryRecurrings.BranchId END
FROM SundryRecurrings
JOIN @GLTransferContractDetails GLTransferInfo ON SundryRecurrings.ContractId = GLTransferInfo.ContractId AND SundryRecurrings.EntityType = 'CT'
WHERE IsActive = 1
UPDATE BookDepreciations
SET BookDepreciations.InstrumentTypeId = GLTransferInfo.InstrumentTypeId
,BookDepreciations.LineofBusinessId = GLTransferInfo.LineOfBusinessId
,CostCenterId = GLTransferInfo.CostCenterId
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM BookDepreciations
JOIN @GLTransferContractDetails GLTransferInfo ON BookDepreciations.ContractId = GLTransferInfo.ContractId
WHERE IsActive = 1
UPDATE LateFeeReceivables
SET LateFeeReceivables.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE LateFeeReceivables.LegalEntityId END
,RemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE LateFeeReceivables.RemitToId END
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime --, LateFeeReceivables.LineofBusinessId = @LineOfBusinessId,LateFeeReceivables.InstrumentTypeId = @InstrumentTypeId
FROM LateFeeReceivables
JOIN @GLTransferContractDetails GLTransferInfo ON LateFeeReceivables.EntityId = GLTransferInfo.ContractId AND LateFeeReceivables.EntityType = 'Contract'
WHERE IsActive = 1
UPDATE CPIContracts
SET CPIContracts.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE CPIContracts.LegalEntityId END
, RemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE CPIContracts.RemitToId END
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM CPIContracts
JOIN @GLTransferContractDetails GLTransferInfo ON CPIContracts.ContractId = GLTransferInfo.ContractId
WHERE IsActive = 1
UPDATE UnallocatedRefunds
SET UnallocatedRefunds.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE UnallocatedRefunds.LegalEntityId END
, PayableRemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL AND PayableRemitToId IS NOT NULL THEN  GLTransferInfo.RemitToId ELSE UnallocatedRefunds.PayableRemitToId END
, UpdatedById = @UpdatedById
, UpdatedTime = @UpdatedTime
FROM UnallocatedRefunds
JOIN @GLTransferContractDetails GLTransferInfo ON UnallocatedRefunds.ContractId = GLTransferInfo.ContractId
UPDATE DR
SET DR.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE DR.LegalEntityId END
, DR.UpdatedById = @UpdatedById
, DR.UpdatedTime = @UpdatedTime
FROM DisbursementRequests DR
JOIN DisbursementRequestPayables DRP ON DR.Id = DRP.DisbursementRequestId
JOIN Payables P ON DRP.PayableId = P.Id
JOIN @GLTransferContractDetails GLTransferInfo ON ((P.EntityType = 'CT' AND P.EntityId = GLTransferInfo.ContractId))
WHERE 
DRP.IsActive = 1

UPDATE DR
SET DR.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE DR.LegalEntityId END	
	, DR.UpdatedById = @UpdatedById
	, DR.UpdatedTime = @UpdatedTime
FROM DisbursementRequests DR
JOIN DisbursementRequestPayables DRP ON DR.Id = DRP.DisbursementRequestId
JOIN Payables P ON DRP.PayableId = P.Id
JOIN PayableInvoices Invoice ON P.EntityId = Invoice.Id AND P.EntityType = 'PI'
JOIN @GLTransferContractDetails GLTransferInfo ON Invoice.ContractId = GLTransferInfo.ContractId
WHERE 
DRP.IsActive = 1

UPDATE TP
SET TP.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE TP.LegalEntityId END
	, TP.RemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE TP.RemitToId END
	, TP.UpdatedById = @UpdatedById
	, TP.UpdatedTime = @UpdatedTime
FROM TreasuryPayables TP
JOIN TreasuryPayableDetails TPD ON TP.Id = TPD.TreasuryPayableId
JOIN Payables P ON TPD.PayableId = P.Id
JOIN @GLTransferContractDetails GLTransferInfo ON ((P.EntityType = 'CT' AND P.EntityId = GLTransferInfo.ContractId))
WHERE 
TPD.IsActive = 1

UPDATE TP
SET TP.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE TP.LegalEntityId END
--, TP.RemitToId = CASE WHEN GLTransferInfo.RemitToId IS NOT NULL THEN GLTransferInfo.RemitToId ELSE TP.RemitToId END
, TP.UpdatedById = @UpdatedById
, TP.UpdatedTime = @UpdatedTime
FROM TreasuryPayables TP
JOIN TreasuryPayableDetails TPD ON TP.Id = TPD.TreasuryPayableId
JOIN Payables P ON TPD.PayableId = P.Id
JOIN PayableInvoices Invoice ON P.EntityId = Invoice.Id AND P.EntityType = 'PI'
JOIN @GLTransferContractDetails GLTransferInfo ON  Invoice.ContractId = GLTransferInfo.ContractId
WHERE 
TPD.IsActive = 1

UPDATE PV
SET PV.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE PV.LegalEntityId END
	, UpdatedById = @UpdatedById
	, UpdatedTime = @UpdatedTime
FROM PaymentVouchers PV
JOIN PaymentVoucherDetails PVD ON PV.Id = PVD.PaymentVoucherId
JOIN TreasuryPayables TP ON PVD.TreasuryPayableId = TP.Id
JOIN TreasuryPayableDetails TPD ON TP.Id = TPD.TreasuryPayableId
JOIN Payables P ON TPD.PayableId = P.Id
JOIN @GLTransferContractDetails GLTransferInfo ON ((P.EntityType = 'CT' AND EntityId = GLTransferInfo.ContractId))
WHERE 
TPD.IsActive = 1

UPDATE PV
SET PV.LegalEntityId = CASE WHEN IsLegalEntityChanged = 1 THEN GLTransferInfo.LegalEntityId ELSE PV.LegalEntityId END
, UpdatedById = @UpdatedById
, UpdatedTime = @UpdatedTime
FROM PaymentVouchers PV
JOIN PaymentVoucherDetails PVD ON PV.Id = PVD.PaymentVoucherId
JOIN TreasuryPayables TP ON PVD.TreasuryPayableId = TP.Id
JOIN TreasuryPayableDetails TPD ON TP.Id = TPD.TreasuryPayableId
JOIN Payables P ON TPD.PayableId = P.Id
LEFT JOIN PayableInvoices Invoice ON P.EntityId = Invoice.Id AND P.EntityType = 'PI'
LEFT JOIN @GLTransferContractDetails GLTransferInfo ON ((P.EntityType = 'CT' AND EntityId = GLTransferInfo.ContractId)  OR (Invoice.Id IS NOT NULL AND Invoice.ContractId = GLTransferInfo.ContractId))
WHERE
TPD.IsActive = 1 AND GLTransferInfo.ContractId IS NOT NULL


--CPU assets to be updated
Update CA
SET 
       CA.RemitToId = GLTransferInfo.RemitToId,
       CA.UpdatedById = @UpdatedById,
       CA.UpdatedTime = @UpdatedTime
FROM 
       CPUAssets CA
       JOIN @GLTransferContractDetails GLTransferInfo 
             ON CA.ContractId = GLTransferInfo.ContractId AND GLTransferInfo.ContractType = 'Lease' AND IsLegalEntityChanged = 1 AND GLTransferInfo.RemitToId IS NOT NULL
       JOIN CPUSchedules CS ON CA.CPUScheduleId = CS.Id
       JOIN CPUContracts CC ON CS.CPUFinanceId = CC.CPUFinanceId
WHERE 
       (CC.Status = 'Commenced' OR CC.Status = 'Pending')
       AND CA.PayoffDate IS NULL   
       AND CS.IsActive = 1
       AND CA.IsActive = 1

Update CA
SET 
       CA.RemitToId = GLTransferInfo.RemitToId,
       CA.UpdatedById = @UpdatedById,
       CA.UpdatedTime = @UpdatedTime
FROM 
       CPUAssets CA
       JOIN @GLTransferContractDetails GLTransferInfo 
             ON CA.ContractId = GLTransferInfo.ContractId AND GLTransferInfo.ContractType = 'Lease' AND IsLegalEntityChanged = 1 AND GLTransferInfo.RemitToId IS NOT NULL
       JOIN CPUSchedules CS ON CA.CPUScheduleId = CS.Id
       JOIN CPURestructures CR ON CS.CPUFinanceId = CR.CPUFinanceId
WHERE 
       CR.Status = 'Pending'
       AND CA.PayoffDate IS NULL   
       AND CS.IsActive = 1
       AND CA.IsActive = 1
 
SET NOCOUNT OFF;

GO

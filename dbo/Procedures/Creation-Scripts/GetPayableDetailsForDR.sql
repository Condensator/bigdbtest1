SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Proc [dbo].[GetPayableDetailsForDR]
(
@payableIds NVARCHAR(max),
@payableInvoiceEntityType NVARCHAR(10),
@payableInvoiceAssetSource NVARCHAR(50),
@payableOtherCostSource NVARCHAR(50),
@payablePPCAssetSource  NVARCHAR(50),
@assetFinancialTypeUnknown NVARCHAR(40),
@inactiveLeaseFinanceStatus NVARCHAR(60),
@inactiveloanFinanceStatus NVARCHAR(60),
@progressLoanContractType NVARCHAR(30),
@chargeBackAllocationMethod NVARCHAR(50),
@loanContractType NVARCHAR(30),
@leaseContractType NVARCHAR(30),
@unallocatedRefundEntityType NVARCHAR(10),
@sundryPayableSourceType NVARCHAR(50),
@PPTInvoiceEntityType NVARCHAR(10),
@receiptTableType NVARCHAR(50),
@leaseApprovedStatus NVARCHAR(60),
@activatedPayoffStatus NVARCHAR(50),
@scrapeReceivableSourceType NVARCHAR(50),
@dueToInvestorAPTransactinType NVARCHAR(20),
@sundryRecurringPaymentScheduleSourceType NVARCHAR(20),
@progressPaymentCreditType NVARCHAR(50),
@specificCostAdjustmentType NVARCHAR(50),
@CPIReceivablePayableSourceType NVARCHAR(MAX),
@CPUPayableSourceType NVARCHAR(24),
@CPUReceivableSourceType NVARCHAR(20),
@CPUContractStatusCommenced NVARCHAR(9),
@CPUContractStatusPaidoff NVARCHAR(7),
@ReceivableContractEntityType NVARCHAR(2),
@discountingPrincipalTransactionType NVARCHAR(50),
@discountingInterestTransactionType NVARCHAR(50),
@CreateCompletedDR NVARCHAR(10),
@loanAmendmentInactiveStatus NVARCHAR(60),
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT * INTO #PayableIds FROM ConvertCSVToBigIntTable(@payableIds, ',');  --TVP can be used

    SELECT P.Id 'PayableId', PT.Name 'PayableType', V.Id 'VendorId', P.SourceId 'SourceId', P.SourceTable 'SourceTable', P.EntityType 'EntityType', P.EntityId 'EntityId', 
	P.Amount_Amount 'PayableAmount', P.Amount_Currency 'PayableCurrency', P.Balance_Amount 'PayableBalance', P.RemitToId 'PayableRemitToId', P.DueDate 'PayableDueDate', 
	V.IsIntercompany, P.CreationSourceId, P.CreationSourceTable,P.AdjustmentBasisPayableId INTO #PayableTemp
    FROM Payables P
    JOIN PayableCodes PC ON P.PayableCodeId = PC.Id
    JOIN PayableTypes PT ON PC.PayableTypeId = PT.Id
    JOIN Parties V ON P.PayeeId = V.Id
	JOIN #PayableIds PI ON P.Id = PI.Id;
   -- WHERE P.Id IN (SELECT Id FROM #PayableIds); remove

	SELECT LeaseAssetId, AssetId, UsePayDate, IsApproved, PayableInvoiceId, IsActive, LeaseFinanceId
	INTO #LeaseAssetIdTemp FROM
	(
		SELECT LA.Id 'LeaseAssetId', LA.AssetId, LA.UsePayDate, LA.IsApproved, PI.Id as PayableInvoiceId, LA.IsActive, LA.LeaseFinanceId,
			ROW_NUMBER() OVER (PARTITION BY P.PayableId ORDER BY LF.IsCurrent DESC, LF.Id DESC) AS RowNumber
		FROM #PayableTemp P
		JOIN PayableInvoiceAssets PIA ON P.SourceTable = @payableInvoiceAssetSource AND P.SourceId = PIA.Id
		JOIN PayableInvoices PI ON PIA.PayableInvoiceId = PI.Id
		JOIN LeaseAssets LA ON PIA.AssetId = LA.AssetId AND LA.IsActive = 1
		JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
		LEFT JOIN Payoffs PO ON PO.LeaseFinanceId = LF.Id AND PO.Status = @activatedPayoffStatus
		WHERE (PI.ParentPayableInvoiceId IS NULL OR LF.IsCurrent = 1) AND PO.Id IS NULL AND (LF.ApprovalStatus != @leaseApprovedStatus OR LF.IsCurrent = 1)
	) AS LeaseAssetInfo 
	WHERE LeaseAssetInfo.RowNumber = 1;

	SELECT P.PayableId, P.EntityType, P.EntityId, P.SourceTable, P.SourceId, P.PayableCurrency, P.PayableAmount, P.PayableBalance, P.PayableType, P.VendorId, PIA.PayableInvoiceId as 'PayableInvoiceId', Case When A.Id Is Not Null Then A.Id Else PIA.AssetId End as 'AssetId', A.Alias, A.FinancialType, A.PartNumber,Case When LF.Id Is Not Null Then LA.UsePayDate Else CONVERT(BIT, 0) END as 'UsePayDate'  ,Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) Then PI.InstrumentTypeId Else LF.InstrumentTypeId End as 'InstrumentTypeId', LF.ContractId, LA.IsApproved 'IsFundingApproved', LF.Id 'LeaseFinanceId',NULL 'LoanFinanceId', MAX(AVH.Id) 'LatestAssetValueHistoryId', NULL 'SundryReceivableId', NULL 'ReceivableId', P.PayableDueDate, CONVERT(NVARCHAR, NULL) 'AllocationMethod', NULL 'OtherCostId', CONVERT(BIT,0) 'AssociateAssets', P.PayableRemitToId, CU.PartyName 'CustomerName', CU.PartyNumber 'CustomerNumber', C.SequenceNumber, PI.InvoiceNumber, CONVERT(BIT, 0) 'IsProgressLoanPayable', Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) Then PI.LineofBusinessId Else C.LineofBusinessId End as 'LineofBusinessId', (CASE WHEN C.Id IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END) 'HasContract', (CASE WHEN PI.InvoiceTotal_Amount < 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END) 'IsInvoiceTotalNegative', PI.DueDate 'InvoiceDueDate', CONVERT(BIT, 0) 'IsChargeBackOtherCost', (CASE WHEN LF.Id IS NULL THEN CONVERT(BIT, 0) ELSE LF.IsCurrent END) 'IsCurrentContract', (CASE WHEN FU.Id IS NULL THEN CONVERT(NVARCHAR, NULL) ELSE FU.Type END) 'FundingType', (CASE WHEN LF.Id IS NOT NULL AND LF.IsFutureFunding = 1 THEN LFD.LeaseBookingGLTemplateId ELSE NULL END) 'MatchingGLTemplate', CONVERT(NVARCHAR, NULL) 'ReceivableType', NULL 'SalesTaxGLTemplate',Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) Then PI.CostCenterId Else LF.CostCenterId End as 'CostCenterId', P.IsIntercompany, A.VendorOrderNumber ,Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null and PI.BranchId Is Not Null) Then PI.BranchId Else LF.BranchId End as 'BranchId', NULL as 'DiscountingId',PI.InitialExchangeRate
    INTO #LeaseAssetTemp
    FROM #PayableTemp P
    JOIN PayableInvoiceAssets PIA ON P.SourceTable =  @payableInvoiceAssetSource AND P.SourceId = PIA.Id
	JOIN PayableInvoices PI ON PIA.PayableInvoiceId = PI.Id AND PI.IsInvalidPayableInvoice = 0
	LEFT JOIN Parties CU ON PI.CustomerId = CU.Id
    LEFT JOIN #LeaseAssetIdTemp LA ON LA.AssetId = PIA.AssetId AND (LA.PayableInvoiceId IS NULL OR PI.Id = LA.PayableInvoiceId) AND LA.IsActive = 1
    LEFT JOIN Assets A ON LA.AssetId = A.Id
    LEFT JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
	LEFT JOIN Contracts C ON LF.ContractId = C.Id
    LEFT JOIN LeaseFundings FU ON LF.Id = FU.LeaseFinanceId AND FU.FundingId = PI.Id
    LEFT JOIN AssetValueHistories AVH ON A.Id = AVH.AssetId
	LEFT JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
    WHERE P.EntityType = @payableInvoiceEntityType 
	  AND P.EntityId = PIA.PayableInvoiceId
      AND LA.LeaseAssetId IS NULL OR (LF.ApprovalStatus != @inactiveLeaseFinanceStatus OR (AVH.AssetId IS NOT NULL
							AND AVH.IsSchedule = 1
							AND AVH.IsCleared = 1
							AND AVH.SourceModule != 'ResidualReclass'))
	GROUP BY A.Id,PIA.AssetId, P.PayableId, P.PayableType, P.SourceTable, P.SourceId, P.VendorId, P.EntityType, P.EntityId, P.PayableCurrency, P.PayableAmount, P.PayableBalance, PIA.PayableInvoiceId, A.Alias, A.FinancialType, A.PartNumber, LA.UsePayDate,  PI.InstrumentTypeId , LF.InstrumentTypeId , LF.ContractId, LA.IsApproved, LF.Id, P.PayableDueDate, P.PayableRemitToId, CU.PartyName, CU.PartyNumber, C.SequenceNumber, PI.InvoiceNumber,  PI.LineofBusinessId , C.LineofBusinessId , C.Id, PI.InvoiceTotal_Amount, PI.DueDate, LF.IsCurrent, FU.Id, FU.Type, LF.IsFutureFunding, LFD.LeaseBookingGLTemplateId,PI.CostCenterId , LF.CostCenterId , P.IsInterCompany, A.VendorOrderNumber, PI.BranchId , LF.BranchId,PI.InitialExchangeRate ;

	SELECT P.PayableId, P.EntityType, P.EntityId, P.SourceTable, P.SourceId, P.PayableCurrency, P.PayableAmount, P.PayableBalance, P.PayableType, P.VendorId, PIOC.PayableInvoiceId 'PayableInvoiceId', NULL 'AssetId', CONVERT(NVARCHAR, NULL) 'Alias', @assetFinancialTypeUnknown 'FinancialType', CONVERT(NVARCHAR, NULL) 'PartNumber', FU.UsePayDate, 
	(CASE WHEN ProgressLoan.Id IS NOT NULL THEN ProgressLoan.InstrumentTypeId WHEN LF.InstrumentTypeId IS NOT NULL THEN LF.InstrumentTypeId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.InstrumentTypeId ELSE Null END) 'InstrumentTypeId',
	 LF.ContractId, FU.IsApproved 'IsFundingApproved', NULL 'LeaseFinanceId', LF.Id 'LoanFinanceId', NULL 'LatestAssetValueHistoryId', PIOC.SundryReceivableId, S.ReceivableId, P.PayableDueDate, PIOC.AllocationMethod, PIOC.Id 'OtherCostId', PIOC.AssociateAssets, P.PayableRemitToId, CU.PartyName 'CustomerName', CU.PartyNumber 'CustomerNumber', C.SequenceNumber, PI.InvoiceNumber,  (CASE WHEN (@CreateCompletedDR='TRUE') And C.ContractType Is Null and PI.ContractType = '' + @progressLoanContractType + '' THEN CONVERT(BIT,1) When C.ContractType = '' + @progressLoanContractType + '' THEN CONVERT(BIT,1)  ELSE CONVERT(BIT,0) END) 'IsProgressLoanPayable', 
	 (CASE WHEN ProgressLoan.Id IS NOT NULL THEN ProgressLoan.LineofBusinessId WHEN LF.LineofBusinessId IS NOT NULL THEN LF.LineofBusinessId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.LineofBusinessId ELSE Null END) 'LineofBusinessId',
	 --Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) Then PI.LineofBusinessId Else C.LineofBusinessId End as 'LineofBusinessId', 
	 (CASE WHEN C.Id IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END) 'HasContract', (CASE WHEN PI.InvoiceTotal_Amount < 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END) 'IsInvoiceTotalNegative', PI.DueDate 'InvoiceDueDate', (CASE WHEN PIOC.AllocationMethod = '' + @chargeBackAllocationMethod + '' THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END) 'IsChargeBackOtherCost', (CASE WHEN LF.Id IS NULL THEN CONVERT(BIT, 0) ELSE LF.IsCurrent END) 'IsCurrentContract', (CASE WHEN FU.Id IS NULL THEN CONVERT(NVARCHAR, NULL) ELSE FU.Type END) 'FundingType', NULL 'MatchingGLTemplate', CONVERT(NVARCHAR, NULL) 'ReceivableType', NULL 'SalesTaxGLTemplate', 
	 (CASE WHEN ProgressLoan.Id IS NOT NULL THEN ProgressLoan.CostCenterId WHEN LF.CostCenterId IS NOT NULL THEN LF.CostCenterId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.CostCenterId ELSE Null END) 'CostCenterId',
	 --Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) Then PI.CostCenterId Else LF.CostCenterId End as 'CostCenterId', 
	 P.IsInterCompany, CONVERT(NVARCHAR, NULL) 'VendorOrderNumber',(CASE WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.BranchId WHEN ProgressLoan.Id IS NOT NULL THEN ProgressLoan.BranchId ELSE LF.BranchId END) 'BranchId', NULL as 'DiscountingId',PI.InitialExchangeRate
    INTO #LoanOtherCostTemp
    FROM #PayableTemp P
    JOIN PayableInvoiceOtherCosts PIOC ON P.SourceTable =  @payableOtherCostSource AND P.SourceId = PIOC.Id
    JOIN PayableInvoices PI ON PIOC.PayableInvoiceId = PI.Id AND PI.IsInvalidPayableInvoice = 0 
	LEFT JOIN Parties CU ON PI.CustomerId = CU.Id
    LEFT JOIN LoanFundings FU ON FU.FundingId = PIOC.PayableInvoiceId AND FU.IsActive = 1					
	LEFT JOIN LoanFinances LF ON FU.LoanFinanceId = LF.Id
	LEFT JOIN LoanAmendments LA ON LF.Id = LA.LoanFinanceId
	LEFT JOIN Contracts C ON LF.ContractId = C.Id
	LEFT JOIN Sundries S ON PIOC.SundryReceivableId = S.Id
	LEFT JOIN PayableInvoiceOtherCosts ProgressFunding ON PIOC.ProgressFundingId = ProgressFunding.Id AND PIOC.AllocationMethod =  @progressPaymentCreditType 
	LEFT JOIN LoanFundings ProgressLoanFunding ON ProgressFunding.PayableInvoiceId = ProgressLoanFunding.FundingId
	LEFT JOIN LoanFinances ProgressLoan ON ProgressLoanFunding.LoanFinanceId = ProgressLoan.Id
    WHERE P.EntityType =  @payableInvoiceEntityType AND P.EntityId = PIOC.PayableInvoiceId 
	AND [PI].ContractType IN (@loanContractType,@progressLoanContractType)
	AND (LF.IsCurrent IS NULL OR LF.IsCurrent = 1 OR (LA.Id IS NOT NULL AND LA.QuoteStatus != @loanAmendmentInactiveStatus AND (FU.IsNewlyAdded = 1 OR PI.Revise = 1)));

	SELECT P.PayableId, MAX(LF.Id) 'LeaseFinanceId' INTO #LeasePayableFinanceMapping
	FROM #PayableTemp P
    JOIN PayableInvoiceOtherCosts PIOC ON P.SourceTable = @payableOtherCostSource AND P.SourceId = PIOC.Id
    JOIN PayableInvoices PI ON PIOC.PayableInvoiceId = PI.Id AND PI.IsInvalidPayableInvoice = 0
	LEFT JOIN LeaseFundings FU ON FU.FundingId = PIOC.PayableInvoiceId AND FU.IsActive = 1
    LEFT JOIN LeaseFinances LF ON FU.LeaseFinanceId = LF.Id
	GROUP BY P.PayableId HAVING COUNT(LF.Id) > 1;

	SELECT P.PayableId, P.EntityType, P.EntityId, P.SourceTable, P.SourceId, P.PayableCurrency, P.PayableAmount, P.PayableBalance, P.PayableType, P.VendorId, PIOC.PayableInvoiceId 'PayableInvoiceId', A.Id 'AssetId', A.Alias 'Alias', @assetFinancialTypeUnknown 'FinancialType', CONVERT(NVARCHAR, NULL) 'PartNumber', FU.UsePayDate, (CASE WHEN AGL.InstrumentTypeId IS NOT NUll THEN AGL.InstrumentTypeId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null)  THEN PI.InstrumentTypeId  WHEN ProgressLoan.Id IS NOT NULL THEN ProgressLoan.InstrumentTypeId WHEN LSCA.PayableInvoiceOtherCostId IS NOT NULL THEN LSCA.InstrumentTypeId ELSE LF.InstrumentTypeId END) 'InstrumentTypeId', ISNULL(LSCA.ContractId,LF.ContractId) 'ContractId', ISNULL(LSCA.IsApproved,FU.IsApproved)  'IsFundingApproved', ISNULL(LSCA.LeaseFinanceId,LF.Id) 'LeaseFinanceId', NULL 'LoanFinanceId', NULL 'LatestAssetValueHistoryId', PIOC.SundryReceivableId, S.ReceivableId, P.PayableDueDate, PIOC.AllocationMethod, PIOC.Id 'OtherCostId', PIOC.AssociateAssets, P.PayableRemitToId, CU.PartyName 'CustomerName', CU.PartyNumber 'CustomerNumber', ISNULL(LSCA.SequenceNumber,C.SequenceNumber) 'SequenceNumber', PI.InvoiceNumber,  CONVERT(BIT,0) 'IsProgressLoanPayable', CASE WHEN AGL.LineofBusinessId IS NOT NUll THEN AGL.LineofBusinessId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.LineofBusinessId  WHEN LSCA.LineofBusinessId IS NOT NULL THEN LSCA.LineofBusinessId ELSE C.LineofBusinessId END as 'LineofBusinessId', (CASE WHEN C.Id IS NULL AND LSCA.ContractId IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END) 'HasContract', (CASE WHEN PI.InvoiceTotal_Amount < 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END) 'IsInvoiceTotalNegative', PI.DueDate 'InvoiceDueDate', (CASE WHEN PIOC.AllocationMethod =  @chargeBackAllocationMethod   THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END) 'IsChargeBackOtherCost', (CASE WHEN LF.Id  IS NULL AND LSCA.ContractId IS NULL THEN CONVERT(BIT, 0) ELSE ISNULL(LF.IsCurrent,LSCA.IsCurrent) END) 'IsCurrentContract', (CASE WHEN FU.Id IS NULL THEN CONVERT(NVARCHAR, NULL) ELSE FU.Type END) 'FundingType', NULL 'MatchingGLTemplate', CONVERT(NVARCHAR, NULL) 'ReceivableType', NULL 'SalesTaxGLTemplate', CASE WHEN AGL.CostCenterId IS NOT NUll THEN AGL.CostCenterId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.CostCenterId  WHEN LSCA.CostCenterId IS NOT NULL THEN LSCA.CostCenterId ELSE LF.CostCenterId END as 'CostCenterId', P.IsInterCompany, CONVERT(NVARCHAR, NULL) 'VendorOrderNumber',(CASE WHEN AGL.BranchId IS NOT NULL THEN AGL.BranchId WHEN PI.BranchId IS NOT NULL THEN PI.BranchId WHEN ProgressLoan.Id IS NOT NULL THEN ProgressLoan.BranchId WHEN LSCA.PayableInvoiceOtherCostId IS NOT NULL THEN LSCA.BranchId ELSE LF.BranchId END) as 'BranchId', NULL as 'DiscountingId',PI.InitialExchangeRate
	INTO #LeaseOtherCostTemp
    FROM #PayableTemp P
    JOIN PayableInvoiceOtherCosts PIOC ON P.SourceTable =@payableOtherCostSource  AND P.SourceId = PIOC.Id
    JOIN PayableInvoices PI ON PIOC.PayableInvoiceId = PI.Id AND PI.IsInvalidPayableInvoice = 0
	LEFT JOIN Parties CU ON PI.CustomerId = CU.Id
    LEFT JOIN LeaseFundings FU ON FU.FundingId = PIOC.PayableInvoiceId AND FU.IsActive = 1
    LEFT JOIN LeaseFinances LF ON FU.LeaseFinanceId = LF.Id
	LEFT JOIN Contracts C ON LF.ContractId = C.Id
	LEFT JOIN Sundries S ON PIOC.SundryReceivableId = S.Id
	LEFT JOIN #LeasePayableFinanceMapping LPFM ON P.PayableId = LPFM.PayableId
	LEFT JOIN PayableInvoiceOtherCosts ProgressFunding ON PIOC.ProgressFundingId = ProgressFunding.Id AND PIOC.AllocationMethod = @progressPaymentCreditType 
	LEFT JOIN LoanFundings ProgressLoanFunding ON ProgressFunding.PayableInvoiceId = ProgressLoanFunding.FundingId
	LEFT JOIN LoanFinances ProgressLoan ON ProgressLoanFunding.LoanFinanceId = ProgressLoan.Id
	LEFT JOIN (SELECT PayableId,PayableInvoiceOtherCosts.Id PayableInvoiceOtherCostId,LeaseFinances.Id LeaseFinanceId,LeaseFinances.InstrumentTypeId,LeaseFinances.BranchId,LeaseFinances.CostCenterId,Contracts.LineofBusinessId,Contracts.Id ContractId,Contracts.SequenceNumber,LeaseFinances.IsCurrent,PayableInvoices.IsForeignCurrency,LeaseAssets.IsApproved, ROW_NUMBER() OVER(PARTITION BY #PayableTemp.PayableId ORDER BY LeaseFinances.IsCurrent DESC,LeaseFinances.Id DESC) RowNumber
				FROM #PayableTemp 
				JOIN PayableInvoiceOtherCosts ON #PayableTemp.SourceTable = @payableOtherCostSource AND #PayableTemp.SourceId = PayableInvoiceOtherCosts.Id AND PayableInvoiceOtherCosts.AllocationMethod =  @specificCostAdjustmentType  AND PayableInvoiceOtherCosts.IsActive=1
				JOIN PayableInvoices ON PayableInvoiceOtherCosts.PayableInvoiceId = PayableInvoices.Id AND PayableInvoices.IsInvalidPayableInvoice = 0
				JOIN LeaseSpecificCostAdjustments ON PayableInvoiceOtherCosts.Id = LeaseSpecificCostAdjustments.PayableInvoiceOtherCostId AND LeaseSpecificCostAdjustments.IsActive=1
				JOIN LeaseAssets ON PayableInvoiceOtherCosts.AssetId = LeaseAssets.AssetId AND LeaseAssets.LeaseFinanceId = LeaseSpecificCostAdjustments.LeaseFinanceId AND (LeaseAssets.IsActive=1 OR LeaseAssets.TerminationDate IS NOT NULL)
				JOIN LeaseFinances ON LeaseSpecificCostAdjustments.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.BookingStatus <> 'Inactive'
				JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
				LEFT JOIN LeaseFundings on LeaseFundings.LeaseFinanceId =LeaseSpecificCostAdjustments.LeaseFinanceId
				where LeaseFundings.IsApproved is null or LeaseFundings.FundingId != PayableInvoiceOtherCosts.PayableInvoiceId) AS LSCA ON P.PayableId = LSCA.PayableId AND LSCA.RowNumber=1
	LEFT JOIN Assets A ON PIOC.AssetId = A.Id 
	LEFT JOIN AssetGLDetails AGL ON A.Id = AGL.Id AND PIOC.AllocationMethod =@specificCostAdjustmentType 
    WHERE P.EntityType = @payableInvoiceEntityType
      AND P.EntityId = PIOC.PayableInvoiceId
      AND PI.ContractType =  @leaseContractType
	  AND (LPFM.PayableId IS NULL OR (LPFM.LeaseFinanceId = LSCA.LeaseFinanceId) OR (FU.Id IS NULL OR FU.LeaseFinanceId = LPFM.LeaseFinanceId));

	SELECT P.PayableId, P.EntityType, P.EntityId, P.SourceTable, P.SourceId, P.PayableCurrency, P.PayableAmount, P.PayableBalance, P.PayableType, P.VendorId, PIOC.PayableInvoiceId 'PayableInvoiceId', A.Id 'AssetId', A.Alias, A.FinancialType, A.PartNumber, (CASE WHEN LEFU.Id IS NOT NULL THEN LEFU.UsePayDate ELSE  LOFU.UsePayDate END) 'UsePayDate', (CASE WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.InstrumentTypeId WHEN LEFU.Id IS NOT NULL THEN LEF.InstrumentTypeId ELSE  LOF.InstrumentTypeId END) 'InstrumentTypeId', (CASE WHEN LEFU.Id IS NOT NULL THEN LEF.ContractId ELSE LOF.ContractId END) 'ContractId', (CASE WHEN LEFU.Id IS NOT NULL THEN LEFU.IsApproved ELSE LOFU.IsApproved END) 'IsFundingApproved', LEF.Id 'LeaseFinanceId', LOF.Id 'LoanFinanceId', MAX(AVH.Id) 'LatestAssetValueHistoryId', NULL 'SundryReceivableId', NULL 'ReceivableId', P.PayableDueDate, CONVERT(NVARCHAR, NULL) 'AllocationMethod', PIOC.Id 'OtherCostId', CONVERT(BIT, 0) 'AssociateAssets', P.PayableRemitToId, CU.PartyName 'CustomerName', CU.PartyNumber 'CustomerNumber', (CASE WHEN LEFC.Id IS NULL THEN LOFC.SequenceNumber ELSE LEFC.SequenceNumber END) 'SequenceNumber', PI.InvoiceNumber,  CONVERT(BIT,0) 'IsProgressLoanPayable', (CASE WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.LineofBusinessId WHEN LEFC.Id IS NULL THEN LOFC.LineofBusinessId ELSE LEFC.LineofBusinessId END) 'LineofBusinessId', (CASE WHEN (LOFC.Id IS NULL AND LEFC.Id IS NULL) THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END) 'HasContract', (CASE WHEN PI.InvoiceTotal_Amount < 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END) 'IsInvoiceTotalNegative', PI.DueDate 'InvoiceDueDate', CONVERT(BIT, 0) 'IsChargeBackOtherCost', (CASE WHEN LEF.Id IS NULL AND LOF.Id IS NULL THEN CONVERT(BIT, 0) WHEN LEF.Id IS NOT NULL THEN LEF.IsCurrent ELSE LOF.IsCurrent END) 'IsCurrentContract', (CASE WHEN LEFU.Id IS NULL AND LOFU.Id IS NULL THEN CONVERT(NVARCHAR, NULL) WHEN LEFU.Id IS NOT NULL THEN LEFU.Type ELSE LOFU.Type END) 'FundingType', NULL 'MatchingGLTemplate', CONVERT(NVARCHAR, NULL) 'ReceivableType', NULL 'SalesTaxGLTemplate', (CASE WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.CostCenterId WHEN LEF.Id IS NOT NULL THEN LEF.CostCenterId ELSE LOF.CostCenterId END) 'CostCenterId', P.IsInterCompany, A.VendorOrderNumber,(CASE WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.BranchId WHEN LEF.Id IS NOT NULL THEN LEF.BranchId ELSE LOF.BranchId END) 'BranchId', NULL as 'DiscountingId',PI.InitialExchangeRate
    INTO #PPCAssetTemp
    FROM #PayableTemp P
    JOIN PayableInvoiceOtherCostDetails PIOD ON P.SourceTable = @payablePPCAssetSource AND P.SourceId = PIOD.Id
    JOIN PayableInvoiceAssets PIA ON PIOD.PayableInvoiceAssetId = PIA.Id
    JOIN Assets A ON PIA.AssetId = A.Id
    JOIN PayableInvoiceOtherCosts PIOC ON PIOD.PayableInvoiceOtherCostId = PIOC.Id
	JOIN PayableInvoices PI ON PIOC.PayableInvoiceId = PI.Id AND PI.IsInvalidPayableInvoice = 0
	LEFT JOIN Parties CU ON PI.CustomerId = CU.Id
    LEFT JOIN AssetValueHistories AVH ON A.Id = AVH.AssetId
    LEFT JOIN LeaseFundings LEFU ON PIOC.PayableInvoiceId = LEFU.FundingId AND LEFU.IsActive = 1
	LEFT JOIN LeaseFinances LEF ON LEFU.LeaseFinanceId = LEF.Id
	LEFT JOIN Contracts LEFC ON LEF.ContractId = LEFC.Id
    LEFT JOIN LoanFundings LOFU ON PIOC.PayableInvoiceId = LOFU.FundingId AND LOFU.IsActive = 1  
	LEFT JOIN LoanFinances LOF ON LOFU.LoanFinanceId = LOF.Id
	LEFT JOIN Contracts LOFC ON LOF.ContractId = LOFC.Id
    WHERE P.EntityType =  @payableInvoiceEntityType
      AND P.EntityId = PIOC.PayableInvoiceId 
	  AND (AVH.AssetId IS NULL OR 
		(AVH.IsSchedule = 1
		 AND AVH.IsCleared = 1
		 AND AVH.SourceModule != 'ResidualReclass'))
	  AND (LEFU.Id IS NULL OR (LEFU.IsActive = 1 AND LEF.ApprovalStatus != @inactiveLeaseFinanceStatus))
	  AND (LOFU.Id IS NULL OR (LOFU.IsActive = 1 AND LOF.ApprovalStatus !=  @inactiveloanFinanceStatus))
	 GROUP BY P.PayableId, P.EntityType, P.EntityId, P.SourceTable, P.SourceId, P.PayableCurrency, P.PayableAmount, P.PayableBalance, P.PayableType, P.VendorId, PIOC.PayableInvoiceId, A.Id, A.Alias, A.FinancialType, A.PartNumber, LEFU.UsePayDate, LOFU.UsePayDate, LEF.InstrumentTypeId, LOF.InstrumentTypeId,PI.InstrumentTypeId, LEF.ContractId, LOF.ContractId, LEFU.IsApproved, LOFU.IsApproved, LEF.Id, LOF.Id, P.PayableDueDate, P.PayableRemitToId, LEFU.Id, LOFU.Id, CU.PartyName, CU.PartyNumber, LOFC.SequenceNumber, LEFC.SequenceNumber, PI.InvoiceNumber, LOFC.LineofBusinessId,PI.LineofBusinessId, LEFC.LineofBusinessId, PI.InvoiceTotal_Amount, PI.DueDate, LOFC.Id, LEFC.Id, LEF.IsCurrent, LOF.IsCurrent, LEFU.Id, LOFU.Id, LEFU.Type, LOFU.Type, PIOC.Id, LEF.CostCenterId,PI.CostCenterId,LOF.CostCenterId, P.IsInterCompany, A.VendorOrderNumber,PI.BranchId,LEF.BranchId,LOF.BranchId,PI.InitialExchangeRate


    SELECT P.PayableId, RC.GLTemplateId INTO #InterimRentSharingPayable
	FROM #PayableTemp P
	JOIN ReceiptApplicationReceivableDetails RARD ON P.CreationSourceId = RARD.Id AND P.CreationSourceTable = 'RARD'
	JOIN ReceivableDetails RD ON RARD.ReceivableDetailId = RD.Id
	JOIN RentSharingDetails RSD ON RD.ReceivableId = RSD.ReceivableId
	JOIN Receivables R ON RSD.ReceivableId = R.Id
	JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	
	SELECT InstrumentTypeId,ContractId,Id,ReceivableId,LineofBusinessId,CostCenterId,LeaseFinanceId,LoanFinanceId,SequenceNumber,PayableId,CustomerId INTO #Sundries
	FROM (
	SELECT S.InstrumentTypeId 'InstrumentTypeId',S.ContractId 'ContractId',S.Id,S.ReceivableId 'ReceivableId',S.LineofBusinessId,S.CostCenterId,LEF.Id 'LeaseFinanceId',LOF.Id 'LoanFinanceId',C.SequenceNumber,P.PayableId,S.CustomerId
	FROM #PayableTemp P
	JOIN Sundries S ON P.PayableId = S.PayableId 
	LEFT JOIN Contracts C ON S.ContractId = C.Id
	LEFT JOIN LoanFinances LOF ON S.ContractId = LOF.ContractId AND LOF.IsCurrent = 1
	LEFT JOIN LeaseFinances LEF ON S.ContractId = LEF.ContractId AND LEF.IsCurrent = 1
	UNION ALL
	SELECT S.InstrumentTypeId 'InstrumentTypeId',S.ContractId 'ContractId',S.Id,S.ReceivableId 'ReceivableId',S.LineofBusinessId,S.CostCenterId,LEF.Id 'LeaseFinanceId',LOF.Id 'LoanFinanceId',C.SequenceNumber,P.PayableId,S.CustomerId
	FROM #PayableTemp P
	JOIN Sundries S ON P.AdjustmentBasisPayableId = S.PayableId 
	LEFT JOIN Contracts C ON S.ContractId = C.Id
	LEFT JOIN LoanFinances LOF ON S.ContractId = LOF.ContractId AND LOF.IsCurrent = 1
	LEFT JOIN LeaseFinances LEF ON S.ContractId = LEF.ContractId AND LEF.IsCurrent = 1
	UNION ALL
	SELECT S.InstrumentTypeId 'InstrumentTypeId',S.ContractId 'ContractId',S.Id,S.ReceivableId 'ReceivableId',S.LineofBusinessId,S.CostCenterId,LEF.Id 'LeaseFinanceId',LOF.Id 'LoanFinanceId',C.SequenceNumber,P.PayableId,S.CustomerId
	FROM #PayableTemp P
	JOIN Sundries S ON P.SourceTable = @sundryPayableSourceType AND P.SourceId = S.Id AND ( S.PayableId IS NULL OR P.PayableId <> S.PayableId )
	LEFT JOIN Contracts C ON S.ContractId = C.Id
	LEFT JOIN LoanFinances LOF ON S.ContractId = LOF.ContractId AND LOF.IsCurrent = 1
	LEFT JOIN LeaseFinances LEF ON S.ContractId = LEF.ContractId AND LEF.IsCurrent = 1
	) List

	SELECT 
		P.PayableId, 
		P.EntityType, 
		P.EntityId, 
		P.SourceTable, 
		P.SourceId, 
		P.PayableCurrency, 
		P.PayableAmount, 
		P.PayableBalance, 
		P.PayableType, 
		P.VendorId, 
		NULL 'PayableInvoiceId', 
		NULL 'AssetId', 
		CONVERT(NVARCHAR, NULL) 'Alias', 
		@assetFinancialTypeUnknown 'FinancialType',
		CONVERT(NVARCHAR, NULL) 'PartNumber', 
		CONVERT(BIT, 0) 'UsePayDate', 
		S.InstrumentTypeId 'InstrumentTypeId', 
		S.ContractId 'ContractId', 
		CONVERT(BIT, 1) 'IsFundingApproved', 
		S.LeaseFinanceId 'LeaseFinanceId', 
		S.LoanFinanceId 'LoanFinanceId', 
		NULL 'LatestAssetValueHistoryId', 
		S.Id 'SundryReceivableId', 
		S.ReceivableId 'ReceivableId', 
		P.PayableDueDate, 
		CONVERT(NVARCHAR, NULL) 'AllocationMethod', 
		NULL 'OtherCostId', 
		CONVERT(BIT, 0) 'AssociateAssets', 
		P.PayableRemitToId, 
		CU.PartyName 'CustomerName', 
		CU.PartyNumber 'CustomerNumber', 
		S.SequenceNumber, 
		CONVERT(NVARCHAR, NULL) 'InvoiceNumber',  
		CONVERT(BIT,0) 'IsProgressLoanPayable', 
		S.LineofBusinessId,
		
		(CASE 
			WHEN S.ContractId IS NULL THEN CONVERT(BIT,0) 
		    ELSE CONVERT(BIT,1) 
		END) 'HasContract', 

		CONVERT(BIT,0) 'IsInvoiceTotalNegative', 
		CONVERT(DATE, NULL) 'InvoiceDueDate', 
		CONVERT(BIT, 0) 'IsChargeBackOtherCost', 
		CONVERT(BIT, 0) 'IsCurrentContract', 
		CONVERT(NVARCHAR, NULL) 'FundingType', 

		(CASE 
			WHEN P.PayableType = @dueToInvestorAPTransactinType THEN (CASE 
																		WHEN IRSP.PayableId IS NOT NULL THEN IRSP.GLTemplateId 
																		ELSE GLT.Id 
																	  END) 
			WHEN P.PayableType = @discountingPrincipalTransactionType THEN DFL.DiscountingGLTemplateId 
			WHEN P.PayableType = @discountingInterestTransactionType THEN DFL.ExpenseRecognitionGLTemplateId 
			ELSE NULL 
		END) 'MatchingGLTemplate', 

		RT.Name 'ReceivableType', 

		(CASE 
			WHEN P.PayableType = @dueToInvestorAPTransactinType THEN RTX.GLTemplateId 
			ELSE NULL 
		END) 'SalesTaxGLTemplate', 

		S.CostCenterId 'CostCenterId', 
		P.IsInterCompany, 
		CONVERT(NVARCHAR, NULL) 'VendorOrderNumber',
		null as 'BranchId', 
		D.Id as 'DiscountingId',
		null as 'InitialExchangeRate'
	INTO #SundryTemp
	FROM #PayableTemp P
	JOIN #Sundries S ON P.PayableId = S.PayableId 
	JOIN Parties CU ON S.CustomerId = CU.Id
	LEFT JOIN Receivables R ON P.SourceId = R.Id AND P.SourceTable = @scrapeReceivableSourceType
	LEFT JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	LEFT JOIN GLTemplates GLT ON RC.SyndicationGLTemplateId = GLT.Id
	LEFT JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId AND RTX.IsActive = 1
	LEFT JOIN DiscountingSundries DS ON S.Id = DS.Id
	LEFT JOIN Discountings D on DS.DiscountingId = D.Id
	LEFT JOIN DiscountingFinances DFL ON D.Id = DFL.DiscountingId AND DFL.IsCurrent = 1
	LEFT JOIN #InterimRentSharingPayable IRSP ON P.PayableId = IRSP.PayableId

	Select P.PayableId, SPS.ReceivableId,SPS.SundryRecurringId, 1 IsLease, LEF.Id Into #SundryRecurringPayables
	FROM #PayableTemp P  
	JOIN SundryRecurringPaymentSchedules SPS ON P.PayableId = SPS.PayableId 
	JOIN SundryRecurrings S ON SPS.SundryRecurringId = S.Id  
	JOIN Contracts C ON S.ContractId = C.Id  
	JOIN LeaseFinances LEF ON S.ContractId = LEF.ContractId AND LEF.IsCurrent = 1;  

	INSERT INTO #SundryRecurringPayables 
	Select P.PayableId, SPS.ReceivableId,SPS.SundryRecurringId, 1, LEF.Id
	FROM #PayableTemp P  
	JOIN SundryRecurringPaymentSchedules SPS ON P.SourceId = SPS.Id AND SPS.PayableId IS NULL AND P.SourceTable = @sundryRecurringPaymentScheduleSourceType
	JOIN SundryRecurrings S ON SPS.SundryRecurringId = S.Id  
	JOIN Contracts C ON S.ContractId = C.Id  
	JOIN LeaseFinances LEF ON S.ContractId = LEF.ContractId AND LEF.IsCurrent = 1;  

	INSERT INTO #SundryRecurringPayables 
	Select P.PayableId, SPS.ReceivableId,SPS.SundryRecurringId, 0 , LOF.Id
	FROM #PayableTemp P  
	JOIN SundryRecurringPaymentSchedules SPS ON P.PayableId = SPS.PayableId 
	JOIN SundryRecurrings S ON SPS.SundryRecurringId = S.Id  
	JOIN Contracts C ON S.ContractId = C.Id  
	JOIN LoanFinances LOF ON S.ContractId = LOF.ContractId AND LOF.IsCurrent = 1;

	INSERT INTO #SundryRecurringPayables 
	Select P.PayableId, SPS.ReceivableId,SPS.SundryRecurringId, 0 , LOF.Id
	FROM #PayableTemp P  
	JOIN SundryRecurringPaymentSchedules SPS ON P.SourceTable = @sundryRecurringPaymentScheduleSourceType AND P.SourceId = SPS.Id AND SPS.PayableId IS NULL   
	JOIN SundryRecurrings S ON SPS.SundryRecurringId = S.Id  
	JOIN Contracts C ON S.ContractId = C.Id  
	JOIN LoanFinances LOF ON S.ContractId = LOF.ContractId AND LOF.IsCurrent = 1;

	
	INSERT INTO #SundryRecurringPayables 
	Select P.PayableId, SPS.ReceivableId,SPS.SundryRecurringId, 0 , 0
	FROM #PayableTemp P  
	JOIN SundryRecurringPaymentSchedules SPS ON P.PayableId = SPS.PayableId   
	JOIN SundryRecurrings S ON SPS.SundryRecurringId = S.Id  Where P.PayableId not in (Select P.PayableId FROM #SundryRecurringPayables)
	UNION 
	(Select P.PayableId, SPS.ReceivableId,SPS.SundryRecurringId, 0 , 0
	FROM #PayableTemp P  
	JOIN SundryRecurringPaymentSchedules SPS ON  (P.SourceTable =  @sundryRecurringPaymentScheduleSourceType AND P.SourceId = SPS.Id)
	JOIN SundryRecurrings S ON SPS.SundryRecurringId = S.Id  Where P.PayableId not in (Select P.PayableId FROM #SundryRecurringPayables))

--CPI Receivables
SELECT P.PayableId, P.EntityType, P.EntityId, P.SourceTable, P.SourceId, P.PayableCurrency, P.PayableAmount, P.PayableBalance, P.PayableType, P.VendorId, NULL 'PayableInvoiceId', NULL 'AssetId', CONVERT(NVARCHAR, NULL) 'Alias', @assetFinancialTypeUnknown 'FinancialType', CONVERT(NVARCHAR, NULL) 'PartNumber', CONVERT(BIT, 0) 'UsePayDate',
(CASE WHEN R.EntityType = @ReceivableContractEntityType THEN LEF.InstrumentTypeId ELSE CPUA.InstrumentTypeId END)  'InstrumentTypeId',
C.Id 'ContractId', CONVERT(BIT, 1) 'IsFundingApproved', LEF.Id 'LeaseFinanceId', NULL 'LoanFinanceId', NULL 'LatestAssetValueHistoryId',
R.Id 'SundryReceivableId',
R.Id 'ReceivableId', P.PayableDueDate, CONVERT(NVARCHAR, NULL) 'AllocationMethod', NULL 'OtherCostId', CONVERT(BIT, 0) 'AssociateAssets', P.PayableRemitToId, CU.PartyName 'CustomerName', CU.PartyNumber 'CustomerNumber', C.SequenceNumber, CONVERT(NVARCHAR, NULL) 'InvoiceNumber',  CONVERT(BIT,0) 'IsProgressLoanPayable',
(CASE WHEN R.EntityType = @ReceivableContractEntityType THEN LEF.LineofBusinessId ELSE CPUA.LineofBusinessId END)  'LineofBusinessId' , (CASE WHEN C.Id IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END) 'HasContract', CONVERT(BIT,0) 'IsInvoiceTotalNegative', CONVERT(DATE, NULL) 'InvoiceDueDate', CONVERT(BIT, 0) 'IsChargeBackOtherCost', CONVERT(BIT, 0) 'IsCurrentContract', CONVERT(NVARCHAR, NULL) 'FundingType', (CASE WHEN P.PayableType = @dueToInvestorAPTransactinType THEN GLT.Id ELSE NULL END) 'MatchingGLTemplate', RT.Name 'ReceivableType', (CASE WHEN P.PayableType = @dueToInvestorAPTransactinType THEN RTX.GLTemplateId ELSE NULL END) 'SalesTaxGLTemplate',
(CASE WHEN R.EntityType = @ReceivableContractEntityType THEN LEF.CostCenterId ELSE CPUA.CostCenterId  END) 'CostCenterId',
P.IsInterCompany, CONVERT(NVARCHAR, NULL) 'VendorOrderNumber',null as 'BranchId', null as 'DiscountingId',NULL as 'InitialExchangeRate'
INTO #CPUTemp
	FROM #PayableTemp P
	JOIN Receivables R ON P.SourceId = R.Id AND P.SourceTable = @CPUPayableSourceType 
	JOIN CPUSchedules CPUS ON CPUS.Id = R.SourceId AND R.SourceTable = @CPUReceivableSourceType AND CPUS.IsActive = 1
	JOIN CPUFinances CPUF ON CPUS.CPUFinanceId = CPUF.Id 
	JOIN CPUAccountings CPUA ON CPUF.Id = CPUA.Id
	JOIN CPUTransactions CPUT ON CPUT.CPUFinanceId = CPUF.Id
	JOIN CPUContracts CPUC ON CPUC.Id = CPUT.CPUContractId
		AND 
		( 
			CPUC.Status = @CPUContractStatusCommenced
			OR CPUC.Status = @CPUContractStatusPaidoff
		)
	JOIN Parties CU ON CPUF.CustomerId = CU.Id
	LEFT JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType = @ReceivableContractEntityType
	LEFT JOIN LeaseFinances LEF ON C.Id = LEF.ContractId AND LEF.IsCurrent = 1
	LEFT JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	LEFT JOIN GLTemplates GLT ON RC.SyndicationGLTemplateId = GLT.Id
	LEFT JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId AND RTX.IsActive = 1;

	SELECT P.PayableId, P.EntityType, P.EntityId, P.SourceTable, P.SourceId, P.PayableCurrency, P.PayableAmount, P.PayableBalance, P.PayableType, P.VendorId, 
	NULL 'PayableInvoiceId', NULL 'AssetId', CONVERT(NVARCHAR, NULL) 'Alias', @assetFinancialTypeUnknown 'FinancialType', 
	CONVERT(NVARCHAR, NULL) 'PartNumber', CONVERT(BIT, 0) 'UsePayDate', S.InstrumentTypeId 'InstrumentTypeId', S.ContractId 'ContractId', CONVERT(BIT, 1) 'IsFundingApproved', 
	CASE WHEN IsLease = 1 THEN SPS.Id ELSE NULL END 'LeaseFinanceId', 
	CASE WHEN IsLease = 0 THEN SPS.Id ELSE NULL END 'LoanFinanceId',
	NULL 'LatestAssetValueHistoryId', S.Id 'SundryReceivableId', SPS.ReceivableId 'ReceivableId', P.PayableDueDate, 
	CONVERT(NVARCHAR, NULL) 'AllocationMethod', NULL 'OtherCostId', CONVERT(BIT, 0) 'AssociateAssets', P.PayableRemitToId, CU.PartyName 'CustomerName', 
	CU.PartyNumber 'CustomerNumber', C.SequenceNumber, CONVERT(NVARCHAR, NULL) 'InvoiceNumber',  CONVERT(BIT,0) 'IsProgressLoanPayable', S.LineofBusinessId, 
	(CASE WHEN C.Id IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END) 'HasContract', CONVERT(BIT,0) 'IsInvoiceTotalNegative', CONVERT(DATE, NULL) 'InvoiceDueDate', 
	CONVERT(BIT, 0) 'IsChargeBackOtherCost', CONVERT(BIT, 0) 'IsCurrentContract', CONVERT(NVARCHAR, NULL) 'FundingType', NULL 'MatchingGLTemplate', 
	CONVERT(NVARCHAR, NULL) 'ReceivableType', NULL 'SalesTaxGLTemplate', S.CostCenterId 'CostCenterId', P.IsInterCompany, CONVERT(NVARCHAR, NULL) 'VendorOrderNumber',NULL AS 'BranchId', NULL as 'DiscountingId',NUll as 'InitialExchangeRate'
	INTO #SundryRecurringTemp
	FROM #PayableTemp P
	JOIN #SundryRecurringPayables SPS ON P.PayableId = SPS.PayableId
	JOIN SundryRecurrings S ON SPS.SundryRecurringId = S.Id
	JOIN Parties CU ON S.CustomerId = CU.Id
	LEFT JOIN Contracts C ON S.ContractId = C.Id;

	SELECT P.PayableId, P.EntityType, P.EntityId, P.SourceTable, P.SourceId, P.PayableCurrency, P.PayableAmount, P.PayableBalance, P.PayableType, P.VendorId, NULL 'PayableInvoiceId', NULL 'AssetId', CONVERT(NVARCHAR, NULL) 'Alias', @assetFinancialTypeUnknown 'FinancialType', CONVERT(NVARCHAR, NULL) 'PartNumber', CONVERT(BIT, 0) 'UsePayDate', UR.InstrumentTypeId 'InstrumentTypeId', NULL 'ContractId', CONVERT(BIT, 1) 'IsFundingApproved', NULL 'LeaseFinanceId', NULL 'LoanFinanceId', NULL 'LatestAssetValueHistoryId', NULL 'SundryReceivableId', NULL 'ReceivableId', P.PayableDueDate, CONVERT(NVARCHAR, NULL) 'AllocationMethod', NULL 'OtherCostId', CONVERT(BIT, 0) 'AssociateAssets', P.PayableRemitToId, CONVERT(NVARCHAR, NULL) 'CustomerName', CONVERT(NVARCHAR, NULL) 'CustomerNumber', CONVERT(NVARCHAR, UR.Id) 'SequenceNumber', CONVERT(NVARCHAR, NULL) 'InvoiceNumber',  CONVERT(BIT,0) 'IsProgressLoanPayable', UR.LineofBusinessId, CONVERT(BIT, 0) 'HasContract', CONVERT(BIT,0) 'IsInvoiceTotalNegative', CONVERT(DATE, NULL) 'InvoiceDueDate', CONVERT(BIT, 0) 'IsChargeBackOtherCost', CONVERT(BIT, 0) 'IsCurrentContract', CONVERT(NVARCHAR, NULL) 'FundingType', ReceiptGLTemplateId 'MatchingGLTemplate', CONVERT(NVARCHAR, NULL) 'ReceivableType', NULL 'SalesTaxGLTemplate', R.CostCenterId 'CostCenterId', P.IsInterCompany, CONVERT(NVARCHAR, NULL) 'VendorOrderNumber',null as 'BranchId', NULL as 'DiscountingId',NULL as 'InitialExchangeRate'
	INTO #CashRefundTemp
	FROM #PayableTemp P
	JOIN UnallocatedRefunds UR ON P.EntityType = @unallocatedRefundEntityType AND P.EntityId = UR.Id
    JOIN UnallocatedRefundDetails URD ON UR.Id = URD.UnallocatedRefundId AND P.SourceTable = @receiptTableType
    JOIN Receipts R ON P.SourceId = R.Id;

	SELECT P.PayableId, P.EntityType, P.EntityId, P.SourceTable, P.SourceId, P.PayableCurrency, P.PayableAmount, P.PayableBalance, P.PayableType, P.VendorId, NULL 'PayableInvoiceId', NULL 'AssetId', CONVERT(NVARCHAR, NULL) 'Alias', @assetFinancialTypeUnknown 'FinancialType', CONVERT(NVARCHAR, NULL) 'PartNumber', CONVERT(BIT, 0) 'UsePayDate', NULL 'InstrumentTypeId', NULL 'ContractId', CONVERT(BIT, 1) 'IsFundingApproved', NULL 'LeaseFinanceId', NULL 'LoanFinanceId', NULL 'LatestAssetValueHistoryId', NULL 'SundryReceivableId', NULL 'ReceivableId', P.PayableDueDate, CONVERT(NVARCHAR, NULL) 'AllocationMethod', NULL 'OtherCostId', CONVERT(BIT, 0) 'AssociateAssets', P.PayableRemitToId, CONVERT(NVARCHAR, NULL) 'CustomerName', CONVERT(NVARCHAR, NULL) 'CustomerNumber', CONVERT(NVARCHAR, PPTI.Id) 'SequenceNumber', CONVERT(NVARCHAR, NULL) 'InvoiceNumber',  CONVERT(BIT,0) 'IsProgressLoanPayable', PPTI.LineofBusinessId 'LineofBusinessId', CONVERT(BIT, 0) 'HasContract', CONVERT(BIT,0) 'IsInvoiceTotalNegative', CONVERT(DATE, NULL) 'InvoiceDueDate', CONVERT(BIT, 0) 'IsChargeBackOtherCost', CONVERT(BIT, 0) 'IsCurrentContract', CONVERT(NVARCHAR, NULL) 'FundingType', NULL 'MatchingGLTemplate', CONVERT(NVARCHAR, NULL) 'ReceivableType', NULL 'SalesTaxGLTemplate', PPTI.CostCenterId 'CostCenterId', P.IsInterCompany, CONVERT(NVARCHAR, NULL) 'VendorOrderNumber',null as 'BranchId', null as 'DiscountingId',NULL as 'InitialExchangeRate'
	INTO #PPTInvoiceTemp
	FROM #PayableTemp P
	JOIN PPTInvoices PPTI ON P.EntityType = @PPTInvoiceEntityType AND P.EntityId = PPTI.Id;
	
;WITH CTE_CTE_DistinctAssetIds AS(
	SELECT DISTINCT AssetId FROM  
		(SELECT AssetId FROM #LeaseAssetTemp
		 UNION
	     SELECT AssetId FROM #PPCAssetTemp
		 ) A
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM CTE_CTE_DistinctAssetIds A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)

	SELECT DISTINCT PD.PayableId, PD.CustomerName, PD.CustomerNumber, PD.EntityType, PD.EntityId, PD.SourceTable, PD.SourceId, PD.PayableCurrency, PD.PayableAmount, PD.PayableBalance, PD.SequenceNumber 'Transaction', PD.LoanFinanceId 'ProgressLoanId', PD.PayableInvoiceId, PD.InvoiceNumber 'PayableInvoiceNumber', PD.PayableType, PD.PayableDueDate 'DueDate', PD.AssetId, PD.Alias, PD.FinancialType 'AssetType', ASN.SerialNumber, PD.PartNumber, PD.VendorId, PD.UsePayDate, PD.IsProgressLoanPayable, PD.LatestAssetValueHistoryId 'AssetValueHistoryId', PD.InstrumentTypeId, PD.LineofBusinessId, PD.HasContract, PD.IsChargeBackOtherCost, PD.SundryReceivableId 'SundryId', PD.ReceivableId 'ReceivableId', PD.ContractId, PD.AllocationMethod 'OtherCostAllocationMethod', PD.IsFundingApproved, PD.OtherCostId, PD.LeaseFinanceId, PD.AssociateAssets, PD.LoanFinanceId, PD.IsInvoiceTotalNegative, PD.PayableRemitToId, PD.InvoiceDueDate, PD.IsCurrentContract, PD.FundingType, PD.MatchingGLTemplate, PD.ReceivableType, PD.SalesTaxGLTemplate, PD.CostCenterId, PD.IsInterCompany, PD.VendorOrderNumber, PD.BranchId, PD.DiscountingId,PD.InitialExchangeRate
    FROM (SELECT * FROM #LeaseAssetTemp
	      UNION
	      SELECT * FROM #LoanOtherCostTemp
	      UNION
	      SELECT * FROM #LeaseOtherCostTemp
	      UNION
	      SELECT * FROM #PPCAssetTemp
		  UNION
		  SELECT * FROM #SundryTemp
		  UNION
		  SELECT * FROM #SundryRecurringTemp
		  UNION
		  SELECT * FROM #CashRefundTemp
          UNION
		  SELECT * FROM #PPTInvoiceTemp
		  UNION
		  SELECT * FROM #CPUTemp
		  ) PD
	LEFT JOIN CTE_AssetSerialNumberDetails ASN ON PD.AssetId = ASN.AssetId;

    DROP TABLE #PayableIds;
    DROP TABLE #LeaseAssetTemp;
    DROP TABLE #LeaseOtherCostTemp;
	DROP TABLE #LoanOtherCostTemp
    DROP TABLE #PayableTemp;
    DROP TABLE #PPCAssetTemp;
	DROP TABLE #SundryTemp;
	DROP TABLE #InterimRentSharingPayable
	DROP TABLE #SundryRecurringTemp;
	DROP TABLE #CashRefundTemp;
	DROP TABLE #PPTInvoiceTemp;
    DROP TABLE #LeaseAssetIdTemp;
	DROP TABLE #LeasePayableFinanceMapping;
	DROP TABLE #CPUTemp;
    SET NOCOUNT OFF;
END

GO

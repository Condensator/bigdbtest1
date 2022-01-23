SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetReceivableForGLPostingDetails]
(
	@RecTaxIdList RecTaxIds					   READONLY,
	@ReceivableSourceTableSecurityDepositValue NVarChar(20),
	@ReceivableSourceTableSundryValue		   NVarChar(20),
	@ReceivableSourceTableSundryRecurringValue NVarChar(20),
	@ReceivableSourceTableCPUScheduleValue	   NVarChar(20),
	@ReceivableSourceTableAssetSaleReceivable  NVarChar(20),
	@ReceivableEntityTypeCTValue			   NVarChar(2),
	@ReceivableEntityTypeCUValue			   NVarChar(2),
	@ReceivableEntityTypeDTValue			   NVarChar(2),
	@ContractTypeLoanValue					   NVarChar(14),
	@ContractTypeProgressLoanValue			   NVarChar(14),
	@ContractTypeLeaseValue					   NVarChar(14),
	@LoanApprovalStatusRejectedValue		   NVarChar(25),
	@LoanApprovalStatusPendingValue			   NVarChar(25),
	@DiscountingApprovalStatusApprovedValue	   NVarChar(20),
	@SyndicationTypeUnknownValue			   NVarChar(16),
	@SyndicationTypeNoneValue				   NVarChar(16)
)  
AS  
BEGIN  
	SET NOCOUNT ON; 
	
	CREATE TABLE #ReceivableGLInfoSummary
	(
		ReceivableTaxId				BIGINT NULL,
		InstrumentTypeId			BIGINT NULL,
		CostCenterId				BIGINT NULL,
		LineOfBusinessId			BIGINT NULL,
		DiscountingId				BIGINT NULL,
		SequenceNumber				NVARCHAR(40) NULL,
		BranchId					BIGINT NULL,
		DiscountingApprovalStatus	NVARCHAR(20),
		DiscountingFinanceId		BIGINT NULL,
		SundryRecurringId			BIGINT NULL,		
		SundryId					BIGINT NULL,
		AssetSaleId					BIGINT NULL,
		CPUAccountingId			    BIGINT NULL,
		SecurityDepositId			BIGINT NULL
	)

	CREATE TABLE #DiscountingInfoSummary
	(
		ReceivableTaxId				BIGINT NULL,
		InstrumentTypeId			BIGINT NULL,
		CostCenterId				BIGINT NULL,
		LineOfBusinessId			BIGINT NULL,
		DiscountingId				BIGINT NULL,
		SequenceNumber				NVARCHAR(40) NULL,
		BranchId					BIGINT NULL,
		DiscountingApprovalStatus	NVARCHAR(20),
		DiscountingFinanceId		BIGINT NULL,
		SundryRecurringId			BIGINT NULL,		
		SundryId					BIGINT NULL,
		AssetSaleId					BIGINT NULL,
		CPUAccountingId			    BIGINT NULL,
		SecurityDepositId			BIGINT NULL
	)


	CREATE TABLE #ContractSummary
	(
		ReceivableTaxId				BIGINT NULL,
		ContractId				    BIGINT NULL,
		LoanFinanceId				BIGINT NULL,
		ContractType				NVARCHAR(25) NULL,
		ContractSequenceNumber		NVARCHAR(40) NULL,
		SyndicationType				NVARCHAR(16) NULL,
		InstrumentTypeId		    BIGINT NULL,
		CostCenterId				BIGINT NULL,
		AcquisitionId				NVARCHAR(12),
		leasePaymentScheduleId		BIGINT NULL,
		loanPaymentScheduleId		BIGINT NULL,
		ReceivableForTransferType	NVARCHAR(20) NULL,
		ReceivableForTransferId		BIGINT NULL,
		LeasePaySchStartDate		DATE NULL,
		LoanPaySchStartDate			DATE NULL,
		LeaseBranchId				BIGINT NULL,
		LoanBranchId				BIGINT NULL,
		LoanApprovalStatus			NVARCHAR(50) NULL,
		DealProductTypeId			BIGINT NULL,
		LineofBusinessId			BIGINT NULL,
		EffectiveDate				DATE NULL
	)

	CREATE TABLE #PrepaidReceivableDetail
	(
		ReceivableId BIGINT NULL,
	    ReceivableTaxId BIGINT NULL,
		PrepaidTaxAmount DECIMAL(16,2) NULL
	)

	CREATE TABLE #ReceivableTaxSummary
	(
		ReceivableTaxId BIGINT NULL,
		ReceivableId BIGINT NULL,
		GlTemplateId BIGINT NULL,
		CurrencyCode NVARCHAR(3) NULL,
		IsCashBased BIT NULL,
		Amount DECIMAL(16,2) NULL,
		Balance  DECIMAL(16,2) NULL,
		IsCollected BIT NULL,
		SourceId BIGINT NULL,
		SourceTable NVARCHAR(20) NULL,
		DueDate DATE NULL,
		CustomerId BIGINT NULL,
		EntityId BIGINT NULL,
		EntityType NVARCHAR(2) NULL,
		PaymentScheduleId BIGINT NULL,
		IsIntercompany BIT NULL,
		LegalEntityId BIGINT NULL,
		ReceivableCode NVARCHAR(100) NULL,
		AccntTreatment NVARCHAR(12) NULL,
		ReceivableType NVARCHAR(21) NULL,
		TaxGLTemplateId BIGINT NULL,
		SynGLTemplateId BIGINT NULL,
		GLTranTypeName NVARCHAR(29) NULL,
		FunderId BIGINT NULL 
	)

	CREATE NONCLUSTERED INDEX IX_ReceivableTaxSummary_ReceivableTaxId 
	ON #ReceivableTaxSummary(ReceivableTaxId);


	--Get All Receivable related details from all table
	INSERT INTO #ReceivableTaxSummary
	SELECT 
		ReceivableTaxId   = receivableTax.Id, 
		ReceivableId      = receivable.Id, 
		GlTemplateId      = recCode.GlTemplateId, 
		CurrencyCode      = receivableTaxDetail.Cost_Currency, 
		IsCashBased       = receivableTax.IsCashBased,
		Amount            = SUM(receivableTaxDetail.Amount_Amount),
		Balance			  =SUM(receivableTaxDetail.Balance_Amount),
		IsCollected       = receivable.IsCollected,
		SourceId	      = receivable.SourceId,
		SourceTable       = receivable.SourceTable,
		DueDate           = receivable.DueDate,
		CustomerId        = receivable.CustomerId,
		EntityId		  = receivable.EntityId,
		EntityType        = receivable.EntityType,
		PaymentScheduleId = receivable.PaymentScheduleId,
		IsIntercompany	  = customer.IsIntercompany,
		LegalEntityId     = receivable.LegalEntityId,
		ReceivableCode	  = recCode.[Name],
		AccntTreatment	  = recCode.AccountingTreatment,
		ReceivableType	  = recType.[Name],
		TaxGLTemplateId	  = receivableTax.GlTemplateId,
		SynGLTemplateId	  = recCode.SyndicationGLTemplateId,
		GLTranTypeName	  = glTransactionType.[Name],
		FunderId          = receivable.FunderId
	FROM @RecTaxIdList recTaxList
	JOIN ReceivableTaxes receivableTax ON recTaxList.Id = receivableTax.Id
	JOIN Receivables receivable ON receivableTax.ReceivableId = receivable.Id
	JOIN ReceivableCodes recCode ON receivable.ReceivableCodeId = recCode.Id
	JOIN ReceivableTypes recType ON recCode.ReceivableTypeId = recType.Id
	JOIN GLTransactionTypes glTransactionType ON recType.GLTransactionTypeId = glTransactionType.Id
	JOIN Parties customer ON receivable.CustomerId = customer.Id
	JOIN GLTemplates glTemplate ON receivableTax.GLTemplateId = glTemplate.Id
	JOIN ReceivableTaxDetails receivableTaxDetail ON  receivableTax.Id = receivableTaxDetail.ReceivableTaxId
	AND receivableTaxDetail.IsGLPosted = 1 AND receivableTaxDetail.IsActive  = 1
	GROUP BY receivableTax.Id, receivable.Id, recCode.GlTemplateId, receivableTaxDetail.Cost_Currency, receivableTax.IsCashBased,
	receivable.IsCollected, receivable.SourceId, receivable.SourceTable, receivable.DueDate, receivable.CustomerId,
	receivable.EntityType,receivable.PaymentScheduleId, customer.IsIntercompany, receivable.LegalEntityId, receivable.EntityId, 
	recCode.[Name], recCode.AccountingTreatment, recType.[Name],receivableTax.GlTemplateId,recCode.SyndicationGLTemplateId, 
	glTransactionType.[Name],receivable.FunderId

	--Get Balance for each ReceivableIds from prepaidReceivable
	INSERT INTO #PrepaidReceivableDetail(ReceivableId,ReceivableTaxId,PrepaidTaxAmount)
	SELECT 
			ReceivableId	  = receivableTaxSummary.ReceivableId,
			ReceivableTaxId	  = receivableTaxSummary.ReceivableTaxId, 
			PrepaidTaxAmount  = SUM(prepaidReceivable.PrePaidTaxAmount_Amount)
	FROM #ReceivableTaxSummary receivableTaxSummary
	JOIN PrepaidReceivables prepaidReceivable ON receivableTaxSummary.ReceivableId = prepaidReceivable.ReceivableId AND prepaidReceivable.IsActive = 1
	GROUP BY receivableTaxSummary.ReceivableId, receivableTaxSummary.ReceivableTaxId

	--Build SecurityDeposit Summary from selected ReceivableTax Ids
	IF EXISTS (SELECT 1 FROM #ReceivableTaxSummary WHERE SourceTable = @ReceivableSourceTableSecurityDepositValue )
	BEGIN
		INSERT INTO #ReceivableGLInfoSummary(ReceivableTaxId, SecurityDepositId,InstrumentTypeId, CostCenterId, LineOfBusinessId)
		SELECT 
			ReceivableTaxId	  = receivableTaxSummary.ReceivableTaxId, 
			SecurityDepositId = securityDeposit.Id,
			InstrumentTypeId  = CASE WHEN securityDeposit.Id IS NOT NULL THEN securityDeposit.InstrumentTypeId ELSE NULL END,
			CostCenterId	  = CASE WHEN securityDeposit.Id IS NOT NULL THEN securityDeposit.CostCenterId ELSE NULL END,
			LineOfBusinessId  = CASE WHEN securityDeposit.Id IS NOT NULL THEN securityDeposit.LineofBusinessId ELSE NULL END
		FROM #ReceivableTaxSummary receivableTaxSummary
		JOIN SecurityDeposits securityDeposit ON receivableTaxSummary.SourceTable = @ReceivableSourceTableSecurityDepositValue
		AND receivableTaxSummary.SourceId = securityDeposit.Id
	END
	--Build Loan and Lease Summary from selected ReceivableTax Ids
	IF EXISTS (SELECT 1 FROM #ReceivableTaxSummary WHERE EntityType= @ReceivableEntityTypeCTValue )
	BEGIN
		INSERT INTO #ContractSummary
		SELECT 
			ReceivableTaxId			   = receivableTaxSummary.ReceivableTaxId, 
			ContractId				   = [contract].Id,
			LoanFinanceId			   = loanFinance.Id,
			ContractType			   = [contract].ContractType,
			ContractSequenceNumber	   = [contract].SequenceNumber,
			SyndicationType			   = [contract].SyndicationType,
			InstrumentTypeId	       = loanFinance.InstrumentTypeId,
			CostCenterId			   = loanFinance.CostCenterId,
			AcquisitionId			   = loanFinance.AcquisitionID,
			leasePaymentScheduleId	   = NULL,
			loanPaymentScheduleId	   = loanPaymentSchedule.Id,
			ReceivableForTransferType  = receivableForTransfer.ReceivableForTransferType,
			ReceivableForTransferId	   = receivableForTransfer.Id,
			LeasePaySchStartDate       = NULL,
			LoanPaySchStartDate        = loanPaymentSchedule.StartDate,
			LeaseBranchId			   = NULL,
			LoanBranchId			   = loanFinance.BranchId,
			LoanApprovalStatus		   = loanFinance.ApprovalStatus,
			DealProductTypeId          = [contract].DealProductTypeId,
			LineofBusinessId		   = [contract].LineofBusinessId,
			EffectiveDate			   = CASE WHEN receivableForTransfer.Id IS NOT NULL 
											  THEN (CASE WHEN receivableForTransfer.LoanPaymentId IS NOT NULL 
																			   THEN loanPaymentSchedule.StartDate 
																			   ELSE NULL END)
											  ELSE NULL END
		FROM #ReceivableTaxSummary receivableTaxSummary
		JOIN Contracts [contract] ON receivableTaxSummary.EntityId = [contract].Id AND receivableTaxSummary.EntityType= @ReceivableEntityTypeCTValue
		JOIN LoanFinances loanFinance ON [contract].Id = loanFinance.ContractId AND loanFinance.IsCurrent = 1
		LEFT JOIN LoanPaymentSchedules loanPaymentSchedule ON receivableTaxSummary.PaymentScheduleId = loanPaymentSchedule.Id
		AND ( [contract].ContractType = @ContractTypeLoanValue OR [contract].ContractType = @ContractTypeProgressLoanValue)
		LEFT JOIN ReceivableForTransfers receivableForTransfer ON [contract].Id = receivableForTransfer.ContractId

		INSERT INTO #ContractSummary
		SELECT 
			ReceivableTaxId			   = receivableTaxSummary.ReceivableTaxId, 
			ContractId				   = [contract].Id,
			LoanFinanceId			   = NULL,
			ContractType			   = [contract].ContractType,
			ContractSequenceNumber	   = [contract].SequenceNumber,
			SyndicationType			   = [contract].SyndicationType,
			InstrumentTypeId	       = leaseFinance.InstrumentTypeId,
			CostCenterId			   = leaseFinance.CostCenterId,
			AcquisitionId			   = leaseFinance.AcquisitionID,
			leasePaymentScheduleId	   = leasePaymentSchedule.Id,
			loanPaymentScheduleId	   = NULL,
			ReceivableForTransferType  = receivableForTransfer.ReceivableForTransferType,
			ReceivableForTransferId	   = receivableForTransfer.Id,
			LeasePaySchStartDate       = leasePaymentSchedule.StartDate,
			LoanPaySchStartDate        = NULL,
			LeaseBranchId			   = leaseFinance.BranchId,
			LoanBranchId			   = NULL,
			LoanApprovalStatus		   = NULL,
			DealProductTypeId          = [contract].DealProductTypeId,
			LineofBusinessId		   = [contract].LineofBusinessId,
			EffectiveDate			   = CASE WHEN receivableForTransfer.Id IS NOT NULL 
											  THEN (CASE WHEN receivableForTransfer.LeasePaymentId IS NOT NULL 
																			   THEN leasePaymentSchedule.StartDate 
																			   ELSE NULL END)
											  ELSE NULL END
		FROM #ReceivableTaxSummary receivableTaxSummary
		JOIN Contracts [contract] ON receivableTaxSummary.EntityId = [contract].Id AND receivableTaxSummary.EntityType= @ReceivableEntityTypeCTValue AND [contract].ContractType = @ContractTypeLeaseValue
		JOIN LeaseFinances leaseFinance ON [contract].Id = leaseFinance.ContractId AND leaseFinance.IsCurrent = 1
		LEFT JOIN LeasePaymentSchedules leasePaymentSchedule ON receivableTaxSummary.PaymentScheduleId = leasePaymentSchedule.Id 
		LEFT JOIN ReceivableForTransfers receivableForTransfer ON [contract].Id = receivableForTransfer.ContractId

		INSERT INTO #ContractSummary
		SELECT 
			ReceivableTaxId			   = receivableTaxSummary.ReceivableTaxId, 
			ContractId				   = [contract].Id,
			LoanFinanceId			   = NULL,
			ContractType			   = [contract].ContractType,
			ContractSequenceNumber	   = [contract].SequenceNumber,
			SyndicationType			   = [contract].SyndicationType,
			InstrumentTypeId	       = leveragedLease.InstrumentTypeId,
			CostCenterId			   = leveragedLease.CostCenterId,
			AcquisitionId			   = leveragedLease.AcquisitionID,
			leasePaymentScheduleId	   = NULL,
			loanPaymentScheduleId	   = NULL,
			ReceivableForTransferType  = NULL,
			ReceivableForTransferId	   = NULL,
			LeasePaySchStartDate       = NULL,
			LoanPaySchStartDate        = NULL,
			LeaseBranchId			   = NULL,
			LoanBranchId			   = NULL,
			LoanApprovalStatus		   = NULL,
			DealProductTypeId          = [contract].DealProductTypeId,
			LineofBusinessId		   = [contract].LineofBusinessId,
			EffectiveDate			   = NULL
		FROM #ReceivableTaxSummary receivableTaxSummary
		JOIN Contracts [contract] ON receivableTaxSummary.EntityId = [contract].Id AND receivableTaxSummary.EntityType= @ReceivableEntityTypeCTValue
		JOIN LeveragedLeases leveragedLease ON [contract].Id = leveragedLease.ContractId AND leveragedLease.IsCurrent = 1

	END

	--Build Discounting Summary from selected ReceivableTax Ids
	IF EXISTS (SELECT 1 FROM #ReceivableTaxSummary WHERE EntityType= @ReceivableEntityTypeDTValue)
	BEGIN
		INSERT INTO #DiscountingInfoSummary(ReceivableTaxId,DiscountingId,SequenceNumber, InstrumentTypeId, CostCenterId,  BranchId, DiscountingApprovalStatus, DiscountingFinanceId)
		SELECT
			ReceivableTaxId				= receivableTaxSummary.ReceivableTaxId, 
			DiscountingId			    = discounting.Id,
			SequenceNumber			    = discounting.SequenceNumber,
			InstrumentTypeId			= CASE WHEN discountingFinance.Id IS NOT NULL THEN discountingFinance.InstrumentTypeId ELSE NULL END,
			CostCenterId				= CASE WHEN discountingFinance.Id IS NOT NULL THEN discountingFinance.CostCenterId ELSE NULL END,
			BranchId					= discountingFinance.Id,
			DiscountingApprovalStatus	= discountingFinance.ApprovalStatus,
			DiscountingFinanceId		= discountingFinance.Id
		FROM #ReceivableTaxSummary receivableTaxSummary
		JOIN Discountings discounting ON receivableTaxSummary.EntityId = discounting.Id AND receivableTaxSummary.EntityType = @ReceivableEntityTypeDTValue
		JOIN DiscountingFinances discountingFinance ON discounting.Id = discountingFinance.DiscountingId 
		AND discountingFinance.IsCurrent = 1
	END

	--Build SundryRecurring Summary from selected ReceivableTax Ids
	IF EXISTS (SELECT 1 FROM #ReceivableTaxSummary WHERE SourceTable = @ReceivableSourceTableSundryRecurringValue )
	BEGIN
		INSERT INTO #ReceivableGLInfoSummary(ReceivableTaxId,InstrumentTypeId,CostCenterId, LineOfBusinessId, SundryRecurringId)
		SELECT 
			ReceivableTaxId	  = receivableTaxSummary.ReceivableTaxId,
			InstrumentTypeId  = CASE WHEN sundryRecurring.Id IS NOT NULL THEN sundryRecurring.InstrumentTypeId ELSE NULL END,
			CostCenterId	  = CASE WHEN sundryRecurring.Id IS NOT NULL THEN sundryRecurring.CostCenterId ELSE NULL END,
			LineOfBusinessId  = CASE WHEN sundryRecurring.Id IS NOT NULL THEN sundryRecurring.LineOfBusinessId ELSE NULL END,
			SundryRecurringId = sundryRecurring.Id
		FROM #ReceivableTaxSummary receivableTaxSummary
		JOIN SundryRecurringPaymentSchedules sundryRecurringPaymentSchedule ON receivableTaxSummary.SourceTable = @ReceivableSourceTableSundryRecurringValue AND receivableTaxSummary.SourceId = sundryRecurringPaymentSchedule.Id
		JOIN SundryRecurrings sundryRecurring ON sundryRecurringPaymentSchedule.SundryRecurringId = sundryRecurring.Id
	END

	--Build Sundry Summary from selected ReceivableTax Ids
	IF EXISTS (SELECT 1 FROM #ReceivableTaxSummary WHERE SourceTable = @ReceivableSourceTableSundryValue )
	BEGIN
		INSERT INTO #ReceivableGLInfoSummary(ReceivableTaxId,InstrumentTypeId,CostCenterId, LineOfBusinessId, SundryId)
		SELECT 
			ReceivableTaxId   = receivableTaxSummary.ReceivableTaxId,
			InstrumentTypeId  = CASE WHEN sundry.Id IS NOT NULL THEN sundry.InstrumentTypeId ELSE NULL END,
			CostCenterId	  = CASE WHEN sundry.Id IS NOT NULL THEN sundry.CostCenterId ELSE NULL END,
			LineOfBusinessId  = CASE WHEN sundry.Id IS NOT NULL THEN sundry.LineOfBusinessId ELSE NULL END,
			SundryId	      = sundry.Id
		FROM #ReceivableTaxSummary receivableTaxSummary
		JOIN Sundries sundry ON receivableTaxSummary.SourceTable = @ReceivableSourceTableSundryValue AND receivableTaxSummary.SourceId = sundry.Id
	END

	--Build AssetSales Summary from selected ReceivableTax Ids
	IF EXISTS (SELECT 1 FROM #ReceivableTaxSummary WHERE SourceTable = @ReceivableSourceTableSundryValue )
	BEGIN
		INSERT INTO #ReceivableGLInfoSummary(ReceivableTaxId,InstrumentTypeId,CostCenterId,LineOfBusinessId, AssetSaleId)
		SELECT 
			ReceivableTaxId		= receivableTaxSummary.ReceivableTaxId, 
			InstrumentTypeId	= CASE WHEN assetSale.Id IS NOT NULL THEN assetSale.InstrumentTypeId ELSE NULL END,
			CostCenterId		= CASE WHEN assetSale.Id IS NOT NULL THEN assetSale.CostCenterId ELSE NULL END,
			LineOfBusinessId	= CASE WHEN assetSale.Id IS NOT NULL THEN assetSale.LineofBusinessId ELSE NULL END,
			AssetSaleId			= assetSale.Id
		FROM #ReceivableTaxSummary receivableTaxSummary
		JOIN AssetSaleReceivables assetSaleReceivable ON receivableTaxSummary.SourceTable = @ReceivableSourceTableAssetSaleReceivable
		AND receivableTaxSummary.SourceId = assetSaleReceivable.Id AND receivableTaxSummary.EntityType = @ReceivableEntityTypeCUValue
		JOIN AssetSales assetSale ON assetSaleReceivable.AssetSaleId = assetSale.Id
	END

	--Build CPUSchedules Summary from selected ReceivableTax Ids
	IF EXISTS (SELECT 1 FROM #ReceivableTaxSummary WHERE SourceTable = @ReceivableSourceTableCPUScheduleValue )
	BEGIN
		INSERT INTO #ReceivableGLInfoSummary(ReceivableTaxId,InstrumentTypeId,CostCenterId, LineOfBusinessId, CPUAccountingId, BranchId)
		SELECT 
			ReceivableTaxId		  = receivableTaxSummary.ReceivableTaxId, 
			InstrumentTypeId	  = CASE WHEN cpuAccounting.Id IS NOT NULL THEN cpuAccounting.InstrumentTypeId ELSE NULL END,
			CostCenterId		  = CASE WHEN cpuAccounting.Id IS NOT NULL THEN cpuAccounting.CostCenterId ELSE NULL END,
			LineOfBusinessId	  = CASE WHEN cpuAccounting.Id IS NOT NULL THEN cpuAccounting.LineofBusinessId ELSE NULL END,
			CPUAccountingId		  = cpuAccounting.Id,
			BranchId			  = cpuAccounting.BranchId
		FROM #ReceivableTaxSummary receivableTaxSummary
		JOIN CPUSchedules cpuSchedule ON receivableTaxSummary.SourceTable = @ReceivableSourceTableCPUScheduleValue
		AND receivableTaxSummary.SourceId = cpuSchedule.Id AND receivableTaxSummary.EntityType = @ReceivableEntityTypeCUValue
		JOIN CPUAccountings cpuAccounting ON cpuSchedule.CPUFinanceId = cpuAccounting.Id
	END

	--Final Select Queries for GLReversal
	SELECT 
		ReceivableId					= receivableTaxSummary.ReceivableId,
		ReceivableCode					= receivableTaxSummary.ReceivableCode,
		ReceivableTaxId					= receivableTaxSummary.ReceivableTaxId,
		AccountingTreatment				= receivableTaxSummary.AccntTreatment,
		EntityType					    = receivableTaxSummary.EntityType,
		ContractId						= leaseORLoanSummary.ContractId,
		DiscountingId					= discountingInfoSummary.DiscountingId,
		ContractType					= leaseORLoanSummary.ContractType,
		SequenceNumber					= CASE WHEN leaseORLoanSummary.ContractSequenceNumber IS NOT NULL 
											   THEN leaseORLoanSummary.ContractSequenceNumber 
											   ELSE discountingInfoSummary.SequenceNumber
											   END,
		DueDate							= receivableTaxSummary.DueDate,
		ReceivableType					= receivableTaxSummary.ReceivableType,
		LegalEntityId					= receivableTaxSummary.LegalEntityId,
		CustomerId						= receivableTaxSummary.CustomerId,
		TotalAmount						= receivableTaxSummary.Amount,
		TotalBalance					= CASE WHEN ISNULL(prepaidReceivableDetail.PrepaidTaxAmount ,0) > 0
				   	  					 THEN receivableTaxSummary.Amount - prepaidReceivableDetail.PrepaidTaxAmount
				   	  					 ELSE receivableTaxSummary.Balance END,
		Currency						= receivableTaxSummary.CurrencyCode,
		SecurityDepositId				= receivableGLInfoSummary.SecurityDepositId,
		IsSyndicated					= CAST( CASE WHEN leaseORLoanSummary.ContractId IS NOT NULL AND leaseORLoanSummary.SyndicationType !=											@SyndicationTypeUnknownValue AND leaseORLoanSummary.SyndicationType !=														@SyndicationTypeNoneValue AND leaseORLoanSummary.EffectiveDate IS NOT NULL AND													receivableTaxSummary.DueDate >= leaseORLoanSummary.EffectiveDate THEN 1 ELSE 0 END AS BIT),
		GLTemplateId					= receivableTaxSummary.GlTemplateId,
		TaxGLTemplateId					= receivableTaxSummary.TaxGLTemplateId,
		SyndicationGLTemplateId			= receivableTaxSummary.SynGLTemplateId,
		InstrumentTypeId			    = CASE WHEN leaseORLoanSummary.InstrumentTypeId IS NOT NULL THEN					                                                    leaseORLoanSummary.InstrumentTypeId WHEN receivableGLInfoSummary.InstrumentTypeId IS NOT NULL
											THEN receivableGLInfoSummary.InstrumentTypeId ELSE discountingInfoSummary.InstrumentTypeId
											END,
		SundryId						= receivableGLInfoSummary.SundryId,
		SourceTable						= receivableTaxSummary.SourceTable,
		SourceId						= receivableTaxSummary.SourceId,
		ReceivableForTransferType		= leaseORLoanSummary.ReceivableForTransferType,
		ReceivableForTransferId			= leaseORLoanSummary.ReceivableForTransferId,
		CostCenterId					= CASE WHEN leaseORLoanSummary.CostCenterId IS NOT NULL THEN leaseORLoanSummary.CostCenterId
											   WHEN receivableGLInfoSummary.CostCenterId IS NOT NULL THEN receivableGLInfoSummary.CostCenterId
											   ELSE discountingInfoSummary.CostCenterId END,
		LineOfBusinessId				= CASE WHEN leaseORLoanSummary.LineofBusinessId IS NOT NULL THEN leaseORLoanSummary.LineofBusinessId										ELSE receivableGLInfoSummary.LineOfBusinessId END,
		IsIntercompany					= receivableTaxSummary.IsIntercompany,
		BranchId						= CASE WHEN leaseORLoanSummary.LoanBranchId IS NOT NULL THEN leaseORLoanSummary.LoanBranchId  									             WHEN leaseORLoanSummary.LeaseBranchId IS NOT NULL THEN leaseORLoanSummary.LeaseBranchId ELSE 									     receivableGLInfoSummary.BranchId END,
		IsCashBasedReceivableTax		= receivableTaxSummary.IsCashBased,
		IsCollected						= receivableTaxSummary.IsCollected,
		LeasePaySchStartDate			= leaseORLoanSummary.LeasePaySchStartDate,
		LoanPaySchStartDate				= leaseORLoanSummary.LoanPaySchStartDate,
		ReceivableGLTransactionType		= receivableTaxSummary.GLTranTypeName,
		AcquisitionId					= leaseORLoanSummary.AcquisitionId,
		SyndicationType					= leaseORLoanSummary.SyndicationType,
		DealProductTypeId,
		FunderId						= receivableTaxSummary.FunderId
	FROM #ReceivableTaxSummary receivableTaxSummary
	LEFT JOIN #PrepaidReceivableDetail prepaidReceivableDetail ON receivableTaxSummary.ReceivableTaxId = prepaidReceivableDetail.ReceivableTaxId
	LEFT JOIN #ReceivableGLInfoSummary receivableGLInfoSummary ON receivableTaxSummary.ReceivableTaxId = receivableGLInfoSummary.ReceivableTaxId
	LEFT JOIN #ContractSummary leaseORLoanSummary ON receivableTaxSummary.ReceivableTaxId = leaseORLoanSummary.ReceivableTaxId
	LEFT JOIN #DiscountingInfoSummary discountingInfoSummary ON receivableTaxSummary.ReceivableTaxId = discountingInfoSummary.ReceivableTaxId
	WHERE  ((
		(CASE 
			WHEN (leaseORLoanSummary.leasePaymentScheduleId IS NOT NULL) OR (leaseORLoanSummary.loanPaymentScheduleId IS NOT NULL) THEN 
				(CASE 
					WHEN (receivableTaxSummary.SourceTable <> @ReceivableSourceTableSundryRecurringValue) OR (receivableTaxSummary.SourceTable <> @ReceivableSourceTableCPUScheduleValue) THEN 1
					WHEN NOT ( (receivableTaxSummary.SourceTable <> @ReceivableSourceTableSundryRecurringValue) OR (receivableTaxSummary.SourceTable <> @ReceivableSourceTableCPUScheduleValue)) THEN 0
					ELSE NULL
				 END)
			ELSE 1
		 END)) = 1) AND ((leaseORLoanSummary.LoanFinanceId IS NULL) OR ((leaseORLoanSummary.LoanApprovalStatus <> @LoanApprovalStatusRejectedValue) AND (leaseORLoanSummary.LoanApprovalStatus <> @LoanApprovalStatusPendingValue))) AND ((discountingInfoSummary.DiscountingFinanceId IS NULL) OR (discountingInfoSummary.DiscountingApprovalStatus = @DiscountingApprovalStatusApprovedValue))

END

GO

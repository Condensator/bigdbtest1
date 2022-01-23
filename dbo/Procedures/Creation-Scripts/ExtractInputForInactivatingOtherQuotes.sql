SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ExtractInputForInactivatingOtherQuotes]
(
	@LeaseIds InactivationOtherQuote_LeaseInput READONLY,
	@AssumptionApprovalStatusApprovedValue NVARCHAR(50),
	@AssumptionApprovalStatusInactiveValue NVARCHAR(50),
	@ContractAmendmentStatusApprovedValue NVARCHAR(50),
	@ContractAmendmentStatusInactiveValue NVARCHAR(50),
	@ContractAmendmentTypeRebookValue NVARCHAR(50),
	@ContractAmendmentTypeRestructureValue NVARCHAR(50),
	@ContractAmendmentTypeRenewalValue NVARCHAR(50),
	@ContractAmendmentTypeNBVImpairmentValue NVARCHAR(50),
	@ContractAmendmentTypeResidualImpairmentValue NVARCHAR(50),
	@ContractTypeLeaseValue NVARCHAR(50),
	@ReceivableForTransferApprovalStatusInactiveValue NVARCHAR(50),
	@ReceivableForTransferApprovalStatusApprovedValue NVARCHAR(50),
	@PayoffStatusActivatedValue NVARCHAR(50),
	@PayoffStatusInactiveValue NVARCHAR(50),
	@PayoffStatusReversedValue NVARCHAR(50)
)
AS
BEGIN
SET NOCOUNT ON;

	SELECT 
		PayoffId = payoff.Id
	FROM @LeaseIds Header
	JOIN LeaseFinances LF ON Header.LeaseFinanceId = LF.Id
	JOIN Payoffs payoff ON LF.Id = payoff.LeaseFinanceId
	WHERE payoff.[Status] NOT IN (@PayoffStatusActivatedValue,
							  @PayoffStatusInactiveValue,
							  @PayoffStatusReversedValue);

	SELECT 
		ReceivableForTransferId = RT.Id
	FROM @LeaseIds Header
	JOIN LeaseFinances LF ON Header.LeaseFinanceId = LF.Id
	JOIN ReceivableForTransfers RT ON LF.Id = RT.LeaseFinanceId
	WHERE RT.ContractType = @ContractTypeLeaseValue
	AND RT.ApprovalStatus NOT IN (@ReceivableForTransferApprovalStatusInactiveValue,
								  @ReceivableForTransferApprovalStatusApprovedValue);
								  
	SELECT 
		AssumptionId = assumption.Id
	FROM @LeaseIds Header
	JOIN LeaseFinances LF ON Header.LeaseFinanceId = LF.Id
	JOIN Contracts CON ON LF.ContractId = CON.Id
	JOIN Assumptions assumption ON CON.Id = assumption.ContractId
	WHERE assumption.[Status] NOT IN (@AssumptionApprovalStatusApprovedValue,
									  @AssumptionApprovalStatusInactiveValue);

	SELECT 
		AmendmentId = leaseAmendment.Id,
        AmendmentType = leaseAmendment.AmendmentType
	FROM @LeaseIds Header
	JOIN LeaseFinances LF ON Header.LeaseFinanceId = LF.Id
	JOIN leaseAmendments leaseAmendment ON LF.Id = leaseAmendment.OriginalLeaseFinanceId
	WHERE leaseAmendment.LeaseAmendmentStatus NOT IN (@ContractAmendmentStatusApprovedValue,
												    @ContractAmendmentStatusInactiveValue)
	AND leaseAmendment.AmendmentType IN (@ContractAmendmentTypeRebookValue,@ContractAmendmentTypeRenewalValue,
							 @ContractAmendmentTypeRestructureValue, @ContractAmendmentTypeNBVImpairmentValue,
							 @ContractAmendmentTypeResidualImpairmentValue);

END

GO

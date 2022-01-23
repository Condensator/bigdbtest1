SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetPayablesSourcesToBeManipulatedInAutoPayoff]
(
	@LeaseInputs SundryInactivation_LeaseInput READONLY,
	@SundryPayableOnlyType NVARCHAR(50),
	@ReceivableEntityCTType NVARCHAR(50),
	@PayableSourceTable_SyndicatedAR NVARCHAR(50),
	@ReceivableForTransferApprovalApprovedStatus NVARCHAR(50),
	@LeasePaymentOTPType NVARCHAR(50),
	@LeasePaymentSupplementalType NVARCHAR(50),
	@PayableInactiveStatus NVARCHAR(50),
	@PayableSourceTable_IndirectAR NVARCHAR(50),
	@PayableSourceTable_SundryRecurPaySch NVARCHAR(50)
)
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #PayablesToAdjust
	(
		LeaseFinanceId BIGINT,
		PayableId BIGINT,
		SourceTable NVARCHAR(48) NULL,
		SourceId BIGINT NULL
	);

	INSERT INTO #PayablesToAdjust
		SELECT
			 LeaseFinanceId = Header.LeaseFinanceId,
			 PayableId = PB.Id,
			 SourceTable = PB.SourceTable,
			 SourceId = Sundries.Id 
		FROM @LeaseInputs Header
			JOIN LeaseFinances LF ON Header.LeaseFinanceId = LF.Id
			JOIN ReceivableForTransfers RT ON LF.ContractId = RT.ContractId
			JOIN Receivables Rec ON Rec.EntityId = LF.ContractId AND Rec.EntityType = @ReceivableEntityCTType
			JOIN Payables PB ON PB.SourceTable = @PayableSourceTable_SyndicatedAR AND Rec.Id = PB.SourceId
			LEFT JOIN Sundries ON PB.Id = Sundries.PayableId AND Sundries.EntityType = @ReceivableEntityCTType AND Sundries.IsActive = 1
			JOIN LeasePaymentSchedules LPS ON Rec.PaymentScheduleId = LPS.Id
		WHERE LPS.PaymentType IN (@LeasePaymentSupplementalType,@LeasePaymentOTPType)
			AND  Rec.IsActive = 1
			AND Rec.SourceTable = '_'
			AND (Sundries.Id IS NULL OR
				(Sundries.SundryType = @SundryPayableOnlyType AND Sundries.PayableCodeId = RT.RentalProceedsPayableCodeId))
			AND LPS.StartDate > Header.PayoffEffectiveDate
			AND RT.ApprovalStatus = @ReceivableForTransferApprovalApprovedStatus


	INSERT INTO #PayablesToAdjust
		SELECT
			 LeaseFinanceId = Header.LeaseFinanceId,
			 PayableId = PB.Id,
			 SourceTable = PB.SourceTable,
			 SourceId = Sundries.Id
		FROM @LeaseInputs Header
			JOIN LeaseFinances LF ON Header.LeaseFinanceId = LF.Id
			JOIN Receivables Rec ON LF.ContractId = Rec.EntityId AND REC.EntityType = @ReceivableEntityCTType
			JOIN LeasePaymentSchedules LPS ON REC.PaymentScheduleId = LPS.Id AND LPS.LeaseFinanceDetailId = LF.Id
			JOIN Payables PB ON PB.SourceTable = @PayableSourceTable_IndirectAR AND Rec.Id = PB.SourceId
			LEFT JOIN Sundries ON PB.Id = Sundries.PayableId AND Sundries.EntityType = @ReceivableEntityCTType AND Sundries.IsActive = 1
		WHERE LPS.PaymentType IN (@LeasePaymentSupplementalType,@LeasePaymentOTPType)
			AND LPS.StartDate > Header.PayoffEffectiveDate
			AND PB.[Status] <> @PayableInactiveStatus
			AND REC.SourceTable = '_';

	INSERT INTO #PayablesToAdjust
		SELECT 
			LeaseFinanceId = Header.LeaseFinanceId,
			PayableId = Payable.Id,
			SourceTable = @PayableSourceTable_SundryRecurPaySch,
			SourceId = SundryRecurring.Id
		FROM @LeaseInputs Header
			JOIN LeaseFinances LF ON Header.LeaseFinanceId = LF.Id
			JOIN SundryRecurrings SundryRecurring ON SundryRecurring.ContractId = LF.ContractId AND SundryRecurring.EntityType = @ReceivableEntityCTType
			JOIN SundryRecurringPaymentSchedules PaymentSchedule ON SundryRecurring.Id = PaymentSchedule.SundryRecurringId
			LEFT JOIN Payables Payable on PaymentSchedule.PayableId IS NOT NULL AND PaymentSchedule.PayableId = Payable.Id
		WHERE PaymentSchedule.DueDate >= CASE WHEN Header.IsAdvanceLease = 1 THEN DATEADD(DAY, 1, Header.PayoffEffectiveDate) ELSE DATEADD(DAY, 2, Header.PayoffEffectiveDate) END
			AND SundryRecurring.IsActive = 1;


	SELECT * FROM #PayablesToAdjust;

	DROP TABLE #PayablesToAdjust;

END

GO

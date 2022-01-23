SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdatePaymentScheduleIdInLeaseReceivables]
(
@EntityType NVARCHAR(50),
@EntityId BIGINT,
@OldLeaseFinanceDetailId BIGINT,
@NewLeaseFinanceDetailId BIGINT,
@TillDate DATETIME
)
AS

--DECLARE @EntityType NVARCHAR(50)=N'CT',
--		@EntityId BIGINT=51442,
--		@OldLeaseFinanceDetailId BIGINT=48783,
--		@NewLeaseFinanceDetailId BIGINT=699256,
--		@TillDate DATETIME='2018-08-31 00:00:00'

BEGIN
	SET NOCOUNT ON

	SELECT 
		@NewLeaseFinanceDetailId NewLeaseFinanceDetailId,
		LPS.StartDate, 
		LPS.EndDate,
		LPS.PaymentType,
		LPS.Id PreviousPaymentScheduleId,
		R.Id ReceivableId
	INTO #PreviousPaymentSchedules
	FROM Receivables R
	JOIN LeasePaymentSchedules LPS 
		On R.PaymentScheduleId = LPS.Id
		AND R.IsActive = 1
		AND R.[EntityType] = @EntityType
		AND R.[EntityId] = @EntityId
		AND	LPS.IsActive = 1
		AND LPS.LeaseFinanceDetailId = @OldLeaseFinanceDetailId
		AND LPS.[StartDate] <= @TillDate

	SELECT 
		PPS.PreviousPaymentScheduleId,
		PPS.ReceivableId,
		LPS.Id CurrentPaymentScheduleId
	INTO #CurrentPaymentSchedules
	FROM LeasePaymentSchedules LPS
	JOIN #PreviousPaymentSchedules PPS
		ON LPS.LeaseFinanceDetailId = PPS.NewLeaseFinanceDetailId
		AND LPS.IsActive = 1
		AND LPS.StartDate = PPS.StartDate 
		AND LPS.EndDate = PPS.EndDate 
		AND LPS.PaymentType = PPS.PaymentType

	UPDATE Receivables SET PaymentScheduleId = CPS.CurrentPaymentScheduleId
	FROM Receivables R
	JOIN #CurrentPaymentSchedules CPS
		ON R.Id = CPS.ReceivableId
		AND R.PaymentScheduleId = CPS.PreviousPaymentScheduleId

	DROP TABLE #PreviousPaymentSchedules
	DROP TABLE #CurrentPaymentSchedules
END

GO

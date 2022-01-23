SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateCPUReceivables]
(
	@CPUContractInfo CPUContractInfoForUpdateCPUReceivables READONLY,
	@OldCPUFinanceId BIGINT,
	@SourceTable NVARCHAR(20),
	@CurrentUserId BIGINT,
	@CurrentTime DATETIMEOFFSET
)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT * INTO #ContractInfo FROM @CPUContractInfo

	SELECT
		Receivables.Id ReceivableId,
		NewScheduleInfo.Id AS NewSourceId	
	INTO
		#ReceivableInfoForSource
	FROM
		#ContractInfo
		JOIN CPUContracts		ON	CPUContracts.SequenceNumber = #ContractInfo.CPUContractSequenceNumber
		JOIN CPUSchedules		ON	CPUSchedules.CPUFinanceId = @OldCPUFinanceId
									AND CPUSchedules.ScheduleNumber = #ContractInfo.CPUScheduleNumber
		JOIN CPUSchedules NewScheduleInfo	
								ON 	NewScheduleInfo.CPUFinanceId = CPUContracts.CPUFinanceId
									AND NewScheduleInfo.ScheduleNumber = #ContractInfo.CPUScheduleNumber
		JOIN Receivables		ON	CPUSchedules.Id = Receivables.SourceId
									AND Receivables.SourceTable = @SourceTable


	SELECT
		Receivables.Id ReceivableId,
		NewCPUPaymentSchedules.Id AS NewPaymentScheduleId
	INTO
		#ReceivableInfoForPaymentSchedule
	FROM
		#ContractInfo
		JOIN CPUContracts			ON	CPUContracts.SequenceNumber = #ContractInfo.CPUContractSequenceNumber
		JOIN CPUSchedules			ON	CPUSchedules.CPUFinanceId = @OldCPUFinanceId
										AND CPUSchedules.ScheduleNumber = #ContractInfo.CPUScheduleNumber
		JOIN Receivables			ON	CPUSchedules.Id= Receivables.SourceId
										AND Receivables.SourceTable= @SourceTable
										AND Receivables.PaymentScheduleId IS NOT NULL
		JOIN CPUPaymentSchedules	ON	Receivables.PaymentScheduleId = CPUPaymentSchedules.Id
										AND CPUPaymentSchedules.IsActive = 1
		JOIN CPUSchedules NewCPUScheduleInfo
									ON	NewCPUScheduleInfo.CPUFinanceId = CPUContracts.CPUFinanceId
										AND NewCPUScheduleInfo.ScheduleNumber = #ContractInfo.CPUScheduleNumber
		JOIN CPUPaymentSchedules NewCPUPaymentSchedules
									ON	NewCPUPaymentSchedules.CPUBaseStructureId = NewCPUScheduleInfo.Id
										AND NewCPUPaymentSchedules.PaymentNumber = CPUPaymentSchedules.PaymentNumber
										AND NewCPUPaymentSchedules.IsActive = 1
										

	UPDATE
		Receivables
	SET
		SourceId = #ReceivableInfoForSource.NewSourceId,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM
		Receivables
		JOIN #ReceivableInfoForSource	ON	Receivables.Id = #ReceivableInfoForSource.ReceivableId

	UPDATE
		Receivables
	SET
		PaymentScheduleId = #ReceivableInfoForPaymentSchedule.NewPaymentScheduleId,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM
		Receivables
		JOIN #ReceivableInfoForPaymentSchedule	ON	Receivables.Id = #ReceivableInfoForPaymentSchedule.ReceivableId


	SET NOCOUNT OFF;

END

GO

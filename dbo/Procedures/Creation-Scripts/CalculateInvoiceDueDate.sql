SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CalculateInvoiceDueDate]
(
	@JobStepInstanceId	BIGINT,
	@SystemDate DATETIMEOFFSET,
	@InvoiceDueDateCalculation_SystemDate NVARCHAR(20),
	@InvoiceDueDateCalculation_ReceivableDueDate NVARCHAR(20),
	@EntityType_CT NVARCHAR(3)
)
AS 
BEGIN 

	SET NOCOUNT ON;
	
	UPDATE InvoiceReceivableDetails_Extract 
	SET InvoiceDueDate = CASE WHEN EntityType = @EntityType_CT
							THEN CASE 
								WHEN (ReceivableDueDate <= DATEADD(DAY, CT_InvoiceTransitDays, @SystemDate))
									THEN DATEADD(DAY, CT_InvoiceTransitDays, @SystemDate)
								ELSE ReceivableDueDate END
							ELSE CASE 
								WHEN (ReceivableDueDate <= DATEADD(DAY, CU_InvoiceTransitDays, @SystemDate))
									THEN DATEADD(DAY, CU_InvoiceTransitDays, @SystemDate)
								ELSE ReceivableDueDate END
							END
	WHERE JobStepInstanceId = @JobStepInstanceId AND IsActive=1
		AND InvoiceDueDateCalculation = @InvoiceDueDateCalculation_SystemDate

	UPDATE InvoiceReceivableDetails_Extract 
	SET InvoiceDueDate = CASE WHEN EntityType = @EntityType_CT
							THEN CASE 
								WHEN (@SystemDate > DATEADD(DAY, CT_InvoiceTransitDays, ReceivableDueDate))
									THEN ReceivableDueDate
								ELSE DATEADD(DAY, CT_InvoiceTransitDays, ReceivableDueDate) END
						 ELSE CASE 
							WHEN (@SystemDate > DATEADD(DAY, CU_InvoiceTransitDays, ReceivableDueDate))
								THEN ReceivableDueDate
							ELSE DATEADD(DAY, CU_InvoiceTransitDays, ReceivableDueDate) END
						END
	WHERE JobStepInstanceId = @JobStepInstanceId AND IsActive=1
		AND InvoiceDueDateCalculation = @InvoiceDueDateCalculation_ReceivableDueDate

END

GO

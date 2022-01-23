SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ExtractRentSharingDetailsForReceipt]
(
	@CreatedById							BIGINT,
	@CreatedTime							DATETIMEOFFSET,
	@JobStepInstanceId						BIGINT,
	@InterimBillingTypeValues_Capitalize	NVARCHAR(20),
	@PayableSourceTableValues_Receivable    NVARCHAR(10),
	@PayableStatusValues_Inactive			NVARCHAR(10)
)
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	;WITH CTE_DistinctReceivableIds AS
	(
		SELECT ReceiptId, ReceivableId
		FROM ReceiptReceivableDetails_Extract RRD
		WHERE JobStepInstanceId = @JobStepInstanceId
		GROUP BY ReceiptId, ReceivableId
	)
	INSERT INTO ReceiptRentSharingDetails_Extract(ReceiptId, ReceivableId, RentSharingPercentage, VendorId, RemitToId, PayableCodeId, WithHoldingTaxRate, SourceType, PaidPayableAmount, JobStepInstanceId, CreatedById, CreatedTime)
	SELECT R.ReceiptId,
		   R.ReceivableId,
		   RSD.Percentage,
		   RSD.VendorId,
		   RSD.RemitToId,
		   RSD.PayableCodeId,
           CPUA.BaseFeePayableWithholdingTaxRate,
		   RSD.SourceType,
		   0,
		   @JobStepInstanceId,
		   @CreatedById,
		   @CreatedTime
	FROM CTE_DistinctReceivableIds R
	INNER JOIN RentSharingDetails RSD ON R.ReceivableId = RSD.ReceivableId AND RSD.IsActive = 1
    INNER JOIN Receivables Rec on RSD.ReceivableId = Rec.Id
    LEFT JOIN CPUSchedules CPUS ON Rec.SourceId = CPUS.Id AND Rec.SourceTable = 'CPUSchedule'
    LEFT JOIN CPUAccountings CPUA on CPUS.CPUFinanceId = CPUA.Id 

	;WITH PayableInfo AS
	(
		SELECT ReceivableId, SUM(Amount_Amount) AS PayableAmount
		FROM ReceiptRentSharingDetails_Extract RRD
		JOIN Payables P ON P.SourceId = RRD.ReceivableId AND P.SourceTable = @PayableSourceTableValues_Receivable AND P.Status != @PayableStatusValues_Inactive
		WHERE JobStepInstanceId = @JobStepInstanceId
		GROUP BY RRD.ReceivableId
	)
	UPDATE ReceiptRentSharingDetails_Extract
	SET PaidPayableAmount = P.PayableAmount
	FROM ReceiptRentSharingDetails_Extract RRD
	JOIN PayableInfo P ON P.ReceivableId = RRD.ReceivableId
	WHERE JobStepInstanceId = @JobStepInstanceId

END

GO

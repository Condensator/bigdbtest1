SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetReceivablesSourcesToBeManipulatedInAutoPayoff]
(
	@ReceivableSourceExtractionInputs ReceivableSourceExtractionInput READONLY,
	@ReceivableEntityType_CT NVARCHAR(50),
	@ReceivableTypeValues_OverTermRental NVARCHAR(50),
    @ReceivableTypeValues_Supplemental NVARCHAR(50),
	@SundryReceivableType_Scrape NVARCHAR(50),
	@ReceivableSourceTable_SyndicatedAR NVARCHAR(50),
	@ReceivableSourcetable_SundryRecurring NVARCHAR(50)
)
AS
BEGIN
SET NOCOUNT ON;

	CREATE TABLE #ReceivablesToAdjust
	(
		ContractId BIGINT,
		ReceivableId BIGINT,
		SourceTable NVARCHAR(20) NULL,
		SourceId BIGINT NULL
	);

	CREATE TABLE #ReceivableIdsToExclude
	(
		ReceivableId BIGINT 
	);

	CREATE CLUSTERED INDEX IDX_ReceivableId ON #ReceivableIdsToExclude (ReceivableId);

	INSERT INTO #ReceivableIdsToExclude
	SELECT
		 DISTINCT AdjustedReceivableDetail.ReceivableId 
	FROM 
		ReceivableDetails AdjustedReceivableDetail
	JOIN ReceivableDetails AdjustmentReceivableDetail 
		ON AdjustedReceivableDetail.Id = AdjustmentReceivableDetail.AdjustmentBasisReceivableDetailId
	JOIN Receivables R 
		ON AdjustedReceivableDetail.ReceivableId = R.Id
	JOIN @ReceivableSourceExtractionInputs Header 
		ON R.EntityId = Header.ContractId
	WHERE R.IsActive = 1 AND
	      AdjustmentReceivableDetail.IsActive = 1 AND
		  AdjustedReceivableDetail.IsActive = 1

	INSERT INTO #ReceivableIdsToExclude
	SELECT 
		DISTINCT AdjustmentReceivableDetail.ReceivableId 
	FROM 
		ReceivableDetails AdjustmentReceivableDetail
	JOIN Receivables R 
		ON AdjustmentReceivableDetail.ReceivableId = R.Id
	JOIN @ReceivableSourceExtractionInputs Header 
		ON R.EntityId = Header.ContractId
	WHERE R.IsActive = 1 AND 
		  AdjustmentReceivableDetail.AdjustmentBasisReceivableDetailId IS NOT NULL AND
		  AdjustmentReceivableDetail.IsActive = 1

	INSERT INTO #ReceivablesToAdjust
	SELECT ContractId = Header.ContractId,
		   ReceivableId = Rec.Id,
		   SourceTable = Rec.SourceTable,
		   SourceId = Header.ContractId
	FROM @ReceivableSourceExtractionInputs Header
	JOIN Contracts CON ON Header.ContractId = CON.Id
	JOIN Receivables Rec ON CON.Id = Rec.EntityId AND Rec.EntityType = @ReceivableEntityType_CT	
	JOIN ReceivableCodes RecCode ON Rec.ReceivableCodeId = RecCode.Id
	JOIN ReceivableTypes RecType ON RecCode.ReceivableTypeId = RecType.Id
	JOIN LeasePaymentSchedules LPS ON Rec.PaymentScheduleId = LPS.Id
	LEFT JOIN #ReceivableIdsToExclude ReceivableIdsToExclude ON Rec.Id = ReceivableIdsToExclude.ReceivableId
	WHERE LPS.StartDate > Header.PayoffEffectiveDate	
	AND Rec.SourceTable = '_'
	AND Rec.IsActive = 1
	AND LPS.IsActive = 1
	AND RecType.[Name] IN (@ReceivableTypeValues_OverTermRental, @ReceivableTypeValues_Supplemental)
	AND ReceivableIdsToExclude.ReceivableId is NULL;

	INSERT INTO #ReceivablesToAdjust
	SELECT ContractId = RecToAdjust.ContractId,
		   ReceivableId = Rec.Id,
		   SourceTable = @ReceivableSourceTable_SyndicatedAR,
		   SourceId = Sundry.Id
	FROM Receivables Rec 
	JOIN #ReceivablesToAdjust RecToAdjust ON Rec.SourceId = RecToAdjust.ReceivableId
	JOIN Sundries Sundry ON Rec.Id = Sundry.ReceivableId
	LEFT JOIN #ReceivableIdsToExclude ReceivableIdsToExclude ON Rec.Id = ReceivableIdsToExclude.ReceivableId
	WHERE Sundry.IsActive = 1
	AND Rec.IsActive = 1
	--AND Sundry.[Type] = @SundryReceivableType_Scrape
	AND Rec.SourceTable = @ReceivableSourceTable_SyndicatedAR
	AND ReceivableIdsToExclude.ReceivableId is NULL;

	INSERT INTO #ReceivablesToAdjust
	SELECT 
		ContractId = SundryRecurring.ContractId,
		ReceivableId = PaymentSchedule.ReceivableId,
		SourceTable = @ReceivableSourcetable_SundryRecurring,
		SourceId = SundryRecurring.Id
	FROM SundryRecurrings SundryRecurring
	JOIN SundryRecurringPaymentSchedules PaymentSchedule ON SundryRecurring.Id = PaymentSchedule.SundryRecurringId
	JOIN @ReceivableSourceExtractionInputs Header ON SundryRecurring.ContractId = Header.ContractId AND SundryRecurring.EntityType = @ReceivableEntityType_CT
	LEFT JOIN Receivables Receivable on PaymentSchedule.ReceivableId IS NOT NULL AND PaymentSchedule.ReceivableId = Receivable.Id
	LEFT JOIN #ReceivableIdsToExclude ReceivableIdsToExclude ON Receivable.Id = ReceivableIdsToExclude.ReceivableId
	WHERE 
		PaymentSchedule.DueDate >= CASE WHEN Header.IsAdvanceLease = 1 THEN DATEADD(DAY, 1, Header.PayoffEffectiveDate) ELSE DATEADD(DAY, 2, Header.PayoffEffectiveDate) END
	    AND SundryRecurring.IsActive = 1
		AND ReceivableIdsToExclude.ReceivableId is NULL;

	SELECT * FROM #ReceivablesToAdjust

	DROP TABLE #ReceivablesToAdjust;
	DROP TABLE #ReceivableIdsToExclude;

END

GO

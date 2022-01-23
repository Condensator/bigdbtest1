SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateReceiptsWithoutReceiptHierarchyTemplate]
(
	@JobStepInstanceId BIGINT,
	@CommentMessage NVARCHAR(2000),
	@ReceiptExtractSourceModuleValues NVARCHAR(20),
	@ReceiptClassificationValues_NonAccrualNonDSL NVARCHAR(20)
)
AS
BEGIN

CREATE TABLE #ReceiptIds (ReceiptId BIGINT)

	IF(@ReceiptExtractSourceModuleValues = 'PostByFile')
	BEGIN	
		INSERT INTO #ReceiptIds 
		SELECT DISTINCT re.ReceiptId
		FROM Receipts_Extract re
		JOIN ReceiptPostByFileExcel_Extract rpbfee ON re.ReceiptId = rpbfee.GroupNumber AND rpbfee.ComputedIsFullPosting = 0
		WHERE re.JobStepInstanceId = @JobStepInstanceId AND rpbfee.JobStepInstanceId = @JobStepInstanceId AND re.IsValid = 1
		AND re.ReceiptHierarchyTemplateId IS NULL AND re.ReceiptClassification != @ReceiptClassificationValues_NonAccrualNonDSL 
		
		UPDATE rpbfee SET 
			CreateUnallocatedReceipt = 1, 
			Comment = CONCAT(ISNULL(rpbfee.Comment, ''), '. ' + @CommentMessage)
		FROM ReceiptPostByFileExcel_Extract rpbfee
		JOIN #ReceiptIds rid ON rpbfee.GroupNumber = rid.ReceiptId
	
	END

	ELSE IF(@ReceiptExtractSourceModuleValues = 'CommonExternalReceipt')
	BEGIN	
		INSERT INTO #ReceiptIds 
		SELECT DISTINCT re.ReceiptId
		FROM Receipts_Extract re
		JOIN CommonExternalReceipt_Extract CEX ON re.ReceiptId = CEX.Id 
		WHERE re.JobStepInstanceId = @JobStepInstanceId AND CEX.JobStepInstanceId = @JobStepInstanceId AND re.IsValid = 1
		AND re.ReceiptHierarchyTemplateId IS NULL
		
		UPDATE CEX SET 
			CreateUnallocatedReceipt = 1, 
			Comment = CONCAT(ISNULL(CEX.Comment, ''), '. ' + @CommentMessage)
		FROM CommonExternalReceipt_Extract CEX
		JOIN #ReceiptIds rid ON CEX.ID = rid.ReceiptId
	
	END

	ELSE IF(@ReceiptExtractSourceModuleValues = 'Lockbox')	
	BEGIN

		INSERT INTO #ReceiptIds 
		SELECT DISTINCT re.ReceiptId
		FROM Receipts_Extract re
		JOIN ReceiptPostByLockBox_Extract rpblbe ON re.ReceiptId = rpblbe.LockBoxReceiptId AND rpblbe.IsFullPosting = 0
		WHERE re.JobStepInstanceId = @JobStepInstanceId AND rpblbe.JobStepInstanceId = @JobStepInstanceId AND re.IsValid = 1
		AND re.ReceiptHierarchyTemplateId IS NULL 
		
		UPDATE rpblbe SET 
			CreateUnallocatedReceipt = 1, 
			Comment = CONCAT(ISNULL(rpblbe.Comment, ''), '. ' + @CommentMessage)	
		FROM ReceiptPostByLockBox_Extract rpblbe
		JOIN #ReceiptIds rid ON rpblbe.LockBoxReceiptId = rid.ReceiptId		

	END

	UPDATE re SET Comment = CONCAT(ISNULL(re.Comment, ''), '. ' + @CommentMessage)	,
	PayOffId = null,
	PayDownId = null
	FROM Receipts_Extract re
	JOIN #ReceiptIds rid ON re.ReceiptId = rid.ReceiptId

	DROP TABLE #ReceiptIds

END

GO

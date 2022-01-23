SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GroupPostByFileReceipts] 
(
	@JobStepInstanceId					BIGINT,
	@GroupingParamNotIdenticalError		NVARCHAR(500),
	@InvalidRecordsInGroupError			NVARCHAR(500),
	@InvalidDSLGroupError				NVARCHAR(500),
	@NonAccrualSameContractError		NVARCHAR(500),
	@NonAccrualGroupedReceiptAmountError NVARCHAR(500),
	@NonAccrualDifferentEntityGroupedError NVARCHAR(500),
	@SameInvoiceInGroupError				NVARCHAR(500)
)
AS
BEGIN
	SET NOCOUNT OFF;

	-- Receipt Group Numbering
	;WITH GroupNumberCte AS 
	(
		SELECT Id, FileReceiptNumber, DENSE_RANK() OVER (ORDER BY FileReceiptNumber) AS GroupNumber, 
			ComputedLegalEntityId, ComputedCurrencyId, CheckNumber, ComputedLineOfBusinessId, ComputedCostCenterId,
			ComputedInstrumentTypeId, ComputedCashTypeId, ComputedReceiptTypeId, ComputedBankAccountId, 
			BankName, ReceivedDate, HasError, ReceivableTaxType
		FROM ReceiptPostByFileExcel_Extract 
		WHERE JobStepInstanceId = @JobStepInstanceId 
	)
	-- Validate uniqueness of mandatory fields
	, IsGroupedCte AS 
	(
		SELECT GroupNumber, CASE WHEN Count(1) > 1 THEN 1 ELSE 0 END AS IsGrouped
		FROM GroupNumberCte 
		GROUP BY GroupNumber, ComputedLegalEntityId, ComputedCurrencyId, CheckNumber, ComputedLineOfBusinessId,
			ComputedCostCenterId, ComputedInstrumentTypeId, ComputedCashTypeId, ComputedReceiptTypeId, 
			ComputedBankAccountId, BankName, ReceivedDate, ReceivableTaxType
	)
	-- Identify mismatch in Grouped mandatory fields
	, InvalidGroupCte AS 
	(
		SELECT GroupNumber, CASE WHEN COUNT(1) > 1 THEN 1 ELSE 0 END AS IsInvalid 
		FROM IsGroupedCte
		GROUP BY GroupNumber 
	) 
	SELECT 
		  Id = RPBF.Id,
		  GroupNumber = InvalidGroupCte.GroupNumber,  
		  HasError = CASE WHEN InvalidGroupCte.IsInvalid = 1 AND RPBF.HasError = 0   
				THEN 1 ELSE RPBF.HasError END,  
		  ErrorMessage = CASE WHEN InvalidGroupCte.IsInvalid = 1 AND RPBF.HasError = 0  
				 THEN REPLACE(@GroupingParamNotIdenticalError, '@ReceiptNumber', RPBF.FileReceiptNumber)   
				 WHEN GroupNumberCte.HasError = 1   
				 THEN RPBF.ErrorMessage  
			   END,  
		  ComputedIsGrouped = IsGroupedCte.IsGrouped  
	 INTO #ReceiptPostByFileExcel_Extract
	 FROM ReceiptPostByFileExcel_Extract RPBF  
	 JOIN GroupNumberCte ON GroupNumberCte.Id = RPBF.Id  
	 JOIN IsGroupedCte ON IsGroupedCte.GroupNumber = GroupNumberCte.GroupNumber  
	 JOIN InvalidGroupCte ON GroupNumberCte.GroupNumber = InvalidGroupCte.GroupNumber  

	 UPDATE ReceiptPostByFileExcel_Extract
	 SET GroupNumber = RPBF.GroupNumber,
		 HasError = RPBF.HasError,
		 ErrorMessage = RPBF.ErrorMessage,
		 ComputedIsGrouped = RPBF.ComputedIsGrouped
	 FROM #ReceiptPostByFileExcel_Extract RPBF WHERE ReceiptPostByFileExcel_Extract.Id = RPBF.Id


	--Update GroupNumber For Repeating  Receivableinvoice Associated To StatementInvoices
	DECLARE @MaxGroupNumber BIGINT = (SELECT MAX(GroupNumber) FROM ReceiptPostByFileExcel_Extract WHERE JobStepInstanceId=@JobStepInstanceId)
	
	CREATE TABLE #InvoiceIdMAP 
	(
		RPBFId BIGINT,Mapped_ReceivableInvoiceId BIGINT, 
		GroupNumber BIGINT, Balance DECIMAL(16, 2)
	)
	
	INSERT INTO #InvoiceIdMAP 
	SELECT 
		RPBF.Id AS RPBFId,
		RISA.ReceivableInvoiceId AS Mapped_ReceivableInvoiceId,
		RPBF.GroupNumber,
		RI.TaxBalance_Amount TaxBalance
	FROM ReceiptPostByFileExcel_Extract RPBF
	JOIN ReceivableInvoices RI ON RPBF.InvoiceNumber = RI.Number
	JOIN ReceivableInvoiceStatementAssociations RISA ON RI.Id = RISA.StatementInvoiceId
	WHERE RPBF.IsStatementInvoice = 1
	AND RPBF.ComputedIsGrouped = 1
	AND RPBF.JobStepInstanceId=@JobStepInstanceId

	INSERT INTO #InvoiceIdMAP 
	SELECT 
		RPBF.Id AS RPBFId, 
		RI.Id AS Mapped_ReceivableInvoiceId,
		RPBF.GroupNumber,
		RI.TaxBalance_Amount TaxBalance
	FROM ReceiptPostByFileExcel_Extract RPBF
	JOIN ReceivableInvoices RI ON RPBF.InvoiceNumber = RI.Number
	WHERE RPBF.IsStatementInvoice = 0
	AND RPBF.ComputedIsGrouped = 1
	AND RPBF.JobStepInstanceId=@JobStepInstanceId
	;

	WITH CTE_MoreThanInvoice AS
	(
		SELECT 
			RPBF.GroupNumber,
			SUM(IM.Balance) ReceiptBalance
		FROM #InvoiceIdMAP IM
		JOIN ReceiptPostByFileExcel_Extract RPBF ON IM.RPBFId = RPBF.Id
		WHERE ReceivableTaxType = 'VAT'
		AND ComputedIsGrouped = 1
		GROUP BY
			 RPBF.GroupNumber
		HAVING COUNT(*) > 1
	)
	UPDATE RPBF
		SET RPBF.HasError = 1,
			ErrorMessage = 'Invoice with non zero VAT Amount cannot be grouped with zero VAT Invoices'
	FROM ReceiptPostByFileExcel_Extract RPBF
	JOIN CTE_MoreThanInvoice CM ON RPBF.JobStepInstanceId = @JobStepInstanceId
	JOIN #InvoiceIdMAP IM ON CM.GroupNumber = IM.GroupNumber
	AND RPBF.GroupNumber = CM.GroupNumber 
	WHERE IM.Balance = 0 AND CM.ReceiptBalance <> 0

	;WITH GroupNumberToModify AS 
	(
		SELECT DISTINCT #InvoiceIdMAP.RPBFId,RANK() OVER (ORDER BY #InvoiceIdMAP.RPBFId) AS NewGroupNumber FROM #InvoiceIdMAP 
		JOIN (SELECT 
				MIN(RPBFId) AS FirstFileExtractId,
				Mapped_ReceivableInvoiceId,
				GroupNumber 
				FROM #InvoiceIdMAP 
				GROUP BY Mapped_ReceivableInvoiceId,GroupNumber 
				HAVING COUNT(#InvoiceIdMAP.RPBFId) > 1
			  ) AS GroupNumbersToCorrect 
				ON #InvoiceIdMAP.GroupNumber = GroupNumbersToCorrect.GroupNumber 
				AND #InvoiceIdMAP.Mapped_ReceivableInvoiceId = GroupNumbersToCorrect.Mapped_ReceivableInvoiceId
				AND #InvoiceIdMAP.RPBFId <> GroupNumbersToCorrect.FirstFileExtractId
	)
	UPDATE RPBF
	SET RPBF.GroupNumber = @MaxGroupNumber + NewGroupNumber
	FROM ReceiptPostByFileExcel_Extract RPBF
	JOIN GroupNumberToModify ON RPBF.Id = GroupNumberToModify.RPBFId
	WHERE RPBF.JobStepInstanceId = @JobStepInstanceId

	-- Check for any error records in group.
	;WITH ErrorGroupCte AS 
	(
		SELECT GroupNumber from ReceiptPostByFileExcel_Extract 
		WHERE JobStepInstanceId = @JobStepInstanceId AND ComputedIsGrouped = 1 and HasError= 1
		GROUP BY GroupNumber
	)
	UPDATE RPBF 
	SET RPBF.HasError = 1,
		RPBF.ErrorMessage = REPLACE(@InvalidRecordsInGroupError, '@ReceiptNumber', RPBF.FileReceiptNumber) 
	FROM ReceiptPostByFileExcel_Extract RPBF
	JOIN ErrorGroupCte ON ErrorGroupCte.GroupNumber = RPBF.GroupNumber AND RPBF.JobStepInstanceId = @JobStepInstanceId
	WHERE RPBF.HasError = 0 

	-- Check for any DSL records in group.
	;WITH DslGroupCte AS 
	(
		SELECT GroupNumber from ReceiptPostByFileExcel_Extract 
		WHERE JobStepInstanceId = @JobStepInstanceId AND ComputedIsGrouped = 1 
		GROUP BY GroupNumber, ComputedIsDSL
	),
	InvaildDslCte AS 
	(
		SELECT GroupNumber FROM DslGroupCte 
		GROUP BY GroupNumber
		HAVING COUNT(1) > 1
	) 
	UPDATE RPBF 
	SET RPBF.HasError = 1,
		RPBF.ErrorMessage = @InvalidDSLGroupError
	FROM ReceiptPostByFileExcel_Extract RPBF
	JOIN InvaildDslCte ON InvaildDslCte.GroupNumber = RPBF.GroupNumber AND RPBF.JobStepInstanceId = @JobStepInstanceId
	WHERE RPBF.HasError = 0 

	--Invalidate entire group if cash and non-accrual rental receipts are mixed
	;WITH FileRecordCountOfGroupedReceipts AS(
		SELECT RPBF.GroupNumber, 
		CountOfCashReceipts=
		SUM(
		CASE
			WHEN (RPBF.NonAccrualCategory='SingleUnAllocated' OR RPBF.NonAccrualCategory='SingleWithOnlyNonRentals' OR RPBF.NonAccrualCategory IS NULL) THEN 1
			ELSE 0
		END
		),
		CountOfNonAccrualRentalReceipts=
		SUM(
		CASE
			WHEN (RPBF.NonAccrualCategory='SingleWithRentals') THEN 1
			ELSE 0
		END
		)
		FROM ReceiptPostByFileExcel_Extract RPBF 
		WHERE RPBF.HasError = 0 AND RPBF.JobStepInstanceId = @JobStepInstanceId AND RPBF.ComputedIsGrouped=1
		GROUP BY RPBF.GroupNumber
	)
	UPDATE RPBF SET
	RPBF.HasError=1,
	RPBF.ErrorMessage=@InvalidDSLGroupError
	FROM ReceiptPostByFileExcel_Extract RPBF INNER JOIN FileRecordCountOfGroupedReceipts FR
	ON RPBF.GroupNumber=FR.GroupNumber
	WHERE RPBF.ComputedIsGrouped=1 AND RPBF.HasError=0 AND RPBF.JobStepInstanceId=@JobStepInstanceId
	AND (FR.CountOfCashReceipts>0 AND FR.CountOfNonAccrualRentalReceipts>0)

	--Within a group, there can be only one Sequence Number for Non-Accrual Rentals
	;WITH EntityDifferenceValues AS (
		SELECT RPBF.GroupNumber, RPBF.EntityType, RPBF.Entity
		FROM ReceiptPostByFileExcel_Extract RPBF 
		WHERE RPBF.HasError = 0 AND RPBF.JobStepInstanceId = @JobStepInstanceId AND RPBF.ComputedIsGrouped=1 AND RPBF.NonAccrualCategory='SingleWithRentals'
		GROUP BY RPBF.GroupNumber, RPBF.EntityType, RPBF.Entity
	), DumpIdsToInvalidate AS (
		SELECT GroupNumber 
		FROM EntityDifferenceValues
		GROUP BY GroupNumber
		HAVING COUNT(1)>1
	)
	UPDATE RPBF SET
	RPBF.HasError=1,
	RPBF.ErrorMessage=@NonAccrualDifferentEntityGroupedError
	FROM ReceiptPostByFileExcel_Extract RPBF INNER JOIN DumpIdsToInvalidate DI
	ON RPBF.GroupNumber=DI.GroupNumber
	WHERE RPBF.ComputedIsGrouped=1 AND RPBF.HasError=0 AND RPBF.JobStepInstanceId=@JobStepInstanceId

	--Invalidate Ungrouped Non-Accrual Loan records with same contract after the first ReceivedDate receipt
	;With GroupedIdentification AS (
		SELECT RPBF.ComputedContractId, RPBF.GroupNumber, RPBF.ReceivedDate
		FROM ReceiptPostByFileExcel_Extract RPBF
		WHERE RPBF.HasError=0 AND RPBF.JobStepInstanceId=@JobStepInstanceId AND RPBF.NonAccrualCategory='SingleWithRentals'
		GROUP BY RPBF.ComputedContractId, RPBF.GroupNumber, RPBF.ReceivedDate
	), GroupsForValidation AS (
		SELECT GroupNumber, ComputedContractId, RANK() OVER (PARTITION BY ComputedContractId ORDER BY ReceivedDate) AS DateRank 
		FROM GroupedIdentification 
	), SameReceivedDateGroupNumbers AS (
		SELECT GF.GroupNumber, GF.ComputedContractId FROM GroupsForValidation GF INNER JOIN 
		(
		SELECT ComputedContractId, DateRank from GroupsForValidation
		GROUP BY ComputedContractId, DateRank
		HAVING COUNT(GroupNumber) > 1
		) SameReceivedDateGroups 
		ON GF.ComputedContractId=SameReceivedDateGroups.ComputedContractId AND GF.DateRank=SameReceivedDateGroups.DateRank
	), RowNumbersInQuestionToInvalidate AS (
		SELECT RPBF.GroupNumber, RPBF.ComputedContractId, RANK() OVER (PARTITION BY RPBF.ComputedContractId ORDER BY RPBF.RowNumber) AS RankOrder FROM ReceiptPostByFileExcel_Extract RPBF INNER JOIN SameReceivedDateGroupNumbers SG
		ON RPBF.GroupNumber=SG.GroupNumber AND RPBF.ComputedContractId=SG.ComputedContractId AND RPBF.JobStepInstanceId=@JobStepInstanceId AND RPBF.ComputedIsGrouped=0
	), GroupsToInvalidate AS (
		SELECT GroupNumber FROM GroupsForValidation WHERE DateRank!=1 
			UNION
		SELECT GroupNumber from RowNumbersInQuestionToInvalidate AS LatterRowNumbersToInValidate WHERE RankOrder!=1
	)
	UPDATE RPBF SET
	RPBF.HasError=1,
	RPBF.ErrorMessage=@NonAccrualSameContractError
	FROM ReceiptPostByFileExcel_Extract RPBF 
	INNER JOIN GroupsToInvalidate G ON RPBF.GroupNumber=G.GroupNumber 
	WHERE RPBF.HasError=0 AND RPBF.JobStepInstanceId=@JobStepInstanceId 

	--Invalidating the whole group if a group contains the same Invoice within that group of records
	;WITH GroupsToCheck AS (
		SELECT DISTINCT GroupNumber FROM ReceiptPostByFileExcel_Extract 
		WHERE ComputedIsGrouped=1 AND HasError=0 AND JobStepInstanceId=@JobStepInstanceId
		AND (NonAccrualCategory!='SingleWithRentals' OR NonAccrualCategory IS NULL)
	), HasSameInvoiceInGroup AS (
		SELECT R.GroupNumber, R.ComputedReceivableInvoiceId, COUNT(1) AS CountOfInvoiceInGroup FROM
		ReceiptPostByFileExcel_Extract R INNER JOIN GroupsToCheck G
		ON R.GroupNumber=G.GroupNumber
		WHERE HasError=0 AND JobStepInstanceId=@JobStepInstanceId AND ComputedReceivableInvoiceId IS NOT NULL
		GROUP BY R.GroupNumber, ComputedReceivableInvoiceId
	), GroupsToMarkInvalid AS (
		SELECT DISTINCT GroupNumber FROM HasSameInvoiceInGroup WHERE CountOfInvoiceInGroup>1
	)
	UPDATE RPBF SET
	RPBF.HasError=1,
	RPBF.ErrorMessage=@SameInvoiceInGroupError
	FROM ReceiptPostByFileExcel_Extract RPBF INNER JOIN GroupsToMarkInvalid G
	ON RPBF.GroupNumber=G.GroupNumber AND RPBF.JobStepInstanceId=@JobStepInstanceId ANd RPBF.HasError=0
	
	--Change Non-Accrual Category for Grouped Non-Accrual Records
	UPDATE RPBF SET
	RPBF.NonAccrualCategory=
	CASE 
		WHEN (RPBF.NonAccrualCategory='SingleWithRentals') THEN 'GroupedRentals'
		WHEN (RPBF.NonAccrualCategory='SingleWithOnlyNonRentals' OR RPBF.NonAccrualCategory='SingleUnAllocated') THEN 'GroupedNonRentals'
		ELSE RPBF.NonAccrualCategory
	END
	FROM ReceiptPostByFileExcel_Extract RPBF
	WHERE RPBF.ComputedIsGrouped=1 AND RPBF.NonAccrualCategory IS NOT NULL
	AND RPBF.HasError=0 AND RPBF.JobStepInstanceId=@JobStepInstanceId

	--Invalidate Non-Accrual GroupedRentals records which have the sum of their ReceiptAmount > ReceivableBalance
	;WITH DumpContractIds AS(
		SELECT distinct RPBF.ComputedContractId AS ContractId FROM ReceiptPostByFileExcel_Extract RPBF
		WHERE RPBF.HasError=0 AND RPBF.ComputedContractId IS NOT NULL AND RPBF.NonAccrualCategory='GroupedRentals' AND RPBF.JobStepInstanceId=@JobStepInstanceId
	), OutstandingBalanceOfRentalReceivables AS (
		SELECT DumpContractIds.ContractId, SUM(R.TotalEffectiveBalance_Amount) AS RentalBalanceOfContract FROM DumpContractIds INNER JOIN Receivables R
		ON DumpContractIds.ContractId=R.EntityId AND R.EntityType='CT' INNER JOIN ReceivableCodes RC
		ON R.ReceivableCodeId=RC.Id INNER JOIN ReceivableTypes RT 
		ON RC.ReceivableTypeId=RT.Id AND (RT.[Name]='LoanInterest' OR RT.[Name]='LoanPrincipal')
		GROUP BY DumpContractIds.ContractId
	), GroupedReceiptAmounts AS(
		SELECT RPBF.GroupNumber, SUM(RPBF.ReceiptAmount) AS SumReceiptAmount 
		FROM ReceiptPostByFileExcel_Extract RPBF
		WHERE RPBF.HasError=0 AND RPBF.ComputedIsGrouped=1 AND RPBF.NonAccrualCategory='GroupedRentals' 
		AND RPBF.JobStepInstanceId=@JobStepInstanceId
		GROUP BY RPBF.GroupNumber
	)
	UPDATE RPBF SET 
	RPBF.HasError=1,
	RPBF.ErrorMessage=@NonAccrualGroupedReceiptAmountError
	FROM ReceiptPostByFileExcel_Extract RPBF
	INNER JOIN OutstandingBalanceOfRentalReceivables OB ON RPBF.ComputedContractId=OB.ContractId
	INNER JOIN GroupedReceiptAmounts GRA ON RPBF.GroupNumber=GRA.GroupNumber
	WHERE RPBF.HasError=0 AND RPBF.JobStepInstanceId=@JobStepInstanceId AND RPBF.NonAccrualCategory='GroupedRentals'
	AND (GRA.SumReceiptAmount>OB.RentalBalanceOfContract) 

    IF EXISTS(SELECT Top 1 * FROM ReceiptPostByFileExcel_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND IsStatementInvoice = 1)
	BEGIN
	UPDATE ReceiptPostByFileExcel_Extract 
	SET IsInvoiceInMultipleReceipts = 1, ComputedIsFullPosting = 0
	FROM ReceiptPostByFileExcel_Extract 
	WHERE JobStepInstanceId = @JobStepInstanceId AND ComputedReceivableInvoiceId IS NOT NULL
	END
END

GO

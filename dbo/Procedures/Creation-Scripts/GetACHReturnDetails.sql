SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetACHReturnDetails]
(@CreatedBy                  BIGINT,
 @CreatedTime                DATETIME,
 @JobStepInstanceId          BIGINT,
 @FileName		             NVARCHAR(500),
 @AchRunFileId               BIGINT,
 @ACHFileDetails                ACHFileDetails READONLY,
 @ReceiptClassificationValues_DSL NVARCHAR(46),
 @ACHRunEntityTypeValues_Receipt  NVARCHAR(14),
 @ReceiptStatusValues_Inactive    NVARCHAR(30),
 @ReceiptStatusValues_Reversed    NVARCHAR(30),
 @ReceiptStatusValues_Posted      NVARCHAR(30),
 @ReceiptTypeValues_ACH           NVARCHAR(60),
 @ReceiptTypeValues_WebOneTimeACH NVARCHAR(60),
 @ReceiptTypeValues_PAP           NVARCHAR(60),
 @ReceiptTypeValues_WebOneTimePAP NVARCHAR(60),
 @LocationApprovalStatus_Approved         NVARCHAR(18),
 @GUID							  UniqueIdentifier NULL
)
AS
  BEGIN
    CREATE TABLE #ACHReturnInfos
    (ACHRunFileId               BIGINT,
     ACHRunId                   BIGINT,
     ACHRunDetailId             BIGINT,
     ReceiptId                  BIGINT,
     ReceiptNumber              NVARCHAR(20),
     ReceiptAmount              DECIMAL(16,2),
     LegalEntityId              BIGINT,
	 LegalEntityACHFailureLimit BIGINT,
	 CustomerBankAccountId		BIGINT,
	 CurrentACHFailureCount		INT,
	 AccountOnHoldCount		INT,
	 CurrentOnHoldStatus		BIT,
     Status                     NVARCHAR(30),
     ReceiptClassification      NVARCHAR(46),
     ReceiptEntity              NVARCHAR(28),
     ACHScheduleId              BIGINT,
     IsOneTimeACH               BIT,
     ReceivedDate               DATE,
	 ContractId					BIGINT,
	 CustomerId					BIGINT,
     EntryDetailLineNumber      BIGINT,
     ReturnReasonCodeLineNumber BIGINT,
     FileName                   NVARCHAR(500),
     OneTimeACHId               BIGINT,
     ReturnFileReceiptAmount    DECIMAL(16,2),
     TraceNumber                NVARCHAR(40),
     ReasonCode                 NVARCHAR(80),
     ReACH                      BIT,
	 NSFCustomerId				BIGINT,
	 NSFLocationId				BIGINT,
	 NSFBillToId				BIGINT,
	 IsNSFChargeEligible		BIT,
	 Currency					NVARCHAR(3),
	 RowNum						BIGINT,
	 IsPending					BIT,
	 IsValid					BIT
    );

	SELECT * INTO #FileDetails FROM @ACHFileDetails;

    INSERT INTO #ACHReturnInfos
    SELECT ACHRunDetails.ACHRunFileId AS ACHRunFileId,
           ACHRuns.Id AS ACHRunId,
           ACHRunDetails.Id AS ACHRunDetailsId,
		   Receipts.Id AS ReceiptId,
           Receipts.Number AS ReceiptNumber,
           Receipts.ReceiptAmount_Amount AS ReceiptAmount,
           Receipts.LegalEntityId AS LegalEntityId,
		   0,
		   0,
		   0,
		   0,
		   0,
           Receipts.Status AS Status,
           Receipts.ReceiptClassification AS ReceiptClassification,
           Receipts.EntityType AS ReceiptEntity,
           ISNULL(ACHRunScheduleDetails.ACHScheduleId, NULL) AS ACHScheduleId,
		   CASE WHEN ACHReceipts.OneTimeACHId IS NOT NULL OR ACHRunScheduleDetails.IsOneTime = 1
		   THEN 1
		   ELSE 0
		   END AS IsOneTimeACH,
           Receipts.ReceivedDate,
		   Receipts.ContractId,
		   Receipts.CustomerId,
           0 AS EntryDetailLineNumber,
           0 AS ReturnReasonCodeLineNumber,
           @FileName AS FileName,
		   ISNULL(ACHReceipts.OneTimeACHId, NULL) as OneTimeACHId,
           0.00 AS ReturnFileReceiptAmount,
		   ACHRunDetails.TraceNumber AS TraceNumber,
           '' AS ReasonCode,
           0 as ReACH,
		   NULL as NSFCustomerId,
		   NULL as NSFLocationId,
		   NULL as NSFBillToId,
		   0 as IsNSFChargeEligible,
		   Receipts.ReceiptAmount_Currency,
		  DENSE_RANK() OVER(PARTITION BY Receipts.ContractId ORDER BY Receipts.ReceivedDate DESC) RowNum,
		  ACHRunDetails.IsPending,
		  CASE WHEN Receipts.Status = @ReceiptStatusValues_Reversed OR ACHRunDetails.IsReversed = 1
		  THEN 0 ELSE 1 END as IsValid
    FROM dbo.ACHRuns
    JOIN dbo.ACHRunDetails ON ACHRuns.Id = ACHRunDetails.ACHRunId
                              AND ACHRunDetails.ACHRunFileId IS NOT NULL
    JOIN dbo.Receipts ON ACHRunDetails.EntityId = Receipts.Id
	LEFT JOIN dbo.ACHReceipts ON ACHReceipts.ReceiptId = Receipts.Id
	LEFT JOIN dbo.ACHRunScheduleDetails ON ACHRunDetails.Id = ACHRunScheduleDetails.ACHRunDetailId
    WHERE ACHRunDetails.ACHRunFileId = @AchRunFileId
          AND ACHRuns.EntityType = @ACHRunEntityTypeValues_Receipt
          AND Receipts.Status <> @ReceiptStatusValues_Inactive
		  AND ACHRunDetails.TraceNumber IN (SELECT TraceNumber FROM #FileDetails)
          AND ACHRunDetails.IsPending = 0;

	UPDATE #ACHReturnInfos SET #ACHReturnInfos.EntryDetailLineNumber = F.EntryDetailLineNumber,
							   #ACHReturnInfos.ReturnReasonCodeLineNumber=F.ReturnReasonCodeLineNumber,
							   #ACHReturnInfos.ReturnFileReceiptAmount = F.ReturnFileReceiptAmount,
							   #ACHReturnInfos.ReasonCode = F.ReceiptReversalReasonCode
	FROM #FileDetails F
	WHERE #ACHReturnInfos.TraceNumber = F.TraceNumber;

	INSERT INTO #ACHReturnInfos
	SELECT ACHRunDetails.ACHRunFileId AS ACHRunFileId,
           ACHRuns.Id AS ACHRunId,
           ACHRunDetails.Id AS ACHRunDetailsId,
		   ACHRunDetails.EntityId AS ReceiptId,
           NULL AS ReceiptNumber,
           ACHReceipts.ReceiptAmount AS ReceiptAmount,
           ACHReceipts.LegalEntityId AS LegalEntityId,
		   0,
		   0,
		   0,
		   0,
		   0,
           CASE WHEN ACHRunDetails.IsReversed = 1 THEN @ReceiptStatusValues_Reversed ELSE ACHReceipts.Status END AS Status,
           ACHReceipts.ReceiptClassification AS ReceiptClassification,
           ACHReceipts.EntityType AS ReceiptEntity,
           ISNULL(ACHRunScheduleDetails.ACHScheduleId, NULL) AS ACHScheduleId,
		   CASE WHEN ACHReceipts.OneTimeACHId IS NOT NULL OR ACHRunScheduleDetails.IsOneTime = 1
		   THEN 1
		   ELSE 0
		   END AS IsOneTimeACH,
           ACHReceipts.SettlementDate AS ReceivedDate,
		   ACHReceipts.ContractId AS ContractId,
		   ACHReceipts.CustomerId AS CustomerId,
           0 AS EntryDetailLineNumber,
           0 AS ReturnReasonCodeLineNumber,
           @FileName AS FileName,
		   ISNULL(ACHReceipts.OneTimeACHId, NULL) as OneTimeACHId,
           0.00 AS ReturnFileReceiptAmount,
		   ACHRunDetails.TraceNumber AS TraceNumber,
           '' AS ReasonCode,
           0 as ReACH,
		   NULL as NSFCustomerId,
		   NULL as NSFLocationId,
		   NULL as NSFBillToId,
		   0 as IsNSFChargeEligible,
		   ACHReceipts.Currency AS ReceiptAmount_Currency,
		   0 AS RowNum,
		   ACHRunDetails.IsPending,
		   CASE WHEN ACHRunDetails.IsReversed = 1 THEN 0 ELSE 1 END as IsValid
    FROM dbo.ACHRuns
    JOIN dbo.ACHRunDetails ON ACHRuns.Id = ACHRunDetails.ACHRunId
                              AND ACHRunDetails.ACHRunFileId IS NOT NULL
	JOIN dbo.ACHReceipts ON ACHRunDetails.EntityId = ACHReceipts.Id
	LEFT JOIN dbo.ACHRunScheduleDetails ON ACHRunDetails.Id = ACHRunScheduleDetails.ACHRunDetailId
    WHERE ACHRunDetails.ACHRunFileId = @AchRunFileId
          AND ACHRuns.EntityType = @ACHRunEntityTypeValues_Receipt
		  AND ACHRunDetails.TraceNumber IN (SELECT TraceNumber FROM #FileDetails)
          AND ACHRunDetails.IsPending = 1;

	UPDATE #ACHReturnInfos SET #ACHReturnInfos.EntryDetailLineNumber = F.EntryDetailLineNumber,
							   #ACHReturnInfos.ReturnReasonCodeLineNumber=F.ReturnReasonCodeLineNumber,
							   #ACHReturnInfos.ReturnFileReceiptAmount = F.ReturnFileReceiptAmount,
							   #ACHReturnInfos.ReasonCode = F.ReceiptReversalReasonCode
	FROM #FileDetails F
	WHERE #ACHReturnInfos.TraceNumber = F.TraceNumber
	AND F.ReturnFileReceiptAmount = #ACHReturnInfos.ReceiptAmount;

    UPDATE extractTable
      SET extractTable.OneTimeACHId = OneTimeACHSchedules.OneTimeACHId
    FROM #ACHReturnInfos extractTable
    JOIN dbo.OneTimeACHSchedules ON extractTable.ACHScheduleId = OneTimeACHSchedules.Id
    WHERE extractTable.IsOneTimeACH = 1;

    UPDATE extractTable
      SET extractTable.ReACH = ReceiptReversalReasons.ReACH
    FROM #ACHReturnInfos extractTable
    JOIN dbo.ReceiptReversalReasons ON extractTable.ReasonCode = ReceiptReversalReasons.Code;

    SELECT ReceiptId , ContractId ,ReturnFileReceiptAmount INTO #DSLReceipts
    FROM #ACHReturnInfos
    WHERE ReceiptClassification = @ReceiptClassificationValues_DSL AND IsPending = 0;

	SELECT Id INTO #ACHReceiptTypeIds FROM ReceiptTypes WHERE ReceiptTypeName IN (@ReceiptTypeValues_ACH,@ReceiptTypeValues_WebOneTimeACH,@ReceiptTypeValues_PAP,@ReceiptTypeValues_WebOneTimePAP)

	SELECT DENSE_RANK() OVER(PARTITION BY R.ContractId ORDER BY R.ReceivedDate DESC) RowNum,
	R.Number AS ReceiptNumber,
    R.Id AS ReceiptId,
	R.ReceivedDate,
	R.ContractId,
	R.Status
	INTO #MaxDSLReceipts
	FROM Receipts R
	INNER JOIN #DSLReceipts DSLR ON R.ContractId = DSLR.ContractId
	INNER JOIN #ACHReceiptTypeIds T ON R.TypeId = T.Id
	AND DSLR.ReturnFileReceiptAmount = R.ReceiptAmount_Amount
	AND R.Status <> @ReceiptStatusValues_Reversed
	AND R.Status <> @ReceiptStatusValues_Inactive;

	UPDATE #ACHReturnInfos
	SET ReceiptId = MaxReceipt.ReceiptId,
		ReceiptNumber = MaxReceipt.ReceiptNumber,
		ReceivedDate = MaxReceipt.ReceivedDate,
		Status = MaxReceipt.Status,
		IsValid = 1
	FROM #MaxDSLReceipts MaxReceipt
	WHERE #ACHReturnInfos.ContractId = MaxReceipt.ContractId
		  AND #ACHReturnInfos.IsPending = 0
		  AND #ACHReturnInfos.RowNum = 1
		  AND MaxReceipt.RowNum = 1;

	UPDATE ARI
	SET ReceiptId = 0
	FROM #ACHReturnInfos ARI
	LEFT JOIN #MaxDSLReceipts MD ON ARI.ContractId = MD.ContractId
					AND ARI.ReceiptId = MD.ReceiptId
					AND ARI.RowNum = MD.RowNum
	WHERE ReceiptClassification = @ReceiptClassificationValues_DSL
	AND ARI.IsPending = 0
	AND MD.ReceiptId IS NULL;

	SELECT ReceiptId,CustomerId,Customers.IsNSFChargeEligible
	INTO #NsfEligibleCustomers
	FROM #ACHReturnInfos ACHE
	JOIN Customers ON Customers.Id = ACHE.CustomerId;

	INSERT INTO #NsfEligibleCustomers
	SELECT ReceiptId,C.Id,C.IsNSFChargeEligible
	FROM #ACHReturnInfos ACHE
	JOIN LoanFinances LF ON ACHE.ContractId = LF.ContractId AND LF.IsCurrent = 1
	JOIN Customers C ON C.Id = LF.CustomerId
	WHERE ACHE.IsValid = 1;

	INSERT INTO #NsfEligibleCustomers
	SELECT ReceiptId,C.Id,C.IsNSFChargeEligible
	FROM #ACHReturnInfos ACHE
	JOIN LeaseFinances LF ON ACHE.ContractId = LF.ContractId AND LF.IsCurrent = 1
	JOIN Customers C ON C.Id = LF.CustomerId
	WHERE ACHE.IsValid = 1;

	UPDATE #ACHReturnInfos
	SET NSFCustomerId = NSF.CustomerId , IsNSFChargeEligible = NSF.IsNSFChargeEligible
	FROM #NsfEligibleCustomers NSF
	WHERE #ACHReturnInfos.ReceiptId = NSF.ReceiptId AND #ACHReturnInfos.IsValid = 1;

	SELECT MIN(L.Id) LocationId ,ACHR.NSFCustomerId INTO #NSFLocations
	FROM #ACHReturnInfos ACHR
	INNER JOIN Locations L ON L.CustomerId = ACHR.NSFCustomerId
		AND L.ApprovalStatus = @LocationApprovalStatus_Approved
		AND L.IsActive = 1 AND ACHR.IsValid = 1
	GROUP BY ACHR.NSFCustomerId

	UPDATE #ACHReturnInfos SET NsfLocationId = L.LocationId
	FROM #NSFLocations L
	WHERE #ACHReturnInfos.NSFCustomerId = L.NSFCustomerId AND #ACHReturnInfos.IsValid = 1

	SELECT MIN(B.Id) BillToId ,ACHR.NSFCustomerId INTO #NSFBillToes
	FROM #ACHReturnInfos ACHR
	INNER JOIN BillToes B ON B.CustomerId = ACHR.NSFCustomerId
		AND B.IsActive = 1 AND ACHR.IsValid = 1
	GROUP BY ACHR.NSFCustomerId

	UPDATE #ACHReturnInfos SET NSFBillToId = B.BillToId
	FROM #NSFBillToes B
	WHERE #ACHReturnInfos.NSFCustomerId = B.NSFCustomerId AND #ACHReturnInfos.IsValid = 1

	UPDATE extractTable SET extractTable.LegalEntityACHFailureLimit = LE.ACHFailureLimit
	FROM #ACHReturnInfos extractTable
	JOIN dbo.LegalEntities LE ON extractTable.LegalEntityId = LE.Id
	WHERE extractTable.IsValid = 1

	UPDATE extractTable SET extractTable.CustomerBankAccountId = ACHS.ACHAccountId
	FROM #ACHReturnInfos extractTable
	JOIN dbo.ACHSchedules ACHS ON extractTable.ACHScheduleId = ACHS.Id
	WHERE extractTable.IsOneTimeACH = 0 AND extractTable.IsValid = 1

	UPDATE extractTable SET extractTable.CustomerBankAccountId = OTACHS.BankAccountId
	FROM #ACHReturnInfos extractTable
	JOIN dbo.OneTimeACHes OTACHS ON extractTable.OneTimeACHId = OTACHS.Id
	WHERE extractTable.IsOneTimeACH = 1 AND extractTable.IsValid = 1

	UPDATE extractTable 
	SET extractTable.CurrentACHFailureCount = BA.ACHFailureCount, 
	extractTable.CurrentOnHoldStatus = BA.OnHold,
	extractTable.AccountOnHoldCount = BA.AccountOnHoldCount
	FROM #ACHReturnInfos extractTable
	JOIN dbo.BankAccounts BA ON extractTable.CustomerBankAccountId = BA.Id
	WHERE extractTable.IsValid = 1

	INSERT INTO [dbo].[ACHReturn_Extract]
           ([ACHRunId]
           ,[ACHRunDetailId]
           ,[ACHRunFileId]
           ,[ReceiptId]
           ,[LegalEntityId]
		   ,[LegalEntityACHFailureLimit]
		   ,[CustomerBankAccountId]
		   ,[CurrentACHFailureCount]
		   ,[AccountOnHoldCount]
		   ,[CurrentOnHoldStatus]
		   ,[ContractId]
           ,[ACHScheduleId]
           ,[OneTimeACHId]
           ,[EntryDetailLineNumber]
           ,[ReturnReasonCodeLineNumber]
           ,[JobStepInstanceId]
           ,[IsOneTimeACH]
           ,[ReceivedDate]
           ,[ReceiptClassification]
           ,[Status]
           ,[ReceiptAmount_Amount]
           ,[ReceiptAmount_Currency]
           ,[ReturnFileReceiptAmount_Amount]
           ,[ReturnFileReceiptAmount_Currency]
           ,[EntityType]
           ,[TraceNumber]
           ,[FileName]
           ,[ReasonCode]
           ,[ReceiptNumber]
           ,[ReACH]
           ,[IsNSFChargeEligible]
           ,[NSFCustomerId]
           ,[NSFLocationId]
           ,[NSFBillToId]
           ,[CreatedById]
           ,[CreatedTime]
		   ,[GUID]
		   ,[IsPending])
    SELECT
		[ACHRunId]
        ,[ACHRunDetailId]
        ,[ACHRunFileId]
        ,[ReceiptId]
        ,[LegalEntityId]
		,[LegalEntityACHFailureLimit]
		,[CustomerBankAccountId]
		,[CurrentACHFailureCount]
		,[AccountOnHoldCount]
		,[CurrentOnHoldStatus]
		,[ContractId]
        ,[ACHScheduleId]
        ,[OneTimeACHId]
        ,[EntryDetailLineNumber]
        ,[ReturnReasonCodeLineNumber]
        ,@JobStepInstanceId
        ,[IsOneTimeACH]
        ,[ReceivedDate]
        ,[ReceiptClassification]
        ,[Status]
        ,ReceiptAmount
        ,Currency
        ,ReturnFileReceiptAmount
        ,Currency
        ,ReceiptEntity
        ,[TraceNumber]
        ,[FileName]
        ,[ReasonCode]
        ,[ReceiptNumber]
        ,[ReACH]
        ,[IsNSFChargeEligible]
        ,[NSFCustomerId]
        ,[NSFLocationId]
        ,[NSFBillToId]
        ,@CreatedBy
        ,@CreatedTime
		,@GUID
		,[IsPending]
	FROM #ACHReturnInfos

  END;

GO

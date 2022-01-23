SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ExtractACHReceipts]
(@JobStepInstanceId                  BIGINT,
 @LegalEntityIds                     LEGALENTITYIDS READONLY,
 @ContractId                         BIGINT,
 @CustomerId                         BIGINT,
 @EntityType                         NVARCHAR(30),
 @FilterOption                       NVARCHAR(50),
 @IsOneFilterOption                  NVARCHAR(10),
 @IsAllFilterOption                  NVARCHAR(10),
 @ProcessThroughDate                 DATE,
 @PostDate                           DATE,
 @DSLReceiptClassification           NVARCHAR(10),
 @NonAccrualNonDSLClassificationType NVARCHAR(20),
 @CashReceiptClassificationType      NVARCHAR(10),
 @CashReceiptType                    NVARCHAR(10),
 @PendingReceiptStatus               NVARCHAR(10),
 @PostedReceiptStatus                NVARCHAR(10),
 @ReceivableContractEntityType       NVARCHAR(10),
 @CustomerEntityType                 NVARCHAR(20),
 @LeaseEntityType                    NVARCHAR(20),
 @LoanEntityType                     NVARCHAR(20),
 @UnAllocatedEntityType              NVARCHAR(20),
 @ErrorCodeAR01                      NVARCHAR(10),
 @ErrorCodeAR02						 NVARCHAR(10),
 @ErrorCodeAR03						 NVARCHAR(10),
 @ErrorCodeAR04						 NVARCHAR(10),
 @ErrorCodeAR05						 NVARCHAR(10),
 @ErrorCodeAR08						 NVARCHAR(10),
 @ErrorCodeAR09						 NVARCHAR(10),
 @ErrorCodeAR12						 NVARCHAR(10),
 @ErrorCodeAR13						 NVARCHAR(10),
 @AllowCashPostingAcrossCustomers    BIT,
 @CreatedById                        BIGINT,
 @CreatedTime                        DATETIMEOFFSET
)
AS
  BEGIN
    SET NOCOUNT ON;
	CREATE TABLE #ReceiptDetails
    (ACHReceiptId                 BIGINT,
     ReceiptId                    BIGINT,
     Currency                     NVARCHAR(10),
     ReceiptClassification        NVARCHAR(46),
     LegalEntityId                BIGINT,
     LineOfBusinessId             BIGINT,
     CostCenterId                 BIGINT,
     InstrumentTypeId             BIGINT,
     BranchId                     BIGINT,
     ContractId                   BIGINT,
     EntityType                   NVARCHAR(28),
     CustomerId                   BIGINT,
     ReceiptAmount                DECIMAL(16,2),
     BankAccountId                BIGINT,
     CurrencyId                   BIGINT,
     ReceiptType                  NVARCHAR(60),
     ReceiptGLTemplateId          BIGINT,
     CheckNumber                  NVARCHAR(400),
     Status                       NVARCHAR(30),
     UnallocatedAmount            DECIMAL(16,2),
     ReceiptApplicationId         BIGINT,
     SettlementDate               DATE,
     IsOneTimeACH                 BIT,
     InactivateBankAccountId      BIGINT,
     ExtractReceiptId           BIGINT,
     ACHEntryDetailId             BIGINT,
     IsActive                     BIT,
     ReceiptTypeId                BIGINT,
     IsNewReceipt                 BIT,
	 IsValid                      BIT,
	 OneTimeACHId                 BIGINT,
	 UpdateJobStepInstanceId      BIGINT,
	 CashTypeId                 BIGINT,
    );
	CREATE TABLE #DSLReceipts
    (
	 ReceiptId                    BIGINT,
	 ReceiptAmount                DECIMAL(16,2),
	 EntityType                   NVARCHAR(28),
	 LegalEntityId                BIGINT,
	 CustomerId                   BIGINT,
	 ContractId                   BIGINT,
     CurrencyId                   BIGINT,
	 SettlementDate               DATE,
	 PostDate                     DATE,
	 AmountApplied                DECIMAL(16,2),
	 LineOfBusinessId             BIGINT,
	 InstrumentTypeId             BIGINT,
	 CashTypeId                   BIGINT,
	 CostCenterId                 BIGINT,
	 CheckNumber                  NVARCHAR(400),
     BankAccountId                BIGINT,
     BranchId                     BIGINT,
     Currency                     NVARCHAR(10),
     ReceiptStatus                NVARCHAR(30),
	 ACHReceiptId                 BIGINT,
     ACHGLTemplateId              BIGINT,
	 ACHReceiptTypeId             BIGINT,
	 ACHRunDetailId               BIGINT
	)
    CREATE TABLE #ReceivableDetails
    (ACHReceiptId       BIGINT,
     ReceivableDetailId BIGINT,
     AmountApplied      DECIMAL(16, 2),
     UnAllocatedAmount  DECIMAL(16, 2),
     TaxApplied         DECIMAL(16, 2),
     UnAllocatedTax     DECIMAL(16, 2)
    );

    CREATE TABLE #ReceivableTaxDetails
    (ACHReceiptId       BIGINT,
     ReceivableDetailId BIGINT,
     TaxApplied         DECIMAL(16, 2),
     UnAllocatedTax     DECIMAL(16, 2)
    );

    CREATE TABLE #ReceivableAmountDetails
    (ACHReceiptId       BIGINT,
     ReceivableDetailId BIGINT,
     AmountApplied      DECIMAL(16, 2),
     UnAllocatedAmount  DECIMAL(16, 2)
    );
    CREATE TABLE #OutputUnallocatedNewDSLReceiptANDNANDSL
    (ACHReceiptId BIGINT,
     OldReceiptId BIGINT,
     TraceNumber  NVARCHAR(50),
     ACHRunId     BIGINT,
     ACHRunFileId BIGINT
    );
	CREATE TABLE #RARD_ExtractTemp
	(
		RARD_ExtractId BIGINT,
		ReceiptId BIGINT,
		ReceivableId BIGINT,
		ReceivableDetailId BIGINT,
		AmountApplied DECIMAL(16,2),
		LeaseComponentAmountApplied DECIMAL(16,2),
		NonLeaseComponentAmountApplied DECIMAL(16,2),
	)

	CREATE TABLE #RARD_Extracts
	(
		RARD_ExtractId BIGINT,
		ReceiptId BIGINT,
		ReceivableId BIGINT,
		ReceivableDetailId BIGINT,
		RowNumber BIGINT,
		Amount_Amount DECIMAL(16,2),
		ComponentType NVARCHAR(20)
	)

	CREATE TABLE #UpdatedRARDTemp
	(
	  Id BIGINT,
	)
	 CREATE TABLE #ACHScheduleDetails
	 (
	    ScheduleId BIGINT,
		ACHReceiptId  BIGINT
     );

	 CREATE TABLE #BankAccountsOnHold
	 (
	    SequenceNumber NVARCHAR(40),
		ACHPaymentNumber  BIGINT,
		ACHReceiptId  BIGINT
     );

	 CREATE TABLE #OTACHBankAccountsOnHold
	 (
		OneTimeACHId BIGINT,
		ACHReceiptId  BIGINT
     );

    DECLARE @CashReceiptTypeId BIGINT=
    (
        SELECT Id
        FROM ReceiptTypes
        WHERE ReceiptTypeName = @CashReceiptType
    );
	DECLARE @RoundingValue DECIMAL(16,2) = 0.01;
    SELECT *
    INTO #LegalEntityIds
    FROM @LegalEntityIds;

    ---Fetching Receipts
	IF(@EntityType = @CustomerEntityType)
	BEGIN
	INSERT INTO #ReceiptDetails
	   (ACHReceiptId,
           ReceiptId,
           Currency,
           ReceiptClassification,
           LegalEntityId,
           LineOfBusinessId,
           CostCenterId,
           InstrumentTypeId,
           BranchId,
           ContractId,
           EntityType,
           CustomerId,
           ReceiptAmount,
           BankAccountId,
           CurrencyId,
           ReceiptType,
           ReceiptGLTemplateId,
           CheckNumber,
           Status,
           UnallocatedAmount,
           ReceiptApplicationId,
           SettlementDate,
           IsOneTimeACH,
           InactivateBankAccountId,
           ExtractReceiptId,
           ACHEntryDetailId,
           IsActive,
           ReceiptTypeId,
           IsNewReceipt,
		   IsValid,
		   OneTimeACHId,
		   UpdateJobStepInstanceId,
		   CashTypeId
          )
    SELECT ACHReceipts.Id AS ACHReceiptId,
           ReceiptId,
           Currency,
           ACHReceipts.ReceiptClassification,
           ACHReceipts.LegalEntityId,
           ACHReceipts.LineOfBusinessId,
           ACHReceipts.CostCenterId,
           ACHReceipts.InstrumentTypeId,
           ACHReceipts.BranchId,
           ACHReceipts.ContractId,
           ACHReceipts.EntityType,
           ACHReceipts.CustomerId,
           ReceiptAmount,
           ACHReceipts.BankAccountId,
           ACHReceipts.CurrencyId,
           ReceiptType,
           ACHReceipts.ReceiptGLTemplateId,
           ACHReceipts.CheckNumber,
           CASE
             WHEN SettlementDate > @ProcessThroughDate
             THEN @PendingReceiptStatus
             WHEN SettlementDate <= @ProcessThroughDate
             THEN @PostedReceiptStatus
           END AS Status,
           UnallocatedAmount,
           ReceiptApplicationId,
           SettlementDate,
           IsOneTimeACH,
           InactivateBankAccountId,
           ExtractReceiptId,
           ACHEntryDetailId,
           IsActive,
           ReceiptTypeId,
           CASE
             WHEN ReceiptId IS NULL
             THEN CAST(1 AS BIT)
             ELSE CAST(0 AS BIT)
           END AS IsNewReceipt,
		   CAST(1 AS BIT),
		   OneTimeACHId,
		   ACHReceipts.UpdateJobStepInstanceId,
		   ACHReceipts.CashTypeId
    FROM ACHReceipts
    INNER JOIN #LegalEntityIds AS LegalEntityIds ON ACHReceipts.LegalEntityId = LegalEntityIds.LegalEntityId
    LEFT JOIN Receipts ON ACHReceipts.ReceiptId = Receipts.Id AND Receipts.Status = @PendingReceiptStatus
    WHERE IsActive = 1
          AND (
				(
				 @FilterOption = @IsOneFilterOption
                 AND ACHReceipts.CustomerId = @CustomerId
				)
                OR
				 @FilterOption = @IsAllFilterOption
              )
          AND
              ( ReceiptId IS NULL
                OR
				 (
				   Receipts.Id IS NOT NULL AND
				   ACHReceipts.Status = @PendingReceiptStatus
                   AND SettlementDate <= @ProcessThroughDate
				 )
              );
    END

    IF(@EntityType = @LeaseEntityType OR @EntityType = @LoanEntityType)
	BEGIN
	INSERT INTO #ReceiptDetails
	   (ACHReceiptId,
           ReceiptId,
           Currency,
           ReceiptClassification,
           LegalEntityId,
           LineOfBusinessId,
           CostCenterId,
           InstrumentTypeId,
           BranchId,
           ContractId,
           EntityType,
           CustomerId,
           ReceiptAmount,
           BankAccountId,
           CurrencyId,
           ReceiptType,
           ReceiptGLTemplateId,
           CheckNumber,
           Status,
           UnallocatedAmount,
           ReceiptApplicationId,
           SettlementDate,
		   IsOneTimeACH,
           InactivateBankAccountId,
           ExtractReceiptId,
           ACHEntryDetailId,
           IsActive,
           ReceiptTypeId,
           IsNewReceipt,
		   IsValid,
		   OneTimeACHId,
		   UpdateJobStepInstanceId,
		   CashTypeId
          )
    SELECT ACHReceipts.Id AS ACHReceiptId,
           ReceiptId,
           Currency,
           ACHReceipts.ReceiptClassification,
           ACHReceipts.LegalEntityId,
           ACHReceipts.LineOfBusinessId,
           ACHReceipts.CostCenterId,
           ACHReceipts.InstrumentTypeId,
           ACHReceipts.BranchId,
           ACHReceipts.ContractId,
           ACHReceipts.EntityType,
           ACHReceipts.CustomerId,
           ReceiptAmount,
           ACHReceipts.BankAccountId,
           ACHReceipts.CurrencyId,
           ReceiptType,
           ACHReceipts.ReceiptGLTemplateId,
           ACHReceipts.CheckNumber,
           CASE
             WHEN SettlementDate > @ProcessThroughDate
             THEN @PendingReceiptStatus
             WHEN SettlementDate <= @ProcessThroughDate
             THEN @PostedReceiptStatus
           END AS Status,
           UnallocatedAmount,
           ReceiptApplicationId,
           SettlementDate,
           IsOneTimeACH,
           InactivateBankAccountId,
           ExtractReceiptId,
           ACHEntryDetailId,
           IsActive,
           ReceiptTypeId,
           CASE
             WHEN ReceiptId IS NULL
             THEN CAST(1 AS BIT)
             ELSE CAST(0 AS BIT)
           END AS IsNewReceipt,
		   CAST(1 AS BIT),
		   OneTimeACHId,
		   ACHReceipts.UpdateJobStepInstanceId,
		   ACHReceipts.CashTypeId
    FROM ACHReceipts
    INNER JOIN #LegalEntityIds AS LegalEntityIds ON ACHReceipts.LegalEntityId = LegalEntityIds.LegalEntityId
    INNER JOIN Contracts ON ACHReceipts.ContractId = Contracts.Id
	LEFT JOIN Receipts ON ACHReceipts.ReceiptId = Receipts.Id AND Receipts.Status = @PendingReceiptStatus
    WHERE IsActive = 1
          AND
              (
			   ( @FilterOption = @IsOneFilterOption
                 AND ACHReceipts.ContractId = @ContractId
			   )
                OR
			   @FilterOption = @IsAllFilterOption
			  )
          AND
              ( ReceiptId IS NULL
                OR
				(
				  Receipts.Id IS NOT NULL AND
				  ACHReceipts.Status = @PendingReceiptStatus
                  AND
				  SettlementDate <= @ProcessThroughDate
			    )
              );
    END

	INSERT INTO #ACHScheduleDetails
	SELECT
		  ScheduleId,
		  RD.ACHReceiptId
    FROM #ReceiptDetails RD
	INNER JOIN ACHReceiptApplicationReceivableDetails RARD ON RD.ACHReceiptId = RARD.ACHReceiptId AND RARD.IsActive = 1

    --Check GL Financial Open Period
	SELECT LegalEntityId,
	       ACHReceiptId
	INTO #GLLegalEntityIds
	FROM #ReceiptDetails

	INSERT INTO #GLLegalEntityIds
	SELECT DISTINCT
	       R.LegalEntityId,
		   RD.ACHReceiptId
	FROM #ReceiptDetails AS RD
    INNER JOIN ACHReceiptApplicationReceivableDetails AS RARD ON RD.ACHReceiptId = RARD.ACHReceiptId AND RARD.IsActive = 1
    INNER JOIN Receivables AS R ON R.Id = RARD.ReceivableId  AND R.IsActive = 1

	SELECT DISTINCT
	L.LegalEntityId,
	LE.LegalEntityNumber,
	ACHReceiptId,
	IsValidFinancialPeriod = CASE WHEN GL.LegalEntityId IS NOT NULL AND @PostDate >= FromDate AND @PostDate <= ToDate
	                              THEN CAST(1 AS BIT)
								  ELSE CAST(0 AS BIT)
                             END
	INTO #GLOpenPeriodLegalEntities
    FROM #GLLegalEntityIds L
	INNER JOIN LegalEntities LE ON L.LegalEntityId = LE.Id
	LEFT JOIN GLFinancialOpenPeriods GL ON L.LegalEntityId = GL.LegalEntityId AND IsCurrent = 1

	UPDATE #ReceiptDetails SET IsValid = 0 WHERE ACHReceiptId IN (SELECT ACHReceiptId FROM #GLOpenPeriodLegalEntities WHERE IsValidFinancialPeriod = 0)

	INSERT INTO ACHReceiptJobLogs
	(
	LegalEntityNumber,
	ErrorCode,
	CreatedById,
    CreatedTime,
	JobstepInstanceId
	)
	SELECT
	LegalEntityNumber,
	@ErrorCodeAR09,
	@CreatedById,
    @CreatedTime,
	@JobstepInstanceId
	FROM #GLOpenPeriodLegalEntities
	WHERE IsValidFinancialPeriod = 0
	GROUP BY LegalEntityNumber

	--Check if GLOrgStructure record exists
    SELECT
	     RD.ACHReceiptId
    INTO #GLOrgStructureNotValid
    FROM #ReceiptDetails RD
	LEFT JOIN GLOrgStructureConfigs GL ON RD.LineOfBusinessId = GL.LineofBusinessId
	                                   AND RD.CostCenterId = GL.CostCenterId
									   AND RD.LegalEntityId = GL.LegalEntityId
									   AND GL.IsActive = 1
    WHERE GL.LegalEntityId IS NULL AND GL.LineofBusinessId IS NULL AND GL.CostCenterId IS NULL

	UPDATE #ReceiptDetails
	SET IsValid = 0
	FROM #ReceiptDetails
	WHERE ACHReceiptId IN (SELECT ACHReceiptId FROM #GLOrgStructureNotValid GROUP BY ACHReceiptId)

    INSERT INTO ACHReceiptJobLogs
	(
	ACHScheduleId,
	ErrorCode,
	CreatedById,
    CreatedTime,
	JobstepInstanceId
	)
	SELECT
	ScheduleId,
	@ErrorCodeAR05,
	@CreatedById,
    @CreatedTime,
	@JobstepInstanceId
    FROM #GLOrgStructureNotValid
	LEFT JOIN #ACHScheduleDetails ASD ON #GLOrgStructureNotValid.ACHReceiptId = ASD.ACHReceiptId
	GROUP BY ScheduleId

    --Check if there is any Balance drop inbetween of update and return job
    IF EXISTS
    (
        SELECT 1
        FROM #ReceiptDetails
        WHERE ReceiptId IS NULL
		      AND IsValid = 1
    )
      BEGIN
        INSERT INTO #ReceivableAmountDetails
        SELECT ACHReceiptId = RARD.ACHReceiptId,
               ReceivableDetailId = RARD.ReceivableDetailId,
               AmountApplied = EffectiveBalance_Amount,
               UnAllocatedAmount = RARD.AmountApplied - RD.EffectiveBalance_Amount
        FROM #ReceiptDetails AS R
        INNER JOIN ACHReceiptApplicationReceivableDetails AS RARD ON R.ACHReceiptId = RARD.ACHReceiptId AND RARD.IsActive = 1
        INNER JOIN ReceivableDetails AS RD ON RD.Id = RARD.ReceivableDetailId  AND RD.IsActive = 1
        WHERE ReceiptId IS NULL
		      AND IsValid = 1
              AND
                  ( RARD.AmountApplied > 0
                    AND RARD.AmountApplied > RD.EffectiveBalance_Amount
                    OR RARD.AmountApplied < 0
                       AND RARD.AmountApplied < RD.EffectiveBalance_Amount
                  );

        INSERT INTO #ReceivableTaxDetails
        SELECT ACHReceiptId = RARD.ACHReceiptId,
               ReceivableDetailId = RARD.ReceivableDetailId,
               TaxApplied = SUM(EffectiveBalance_Amount),
               UnAllocatedTax = RARD.TaxApplied - SUM(RT.EffectiveBalance_Amount)
        FROM #ReceiptDetails AS R
        INNER JOIN ACHReceiptApplicationReceivableDetails AS RARD ON R.ACHReceiptId = RARD.ACHReceiptId AND RARD.IsActive = 1
        INNER JOIN ReceivableTaxDetails AS RT ON RARD.ReceivableDetailId = RT.ReceivableDetailId  AND RT.IsActive = 1
        WHERE ReceiptId IS NULL
		      AND IsValid = 1
        GROUP BY RARD.ACHReceiptId,RARD.ReceivableDetailId,TaxApplied
		HAVING
                  ( RARD.TaxApplied > 0
                    AND RARD.TaxApplied > SUM(RT.EffectiveBalance_Amount)
                    OR RARD.TaxApplied < 0
                       AND RARD.TaxApplied < SUM(RT.EffectiveBalance_Amount)
                  );

        INSERT INTO #ReceivableDetails
        SELECT ACHReceiptId = R.ACHReceiptId,
               ReceivableDetailId = R.ReceivableDetailId,
               AmountApplied = CASE
                                 WHEN A.AmountApplied IS NULL
                                 THEN R.AmountApplied
                                 ELSE A.AmountApplied
                               END,
               UnAllocatedAmount = CASE
                                     WHEN A.UnAllocatedAmount IS NULL
                                     THEN 0
                                     ELSE A.UnAllocatedAmount
                                   END,
               TaxApplied = CASE
                              WHEN T.TaxApplied IS NULL
                              THEN R.TaxApplied
                              ELSE T.TaxApplied
                            END,
               UnAllocatedTax = CASE
                                  WHEN T.UnAllocatedTax IS NULL
                                  THEN 0
                                  ELSE T.UnAllocatedTax
                                END
        FROM ACHReceiptApplicationReceivableDetails AS R
        LEFT JOIN #ReceivableAmountDetails AS A ON R.ReceivableDetailId = A.ReceivableDetailId
                                                   AND R.ACHReceiptId = A.ACHReceiptId
        LEFT JOIN #ReceivableTaxDetails AS T ON R.ReceivableDetailId = T.ReceivableDetailId
                                                AND R.ACHReceiptId = T.ACHReceiptId
        WHERE R.IsActive =1 AND A.ReceivableDetailId IS NOT NULL
              OR T.ReceivableDetailId IS NOT NULL;
    END;

   --Update the Amount applied and Unallocated Amount in Receipts
    IF EXISTS
    (
        SELECT 1
        FROM #ReceivableDetails
    )
      BEGIN
        UPDATE #ReceiptDetails
          SET
              UnAllocatedAmount = UnAllocatedAmount + UnAllocatedAmt
        FROM
        (
            SELECT SUM(UnAllocatedAmount) + SUM(UnAllocatedTax) AS UnAllocatedAmt,
                   ACHReceiptId
            FROM #ReceivableDetails AS RD
            GROUP BY RD.ACHReceiptId
        ) AS ReceiptDetails
        INNER JOIN #ReceiptDetails ON ReceiptDetails.ACHReceiptId = #ReceiptDetails.ACHReceiptId
		WHERE IsValid = 1;

        UPDATE ACHReceipts
          SET
              UnallocatedAmount = R.UnAllocatedAmount
        FROM #ReceiptDetails R
        INNER JOIN ACHReceipts AR ON R.ACHReceiptId = AR.Id
		WHERE IsValid = 1;

        UPDATE ACHReceiptApplicationReceivableDetails
          SET
              AmountApplied = RD.AmountApplied,
              TaxApplied = RD.TaxApplied
        FROM ACHReceiptApplicationReceivableDetails RARD
        INNER JOIN #ReceivableDetails RD ON RARD.ReceivableDetailId = RD.ReceivableDetailId
                                            AND RARD.ACHReceiptId = RD.ACHReceiptId;
    END;

    --Creating Unallocated Cash Receipt If Pending Receipts NonAccrual NonDSL Receipt Exists
	IF EXISTS(Select 1 FROM #ReceiptDetails WHERE ReceiptClassification = @NonAccrualNonDSLClassificationType)
	BEGIN
    SELECT
	R.ContractId,
	R.Number,
	Rd.ACHReceiptId
	INTO #NonAccrualNonDSLPendingContracts
	FROM #ReceiptDetails Rd
	INNER JOIN Receipts R ON RD.ContractId = R.ContractId AND Rd.ReceiptClassification = R.ReceiptClassification
	LEFT JOIN Receipts RDD ON RDD.Id = Rd.ReceiptId
	WHERE RDD.Id IS NULL AND R.Status = @PendingReceiptStatus
	       AND R.ReceiptClassification = @NonAccrualNonDSLClassificationType
		   AND IsValid = 1

	SELECT RD.ACHReceiptId,
	       N.ContractId
    INTO #NonAccrualNonDSLACHDetails
	FROM #NonAccrualNonDSLPendingContracts N
	INNER JOIN #ReceiptDetails RD ON N.ContractId = RD.ContractId
	                             AND RD.ReceiptClassification = @NonAccrualNonDSLClassificationType
								 AND IsValid = 1

	UPDATE #ReceiptDetails
	SET ReceiptClassification = @CashReceiptClassificationType,
	    UnallocatedAmount =  ReceiptAmount
	FROM #ReceiptDetails RD
	INNER JOIN #NonAccrualNonDSLACHDetails N ON RD.ACHReceiptId = N.ACHReceiptId
	WHERE ReceiptClassification = @NonAccrualNonDSLClassificationType
	      AND ReceiptId IS NULL
		  AND IsValid = 1

	UPDATE ACHReceipts
	SET ReceiptClassification = @CashReceiptClassificationType,
	    UnallocatedAmount =  ReceiptAmount
	FROM ACHReceipts R
	INNER JOIN #NonAccrualNonDSLACHDetails N ON R.Id = N.ACHReceiptId
	WHERE ReceiptClassification = @NonAccrualNonDSLClassificationType
	      AND ReceiptId IS NULL

	UPDATE ACHReceiptApplicationReceivableDetails
	SET IsActive = 0
	WHERE ACHReceiptId IN (SELECT ACHReceiptId FROM #NonAccrualNonDSLACHDetails)

	INSERT INTO ACHReceiptJobLogs
	(
	ErrorCode,
	ReceiptNumber,
	CreatedById,
    CreatedTime,
	JobstepInstanceId
	)
	SELECT
	@ErrorCodeAR01,
	Number,
	@CreatedById,
    @CreatedTime,
	@JobstepInstanceId
	FROM #NonAccrualNonDSLPendingContracts
	GROUP BY Number

	--Creating Unallocated Cash Receipt If More than One NonAccrual NonDSL Receipt Exists
	SELECT ACHReceiptId,
	       ContractId,
		   Row_number() OVER (PARTITION BY ContractId ORDER BY ContractId,ACHReceiptId) AS RowNumber,
		   SequenceNumber
    INTO #NonAccrualReceipts
	FROM #ReceiptDetails RD
	INNER JOIN Contracts C ON RD.ContractId = C.Id
	WHERE IsValid = 1 AND ReceiptId IS NULL AND ReceiptClassification = @NonAccrualNonDSLClassificationType
	GROUP BY ContractId,ACHReceiptId,SequenceNumber

	UPDATE #ReceiptDetails
	SET ReceiptClassification = @CashReceiptClassificationType,
	    UnallocatedAmount = ReceiptAmount
	FROM #ReceiptDetails
	INNER JOIN #NonAccrualReceipts ON #ReceiptDetails.ACHReceiptId = #NonAccrualReceipts.ACHReceiptId
	WHERE IsValid = 1 AND RowNumber > 1

	UPDATE ACHReceipts
	SET ReceiptClassification = @CashReceiptClassificationType,
	    UnallocatedAmount =  ReceiptAmount
	FROM ACHReceipts
	INNER JOIN #NonAccrualReceipts ON ACHReceipts.Id = #NonAccrualReceipts.ACHReceiptId
	WHERE RowNumber > 1

	UPDATE ACHReceiptApplicationReceivableDetails
	SET IsActive = 0
	WHERE ACHReceiptId IN (SELECT ACHReceiptId FROM #NonAccrualReceipts WHERE RowNumber > 1)

	INSERT INTO ACHReceiptJobLogs
	(
	ErrorCode,
	SequenceNumber,
	ACHScheduleId,
	CreatedById,
    CreatedTime,
	JobstepInstanceId
	)
	SELECT
	@ErrorCodeAR02,
	SequenceNumber,
	ScheduleId,
	@CreatedById,
    @CreatedTime,
	@JobstepInstanceId
	FROM #NonAccrualReceipts NR
	INNER JOIN ACHReceiptApplicationReceivableDetails RARD ON NR.ACHReceiptId = RARD.ACHReceiptId
	WHERE RowNumber > 1
	GROUP BY SequenceNumber,ScheduleId

    --Check for NonAccralNonDSL if Receivables are posting towards earliest
	;WITH CTE_Receivables AS
	(
	 SELECT Min(ReceivableId) As MinReceivableId,
	        RD.ACHReceiptId,
			RARD.ContractId
	 FROM #ReceiptDetails RD
	 INNER JOIN ACHReceiptApplicationReceivableDetails RARD
	 ON RD.ACHReceiptId = RARD.ACHReceiptId
	 WHERE IsValid = 1 AND RARD.IsActive = 1 AND RD.ReceiptClassification = @NonAccrualNonDSLClassificationType
	 GROUP BY RARD.ContractId, RD.ACHReceiptId
	 )
	 SELECT
	       CR.ContractId,
		   CR.ACHReceiptId,
		   ScheduleId
     INTO #NonAccrualNonDSLNotEarliestReceivables
	 FROM CTE_Receivables CR
	 INNER JOIN ACHReceiptApplicationReceivableDetails RARD ON CR.ACHReceiptId = RARD.ACHReceiptId
	                                                        AND RARD.IsActive = 1
	 INNER JOIN Receivables R
	 ON CR.ContractId = R.EntityId
	 WHERE R.Id < cr.MinReceivableId AND R.TotalEffectiveBalance_Amount > 0 AND R.IsActive = 1 AND R.PaymentScheduleId IS NOT NULL
	 GROUP BY CR.ContractId, CR.ACHReceiptId,ScheduleId

	UPDATE #ReceiptDetails
	SET ReceiptClassification = @CashReceiptClassificationType,
	    UnallocatedAmount =  ReceiptAmount
	FROM #ReceiptDetails RD
	INNER JOIN #NonAccrualNonDSLNotEarliestReceivables N
	ON RD.ACHReceiptId = N.ACHReceiptId
	WHERE IsValid = 1 AND ReceiptClassification = @NonAccrualNonDSLClassificationType
	AND ReceiptId IS NULL

	UPDATE ACHReceipts
	SET ReceiptClassification = @CashReceiptClassificationType,
	    UnallocatedAmount =  ReceiptAmount
	FROM ACHReceipts R
	INNER JOIN #NonAccrualNonDSLNotEarliestReceivables N ON R.Id = N.ACHReceiptId
	WHERE ReceiptClassification = @NonAccrualNonDSLClassificationType
	AND ReceiptId IS NULL

	UPDATE ACHReceiptApplicationReceivableDetails
	SET IsActive = 0
	WHERE ACHReceiptId IN (SELECT ACHReceiptId FROM #NonAccrualNonDSLNotEarliestReceivables)

	INSERT INTO ACHReceiptJobLogs
	(
	ErrorCode,
	SequenceNumber,
	ACHScheduleId,
	CreatedById,
    CreatedTime,
	JobstepInstanceId
	)
	SELECT
	@ErrorCodeAR04,
	SequenceNumber,
	ScheduleId,
	@CreatedById,
    @CreatedTime,
	@JobstepInstanceId
	FROM #NonAccrualNonDSLNotEarliestReceivables NR
	INNER JOIN Contracts C
	ON NR.ContractId = C.Id
	GROUP BY SequenceNumber,ScheduleId
	END


	--Log Info of Pending Receipts of DSL will get inactivated
	IF EXISTS(Select 1 FROM #ReceiptDetails WHERE ReceiptClassification = @DSLReceiptClassification)
	BEGIN
	SELECT
	     C.SequenceNumber,
		 RD.ACHReceiptId
	INTO #DSLPendingReceipts
	FROM #ReceiptDetails RD
	INNER JOIN Receipts R ON RD.ContractId = R.ContractId
	INNER JOIN Contracts C ON RD.ContractId = C.Id
	WHERE RD.IsValid = 1 AND RD.ReceiptClassification = @DSLReceiptClassification
	      AND R.Status = @PendingReceiptStatus
    GROUP BY C.SequenceNumber,RD.ACHReceiptId

	UPDATE #ReceiptDetails
	SET ReceiptClassification = @CashReceiptClassificationType,
	    UnallocatedAmount =  ReceiptAmount
	FROM #ReceiptDetails RD
	INNER JOIN #DSLPendingReceipts D ON RD.ACHReceiptId = D.ACHReceiptId
	WHERE IsValid = 1
	      AND ReceiptId IS NULL

	UPDATE ACHReceipts
	SET ReceiptClassification = @CashReceiptClassificationType,
	    UnallocatedAmount =  ReceiptAmount
	FROM ACHReceipts R
	INNER JOIN #DSLPendingReceipts D ON R.Id = D.ACHReceiptId
	WHERE ReceiptId IS NULL

	UPDATE ACHReceiptApplicationReceivableDetails
	SET IsActive = 0
	WHERE ACHReceiptId IN (SELECT ACHReceiptId FROM #DSLPendingReceipts)

	INSERT INTO ACHReceiptJobLogs
	(
	ErrorCode,
	SequenceNumber,
	ACHScheduleId,
	CreatedById,
    CreatedTime,
	JobstepInstanceId
	)
	SELECT
	@ErrorCodeAR03,
	SequenceNumber,
	ScheduleId,
	@CreatedById,
    @CreatedTime,
	@JobstepInstanceId
	FROM #DSLPendingReceipts D
	LEFT JOIN #ACHScheduleDetails ASD ON D.ACHReceiptId = ASD.ACHReceiptId
    GROUP BY SequenceNumber,ScheduleId

	SELECT
	     C.SequenceNumber,
		 RD.ACHReceiptId,
		 Row_number() OVER (
		      PARTITION BY RD.ContractId
			  ORDER BY RD.ContractId,RD.ACHReceiptId
              ) AS RowNumber
	INTO #DSLPendingReceiptsInCurrentRoutine
	FROM #ReceiptDetails RD
    INNER JOIN Contracts C ON RD.ContractId = C.Id
	WHERE RD.IsValid = 1 AND RD.ReceiptClassification = @DSLReceiptClassification
	      AND RD.Status = @PendingReceiptStatus
    GROUP BY C.SequenceNumber,RD.ACHReceiptId,RD.ContractId

	UPDATE #ReceiptDetails
	SET ReceiptClassification = @CashReceiptClassificationType,
	    UnallocatedAmount =  ReceiptAmount
	FROM #ReceiptDetails RD
	INNER JOIN #DSLPendingReceiptsInCurrentRoutine D ON RD.ACHReceiptId = D.ACHReceiptId
	WHERE IsValid = 1
	      AND ReceiptId IS NULL
		  AND RowNumber > 1

	UPDATE ACHReceipts
	SET ReceiptClassification = @CashReceiptClassificationType,
	    UnallocatedAmount =  ReceiptAmount
	FROM ACHReceipts R
	INNER JOIN #DSLPendingReceiptsInCurrentRoutine D ON R.Id = D.ACHReceiptId
	WHERE ReceiptId IS NULL AND RowNumber > 1

	UPDATE ACHReceiptApplicationReceivableDetails
	SET IsActive = 0
	WHERE ACHReceiptId IN (SELECT ACHReceiptId FROM #DSLPendingReceiptsInCurrentRoutine WHERE  RowNumber > 1)

	INSERT INTO ACHReceiptJobLogs
	(
	ErrorCode,
	SequenceNumber,
	ACHScheduleId,
	CreatedById,
    CreatedTime,
	JobstepInstanceId
	)
	SELECT
	@ErrorCodeAR03,
	SequenceNumber,
	ScheduleId,
	@CreatedById,
    @CreatedTime,
	@JobstepInstanceId
	FROM #DSLPendingReceiptsInCurrentRoutine D
	LEFT JOIN #ACHScheduleDetails ASD ON D.ACHReceiptId = ASD.ACHReceiptId
	WHERE RowNumber > 1
    GROUP BY SequenceNumber,ScheduleId

	--DSL Creating Unallocated Receipts if Settlement Date < Previous DueDate

    ;WITH CTE_ReceivableInfo AS
	(
	  SELECT
	       RD.ACHReceiptId,
	       ReceivableId,
	  	   RARD.ContractId,
	 	   SettlementDate
	  FROM #ReceiptDetails RD
	  INNER JOIN ACHReceiptApplicationReceivableDetails RARD ON RD.ACHReceiptId = RARD.ACHReceiptId
	  WHERE RARD.IsActive =1  AND ReceiptClassification = @DSLReceiptClassification
	  GROUP BY ReceivableId,RARD.ContractId,SettlementDate,RD.ACHReceiptId
	 )
	 SELECT
	       ACHReceiptId,
		   ContractId
     INTO #DSLCashReceipt
	 FROM CTE_ReceivableInfo RI
	 INNER JOIN Receivables R ON RI.ContractId = R.EntityId
	 WHERE R.IsActive = 1 AND R.IsDummy = 0 AND R.IsDSL = 1 AND R.PaymentScheduleId IS NOT NULL
	 GROUP BY RI.SettlementDate,RI.ContractId,ACHReceiptId
	 HAVING RI.SettlementDate < Max(DueDate)

	 UPDATE #ReceiptDetails
	 SET ReceiptClassification = @CashReceiptClassificationType,
	     UnallocatedAmount =  ReceiptAmount
	 FROM #ReceiptDetails RD
	 INNER JOIN #DSLCashReceipt D
	 ON RD.ACHReceiptId = D.ACHReceiptId
	 WHERE IsValid = 1 AND ReceiptClassification = @DSLReceiptClassification
	 AND ReceiptId IS NULL

	 UPDATE ACHReceipts
	 SET ReceiptClassification = @CashReceiptClassificationType,
	     UnallocatedAmount =  ReceiptAmount
	 FROM ACHReceipts R
	 INNER JOIN #DSLCashReceipt D ON R.Id = D.ACHReceiptId
	 WHERE ReceiptClassification = @DSLReceiptClassification
	 AND ReceiptId IS NULL

	 UPDATE ACHReceiptApplicationReceivableDetails
	 SET IsActive = 0
	 WHERE ACHReceiptId IN (SELECT ACHReceiptId FROM #DSLCashReceipt)

	 INSERT INTO ACHReceiptJobLogs
	 (
	 ErrorCode,
	 SequenceNumber,
	 CreatedById,
     CreatedTime,
	 JobstepInstanceId
	 )
	 SELECT
	 @ErrorCodeAR08,
	 SequenceNumber,
	 @CreatedById,
     @CreatedTime,
	 @JobstepInstanceId
	 FROM #DSLCashReceipt D
	 INNER JOIN Contracts C
	 ON D.ContractId = C.Id
	 GROUP BY SequenceNumber
	 END
	 
	 --Log info for Bank Accounts on Hold

	 INSERT INTO #BankAccountsOnHold
	 (
	 SequenceNumber,
	 ACHPaymentNumber,
	 ACHReceiptId
	 )
	 SELECT 
	 C.SequenceNumber,
	 ACHS.ACHPaymentNumber,
	 RD.ACHReceiptId
	 FROM #ReceiptDetails RD
	 JOIN #ACHScheduleDetails ACHSD ON RD.ACHReceiptId = ACHSD.ACHReceiptId
	 JOIN Contracts C ON RD.ContractId = C.Id
	 JOIN ACHSchedules ACHS ON ACHS.Id =  ACHSD.ScheduleId
	 JOIN BankAccounts BA ON ACHS.ACHAccountId = BA.Id AND BA.OnHold = 1
	 WHERE RD.IsOneTimeACH = 0 AND RD.IsValid = 1

	 INSERT INTO #OTACHBankAccountsOnHold
	 (
	 OneTimeACHId,
	 ACHReceiptId
	 )
	 SELECT 
	 RD.OneTimeACHId,
	 ACHReceiptId
	 FROM #ReceiptDetails RD
	 JOIN OneTimeACHes OTACHS ON OTACHS.Id =  RD.OneTimeACHId
	 JOIN BankAccounts BA ON OTACHS.BankAccountId = BA.Id AND BA.OnHold = 1
	 WHERE RD.IsOneTimeACH = 1 AND RD.IsValid = 1

	 UPDATE #ReceiptDetails
	 SET IsValid = 0
	 FROM #ReceiptDetails
	 WHERE ACHReceiptId IN (SELECT ACHReceiptId FROM #BankAccountsOnHold GROUP BY ACHReceiptId)

	 UPDATE #ReceiptDetails
	 SET IsValid = 0
	 FROM #ReceiptDetails
	 WHERE ACHReceiptId IN (SELECT ACHReceiptId FROM #OTACHBankAccountsOnHold GROUP BY ACHReceiptId)

	 INSERT INTO ACHReceiptJobLogs
	 (
	 ErrorCode,
	 SequenceNumber,
	 PaymentNumber,
	 CreatedById,
     CreatedTime,
	 JobstepInstanceId
	 )
	 SELECT
	 @ErrorCodeAR12,
	 SequenceNumber,
	 ACHPaymentNumber,
	 @CreatedById,
     @CreatedTime,
	 @JobstepInstanceId
	 FROM #BankAccountsOnHold 

	 INSERT INTO ACHReceiptJobLogs
	 (
	 ErrorCode,
	 OneTimeACHId,
	 CreatedById,
     CreatedTime,
	 JobstepInstanceId
	 )
	 SELECT
	 @ErrorCodeAR13,
	 OneTimeACHId,
	 @CreatedById,
     @CreatedTime,
	 @JobstepInstanceId
	 FROM #OTACHBankAccountsOnHold 


    --Creating unallocated if same ReceivableDetails exists in more than one Receivables
	 SELECT RD.ACHReceiptId,
            RARD.ReceivableDetailId,
		     Row_number() OVER (
		                       PARTITION BY RARD.ReceivableDetailId
							   ORDER BY
							   CASE WHEN RD.ReceiptId IS NULL THEN 0 ELSE 1 END DESC,
							   RD.ACHReceiptId
                              ) AS RowNumber
    INTO #DuplicateReceivableDetails
    FROM #ReceiptDetails RD
    INNER JOIN ACHReceiptApplicationReceivableDetails RARD ON RD.ACHReceiptId = RARD.ACHReceiptId AND RARD.IsActive = 1
    INNER JOIN
           (SELECT ReceivableDetailId
            FROM #ReceiptDetails RD
            INNER JOIN ACHReceiptApplicationReceivableDetails RARD ON RD.ACHReceiptId = RARD.ACHReceiptId AND RARD.IsActive = 1
			INNER JOIN ReceivableDetails R ON RARD.ReceivableDetailId = R.Id AND R.IsActive = 1
            GROUP BY ReceivableDetailId,EffectiveBalance_Amount
               HAVING Count(ReceivableDetailId) > 1
			          AND ((EffectiveBalance_Amount > 0 AND SUM(AmountApplied) > EffectiveBalance_Amount)
					       OR (EffectiveBalance_Amount < 0 AND SUM(AmountApplied) < EffectiveBalance_Amount))
			UNION
			SELECT RARD.ReceivableDetailId
            FROM #ReceiptDetails RD
            INNER JOIN ACHReceiptApplicationReceivableDetails RARD ON RD.ACHReceiptId = RARD.ACHReceiptId AND RARD.IsActive = 1
			INNER JOIN ReceivableTaxDetails R ON RARD.ReceivableDetailId = R.ReceivableDetailId AND R.IsActive = 1
            GROUP BY RARD.ReceivableDetailId,EffectiveBalance_Amount
               HAVING Count(RARD.ReceivableDetailId) > 1
			          AND ((EffectiveBalance_Amount > 0 AND SUM(TaxApplied) > EffectiveBalance_Amount)
					       OR (EffectiveBalance_Amount < 0 AND SUM(TaxApplied) < EffectiveBalance_Amount)
						   )) AS temp
    	    ON RARD.ReceivableDetailId = temp.ReceivableDetailId
			WHERE IsValid = 1

	UPDATE ACHReceiptApplicationReceivableDetails
	SET IsActive = 0
	FROM #DuplicateReceivableDetails
	INNER JOIN ACHReceiptApplicationReceivableDetails ON #DuplicateReceivableDetails.ACHReceiptId = ACHReceiptApplicationReceivableDetails.ACHReceiptId AND #DuplicateReceivableDetails.ReceivableDetailId = ACHReceiptApplicationReceivableDetails.ReceivableDetailId
	WHERE  RowNumber > 1

	 --DSL AND NONAccrual Loan New Receipts
    SELECT R.*,
           ROW_NUMBER() OVER(
           ORDER BY ACHReceiptId ASC) AS RowNumber,
           ACHRunDetails.ACHRunId,
		   ACHRunDetails.Id AS ACHRunDetailId,
           ACHRunDetails.TraceNumber,
           ACHRunDetails.ACHRunFileId
    INTO #UnallocatedReceiptForDSLandNANDSL
    FROM #ReceiptDetails AS R
	LEFT JOIN ACHRunDetails ON R.ACHReceiptId = ACHRunDetails.EntityId AND IsPending = 1 AND IsReversed = 0
    WHERE ReceiptClassification IN(@DSLReceiptClassification, @NonAccrualNonDSLClassificationType)
	      AND IsValid = 1
          AND UnallocatedAmount > 0
          AND ReceiptId IS NULL;

	UPDATE #ReceiptDetails
	SET ReceiptAmount = CASE WHEN (R.ReceiptAmount - U.UnallocatedAmount) <> 0 THEN  (R.ReceiptAmount - U.UnallocatedAmount) ELSE R.ReceiptAmount END ,
	    ReceiptClassification = CASE WHEN (R.ReceiptAmount - U.UnallocatedAmount) <> 0  THEN R.ReceiptClassification ELSE @CashReceiptClassificationType END
	FROM #ReceiptDetails R
	INNER JOIN #UnallocatedReceiptForDSLandNANDSL U ON R.ACHReceiptId = U.ACHReceiptId
	WHERE R.IsValid = 1

	UPDATE ACHReceipts
	SET ReceiptAmount = CASE WHEN (R.ReceiptAmount - U.UnallocatedAmount) <> 0 THEN  (R.ReceiptAmount - U.UnallocatedAmount) ELSE R.ReceiptAmount END ,
	    ReceiptClassification = CASE WHEN (R.ReceiptAmount - U.UnallocatedAmount) <> 0  THEN R.ReceiptClassification ELSE @CashReceiptClassificationType END
	FROM ACHReceipts R
	INNER JOIN #UnallocatedReceiptForDSLandNANDSL U ON R.Id = U.ACHReceiptId
	WHERE IsValid = 1

	DELETE U
    FROM #UnallocatedReceiptForDSLandNANDSL U
	INNER JOIN #ReceiptDetails AR ON U.ACHReceiptId = AR.ACHReceiptId
	WHERE AR.ReceiptClassification = @CashReceiptClassificationType

    --Creating New Receipts For DSL and NonAccrual Unallocated
    IF EXISTS( SELECT 1 FROM #UnallocatedReceiptForDSLandNANDSL)
      BEGIN
        MERGE ACHReceipts R
        USING #UnallocatedReceiptForDSLandNANDSL NR
        ON R.Id = 0
          WHEN NOT MATCHED
          THEN
              INSERT(Currency,
                     ReceiptClassification,
                     LegalEntityId,
                     LineOfBusinessId,
                     CostCenterId,
                     InstrumentTypeId,
                     BranchId,
                     ContractId,
                     EntityType,
                     ReceiptGLTemplateId,
                     CustomerId,
                     ReceiptAmount,
                     BankAccountId,
                     ReceiptApplicationId,
                     CurrencyId,
                     ReceiptType,
                     CheckNumber,
                     SettlementDate,
                     Status,
                     UnallocatedAmount,
                     TraceNumber,
                     IsOneTimeACH,
                     InactivateBankAccountId,
                     ExtractReceiptId,
                     ACHEntryDetailId,
                     IsActive,
                     ReceiptTypeId,
                     CreatedById,
                     CreatedTime,
					 UpdateJobStepInstanceId,
					 CashTypeId)
              VALUES
        (Currency,
         @CashReceiptClassificationType,
         LegalEntityId,
         LineOfBusinessId,
         CostCenterId,
         InstrumentTypeId,
         BranchId,
         ContractId,
         EntityType,
         ReceiptGLTemplateId,
         CustomerId,
         UnallocatedAmount,
         BankAccountId,
         ReceiptApplicationId,
         CurrencyId,
         ReceiptType,
         CheckNumber,
         SettlementDate,
         Status,
         0,
         TraceNumber,
         IsOneTimeACH,
         InactivateBankAccountId,
         ExtractReceiptId,
         ACHEntryDetailId,
         NR.IsActive,
         ReceiptTypeId,
         @CreatedById,
         @CreatedTime,
		 UpdateJobStepInstanceId,
		 CashTypeId
        )
        OUTPUT Inserted.Id AS ACHReceiptId,
               NR.ACHReceiptId AS OldACHReceiptId,
               NR.TraceNumber,
               NR.ACHRunId,
               NR.ACHRunFileId
               INTO #OutputUnallocatedNewDSLReceiptANDNANDSL;

        INSERT INTO ACHRunDetails
          (EntityId,
           TraceNumber,
           CreatedById,
           CreatedTime,
           ACHRunId,
           ACHRunFileId,
           IsPending,
           IsReversed
          )
        SELECT ACHReceiptId AS EntityId,
               TraceNumber,
               @CreatedById,
               @CreatedTime,
               ACHRunId,
               ACHRunFileId,
               CAST(0 AS BIT) AS IsPending,
               CAST(0 AS BIT) AS IsReversed
        FROM #OutputUnallocatedNewDSLReceiptANDNANDSL;

        INSERT INTO #ReceiptDetails
          (ACHReceiptId,
           ReceiptId,
           Currency,
           ReceiptClassification,
           LegalEntityId,
           LineOfBusinessId,
           CostCenterId,
           InstrumentTypeId,
           BranchId,
           ContractId,
           EntityType,
           CustomerId,
           ReceiptAmount,
           BankAccountId,
           CurrencyId,
           ReceiptType,
           ReceiptGLTemplateId,
           CheckNumber,
           Status,
           UnallocatedAmount,
           ReceiptApplicationId,
           SettlementDate,
           IsOneTimeACH,
           InactivateBankAccountId,
           ExtractReceiptId,
           ACHEntryDetailId,
           IsActive,
           ReceiptTypeId,
           IsNewReceipt,
		   IsValid,
		   OneTimeACHId,
		   UpdateJobStepInstanceId,
		   CashTypeId
          )
        SELECT R.ACHReceiptId,
               ReceiptId,
               Currency,
               @CashReceiptClassificationType AS ReceiptClassification,
               LegalEntityId,
               LineOfBusinessId,
               CostCenterId,
               InstrumentTypeId,
               BranchId,
               ContractId,
               EntityType,
               CustomerId,
               UnallocatedAmount,
               BankAccountId,
               CurrencyId,
               ReceiptType,
               ReceiptGLTemplateId,
               CheckNumber,
               Status,
               UnallocatedAmount,
               ReceiptApplicationId,
               SettlementDate,
               IsOneTimeACH,
               InactivateBankAccountId,
               ExtractReceiptId,
               ACHEntryDetailId,
               AR.IsActive,
               ReceiptTypeId,
               CAST(1 AS BIT),
			   CAST(1 AS BIT),
			   OneTimeACHId,
			   AR.UpdateJobStepInstanceId,
			   AR.CashTypeId
        FROM #UnallocatedReceiptForDSLandNANDSL AS AR
        INNER JOIN #OutputUnallocatedNewDSLReceiptANDNANDSL AS R ON AR.ACHReceiptId = R.OldReceiptId;
    END;

   INSERT INTO #DSLReceipts
   (
    ReceiptId,
	ReceiptAmount,
	EntityType,
	LegalEntityId,
	CustomerId,
	ContractId,
    CurrencyId,
	SettlementDate,
	PostDate,
	AmountApplied,
	LineOfBusinessId,
	InstrumentTypeId,
	CashTypeId,
	CostCenterId,
	CheckNumber,
    BankAccountId,
    BranchId,
    Currency,
    ReceiptStatus,
	ACHReceiptId,
    ACHGLTemplateId,
	ACHReceiptTypeId,
	ACHRunDetailId
   )
   SELECT ISNULL(ReceiptId,0),
          ReceiptAmount,
          EntityType,
          LegalEntityId,
          CustomerId,
          ContractId,
          CurrencyId,
          SettlementDate,
          @PostDate AS PostDate,
          ReceiptAmount AS AmountApplied,
          LineofBusinessId,
          InstrumentTypeId,
          @CashReceiptTypeId AS CashTypeId,
          CostCenterId,
          ReceiptClassification AS CheckNumber,
          BankAccountId,
          BranchId,
          Currency,
          Status AS ReceiptStatus,
		  ACHReceiptId,
		  ReceiptGLTemplateId AS ACHGLTemplateId,
		  ReceiptTypeId AS ACHReceiptTypeId,
		  ISNULL(ACHRunDetails.Id,ReceiptACHRunDetails.Id) AS ACHRunDetailId
    FROM #ReceiptDetails
	LEFT JOIN ACHRunDetails ON ReceiptId IS NULL
	                            AND #ReceiptDetails.ACHReceiptId = ACHRunDetails.EntityId
								AND ACHRunDetails.IsPending = 1 AND ACHRunDetails.IsReversed = 0
	LEFT JOIN ACHRunDetails ReceiptACHRunDetails ON #ReceiptDetails.ReceiptId IS NOT NULL
													AND  #ReceiptDetails.ReceiptId = ReceiptACHRunDetails.EntityId
													AND ReceiptACHRunDetails.IsPending = 0 AND ReceiptACHRunDetails.IsReversed = 0
    WHERE ReceiptClassification = @DSLReceiptClassification
	      AND IsValid = 1;

	SELECT * FROM #DSLReceipts

	SELECT RD.ACHReceiptId,
		   ScheduleId,
		   IsOneTimeACH,
		   CASE WHEN RARD.ACHReceiptId IS NULL AND OneTimeACHId IS NOT NULL THEN OneTimeACHId ELSE NULL END AS OneTimeACHId
    FROM #ReceiptDetails RD
    LEFT JOIN dbo.ACHReceiptApplicationReceivableDetails AS RARD ON RD.ACHReceiptId = RARD.ACHReceiptId
    WHERE ReceiptClassification = @DSLReceiptClassification
    GROUP BY RD.IsOneTimeACH,RD.ACHReceiptId,RARD.ScheduleId,RD.OneTimeACHId,RARD.ACHReceiptId;

	--Updating ReceiptId IN #Temp
    UPDATE #ReceiptDetails
    SET    ReceiptId = RowNumber
    FROM  (SELECT
	              (Row_number()
                     OVER (
                       ORDER BY achreceiptid)*-1) AS RowNumber,
                   achreceiptid
            FROM   #ReceiptDetails
            WHERE IsValid = 1
			      AND ReceiptId IS NULL) AS T
           INNER JOIN #ReceiptDetails R
                   ON R.ACHReceiptId = T.ACHReceiptId
		   WHERE IsValid = 1
		         AND ReceiptClassification <> @DSLReceiptClassification;

    INSERT INTO Receipts_Extract
      (ReceiptId,
       Currency,
       PostDate,
       ReceivedDate,
       ReceiptClassification,
       LegalEntityId,
       IsValid,
       LineOfBusinessId,
       CostCenterId,
       InstrumentTypeId,
       BranchId,
       ContractId,
       EntityType,
       ReceiptGLTemplateId,
       CustomerId,
       IsNewReceipt,
       ReceiptType,
       ReceiptAmount,
       BankAccountId,
       CurrencyId,
       CheckNumber,
       IsReceiptHierarchyProcessed,
       Status,
       ReceiptApplicationId,
       ACHReceiptId,
       ReceiptTypeId,
       JobStepInstanceId,
       CreatedById,
       CreatedTime,
	   CashTypeId
      )
    SELECT ReceiptId,
           Currency,
           @PostDate,
           SettlementDate AS ReceivedDate,
           ReceiptClassification,
           LegalEntityId,
           CAST(1 AS BIT) AS IsValid,
           LineOfBusinessId,
           CostCenterId,
           InstrumentTypeId,
           BranchId,
           CASE WHEN EntityType = @CustomerEntityType THEN NULL ELSE ContractId END,
           EntityType,
           ReceiptGLTemplateId,
           CustomerId,
           IsNewReceipt,
           ReceiptType,
           ReceiptAmount,
           BankAccountId,
           CurrencyId,
           CheckNumber,
           CAST(1 AS BIT) AS IsReceiptHierarchyProcessed,
           Status,
           ReceiptApplicationId,
           ACHReceiptId,
           ReceiptTypeId,
           @JobStepInstanceId AS JobStepInstanceId,
           @CreatedById AS CreatedById,
           @CreatedTime AS CreatedTime,
		   CashTypeId
    FROM #ReceiptDetails
    WHERE IsValid = 1
		  AND ReceiptClassification <> @DSLReceiptClassification

	SELECT RARD.Id,
	RARD.ReceivableDetailId,
	R.ReceiptApplicationId
	INTO #ExistingRARDDetails
	FROM #ReceiptDetails AS R
    INNER JOIN ReceiptApplicationReceivableDetails AS RARD ON R.ReceiptApplicationId = RARD.ReceiptApplicationId
	AND RARD.IsActive = 1

	UPDATE ARARD
	SET ARARD.LeaseComponentAmountApplied = ISNULL(ROUND(((ARARD.AmountApplied * RDD.LeaseComponentBalance_Amount)/NULLIF(RDD.LeaseComponentBalance_Amount + RDD.NonLeaseComponentBalance_Amount,0)),2),0.00),
	ARARD.NonLeaseComponentAmountApplied = ISNULL(ROUND(((ARARD.AmountApplied  * RDD.NonLeaseComponentBalance_Amount)/NULLIF(RDD.LeaseComponentBalance_Amount + RDD.NonLeaseComponentBalance_Amount,0)),2),0.00)
	FROM #ReceiptDetails AS R
    INNER JOIN ACHReceiptApplicationReceivableDetails AS ARARD ON R.ACHReceiptId = ARARD.ACHReceiptId AND ARARD.IsActive = 1
	INNER JOIN ReceivableDetails RDD ON ARARD.ReceivableDetailId = RDD.Id AND RDD.IsActive = 1
    WHERE IsValid = 1
	AND ARARD.IsActive = 1
	AND R.ReceiptClassification <> @DSLReceiptClassification
	AND IsNewReceipt = 1;

    INSERT INTO dbo.ReceiptApplicationReceivableDetails_Extract
      (ReceiptId,
       AmountApplied,
       TaxApplied,
       BookAmountApplied,
       ReceivableDetailId,
       ReceivableDetailIsActive,
       InvoiceId,
       ContractId,
       DiscountingId,
       ReceivableId,
       IsReApplication,
       ReceiptApplicationReceivableDetailId,
       JobStepInstanceId,
       CreatedById,
       CreatedTime,
	   LeaseComponentAmountApplied,
	   NonLeaseComponentAmountApplied)
	   OUTPUT INSERTED.Id,INSERTED.ReceiptId,INSERTED.ReceivableId,INSERTED.ReceivableDetailId,INSERTED.AmountApplied,INSERTED.LeaseComponentAmountApplied,INSERTED.NonLeaseComponentAmountApplied into #RARD_ExtractTemp
    SELECT RD.ReceiptId,
           0,
           0,
           0,
           RDD.Id,
           CAST(1 AS BIT),
           NULL,
           R.EntityId,
           NULL,
           R.Id,
           CAST(0 AS BIT),
           0,
           @JobStepInstanceId,
           @CreatedById,
           @CreatedTime,
		   0.00,
		   0.00
    FROM #ReceiptDetails AS RD
    INNER JOIN Receivables R ON RD.ContractId = R.EntityId AND R.EntityType = @ReceivableContractEntityType AND RD.ReceiptClassification = @NonAccrualNonDSLClassificationType
    INNER JOIN ReceivableDetails RDD ON RDD.ReceivableId = R.Id AND R.PaymentScheduleId IS NOT NULL
    LEFT JOIN ACHReceiptApplicationReceivableDetails ARARD ON ARARD.ReceivableDetailId = RDD.Id AND ARARD.IsActive = 1 AND RD.ACHReceiptId = ARARD.ACHReceiptId
    WHERE IsValid = 1
	      AND ARARD.ReceivableDetailId IS NULL
    GROUP BY R.Id,R.EntityId,RD.ReceiptId,RDD.Id;

    INSERT INTO dbo.ReceiptApplicationReceivableDetails_Extract
      (ReceiptId,
       AmountApplied,
       TaxApplied,
       BookAmountApplied,
       ReceivableDetailId,
       ReceivableDetailIsActive,
       InvoiceId,
       ContractId,
       DiscountingId,
       ReceivableId,
       IsReApplication,
       ReceiptApplicationReceivableDetailId,
       JobStepInstanceId,
       CreatedById,
       CreatedTime,
	   LeaseComponentAmountApplied,
	   NonLeaseComponentAmountApplied)
	   OUTPUT INSERTED.Id,INSERTED.ReceiptId,INSERTED.ReceivableId,INSERTED.ReceivableDetailId,INSERTED.AmountApplied,INSERTED.LeaseComponentAmountApplied,INSERTED.NonLeaseComponentAmountApplied into #RARD_ExtractTemp
    SELECT R.ReceiptId,
           ARARD.AmountApplied,
           ARARD.TaxApplied,
           ISNULL(ARARD.BookAmountApplied,0),
           ARARD.ReceivableDetailId,
           CAST(1 AS BIT),
           ARARD.InvoiceId,
           ARARD.ContractId,
           NULL,
           ARARD.ReceivableId,
           CAST(0 AS BIT),
           CASE WHEN RARD.ReceivableDetailId IS NULL THEN 0 ELSE RARD.Id END,
           @JobStepInstanceId,
           @CreatedById,
           @CreatedTime,
		   ARARD.LeaseComponentAmountApplied,
		   ARARD.NonLeaseComponentAmountApplied
    FROM #ReceiptDetails AS R
    INNER JOIN ACHReceiptApplicationReceivableDetails AS ARARD ON R.ACHReceiptId = ARARD.ACHReceiptId AND ARARD.IsActive = 1
	INNER JOIN ReceivableDetails RDD ON ARARD.ReceivableDetailId = RDD.Id AND RDD.IsActive = 1
    LEFT JOIN #ExistingRARDDetails AS RARD ON R.ReceiptApplicationId = RARD.ReceiptApplicationId
                                            AND ARARD.ReceivableDetailId = RARD.ReceivableDetailId
    WHERE IsValid = 1 AND ARARD.IsActive = 1 AND R.ReceiptClassification <> @DSLReceiptClassification AND (ARARD.AmountApplied + ARARD.TaxApplied <> 0);

    INSERT INTO ReceiptAllocations_Extract
      (ReceiptId,
       EntityType,
       AllocationAmount,
       LegalEntityId,
       ContractId,
       IsStatementInvoiceCalculationRequired,
       JobStepInstanceId,
       CreatedById,
       CreatedTime
      )
    SELECT ReceiptId,
           CASE WHEN (@EntityType=@CustomerEntityType OR @AllowCashPostingAcrossCustomers = 1) THEN @UnAllocatedEntityType ELSE  AR.EntityType END,
           AR.ReceiptAmount,
           LegalEntityId,
           CASE WHEN (EntityType = @CustomerEntityType OR @AllowCashPostingAcrossCustomers = 1) THEN NULL ELSE ContractId END,
           CAST(0 AS BIT),
           @JobStepInstanceId,
           @CreatedById,
           @CreatedTime
    FROM #ReceiptDetails AS AR
    WHERE IsValid = 1
	      AND AR.ReceiptClassification <> @DSLReceiptClassification;

    INSERT INTO ReceiptStatmentInvoiceAssociations_Extract
      (ReceiptId,
       StatementInvoiceId,
	   JobstepInstanceId,
       CreatedById,
       CreatedTime
      )
    SELECT R.ReceiptId AS ReceiptId,
           StatementInvoiceId,
		   @JobstepInstanceId,
           @CreatedById,
           @CreatedTime
    FROM ACHReceiptAssociatedStatementInvoices AS SI
    INNER JOIN #ReceiptDetails AS R ON SI.ACHReceiptId = R.ACHReceiptId
	WHERE IsValid = 1
	      AND R.ReceiptClassification <> @DSLReceiptClassification;

	UPDATE ReceiptApplicationReceivableDetails_Extract
	SET InvoiceId = RID.ReceivableInvoiceId
	FROM ReceivableInvoiceDetails RID
	WHERE ReceiptApplicationReceivableDetails_Extract.JobStepInstanceId = @JobStepInstanceId
	AND ReceiptApplicationReceivableDetails_Extract.InvoiceId IS NULL
	AND ReceiptApplicationReceivableDetails_Extract.ReceivableDetailId = RID.ReceivableDetailId
	AND RID.IsActive = 1;

	INSERT INTO #RARD_Extracts(RARD_ExtractId,ReceiptId,ReceivableId,ReceivableDetailId,Amount_Amount,ComponentType,RowNumber)
	SELECT RARD_ExtractId,ReceiptId,ReceivableId,ReceivableDetailId,LeaseComponentAmountApplied AS Amount_Amount,'Lease',
	CASE WHEN LeaseComponentAmountApplied >= NonLeaseComponentAmountApplied THEN 1 ELSE 2 END AS RowNumber
	FROM #RARD_ExtractTemp RE
    UNION ALL
	SELECT RARD_ExtractId,ReceiptId,ReceivableId,ReceivableDetailId,NonLeaseComponentAmountApplied AS Amount_Amount,'NonLease',
	CASE WHEN NonLeaseComponentAmountApplied > LeaseComponentAmountApplied THEN 1 ELSE 2 END AS RowNumber
	FROM #RARD_ExtractTemp RE;

    UPDATE #RARD_Extracts
	SET Amount_Amount = Amount_Amount + RoundingValue
	OUTPUT INSERTED.RARD_ExtractId INTO #UpdatedRARDTemp
	FROM #RARD_Extracts
	JOIN (
	        SELECT #RARD_ExtractTemp.RARD_ExtractId,(#RARD_ExtractTemp.AmountApplied - SUM(Amount_Amount)) DifferenceAfterDistribution,
			CASE WHEN (#RARD_ExtractTemp.AmountApplied - SUM(Amount_Amount)) < 0 THEN -(@RoundingValue) ELSE @RoundingValue END AS RoundingValue
		    FROM  #RARD_ExtractTemp
			JOIN #RARD_Extracts ON #RARD_ExtractTemp.RARD_ExtractId = #RARD_Extracts.RARD_ExtractId
								AND #RARD_Extracts.ReceivableDetailId = #RARD_ExtractTemp.ReceivableDetailId
								AND #RARD_Extracts.ReceivableId = #RARD_ExtractTemp.ReceivableId
			GROUP BY  #RARD_ExtractTemp.ReceivableId,
					  #RARD_ExtractTemp.ReceivableDetailId,
					  #RARD_ExtractTemp.RARD_ExtractId,
					  #RARD_ExtractTemp.AmountApplied
			HAVING #RARD_ExtractTemp.AmountApplied <> SUM(Amount_Amount)
         ) AS AppliedRARD_Extracts
		 ON #RARD_Extracts.RARD_ExtractId = AppliedRARD_Extracts.RARD_ExtractId
    WHERE  (#RARD_Extracts.RowNumber <= CAST(AppliedRARD_Extracts.DifferenceAfterDistribution/RoundingValue AS BIGINT)
	     AND AppliedRARD_Extracts.RARD_ExtractId = #RARD_Extracts.RARD_ExtractId)

	UPDATE ReceiptApplicationReceivableDetails_Extract
       SET LeaseComponentAmountApplied = CASE WHEN #RARD_Extracts.ComponentType = 'Lease' THEN #RARD_Extracts.Amount_Amount ELSE LeaseComponentAmountApplied END
           ,NonLeaseComponentAmountApplied = CASE WHEN #RARD_Extracts.ComponentType = 'NonLease' THEN #RARD_Extracts.Amount_Amount ELSE NonLeaseComponentAmountApplied END
   FROM #RARD_Extracts
       INNER JOIN ReceiptApplicationReceivableDetails_Extract RARDE ON #RARD_Extracts.RARD_ExtractId = RARDE.Id
       INNER JOIN #UpdatedRARDTemp ON RARDE.Id = #UpdatedRARDTemp.Id;


	UPDATE ReceiptApplicationReceivableDetails_Extract
	SET LeaseComponentAmountApplied = 0.00,
	    NonLeaseComponentAmountApplied = 0.00
    WHERE JobStepInstanceId =@JobStepInstanceId
	AND AmountApplied = 0.00;


	DROP TABLE #RARD_ExtractTemp
	DROP TABLE #RARD_Extracts
	DROP TABLE #UpdatedRARDTemp
	DROP TABLE #ReceiptDetails
	DROP TABLE #ReceivableDetails
	DROP TABLE #ReceivableTaxDetails
	DROP TABLE #ReceivableAmountDetails
	DROP TABLE #OutputUnallocatedNewDSLReceiptANDNANDSL
	DROP TABLE #LegalEntityIds
	DROP TABLE #UnallocatedReceiptForDSLandNANDSL
	DROP TABLE #ExistingRARDDetails
	DROP TABLE #GLOpenPeriodLegalEntities
	DROP TABLE #GLLegalEntityIds
	DROP TABLE #DuplicateReceivableDetails
  END

GO

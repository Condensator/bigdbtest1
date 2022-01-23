SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateACHValidatingParameters]
(@DSLReceiptClassification           NVARCHAR(23),
 @NANDSLReceiptClassification        NVARCHAR(23),
 @ReadyForPostingReceiptStatus       NVARCHAR(15),
 @PendingReceiptStatus               NVARCHAR(15),
 @SubmittedReceiptStatus             NVARCHAR(15),
 @NANDSLNonCashReceiptClassification NVARCHAR(23),
 @EntityType                         NVARCHAR(15),
 @LeaseEntityType                    NVARCHAR(15),
 @LoanEntityType                     NVARCHAR(15),
 @CustomerEntityType                 NVARCHAR(15),
 @FilterOption                       NVARCHAR(9),
 @AllFilterOption                    NVARCHAR(9),
 @OneFilterOption                    NVARCHAR(9),
 @CTReceivableEntityType             NVARCHAR(5),
 @LoanContractType                   NVARCHAR(15),
 @ProgressLoanContractType           NVARCHAR(15),
 @ContractId                         BIGINT,
 @JobStepInstanceId                  BIGINT,
 @FromCustomerId                     BIGINT,
 @ToCustomerId                       BIGINT
)
AS
  BEGIN

    SELECT DISTINCT
           ACHDetail.OneTimeACHId,
           ACHDetail.ACHScheduleId,
           r.Id AS ReceiptId
    INTO #DSLOrNonAccruvalContractsToExclude
    FROM dbo.ACHSchedule_Extract AS ACHDetail
    JOIN dbo.Receipts AS r ON r.ContractId = ACHDetail.ContractId
    WHERE ACHDetail.JobStepInstanceId = @JobStepInstanceId
          AND ACHDetail.ReceiptClassificationTYpe IN(@DSLReceiptClassification, @NANDSLReceiptClassification)
         AND r.STATUS IN(@ReadyForPostingReceiptStatus, @PendingReceiptStatus, @SubmittedReceiptStatus)
    AND r.ReceiptClassification IN(@DSLReceiptClassification, @NANDSLReceiptClassification, @NANDSLNonCashReceiptClassification)
    AND
        ( @ToCustomerId = 0
          OR ACHDetail.CustomerId BETWEEN @FromCustomerId AND @ToCustomerId
        );

    WITH CTE_OneTimeACHIds
         AS (SELECT #DSLOrNonAccruvalContractsToExclude.OneTimeAChId,
                    STRING_AGG(CAST(#DSLOrNonAccruvalContractsToExclude.ReceiptId AS NVARCHAR(MAX)), ',') AS ReceiptIds
             FROM #DSLOrNonAccruvalContractsToExclude
             GROUP BY #DSLOrNonAccruvalContractsToExclude.OneTimeACHId)
         UPDATE ACHDetail
           SET
               HasPendingDSLOrNANSDLReceipt = 1,
               PendingReceiptIds = ReceiptIds
         FROM dbo.ACHSchedule_Extract ACHDetail
         JOIN CTE_OneTimeACHIds ON CTE_OneTimeACHIds.OneTimeACHId = ACHDetail.OneTimeACHId
         WHERE JobStepInstanceId = @JobStepInstanceId
               AND ErrorCode = '_';

    WITH CTE_ACHIds
         AS (SELECT #DSLOrNonAccruvalContractsToExclude.ACHScheduleId,
                    STRING_AGG(CAST(#DSLOrNonAccruvalContractsToExclude.ReceiptId AS NVARCHAR(MAX)), ',') AS ReceiptIds
             FROM #DSLOrNonAccruvalContractsToExclude
             GROUP BY #DSLOrNonAccruvalContractsToExclude.ACHScheduleId)
         UPDATE ACHDetail
           SET
               HasPendingDSLOrNANSDLReceipt = 1,
               PendingReceiptIds = ReceiptIds
         FROM dbo.ACHSchedule_Extract ACHDetail
         JOIN CTE_ACHIds ON CTE_ACHIds.ACHScheduleId = ACHDetail.ACHScheduleId
         WHERE JobStepInstanceId = @JobStepInstanceId
               AND ErrorCode = '_';

    IF @EntityType <> @CustomerEntityType
      BEGIN
        CREATE TABLE #InvalidOneTimeACHIdsHavingMultipleContract(OneTimeACHId BIGINT);

        SELECT AE.OneTimeACHId,
               AE.OneTimeACHScheduleId,
			   AE.ReceivableDetailId
        INTO #DistinctOneTimeACHDetails
        FROM dbo.ACHSchedule_Extract AS AE
        WHERE AE.JobStepInstanceId = @JobStepInstanceId
              AND AE.ErrorCode = '_'
              AND AE.IsOneTimeACH = 1
        GROUP BY AE.OneTimeACHId,
                 AE.OneTimeACHScheduleId,
				 AE.ReceivableDetailId;

	SELECT OneTimeACHId INTO #DistinctOneTimeACHIds FROM #DistinctOneTimeACHDetails GROUP BY OneTimeACHId
        -----Has Invoices of Multiple Contracts
		;WITH ValidOneTimeAChSchedules 
		AS
		(
		Select OTAS.Id,OTAS.OneTimeACHId, OTRD.ReceivableDetailId
		from #DistinctOneTimeACHIds AE
		JOIN OneTimeACHSchedules OTAS ON AE.OneTimeACHId = OTAS.OneTimeACHId 
		JOIN OneTimeACHReceivableDetails OTRD ON OTRD.OneTimeACHScheduleId = OTAS.Id 
		Where OTAS.IsActive = 1 AND OTAS.ACHAmount_Amount <> 0 AND (OTRD.AmountApplied_Amount<>0 OR OTRD.TaxApplied_Amount<>0)
		AND OTRD.IsActive = 1 
		GROUP BY OTAS.Id,OTAS.OneTimeACHId,OTRD.ReceivableDetailId
		)
        INSERT INTO #InvalidOneTimeACHIdsHavingMultipleContract
        SELECT OTAS.OneTimeACHId
        FROM ValidOneTimeAChSchedules AS OTAS
        LEFT JOIN #DistinctOneTimeACHDetails AS AE ON OTAS.ID = AE.OneTimeACHScheduleId AND OTAS.OneTimeACHId = AE.OneTimeACHId AND OTAS.ReceivableDetailId = AE.ReceivableDetailId
        WHERE AE.ReceivableDetailId IS NULL
        GROUP BY OTAS.OneTimeACHId;

        UPDATE AE
          SET
              AE.HasMultipleContractReceivables = 1
        FROM dbo.ACHSchedule_Extract AE
        JOIN #InvalidOneTimeACHIdsHavingMultipleContract ON AE.OneTimeACHId = #InvalidOneTimeACHIdsHavingMultipleContract.OneTimeACHId
        WHERE AE.JobStepInstanceId = @JobStepInstanceId;
    END;
  END;

GO

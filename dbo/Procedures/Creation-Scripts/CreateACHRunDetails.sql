SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[CreateACHRunDetails]
(
 @UpdatedById       BIGINT,
 @UpdatedTime       DATETIMEOFFSET,
 @JobStepInstanceId BIGINT,
 @ACHRunEntityType  NVARCHAR(8),
 @ACHFileExtension  NVARCHAR(6),
 @FilePath          NVARCHAR(100),
 @RecurringFilePath NVARCHAR(100),
 @OTFilePath        NVARCHAR(100),
 @GenerateSeparateFileForOTACH BIT,
 @ACHRunId BIGINT OUT
)
AS
  BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    CREATE TABLE #PersistedACHRunFiles
    (Id           BIGINT,
     FileHeaderId BIGINT
    );

    CREATE TABLE #PersistedACHRunDetails
    (Id             BIGINT,
     ACHReceiptId BIGINT,
	 IsOneTimeACH BIT
    );

	 CREATE TABLE #ACHRunScheduleDetails
    (ACHRunDetailId		  BIGINT,
     ScheduleId BIGINT,
	 IsOneTimeACH BIT
    );

    INSERT INTO dbo.ACHRuns
      (JobStepInstanceId,
       EntityType,
       CreatedById,
       CreatedTime
      )
    VALUES
    (@JobStepInstanceId,
     @ACHRunEntityType,
     @UpdatedById,
     @UpdatedTime
    );

    SET @ACHRunId = SCOPE_IDENTITY();

    MERGE INTO ACHRunFiles
    USING
    (
        SELECT H.Id,
               ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) AS FileCount,
               H.FileFormat,
			    CASE WHEN @GenerateSeparateFileForOTACH = 1 THEN CASE WHEN  H.GenerateSeparateOneTimeACH = 1 THEN @OTFilePath ELSE @RecurringFilePath END ELSE @FilePath END AS FilePath
        FROM dbo.ACHFileHeaders AS H
        WHERE H.JobStepInstanceId = @JobStepInstanceId
		AND H.TotalDebitAmount > 0
    ) AS FH
    ON 1 = 0
      WHEN NOT MATCHED
      THEN
          INSERT(FileLocation,
                 CreatedById,
                 CreatedTime,
                 ACHRunId)
          VALUES
    (FilePath + FileFormat + '-' + CAST(@ACHRunId AS NVARCHAR) + '-' + CAST(FileCount AS NVARCHAR) + +'-' + CAST(DATEPART(YEAR, @UpdatedTime) AS NVARCHAR) + CAST(DATEPART(MONTH, @UpdatedTime) AS NVARCHAR) + CAST(DATEPART(DAY, @UpdatedTime) AS NVARCHAR) + @ACHFileExtension,
     @UpdatedById,
     @UpdatedTime,
     @ACHRunId
    )
    OUTPUT INSERTED.Id,
           FH.Id
           INTO #PersistedACHRunFiles;

	UPDATE ACHFileHeader SET ACHRunFileId = #PersistedACHRunFiles.Id
	FROM ACHFileHeaders ACHFileHeader
	JOIN #PersistedACHRunFiles ON #PersistedACHRunFiles.FileHeaderId = ACHFileHeader.Id
	WHERE JObstepInstanceId = @JobstepInstanceId

    MERGE INTO dbo.ACHRunDetails
    USING
    (
        SELECT
               ACHR.Id AS ACHRunFileId,
               RIGHT(REPLICATE('0',7)+ CAST(E.TraceNumber AS NVARCHAR(MAX)),7) AS TraceNumber,
               R.Id AS ReceiptId,
			   R.IsOneTimeACH
        FROM dbo.ACHEntryDetails AS E
        INNER JOIN dbo.ACHBatchHeaders AS B ON E.ACHBatchHeaderId = B.Id
        INNER JOIN #PersistedACHRunFiles AS ACHR ON B.ACHFileHeaderId = ACHR.FileHeaderId
        INNER JOIN ACHReceipts AS R ON E.Id = R.ACHEntryDetailId
        WHERE B.JobStepInstanceId = @JobStepInstanceId AND R.UpdateJobStepInstanceId = @JobStepInstanceId AND E.JobStepInstanceId = @JobStepInstanceId
    ) AS BH
    ON 1 = 0
      WHEN NOT MATCHED
      THEN
          INSERT(EntityId,
                 CreatedById,
                 CreatedTime,
                 ACHRunId,
                 TraceNumber,
                 ACHRunFileId,
                 IsReversed,
				 IsPending)
          VALUES
    (ReceiptId,
     @UpdatedById,
     @UpdatedTime,
     @ACHRunId,
     TraceNumber,
     ACHRunFileId,
     0,
	 1
    )
    OUTPUT INSERTED.ID,
           INSERTED.EntityId,
		   BH.IsOneTimeACH
           INTO #PersistedACHRunDetails;

	INSERT INTO #ACHRunScheduleDetails
    SELECT AR.Id AS ACHRunDetailId,
           ARARD.ScheduleId,
		   AR.IsOneTimeACH
    FROM #PersistedACHRunDetails AS AR
	INNER JOIN ACHReceipts R ON R.Id = AR.ACHReceiptId
	INNER JOIN ACHReceiptApplicationReceivableDetails ARARD ON AR.ACHReceiptId = ARARD.ACHReceiptId
	WHERE ARARD.IsActive = 1 AND R.ReceiptId IS Null AND ReceiptApplicationId IS NULL
	AND R.UpdateJobStepInstanceId = @JobStepInstanceId
    GROUP BY AR.Id,ARARD.ScheduleId,AR.IsOneTimeACH

    INSERT INTO dbo.ACHRunScheduleDetails
      (ACHScheduleId,
       IsOneTime,
       CreatedById,
       CreatedTime,
       ACHRunDetailId
      )
    SELECT DISTINCT
		   RSD.ScheduleId,
           RSD.IsOneTimeACH,
           @UpdatedById,
           @UpdatedTime,
           RSD.ACHRunDetailId
    FROM #ACHRunScheduleDetails AS RSD
  END;

GO

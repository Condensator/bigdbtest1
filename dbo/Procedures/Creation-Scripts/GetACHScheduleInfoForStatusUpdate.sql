SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 

CREATE PROC [dbo].[GetACHScheduleInfoForStatusUpdate]
(
 @JobStepInstanceId BIGINT,
 @FileGeneratedDate DATETIME,
 @ACHFileGeneratedStatus NVARCHAR(20),
 @ACHThresholdExceededStatus NVARCHAR(50),
 @ThresholdErrorCode NVARCHAR(4)
)
AS
  BEGIN

 

  SELECT * INTO #ValidDetails FROM (
  SELECT
      OneTimeACHScheduleId AS ScheduleId,
      @ACHFileGeneratedStatus AS ScheduleStatus,
      CAST(1 AS BIT) AS IsOneTimeACH,
      @FileGeneratedDate AS FileGenerationDate,
      Max(SettlementDate) AS SettlementDate,
      0.00 AS ACHAmount_Amount,
      MAX(CurrencyCode) AS ACHAmount_Currency,
      CAST(NULL AS BIGINT) AS OneTimeACHId
  FROM ACHSchedule_Extract
  WHERE JobStepInstanceId = @JobStepInstanceId
      AND IsOneTimeACH = 1
      AND ErrorCode ='_'
  GROUP BY ACHSchedule_Extract.OneTimeACHScheduleId

 

  UNION ALL

 

  SELECT
      ACHScheduleId  AS ScheduleId,
      CASE WHEN ErrorCode ='_' THEN @ACHFileGeneratedStatus ELSE @ACHThresholdExceededStatus END AS ScheduleStatus,
      CAST(0 AS BIT) AS IsOneTimeACH,
      @FileGeneratedDate AS FileGenerationDate,
      MAX(SettlementDate) AS SettlementDate,
      SUM(ACHAmount)  AS ACHAmount_Amount,
      MAX(CurrencyCode) AS ACHAmount_Currency,
      CAST(NULL AS BIGINT) AS OneTimeACHId
  FROM ACHSchedule_Extract
  WHERE JobStepInstanceId = @JobStepInstanceId
      AND IsOneTimeACH = 0
      AND (ErrorCode ='_' OR ErrorCode = @ThresholdErrorCode)
  GROUP BY ACHSchedule_Extract.ACHScheduleId,ErrorCode
  ) AS T

 

    SELECT OneTimeACHId,
        MAX(OneTimeACHScheduleId) ScheduleId,
        MAX(SettlementDate ) AS SettlementDate,
        MAX(CurrencyCode) AS CurrencyCode
    INTO #UnallocatedDetails
    FROM ACHSchedule_Extract
    WHERE JobStepInstanceId = @JobStepInstanceId
        AND IsOneTimeACH = 1
        AND ErrorCode ='_'
    GROUP BY OneTimeACHId

 

    INSERT INTO #ValidDetails
    SELECT
        NULL AS ScheduleId,
        @ACHFileGeneratedStatus AS ScheduleStatus,
        CAST(1 AS BIT) AS IsOneTimeACH,
        @FileGeneratedDate AS FileGenerationDate,
        SettlementDate AS SettlementDate,
        0.00 AS ACHAmount_Amount,
        CurrencyCode AS ACHAmount_Currency,
        CAST(OneTimeACHId AS BIGINT) AS OneTimeACHId
    FROM #UnallocatedDetails
    WHERE ScheduleId IS NULL

 

    SELECT * FROM #ValidDetails

 

 END

GO

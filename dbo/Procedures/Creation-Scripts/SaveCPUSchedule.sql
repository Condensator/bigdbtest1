SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUSchedule]
(
 @val [dbo].[CPUSchedule] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[CPUSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BaseJobRanForCompletion]=S.[BaseJobRanForCompletion],[CommencementDate]=S.[CommencementDate],[EstimationMethod]=S.[EstimationMethod],[IsActive]=S.[IsActive],[IsBasePaymentScheduleGenerationRequired]=S.[IsBasePaymentScheduleGenerationRequired],[IsCreatedFromBooking]=S.[IsCreatedFromBooking],[IsOverageTierScheduleGenerationRequired]=S.[IsOverageTierScheduleGenerationRequired],[MeterTypeId]=S.[MeterTypeId],[PayoffDate]=S.[PayoffDate],[ScheduleNumber]=S.[ScheduleNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BaseJobRanForCompletion],[CommencementDate],[CPUFinanceId],[CreatedById],[CreatedTime],[EstimationMethod],[IsActive],[IsBasePaymentScheduleGenerationRequired],[IsCreatedFromBooking],[IsOverageTierScheduleGenerationRequired],[MeterTypeId],[PayoffDate],[ScheduleNumber])
    VALUES (S.[BaseJobRanForCompletion],S.[CommencementDate],S.[CPUFinanceId],S.[CreatedById],S.[CreatedTime],S.[EstimationMethod],S.[IsActive],S.[IsBasePaymentScheduleGenerationRequired],S.[IsCreatedFromBooking],S.[IsOverageTierScheduleGenerationRequired],S.[MeterTypeId],S.[PayoffDate],S.[ScheduleNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

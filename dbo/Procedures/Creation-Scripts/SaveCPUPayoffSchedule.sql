SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUPayoffSchedule]
(
 @val [dbo].[CPUPayoffSchedule] READONLY
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
MERGE [dbo].[CPUPayoffSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BaseAmount_Amount]=S.[BaseAmount_Amount],[BaseAmount_Currency]=S.[BaseAmount_Currency],[BaseUnits]=S.[BaseUnits],[IsActive]=S.[IsActive],[IsFullPayoff]=S.[IsFullPayoff],[IsPaymentScheduleGenerationRequired]=S.[IsPaymentScheduleGenerationRequired],[NumberofPayments]=S.[NumberofPayments],[PayoffDate]=S.[PayoffDate],[RefreshRequired]=S.[RefreshRequired],[ScheduleNumber]=S.[ScheduleNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BaseAmount_Amount],[BaseAmount_Currency],[BaseUnits],[CPUPayoffId],[CreatedById],[CreatedTime],[IsActive],[IsFullPayoff],[IsPaymentScheduleGenerationRequired],[NumberofPayments],[PayoffDate],[RefreshRequired],[ScheduleNumber])
    VALUES (S.[BaseAmount_Amount],S.[BaseAmount_Currency],S.[BaseUnits],S.[CPUPayoffId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsFullPayoff],S.[IsPaymentScheduleGenerationRequired],S.[NumberofPayments],S.[PayoffDate],S.[RefreshRequired],S.[ScheduleNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

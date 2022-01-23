SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUPayoffPaymentSchedule]
(
 @val [dbo].[CPUPayoffPaymentSchedule] READONLY
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
MERGE [dbo].[CPUPayoffPaymentSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BaseAmount_Amount]=S.[BaseAmount_Amount],[BaseAmount_Currency]=S.[BaseAmount_Currency],[BaseUnits]=S.[BaseUnits],[DueDate]=S.[DueDate],[EndDate]=S.[EndDate],[IsActive]=S.[IsActive],[PaymentNumber]=S.[PaymentNumber],[PaymentType]=S.[PaymentType],[StartDate]=S.[StartDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BaseAmount_Amount],[BaseAmount_Currency],[BaseUnits],[CPUPayoffScheduleId],[CreatedById],[CreatedTime],[DueDate],[EndDate],[IsActive],[PaymentNumber],[PaymentType],[StartDate])
    VALUES (S.[BaseAmount_Amount],S.[BaseAmount_Currency],S.[BaseUnits],S.[CPUPayoffScheduleId],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[EndDate],S.[IsActive],S.[PaymentNumber],S.[PaymentType],S.[StartDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

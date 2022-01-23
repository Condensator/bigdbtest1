SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUPaymentSchedule]
(
 @val [dbo].[CPUPaymentSchedule] READONLY
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
MERGE [dbo].[CPUPaymentSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[DueDate]=S.[DueDate],[EndDate]=S.[EndDate],[IsActive]=S.[IsActive],[PaymentNumber]=S.[PaymentNumber],[PaymentType]=S.[PaymentType],[StartDate]=S.[StartDate],[Units]=S.[Units],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[CPUBaseStructureId],[CreatedById],[CreatedTime],[DueDate],[EndDate],[IsActive],[PaymentNumber],[PaymentType],[StartDate],[Units])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[CPUBaseStructureId],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[EndDate],S.[IsActive],S.[PaymentNumber],S.[PaymentType],S.[StartDate],S.[Units])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

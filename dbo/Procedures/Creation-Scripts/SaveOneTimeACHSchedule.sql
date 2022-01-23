SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOneTimeACHSchedule]
(
 @val [dbo].[OneTimeACHSchedule] READONLY
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
MERGE [dbo].[OneTimeACHSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHAmount_Amount]=S.[ACHAmount_Amount],[ACHAmount_Currency]=S.[ACHAmount_Currency],[IsActive]=S.[IsActive],[IsSeparateReceipt]=S.[IsSeparateReceipt],[ReceivableId]=S.[ReceivableId],[ReceivableInvoiceId]=S.[ReceivableInvoiceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHAmount_Amount],[ACHAmount_Currency],[CreatedById],[CreatedTime],[IsActive],[IsSeparateReceipt],[OneTimeACHId],[ReceivableId],[ReceivableInvoiceId])
    VALUES (S.[ACHAmount_Amount],S.[ACHAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsSeparateReceipt],S.[OneTimeACHId],S.[ReceivableId],S.[ReceivableInvoiceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

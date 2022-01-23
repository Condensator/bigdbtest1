SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptReversalReason]
(
 @val [dbo].[ReceiptReversalReason] READONLY
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
MERGE [dbo].[ReceiptReversalReasons] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Code]=S.[Code],[CreateReceivable]=S.[CreateReceivable],[Description]=S.[Description],[IncrementACHFailureCount]=S.[IncrementACHFailureCount],[IsActive]=S.[IsActive],[NSFFee_Amount]=S.[NSFFee_Amount],[NSFFee_Currency]=S.[NSFFee_Currency],[ReACH]=S.[ReACH],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Code],[CreatedById],[CreatedTime],[CreateReceivable],[Description],[IncrementACHFailureCount],[IsActive],[NSFFee_Amount],[NSFFee_Currency],[ReACH])
    VALUES (S.[Code],S.[CreatedById],S.[CreatedTime],S.[CreateReceivable],S.[Description],S.[IncrementACHFailureCount],S.[IsActive],S.[NSFFee_Amount],S.[NSFFee_Currency],S.[ReACH])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

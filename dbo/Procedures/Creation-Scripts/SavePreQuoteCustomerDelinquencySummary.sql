SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePreQuoteCustomerDelinquencySummary]
(
 @val [dbo].[PreQuoteCustomerDelinquencySummary] READONLY
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
MERGE [dbo].[PreQuoteCustomerDelinquencySummaries] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CustomerId]=S.[CustomerId],[Fifteendayslate]=S.[Fifteendayslate],[IsActive]=S.[IsActive],[Nintydayslate]=S.[Nintydayslate],[Sixtydayslate]=S.[Sixtydayslate],[Thirtydayslate]=S.[Thirtydayslate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CustomerId],[Fifteendayslate],[IsActive],[Nintydayslate],[PreQuoteId],[Sixtydayslate],[Thirtydayslate])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[Fifteendayslate],S.[IsActive],S.[Nintydayslate],S.[PreQuoteId],S.[Sixtydayslate],S.[Thirtydayslate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

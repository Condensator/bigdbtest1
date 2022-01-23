SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditRAC]
(
 @val [dbo].[CreditRAC] READONLY
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
MERGE [dbo].[CreditRACs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BusinessDeclineReasonCode]=S.[BusinessDeclineReasonCode],[IsActive]=S.[IsActive],[PortfolioId]=S.[PortfolioId],[RACId]=S.[RACId],[Result]=S.[Result],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Use]=S.[Use]
WHEN NOT MATCHED THEN
	INSERT ([BusinessDeclineReasonCode],[CreatedById],[CreatedTime],[CreditDecisionId],[IsActive],[PortfolioId],[RACId],[Result],[Use])
    VALUES (S.[BusinessDeclineReasonCode],S.[CreatedById],S.[CreatedTime],S.[CreditDecisionId],S.[IsActive],S.[PortfolioId],S.[RACId],S.[Result],S.[Use])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

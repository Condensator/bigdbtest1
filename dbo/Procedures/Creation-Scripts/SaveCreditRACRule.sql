SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditRACRule]
(
 @val [dbo].[CreditRACRule] READONLY
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
MERGE [dbo].[CreditRACRules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActualValue]=S.[ActualValue],[BusinessDeclineReasonCode]=S.[BusinessDeclineReasonCode],[RACRuleId]=S.[RACRuleId],[Result]=S.[Result],[RuleDisplayText]=S.[RuleDisplayText],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActualValue],[BusinessDeclineReasonCode],[CreatedById],[CreatedTime],[CreditRACId],[RACRuleId],[Result],[RuleDisplayText],[Type])
    VALUES (S.[ActualValue],S.[BusinessDeclineReasonCode],S.[CreatedById],S.[CreatedTime],S.[CreditRACId],S.[RACRuleId],S.[Result],S.[RuleDisplayText],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

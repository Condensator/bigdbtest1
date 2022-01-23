SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAcceleratedBalanceCredit]
(
 @val [dbo].[AcceleratedBalanceCredit] READONLY
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
MERGE [dbo].[AcceleratedBalanceCredits] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[CheckNumber]=S.[CheckNumber],[CreditDescription]=S.[CreditDescription],[DateApplied]=S.[DateApplied],[IsActive]=S.[IsActive],[IsJudgement]=S.[IsJudgement],[IsLease]=S.[IsLease],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcceleratedBalanceDetailId],[Amount_Amount],[Amount_Currency],[CheckNumber],[CreatedById],[CreatedTime],[CreditDescription],[DateApplied],[IsActive],[IsJudgement],[IsLease])
    VALUES (S.[AcceleratedBalanceDetailId],S.[Amount_Amount],S.[Amount_Currency],S.[CheckNumber],S.[CreatedById],S.[CreatedTime],S.[CreditDescription],S.[DateApplied],S.[IsActive],S.[IsJudgement],S.[IsLease])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

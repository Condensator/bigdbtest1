SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAcceleratedBalanceInterestAccrualDetail]
(
 @val [dbo].[AcceleratedBalanceInterestAccrualDetail] READONLY
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
MERGE [dbo].[AcceleratedBalanceInterestAccrualDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[From]=S.[From],[IsActive]=S.[IsActive],[IsJudgement]=S.[IsJudgement],[IsLease]=S.[IsLease],[RowNo]=S.[RowNo],[To]=S.[To],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcceleratedBalanceDetailId],[Amount_Amount],[Amount_Currency],[CreatedById],[CreatedTime],[From],[IsActive],[IsJudgement],[IsLease],[RowNo],[To],[Type])
    VALUES (S.[AcceleratedBalanceDetailId],S.[Amount_Amount],S.[Amount_Currency],S.[CreatedById],S.[CreatedTime],S.[From],S.[IsActive],S.[IsJudgement],S.[IsLease],S.[RowNo],S.[To],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

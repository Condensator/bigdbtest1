SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAcceleratedBalancePIHistory]
(
 @val [dbo].[AcceleratedBalancePIHistory] READONLY
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
MERGE [dbo].[AcceleratedBalancePIHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccruedInterest_Amount]=S.[AccruedInterest_Amount],[AccruedInterest_Currency]=S.[AccruedInterest_Currency],[Asof]=S.[Asof],[InterestAccrualDetailRowNo]=S.[InterestAccrualDetailRowNo],[IsActive]=S.[IsActive],[IsJudgement]=S.[IsJudgement],[IsLease]=S.[IsLease],[PerDiem_Amount]=S.[PerDiem_Amount],[PerDiem_Currency]=S.[PerDiem_Currency],[Principal_Amount]=S.[Principal_Amount],[Principal_Currency]=S.[Principal_Currency],[TotalPAndI_Amount]=S.[TotalPAndI_Amount],[TotalPAndI_Currency]=S.[TotalPAndI_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcceleratedBalanceDetailId],[AccruedInterest_Amount],[AccruedInterest_Currency],[Asof],[CreatedById],[CreatedTime],[InterestAccrualDetailRowNo],[IsActive],[IsJudgement],[IsLease],[PerDiem_Amount],[PerDiem_Currency],[Principal_Amount],[Principal_Currency],[TotalPAndI_Amount],[TotalPAndI_Currency])
    VALUES (S.[AcceleratedBalanceDetailId],S.[AccruedInterest_Amount],S.[AccruedInterest_Currency],S.[Asof],S.[CreatedById],S.[CreatedTime],S.[InterestAccrualDetailRowNo],S.[IsActive],S.[IsJudgement],S.[IsLease],S.[PerDiem_Amount],S.[PerDiem_Currency],S.[Principal_Amount],S.[Principal_Currency],S.[TotalPAndI_Amount],S.[TotalPAndI_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

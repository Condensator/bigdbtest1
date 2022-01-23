SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseInvestmentTracking]
(
 @val [dbo].[LeaseInvestmentTracking] READONLY
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
MERGE [dbo].[LeaseInvestmentTrackings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractId]=S.[ContractId],[Investment]=S.[Investment],[InvestmentDate]=S.[InvestmentDate],[IsActive]=S.[IsActive],[IsLessorOwned]=S.[IsLessorOwned],[LeaseFinanceId]=S.[LeaseFinanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractId],[CreatedById],[CreatedTime],[Investment],[InvestmentDate],[IsActive],[IsLessorOwned],[LeaseFinanceId])
    VALUES (S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[Investment],S.[InvestmentDate],S.[IsActive],S.[IsLessorOwned],S.[LeaseFinanceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

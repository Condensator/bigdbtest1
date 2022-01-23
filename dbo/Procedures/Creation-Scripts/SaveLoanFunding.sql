SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanFunding]
(
 @val [dbo].[LoanFunding] READONLY
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
MERGE [dbo].[LoanFundings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [FundingId]=S.[FundingId],[IsActive]=S.[IsActive],[IsApproved]=S.[IsApproved],[IsEligibleForInterimBilling]=S.[IsEligibleForInterimBilling],[IsNewlyAdded]=S.[IsNewlyAdded],[RowNumber]=S.[RowNumber],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UsePayDate]=S.[UsePayDate]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[FundingId],[IsActive],[IsApproved],[IsEligibleForInterimBilling],[IsNewlyAdded],[LoanFinanceId],[RowNumber],[Type],[UsePayDate])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[FundingId],S.[IsActive],S.[IsApproved],S.[IsEligibleForInterimBilling],S.[IsNewlyAdded],S.[LoanFinanceId],S.[RowNumber],S.[Type],S.[UsePayDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

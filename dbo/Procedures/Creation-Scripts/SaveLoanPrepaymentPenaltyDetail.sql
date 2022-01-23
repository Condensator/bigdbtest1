SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanPrepaymentPenaltyDetail]
(
 @val [dbo].[LoanPrepaymentPenaltyDetail] READONLY
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
MERGE [dbo].[LoanPrepaymentPenaltyDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [FromMonth]=S.[FromMonth],[IsActive]=S.[IsActive],[Percentage]=S.[Percentage],[RowNumber]=S.[RowNumber],[ToMonth]=S.[ToMonth],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[FromMonth],[IsActive],[LoanPrepaymentPenaltyId],[Percentage],[RowNumber],[ToMonth])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[FromMonth],S.[IsActive],S.[LoanPrepaymentPenaltyId],S.[Percentage],S.[RowNumber],S.[ToMonth])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditRiskGrade]
(
 @val [dbo].[CreditRiskGrade] READONLY
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
MERGE [dbo].[CreditRiskGrades] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustedCode]=S.[AdjustedCode],[AdjustmentReasonId]=S.[AdjustmentReasonId],[Code]=S.[Code],[ContractId]=S.[ContractId],[DefaultEvent]=S.[DefaultEvent],[EntryDate]=S.[EntryDate],[FinancialStatementDate]=S.[FinancialStatementDate],[IsActive]=S.[IsActive],[IsRatingSubstitution]=S.[IsRatingSubstitution],[OverrideParty]=S.[OverrideParty],[OverrideRating]=S.[OverrideRating],[OverrideRatingDate]=S.[OverrideRatingDate],[RAID]=S.[RAID],[RatingModelId]=S.[RatingModelId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustedCode],[AdjustmentReasonId],[Code],[ContractId],[CreatedById],[CreatedTime],[CustomerId],[DefaultEvent],[EntryDate],[FinancialStatementDate],[IsActive],[IsRatingSubstitution],[OverrideParty],[OverrideRating],[OverrideRatingDate],[RAID],[RatingModelId])
    VALUES (S.[AdjustedCode],S.[AdjustmentReasonId],S.[Code],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DefaultEvent],S.[EntryDate],S.[FinancialStatementDate],S.[IsActive],S.[IsRatingSubstitution],S.[OverrideParty],S.[OverrideRating],S.[OverrideRatingDate],S.[RAID],S.[RatingModelId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

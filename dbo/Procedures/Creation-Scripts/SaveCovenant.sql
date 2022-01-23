SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCovenant]
(
 @val [dbo].[Covenant] READONLY
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
MERGE [dbo].[Covenants] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CcEmail]=S.[CcEmail],[Description]=S.[Description],[Frequency]=S.[Frequency],[IsActive]=S.[IsActive],[IsOverDue]=S.[IsOverDue],[IsPrimaryCustomer]=S.[IsPrimaryCustomer],[LastReviewById]=S.[LastReviewById],[LastReviewStatementDate]=S.[LastReviewStatementDate],[LastReviewStatus]=S.[LastReviewStatus],[LastReviewStatusDate]=S.[LastReviewStatusDate],[LastStatementDate]=S.[LastStatementDate],[LastStatus]=S.[LastStatus],[LastStatusDate]=S.[LastStatusDate],[RelationshipType]=S.[RelationshipType],[RemediationPlanNarrative]=S.[RemediationPlanNarrative],[ReviewDays]=S.[ReviewDays],[StatementDate]=S.[StatementDate],[Status]=S.[Status],[StatusDueDate]=S.[StatusDueDate],[TargetMaximumAmount]=S.[TargetMaximumAmount],[TargetMinimumAmount]=S.[TargetMinimumAmount],[ThirdPartyDealRelationshipId]=S.[ThirdPartyDealRelationshipId],[ToEmail]=S.[ToEmail],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CcEmail],[CreatedById],[CreatedTime],[CreditDecisionId],[Description],[Frequency],[IsActive],[IsOverDue],[IsPrimaryCustomer],[LastReviewById],[LastReviewStatementDate],[LastReviewStatus],[LastReviewStatusDate],[LastStatementDate],[LastStatus],[LastStatusDate],[RelationshipType],[RemediationPlanNarrative],[ReviewDays],[StatementDate],[Status],[StatusDueDate],[TargetMaximumAmount],[TargetMinimumAmount],[ThirdPartyDealRelationshipId],[ToEmail],[Type])
    VALUES (S.[CcEmail],S.[CreatedById],S.[CreatedTime],S.[CreditDecisionId],S.[Description],S.[Frequency],S.[IsActive],S.[IsOverDue],S.[IsPrimaryCustomer],S.[LastReviewById],S.[LastReviewStatementDate],S.[LastReviewStatus],S.[LastReviewStatusDate],S.[LastStatementDate],S.[LastStatus],S.[LastStatusDate],S.[RelationshipType],S.[RemediationPlanNarrative],S.[ReviewDays],S.[StatementDate],S.[Status],S.[StatusDueDate],S.[TargetMaximumAmount],S.[TargetMinimumAmount],S.[ThirdPartyDealRelationshipId],S.[ToEmail],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveProposal]
(
 @val [dbo].[Proposal] READONLY
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
MERGE [dbo].[Proposals] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AnticipatedFeeToSource_Amount]=S.[AnticipatedFeeToSource_Amount],[AnticipatedFeeToSource_Currency]=S.[AnticipatedFeeToSource_Currency],[DocumentMethod]=S.[DocumentMethod],[IsCreditOrAMProposal]=S.[IsCreditOrAMProposal],[IsDataGatheringComplete]=S.[IsDataGatheringComplete],[IsPreApproved]=S.[IsPreApproved],[IsSyndicated]=S.[IsSyndicated],[OpportunityAmount_Amount]=S.[OpportunityAmount_Amount],[OpportunityAmount_Currency]=S.[OpportunityAmount_Currency],[PreApprovalLOCId]=S.[PreApprovalLOCId],[Status]=S.[Status],[SyndicationStrategy]=S.[SyndicationStrategy],[TransactionDescription]=S.[TransactionDescription],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AnticipatedFeeToSource_Amount],[AnticipatedFeeToSource_Currency],[CreatedById],[CreatedTime],[DocumentMethod],[Id],[IsCreditOrAMProposal],[IsDataGatheringComplete],[IsPreApproved],[IsSyndicated],[OpportunityAmount_Amount],[OpportunityAmount_Currency],[PreApprovalLOCId],[Status],[SyndicationStrategy],[TransactionDescription])
    VALUES (S.[AnticipatedFeeToSource_Amount],S.[AnticipatedFeeToSource_Currency],S.[CreatedById],S.[CreatedTime],S.[DocumentMethod],S.[Id],S.[IsCreditOrAMProposal],S.[IsDataGatheringComplete],S.[IsPreApproved],S.[IsSyndicated],S.[OpportunityAmount_Amount],S.[OpportunityAmount_Currency],S.[PreApprovalLOCId],S.[Status],S.[SyndicationStrategy],S.[TransactionDescription])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveFunder]
(
 @val [dbo].[Funder] READONLY
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
MERGE [dbo].[Funders] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[ApprovalStatus]=S.[ApprovalStatus],[DeactivationDate]=S.[DeactivationDate],[FATCA]=S.[FATCA],[InactivationReason]=S.[InactivationReason],[IsForFunderEdit]=S.[IsForFunderEdit],[IsForFunderLegalEntityAddition]=S.[IsForFunderLegalEntityAddition],[IsForFunderRemitToAddition]=S.[IsForFunderRemitToAddition],[NextReviewDate]=S.[NextReviewDate],[Percentage1441]=S.[Percentage1441],[RejectionReasonCode]=S.[RejectionReasonCode],[Status]=S.[Status],[StatusPostApproval]=S.[StatusPostApproval],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[W8ExpirationDate]=S.[W8ExpirationDate],[W8IssueDate]=S.[W8IssueDate]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[ApprovalStatus],[CreatedById],[CreatedTime],[DeactivationDate],[FATCA],[Id],[InactivationReason],[IsForFunderEdit],[IsForFunderLegalEntityAddition],[IsForFunderRemitToAddition],[NextReviewDate],[Percentage1441],[RejectionReasonCode],[Status],[StatusPostApproval],[Type],[W8ExpirationDate],[W8IssueDate])
    VALUES (S.[ActivationDate],S.[ApprovalStatus],S.[CreatedById],S.[CreatedTime],S.[DeactivationDate],S.[FATCA],S.[Id],S.[InactivationReason],S.[IsForFunderEdit],S.[IsForFunderLegalEntityAddition],S.[IsForFunderRemitToAddition],S.[NextReviewDate],S.[Percentage1441],S.[RejectionReasonCode],S.[Status],S.[StatusPostApproval],S.[Type],S.[W8ExpirationDate],S.[W8IssueDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

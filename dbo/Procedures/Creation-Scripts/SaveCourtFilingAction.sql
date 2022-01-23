SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCourtFilingAction]
(
 @val [dbo].[CourtFilingAction] READONLY
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
MERGE [dbo].[CourtFilingActions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActionName]=S.[ActionName],[ActionStatus]=S.[ActionStatus],[ActionType]=S.[ActionType],[Comments]=S.[Comments],[DeadlineDate]=S.[DeadlineDate],[FilingDate]=S.[FilingDate],[IsDeletedRecord]=S.[IsDeletedRecord],[LegalAction]=S.[LegalAction],[LegalReliefType]=S.[LegalReliefType],[RelatedLegalActionId]=S.[RelatedLegalActionId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActionName],[ActionStatus],[ActionType],[Comments],[CourtFilingId],[CreatedById],[CreatedTime],[DeadlineDate],[FilingDate],[IsDeletedRecord],[LegalAction],[LegalReliefType],[RelatedLegalActionId])
    VALUES (S.[ActionName],S.[ActionStatus],S.[ActionType],S.[Comments],S.[CourtFilingId],S.[CreatedById],S.[CreatedTime],S.[DeadlineDate],S.[FilingDate],S.[IsDeletedRecord],S.[LegalAction],S.[LegalReliefType],S.[RelatedLegalActionId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

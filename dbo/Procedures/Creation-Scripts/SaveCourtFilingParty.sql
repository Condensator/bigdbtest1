SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCourtFilingParty]
(
 @val [dbo].[CourtFilingParty] READONLY
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
MERGE [dbo].[CourtFilingParties] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AnswerDeadlineDate]=S.[AnswerDeadlineDate],[DateServed]=S.[DateServed],[IsActive]=S.[IsActive],[IsDeletedRecord]=S.[IsDeletedRecord],[IsMainParty]=S.[IsMainParty],[LegalEntityId]=S.[LegalEntityId],[PartyId]=S.[PartyId],[PartyName]=S.[PartyName],[PartyTypes]=S.[PartyTypes],[RelatedCustomerId]=S.[RelatedCustomerId],[Role]=S.[Role],[ThirdPartyRelationshipId]=S.[ThirdPartyRelationshipId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AnswerDeadlineDate],[CourtFilingId],[CreatedById],[CreatedTime],[DateServed],[IsActive],[IsDeletedRecord],[IsMainParty],[LegalEntityId],[PartyId],[PartyName],[PartyTypes],[RelatedCustomerId],[Role],[ThirdPartyRelationshipId])
    VALUES (S.[AnswerDeadlineDate],S.[CourtFilingId],S.[CreatedById],S.[CreatedTime],S.[DateServed],S.[IsActive],S.[IsDeletedRecord],S.[IsMainParty],S.[LegalEntityId],S.[PartyId],S.[PartyName],S.[PartyTypes],S.[RelatedCustomerId],S.[Role],S.[ThirdPartyRelationshipId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

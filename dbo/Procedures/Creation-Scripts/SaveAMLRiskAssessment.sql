SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAMLRiskAssessment]
(
 @val [dbo].[AMLRiskAssessment] READONLY
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
MERGE [dbo].[AMLRiskAssessments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Entity]=S.[Entity],[EntryDate]=S.[EntryDate],[FinalDecision]=S.[FinalDecision],[InformationOnlyText]=S.[InformationOnlyText],[IsActive]=S.[IsActive],[PartyContactId]=S.[PartyContactId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[Entity],[EntryDate],[FinalDecision],[InformationOnlyText],[IsActive],[PartyContactId],[PartyId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[Entity],S.[EntryDate],S.[FinalDecision],S.[InformationOnlyText],S.[IsActive],S.[PartyContactId],S.[PartyId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

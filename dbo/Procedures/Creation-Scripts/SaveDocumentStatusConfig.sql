SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentStatusConfig]
(
 @val [dbo].[DocumentStatusConfig] READONLY
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
MERGE [dbo].[DocumentStatusConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApplicableForInDoc]=S.[ApplicableForInDoc],[ApplicableForOutDoc]=S.[ApplicableForOutDoc],[IsActive]=S.[IsActive],[IsDefault]=S.[IsDefault],[IsEnd]=S.[IsEnd],[IsException]=S.[IsException],[IsMandatory]=S.[IsMandatory],[Name]=S.[Name],[SequenceNumber]=S.[SequenceNumber],[SystemStatus]=S.[SystemStatus],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VerifyAttachment]=S.[VerifyAttachment]
WHEN NOT MATCHED THEN
	INSERT ([ApplicableForInDoc],[ApplicableForOutDoc],[CreatedById],[CreatedTime],[IsActive],[IsDefault],[IsEnd],[IsException],[IsMandatory],[Name],[SequenceNumber],[SystemStatus],[VerifyAttachment])
    VALUES (S.[ApplicableForInDoc],S.[ApplicableForOutDoc],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsDefault],S.[IsEnd],S.[IsException],S.[IsMandatory],S.[Name],S.[SequenceNumber],S.[SystemStatus],S.[VerifyAttachment])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

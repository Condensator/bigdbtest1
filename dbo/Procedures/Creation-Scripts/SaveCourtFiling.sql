SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCourtFiling]
(
 @val [dbo].[CourtFiling] READONLY
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
MERGE [dbo].[CourtFilings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CaseNumber]=S.[CaseNumber],[CourtId]=S.[CourtId],[CustomerId]=S.[CustomerId],[FilingDate]=S.[FilingDate],[IsActive]=S.[IsActive],[IsFromLegalRelief]=S.[IsFromLegalRelief],[LegalRelief]=S.[LegalRelief],[RecordStartDate]=S.[RecordStartDate],[RecordStatus]=S.[RecordStatus],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CaseNumber],[CourtId],[CreatedById],[CreatedTime],[CustomerId],[FilingDate],[IsActive],[IsFromLegalRelief],[LegalRelief],[RecordStartDate],[RecordStatus])
    VALUES (S.[CaseNumber],S.[CourtId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[FilingDate],S.[IsActive],S.[IsFromLegalRelief],S.[LegalRelief],S.[RecordStartDate],S.[RecordStatus])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

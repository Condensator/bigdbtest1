SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLienResponse]
(
 @val [dbo].[LienResponse] READONLY
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
MERGE [dbo].[LienResponses] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AuthorityFileDate]=S.[AuthorityFileDate],[AuthorityFileExpiryDate]=S.[AuthorityFileExpiryDate],[AuthorityFileNumber]=S.[AuthorityFileNumber],[AuthorityFilingOffice]=S.[AuthorityFilingOffice],[AuthorityFilingStateId]=S.[AuthorityFilingStateId],[AuthorityFilingStatus]=S.[AuthorityFilingStatus],[AuthorityFilingType]=S.[AuthorityFilingType],[AuthorityOriginalFileDate]=S.[AuthorityOriginalFileDate],[AuthoritySubmitDate]=S.[AuthoritySubmitDate],[ExternalRecordStatus]=S.[ExternalRecordStatus],[ExternalSystemNumber]=S.[ExternalSystemNumber],[ReasonReport_Content]=S.[ReasonReport_Content],[ReasonReport_Source]=S.[ReasonReport_Source],[ReasonReport_Type]=S.[ReasonReport_Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AuthorityFileDate],[AuthorityFileExpiryDate],[AuthorityFileNumber],[AuthorityFilingOffice],[AuthorityFilingStateId],[AuthorityFilingStatus],[AuthorityFilingType],[AuthorityOriginalFileDate],[AuthoritySubmitDate],[CreatedById],[CreatedTime],[ExternalRecordStatus],[ExternalSystemNumber],[Id],[ReasonReport_Content],[ReasonReport_Source],[ReasonReport_Type])
    VALUES (S.[AuthorityFileDate],S.[AuthorityFileExpiryDate],S.[AuthorityFileNumber],S.[AuthorityFilingOffice],S.[AuthorityFilingStateId],S.[AuthorityFilingStatus],S.[AuthorityFilingType],S.[AuthorityOriginalFileDate],S.[AuthoritySubmitDate],S.[CreatedById],S.[CreatedTime],S.[ExternalRecordStatus],S.[ExternalSystemNumber],S.[Id],S.[ReasonReport_Content],S.[ReasonReport_Source],S.[ReasonReport_Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

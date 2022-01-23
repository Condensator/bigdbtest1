SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveFinancialStatement]
(
 @val [dbo].[FinancialStatement] READONLY
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
MERGE [dbo].[FinancialStatements] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Comment]=S.[Comment],[DaysToUpload]=S.[DaysToUpload],[DocumentTypeId]=S.[DocumentTypeId],[Frequency]=S.[Frequency],[IsActive]=S.[IsActive],[OtherStatementType]=S.[OtherStatementType],[RAIDNumber]=S.[RAIDNumber],[StatementDate]=S.[StatementDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UploadByDate]=S.[UploadByDate]
WHEN NOT MATCHED THEN
	INSERT ([Comment],[CreatedById],[CreatedTime],[DaysToUpload],[DocumentTypeId],[Frequency],[IsActive],[OtherStatementType],[PartyId],[RAIDNumber],[StatementDate],[UploadByDate])
    VALUES (S.[Comment],S.[CreatedById],S.[CreatedTime],S.[DaysToUpload],S.[DocumentTypeId],S.[Frequency],S.[IsActive],S.[OtherStatementType],S.[PartyId],S.[RAIDNumber],S.[StatementDate],S.[UploadByDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

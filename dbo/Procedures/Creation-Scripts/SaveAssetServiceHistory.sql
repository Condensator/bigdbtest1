SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetServiceHistory]
(
 @val [dbo].[AssetServiceHistory] READONLY
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
MERGE [dbo].[AssetServiceHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingDocumentNumber]=S.[AccountingDocumentNumber],[IsActive]=S.[IsActive],[RowNumber]=S.[RowNumber],[ServiceAmountInclVAT_Amount]=S.[ServiceAmountInclVAT_Amount],[ServiceAmountInclVAT_Currency]=S.[ServiceAmountInclVAT_Currency],[ServiceConfigId]=S.[ServiceConfigId],[ServiceDate]=S.[ServiceDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingDocumentNumber],[AssetId],[CreatedById],[CreatedTime],[IsActive],[RowNumber],[ServiceAmountInclVAT_Amount],[ServiceAmountInclVAT_Currency],[ServiceConfigId],[ServiceDate])
    VALUES (S.[AccountingDocumentNumber],S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[RowNumber],S.[ServiceAmountInclVAT_Amount],S.[ServiceAmountInclVAT_Currency],S.[ServiceConfigId],S.[ServiceDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

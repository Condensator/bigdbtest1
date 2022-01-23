SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableSKU]
(
 @val [dbo].[ReceivableSKU] READONLY
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
MERGE [dbo].[ReceivableSKUs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AssetSKUId]=S.[AssetSKUId],[PreCapitalizationRent_Amount]=S.[PreCapitalizationRent_Amount],[PreCapitalizationRent_Currency]=S.[PreCapitalizationRent_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AssetSKUId],[CreatedById],[CreatedTime],[PreCapitalizationRent_Amount],[PreCapitalizationRent_Currency],[ReceivableDetailId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AssetSKUId],S.[CreatedById],S.[CreatedTime],S.[PreCapitalizationRent_Amount],S.[PreCapitalizationRent_Currency],S.[ReceivableDetailId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

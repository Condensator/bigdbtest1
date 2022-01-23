SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetDetail]
(
 @val [dbo].[AssetDetail] READONLY
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
MERGE [dbo].[AssetDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AgeofAsset]=S.[AgeofAsset],[AssetClassConfigId]=S.[AssetClassConfigId],[DateofProduction]=S.[DateofProduction],[EngineCapacity]=S.[EngineCapacity],[IsVAT]=S.[IsVAT],[KW]=S.[KW],[MakeId]=S.[MakeId],[ModelId]=S.[ModelId],[TaxCodeId]=S.[TaxCodeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[ValueExclVAT_Amount]=S.[ValueExclVAT_Amount],[ValueExclVAT_Currency]=S.[ValueExclVAT_Currency],[ValueInclVAT_Amount]=S.[ValueInclVAT_Amount],[ValueInclVAT_Currency]=S.[ValueInclVAT_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AgeofAsset],[AssetClassConfigId],[CreatedById],[CreatedTime],[DateofProduction],[EngineCapacity],[Id],[IsVAT],[KW],[MakeId],[ModelId],[TaxCodeId],[ValueExclVAT_Amount],[ValueExclVAT_Currency],[ValueInclVAT_Amount],[ValueInclVAT_Currency])
    VALUES (S.[AgeofAsset],S.[AssetClassConfigId],S.[CreatedById],S.[CreatedTime],S.[DateofProduction],S.[EngineCapacity],S.[Id],S.[IsVAT],S.[KW],S.[MakeId],S.[ModelId],S.[TaxCodeId],S.[ValueExclVAT_Amount],S.[ValueExclVAT_Currency],S.[ValueInclVAT_Amount],S.[ValueInclVAT_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

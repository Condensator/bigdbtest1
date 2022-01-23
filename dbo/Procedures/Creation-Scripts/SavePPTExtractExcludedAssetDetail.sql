SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePPTExtractExcludedAssetDetail]
(
 @val [dbo].[PPTExtractExcludedAssetDetail] READONLY
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
MERGE [dbo].[PPTExtractExcludedAssetDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ExportFile]=S.[ExportFile],[LegalEntityId]=S.[LegalEntityId],[NumberOfAssets]=S.[NumberOfAssets],[Reason]=S.[Reason],[StateId]=S.[StateId],[TotalPPTBasis_Amount]=S.[TotalPPTBasis_Amount],[TotalPPTBasis_Currency]=S.[TotalPPTBasis_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[ExportFile],[LegalEntityId],[NumberOfAssets],[PPTExtractDetailId],[Reason],[StateId],[TotalPPTBasis_Amount],[TotalPPTBasis_Currency])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[ExportFile],S.[LegalEntityId],S.[NumberOfAssets],S.[PPTExtractDetailId],S.[Reason],S.[StateId],S.[TotalPPTBasis_Amount],S.[TotalPPTBasis_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

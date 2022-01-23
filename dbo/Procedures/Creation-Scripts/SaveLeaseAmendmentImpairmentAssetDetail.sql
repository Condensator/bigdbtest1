SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseAmendmentImpairmentAssetDetail]
(
 @val [dbo].[LeaseAmendmentImpairmentAssetDetail] READONLY
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
MERGE [dbo].[LeaseAmendmentImpairmentAssetDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[BookDepreciationTemplateId]=S.[BookDepreciationTemplateId],[IsActive]=S.[IsActive],[NBVImpairmentAmount_Amount]=S.[NBVImpairmentAmount_Amount],[NBVImpairmentAmount_Currency]=S.[NBVImpairmentAmount_Currency],[PostRestructureBookedResidualAmount_Amount]=S.[PostRestructureBookedResidualAmount_Amount],[PostRestructureBookedResidualAmount_Currency]=S.[PostRestructureBookedResidualAmount_Currency],[PreRestructureBookedResidualAmount_Amount]=S.[PreRestructureBookedResidualAmount_Amount],[PreRestructureBookedResidualAmount_Currency]=S.[PreRestructureBookedResidualAmount_Currency],[PVOfAsset_Amount]=S.[PVOfAsset_Amount],[PVOfAsset_Currency]=S.[PVOfAsset_Currency],[ResidualImpairmentAmount_Amount]=S.[ResidualImpairmentAmount_Amount],[ResidualImpairmentAmount_Currency]=S.[ResidualImpairmentAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[BookDepreciationTemplateId],[CreatedById],[CreatedTime],[IsActive],[LeaseAmendmentId],[NBVImpairmentAmount_Amount],[NBVImpairmentAmount_Currency],[PostRestructureBookedResidualAmount_Amount],[PostRestructureBookedResidualAmount_Currency],[PreRestructureBookedResidualAmount_Amount],[PreRestructureBookedResidualAmount_Currency],[PVOfAsset_Amount],[PVOfAsset_Currency],[ResidualImpairmentAmount_Amount],[ResidualImpairmentAmount_Currency])
    VALUES (S.[AssetId],S.[BookDepreciationTemplateId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[LeaseAmendmentId],S.[NBVImpairmentAmount_Amount],S.[NBVImpairmentAmount_Currency],S.[PostRestructureBookedResidualAmount_Amount],S.[PostRestructureBookedResidualAmount_Currency],S.[PreRestructureBookedResidualAmount_Amount],S.[PreRestructureBookedResidualAmount_Currency],S.[PVOfAsset_Amount],S.[PVOfAsset_Currency],S.[ResidualImpairmentAmount_Amount],S.[ResidualImpairmentAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

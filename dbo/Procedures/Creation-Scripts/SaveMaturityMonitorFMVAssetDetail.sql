SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMaturityMonitorFMVAssetDetail]
(
 @val [dbo].[MaturityMonitorFMVAssetDetail] READONLY
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
MERGE [dbo].[MaturityMonitorFMVAssetDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[FMVMaturity_Amount]=S.[FMVMaturity_Amount],[FMVMaturity_Currency]=S.[FMVMaturity_Currency],[FMVMDate]=S.[FMVMDate],[GeneralDescription]=S.[GeneralDescription],[IsActive]=S.[IsActive],[IsNegotiable]=S.[IsNegotiable],[OLVPresent_Amount]=S.[OLVPresent_Amount],[OLVPresent_Currency]=S.[OLVPresent_Currency],[OLVPresentDate]=S.[OLVPresentDate],[OriginalCost_Amount]=S.[OriginalCost_Amount],[OriginalCost_Currency]=S.[OriginalCost_Currency],[PurchasePrice_Amount]=S.[PurchasePrice_Amount],[PurchasePrice_Currency]=S.[PurchasePrice_Currency],[PurchasePriceDate]=S.[PurchasePriceDate],[Residual_Amount]=S.[Residual_Amount],[Residual_Currency]=S.[Residual_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CreatedById],[CreatedTime],[FMVMaturity_Amount],[FMVMaturity_Currency],[FMVMDate],[GeneralDescription],[IsActive],[IsNegotiable],[MaturityMonitorId],[OLVPresent_Amount],[OLVPresent_Currency],[OLVPresentDate],[OriginalCost_Amount],[OriginalCost_Currency],[PurchasePrice_Amount],[PurchasePrice_Currency],[PurchasePriceDate],[Residual_Amount],[Residual_Currency])
    VALUES (S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[FMVMaturity_Amount],S.[FMVMaturity_Currency],S.[FMVMDate],S.[GeneralDescription],S.[IsActive],S.[IsNegotiable],S.[MaturityMonitorId],S.[OLVPresent_Amount],S.[OLVPresent_Currency],S.[OLVPresentDate],S.[OriginalCost_Amount],S.[OriginalCost_Currency],S.[PurchasePrice_Amount],S.[PurchasePrice_Currency],S.[PurchasePriceDate],S.[Residual_Amount],S.[Residual_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

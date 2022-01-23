SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayoffAssetSKU]
(
 @val [dbo].[PayoffAssetSKU] READONLY
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
MERGE [dbo].[PayoffAssetSKUs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Alias]=S.[Alias],[BuyoutAmount_Amount]=S.[BuyoutAmount_Amount],[BuyoutAmount_Currency]=S.[BuyoutAmount_Currency],[FMV_Amount]=S.[FMV_Amount],[FMV_Currency]=S.[FMV_Currency],[LeaseAssetSKUId]=S.[LeaseAssetSKUId],[NBV_Amount]=S.[NBV_Amount],[NBV_Currency]=S.[NBV_Currency],[NBVAsOfEffectiveDate_Amount]=S.[NBVAsOfEffectiveDate_Amount],[NBVAsOfEffectiveDate_Currency]=S.[NBVAsOfEffectiveDate_Currency],[OLV_Amount]=S.[OLV_Amount],[OLV_Currency]=S.[OLV_Currency],[PayoffAmount_Amount]=S.[PayoffAmount_Amount],[PayoffAmount_Currency]=S.[PayoffAmount_Currency],[PlaceholderRent_Amount]=S.[PlaceholderRent_Amount],[PlaceholderRent_Currency]=S.[PlaceholderRent_Currency],[SKUValuation_Amount]=S.[SKUValuation_Amount],[SKUValuation_Currency]=S.[SKUValuation_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Alias],[BuyoutAmount_Amount],[BuyoutAmount_Currency],[CreatedById],[CreatedTime],[FMV_Amount],[FMV_Currency],[LeaseAssetSKUId],[NBV_Amount],[NBV_Currency],[NBVAsOfEffectiveDate_Amount],[NBVAsOfEffectiveDate_Currency],[OLV_Amount],[OLV_Currency],[PayoffAmount_Amount],[PayoffAmount_Currency],[PayoffAssetId],[PlaceholderRent_Amount],[PlaceholderRent_Currency],[SKUValuation_Amount],[SKUValuation_Currency])
    VALUES (S.[Alias],S.[BuyoutAmount_Amount],S.[BuyoutAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[FMV_Amount],S.[FMV_Currency],S.[LeaseAssetSKUId],S.[NBV_Amount],S.[NBV_Currency],S.[NBVAsOfEffectiveDate_Amount],S.[NBVAsOfEffectiveDate_Currency],S.[OLV_Amount],S.[OLV_Currency],S.[PayoffAmount_Amount],S.[PayoffAmount_Currency],S.[PayoffAssetId],S.[PlaceholderRent_Amount],S.[PlaceholderRent_Currency],S.[SKUValuation_Amount],S.[SKUValuation_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

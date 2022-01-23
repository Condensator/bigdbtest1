SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableTaxDetail]
(
 @val [dbo].[ReceivableTaxDetail] READONLY
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
MERGE [dbo].[ReceivableTaxDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AssetId]=S.[AssetId],[AssetLocationId]=S.[AssetLocationId],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[Cost_Amount]=S.[Cost_Amount],[Cost_Currency]=S.[Cost_Currency],[EffectiveBalance_Amount]=S.[EffectiveBalance_Amount],[EffectiveBalance_Currency]=S.[EffectiveBalance_Currency],[FairMarketValue_Amount]=S.[FairMarketValue_Amount],[FairMarketValue_Currency]=S.[FairMarketValue_Currency],[IsActive]=S.[IsActive],[IsGLPosted]=S.[IsGLPosted],[LocationId]=S.[LocationId],[ManuallyAssessed]=S.[ManuallyAssessed],[ReceivableDetailId]=S.[ReceivableDetailId],[Revenue_Amount]=S.[Revenue_Amount],[Revenue_Currency]=S.[Revenue_Currency],[TaxAreaId]=S.[TaxAreaId],[TaxBasisType]=S.[TaxBasisType],[TaxCodeId]=S.[TaxCodeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontPayableFactor]=S.[UpfrontPayableFactor],[UpfrontTaxMode]=S.[UpfrontTaxMode],[UpfrontTaxSundryId]=S.[UpfrontTaxSundryId]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AssetId],[AssetLocationId],[Balance_Amount],[Balance_Currency],[Cost_Amount],[Cost_Currency],[CreatedById],[CreatedTime],[EffectiveBalance_Amount],[EffectiveBalance_Currency],[FairMarketValue_Amount],[FairMarketValue_Currency],[IsActive],[IsGLPosted],[LocationId],[ManuallyAssessed],[ReceivableDetailId],[ReceivableTaxId],[Revenue_Amount],[Revenue_Currency],[TaxAreaId],[TaxBasisType],[TaxCodeId],[UpfrontPayableFactor],[UpfrontTaxMode],[UpfrontTaxSundryId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AssetId],S.[AssetLocationId],S.[Balance_Amount],S.[Balance_Currency],S.[Cost_Amount],S.[Cost_Currency],S.[CreatedById],S.[CreatedTime],S.[EffectiveBalance_Amount],S.[EffectiveBalance_Currency],S.[FairMarketValue_Amount],S.[FairMarketValue_Currency],S.[IsActive],S.[IsGLPosted],S.[LocationId],S.[ManuallyAssessed],S.[ReceivableDetailId],S.[ReceivableTaxId],S.[Revenue_Amount],S.[Revenue_Currency],S.[TaxAreaId],S.[TaxBasisType],S.[TaxCodeId],S.[UpfrontPayableFactor],S.[UpfrontTaxMode],S.[UpfrontTaxSundryId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

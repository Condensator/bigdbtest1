SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxSourceDetail]
(
 @val [dbo].[TaxSourceDetail] READONLY
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
MERGE [dbo].[TaxSourceDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BuyerLocationId]=S.[BuyerLocationId],[DealCountryId]=S.[DealCountryId],[EffectiveDate]=S.[EffectiveDate],[SellerLocationId]=S.[SellerLocationId],[SourceId]=S.[SourceId],[SourceTable]=S.[SourceTable],[TaxLevel]=S.[TaxLevel],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BuyerLocationId],[CreatedById],[CreatedTime],[DealCountryId],[EffectiveDate],[SellerLocationId],[SourceId],[SourceTable],[TaxLevel])
    VALUES (S.[BuyerLocationId],S.[CreatedById],S.[CreatedTime],S.[DealCountryId],S.[EffectiveDate],S.[SellerLocationId],S.[SourceId],S.[SourceTable],S.[TaxLevel])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

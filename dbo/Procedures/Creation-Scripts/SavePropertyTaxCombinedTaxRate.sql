SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePropertyTaxCombinedTaxRate]
(
 @val [dbo].[PropertyTaxCombinedTaxRate] READONLY
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
MERGE [dbo].[PropertyTaxCombinedTaxRates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[ExemptionCode]=S.[ExemptionCode],[IsActive]=S.[IsActive],[TaxAreaId]=S.[TaxAreaId],[TaxRate]=S.[TaxRate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CreatedById],[CreatedTime],[ExemptionCode],[IsActive],[TaxAreaId],[TaxRate])
    VALUES (S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[ExemptionCode],S.[IsActive],S.[TaxAreaId],S.[TaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

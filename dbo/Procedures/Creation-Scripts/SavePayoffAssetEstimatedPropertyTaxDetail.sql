SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayoffAssetEstimatedPropertyTaxDetail]
(
 @val [dbo].[PayoffAssetEstimatedPropertyTaxDetail] READONLY
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
MERGE [dbo].[PayoffAssetEstimatedPropertyTaxDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EstimatedPropertyTax_Amount]=S.[EstimatedPropertyTax_Amount],[EstimatedPropertyTax_Currency]=S.[EstimatedPropertyTax_Currency],[IsActive]=S.[IsActive],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Year]=S.[Year]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EstimatedPropertyTax_Amount],[EstimatedPropertyTax_Currency],[IsActive],[PayoffAssetId],[Year])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[EstimatedPropertyTax_Amount],S.[EstimatedPropertyTax_Currency],S.[IsActive],S.[PayoffAssetId],S.[Year])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

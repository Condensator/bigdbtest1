SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAcceleratedBalanceEstimatedPropertyTax]
(
 @val [dbo].[AcceleratedBalanceEstimatedPropertyTax] READONLY
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
MERGE [dbo].[AcceleratedBalanceEstimatedPropertyTaxes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsActive]=S.[IsActive],[PPTAmount_Amount]=S.[PPTAmount_Amount],[PPTAmount_Currency]=S.[PPTAmount_Currency],[TaxonPPT_Amount]=S.[TaxonPPT_Amount],[TaxonPPT_Currency]=S.[TaxonPPT_Currency],[TotalPPT_Amount]=S.[TotalPPT_Amount],[TotalPPT_Currency]=S.[TotalPPT_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Year]=S.[Year]
WHEN NOT MATCHED THEN
	INSERT ([AcceleratedBalanceDetailId],[CreatedById],[CreatedTime],[IsActive],[PPTAmount_Amount],[PPTAmount_Currency],[TaxonPPT_Amount],[TaxonPPT_Currency],[TotalPPT_Amount],[TotalPPT_Currency],[Year])
    VALUES (S.[AcceleratedBalanceDetailId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[PPTAmount_Amount],S.[PPTAmount_Currency],S.[TaxonPPT_Amount],S.[TaxonPPT_Currency],S.[TotalPPT_Amount],S.[TotalPPT_Currency],S.[Year])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

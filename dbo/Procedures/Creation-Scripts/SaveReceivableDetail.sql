SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableDetail]
(
 @val [dbo].[ReceivableDetail] READONLY
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
MERGE [dbo].[ReceivableDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentBasisReceivableDetailId]=S.[AdjustmentBasisReceivableDetailId],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AssetComponentType]=S.[AssetComponentType],[AssetId]=S.[AssetId],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[BilledStatus]=S.[BilledStatus],[BillToId]=S.[BillToId],[EffectiveBalance_Amount]=S.[EffectiveBalance_Amount],[EffectiveBalance_Currency]=S.[EffectiveBalance_Currency],[EffectiveBookBalance_Amount]=S.[EffectiveBookBalance_Amount],[EffectiveBookBalance_Currency]=S.[EffectiveBookBalance_Currency],[IsActive]=S.[IsActive],[IsTaxAssessed]=S.[IsTaxAssessed],[LeaseComponentAmount_Amount]=S.[LeaseComponentAmount_Amount],[LeaseComponentAmount_Currency]=S.[LeaseComponentAmount_Currency],[LeaseComponentBalance_Amount]=S.[LeaseComponentBalance_Amount],[LeaseComponentBalance_Currency]=S.[LeaseComponentBalance_Currency],[NonLeaseComponentAmount_Amount]=S.[NonLeaseComponentAmount_Amount],[NonLeaseComponentAmount_Currency]=S.[NonLeaseComponentAmount_Currency],[NonLeaseComponentBalance_Amount]=S.[NonLeaseComponentBalance_Amount],[NonLeaseComponentBalance_Currency]=S.[NonLeaseComponentBalance_Currency],[PreCapitalizationRent_Amount]=S.[PreCapitalizationRent_Amount],[PreCapitalizationRent_Currency]=S.[PreCapitalizationRent_Currency],[StopInvoicing]=S.[StopInvoicing],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentBasisReceivableDetailId],[Amount_Amount],[Amount_Currency],[AssetComponentType],[AssetId],[Balance_Amount],[Balance_Currency],[BilledStatus],[BillToId],[CreatedById],[CreatedTime],[EffectiveBalance_Amount],[EffectiveBalance_Currency],[EffectiveBookBalance_Amount],[EffectiveBookBalance_Currency],[IsActive],[IsTaxAssessed],[LeaseComponentAmount_Amount],[LeaseComponentAmount_Currency],[LeaseComponentBalance_Amount],[LeaseComponentBalance_Currency],[NonLeaseComponentAmount_Amount],[NonLeaseComponentAmount_Currency],[NonLeaseComponentBalance_Amount],[NonLeaseComponentBalance_Currency],[PreCapitalizationRent_Amount],[PreCapitalizationRent_Currency],[ReceivableId],[StopInvoicing])
    VALUES (S.[AdjustmentBasisReceivableDetailId],S.[Amount_Amount],S.[Amount_Currency],S.[AssetComponentType],S.[AssetId],S.[Balance_Amount],S.[Balance_Currency],S.[BilledStatus],S.[BillToId],S.[CreatedById],S.[CreatedTime],S.[EffectiveBalance_Amount],S.[EffectiveBalance_Currency],S.[EffectiveBookBalance_Amount],S.[EffectiveBookBalance_Currency],S.[IsActive],S.[IsTaxAssessed],S.[LeaseComponentAmount_Amount],S.[LeaseComponentAmount_Currency],S.[LeaseComponentBalance_Amount],S.[LeaseComponentBalance_Currency],S.[NonLeaseComponentAmount_Amount],S.[NonLeaseComponentAmount_Currency],S.[NonLeaseComponentBalance_Amount],S.[NonLeaseComponentBalance_Currency],S.[PreCapitalizationRent_Amount],S.[PreCapitalizationRent_Currency],S.[ReceivableId],S.[StopInvoicing])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

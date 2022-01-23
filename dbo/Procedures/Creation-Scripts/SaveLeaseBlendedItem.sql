SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseBlendedItem]
(
 @val [dbo].[LeaseBlendedItem] READONLY
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
MERGE [dbo].[LeaseBlendedItems] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BlendedItemId]=S.[BlendedItemId],[FeeDetailId]=S.[FeeDetailId],[FundingId]=S.[FundingId],[FundingSourceId]=S.[FundingSourceId],[PayableInvoiceOtherCostId]=S.[PayableInvoiceOtherCostId],[Revise]=S.[Revise],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BlendedItemId],[CreatedById],[CreatedTime],[FeeDetailId],[FundingId],[FundingSourceId],[LeaseFinanceId],[PayableInvoiceOtherCostId],[Revise])
    VALUES (S.[BlendedItemId],S.[CreatedById],S.[CreatedTime],S.[FeeDetailId],S.[FundingId],S.[FundingSourceId],S.[LeaseFinanceId],S.[PayableInvoiceOtherCostId],S.[Revise])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

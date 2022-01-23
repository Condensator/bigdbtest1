SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayOffOutStandingChargeDetail]
(
 @val [dbo].[PayOffOutStandingChargeDetail] READONLY
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
MERGE [dbo].[PayOffOutStandingChargeDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DueDate]=S.[DueDate],[IncludeinInvoice]=S.[IncludeinInvoice],[IsActive]=S.[IsActive],[ReceivableAmount_Amount]=S.[ReceivableAmount_Amount],[ReceivableAmount_Currency]=S.[ReceivableAmount_Currency],[ReceivableBalance_Amount]=S.[ReceivableBalance_Amount],[ReceivableBalance_Currency]=S.[ReceivableBalance_Currency],[ReceivableId]=S.[ReceivableId],[ReceivableType]=S.[ReceivableType],[SalesTaxAmount_Amount]=S.[SalesTaxAmount_Amount],[SalesTaxAmount_Currency]=S.[SalesTaxAmount_Currency],[SalesTaxBalance_Amount]=S.[SalesTaxBalance_Amount],[SalesTaxBalance_Currency]=S.[SalesTaxBalance_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DueDate],[IncludeinInvoice],[IsActive],[PayoffId],[ReceivableAmount_Amount],[ReceivableAmount_Currency],[ReceivableBalance_Amount],[ReceivableBalance_Currency],[ReceivableId],[ReceivableType],[SalesTaxAmount_Amount],[SalesTaxAmount_Currency],[SalesTaxBalance_Amount],[SalesTaxBalance_Currency])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[IncludeinInvoice],S.[IsActive],S.[PayoffId],S.[ReceivableAmount_Amount],S.[ReceivableAmount_Currency],S.[ReceivableBalance_Amount],S.[ReceivableBalance_Currency],S.[ReceivableId],S.[ReceivableType],S.[SalesTaxAmount_Amount],S.[SalesTaxAmount_Currency],S.[SalesTaxBalance_Amount],S.[SalesTaxBalance_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePrepaidReceivable]
(
 @val [dbo].[PrepaidReceivable] READONLY
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
MERGE [dbo].[PrepaidReceivables] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [FinancingPrePaidAmount_Amount]=S.[FinancingPrePaidAmount_Amount],[FinancingPrePaidAmount_Currency]=S.[FinancingPrePaidAmount_Currency],[IsActive]=S.[IsActive],[PrePaidAmount_Amount]=S.[PrePaidAmount_Amount],[PrePaidAmount_Currency]=S.[PrePaidAmount_Currency],[PrePaidTaxAmount_Amount]=S.[PrePaidTaxAmount_Amount],[PrePaidTaxAmount_Currency]=S.[PrePaidTaxAmount_Currency],[ReceiptId]=S.[ReceiptId],[ReceivableId]=S.[ReceivableId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[FinancingPrePaidAmount_Amount],[FinancingPrePaidAmount_Currency],[IsActive],[PrePaidAmount_Amount],[PrePaidAmount_Currency],[PrePaidTaxAmount_Amount],[PrePaidTaxAmount_Currency],[ReceiptId],[ReceivableId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[FinancingPrePaidAmount_Amount],S.[FinancingPrePaidAmount_Currency],S.[IsActive],S.[PrePaidAmount_Amount],S.[PrePaidAmount_Currency],S.[PrePaidTaxAmount_Amount],S.[PrePaidTaxAmount_Currency],S.[ReceiptId],S.[ReceivableId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

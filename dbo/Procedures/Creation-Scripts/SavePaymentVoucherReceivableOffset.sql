SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePaymentVoucherReceivableOffset]
(
 @val [dbo].[PaymentVoucherReceivableOffset] READONLY
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
MERGE [dbo].[PaymentVoucherReceivableOffsets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountToApply_Amount]=S.[AmountToApply_Amount],[AmountToApply_Currency]=S.[AmountToApply_Currency],[ReceivableId]=S.[ReceivableId],[TaxToApply_Amount]=S.[TaxToApply_Amount],[TaxToApply_Currency]=S.[TaxToApply_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountToApply_Amount],[AmountToApply_Currency],[CreatedById],[CreatedTime],[PaymentVoucherId],[ReceivableId],[TaxToApply_Amount],[TaxToApply_Currency])
    VALUES (S.[AmountToApply_Amount],S.[AmountToApply_Currency],S.[CreatedById],S.[CreatedTime],S.[PaymentVoucherId],S.[ReceivableId],S.[TaxToApply_Amount],S.[TaxToApply_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

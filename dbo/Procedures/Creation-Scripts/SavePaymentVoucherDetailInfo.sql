SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePaymentVoucherDetailInfo]
(
 @val [dbo].[PaymentVoucherDetailInfo] READONLY
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
MERGE [dbo].[PaymentVoucherDetailInfoes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountsPayableDetailId]=S.[AccountsPayableDetailId],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[ReceivableOffsetAmount_Amount]=S.[ReceivableOffsetAmount_Amount],[ReceivableOffsetAmount_Currency]=S.[ReceivableOffsetAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithholdingTaxAmount_Amount]=S.[WithholdingTaxAmount_Amount],[WithholdingTaxAmount_Currency]=S.[WithholdingTaxAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AccountsPayableDetailId],[Amount_Amount],[Amount_Currency],[CreatedById],[CreatedTime],[PaymentVoucherInfoId],[ReceivableOffsetAmount_Amount],[ReceivableOffsetAmount_Currency],[WithholdingTaxAmount_Amount],[WithholdingTaxAmount_Currency])
    VALUES (S.[AccountsPayableDetailId],S.[Amount_Amount],S.[Amount_Currency],S.[CreatedById],S.[CreatedTime],S.[PaymentVoucherInfoId],S.[ReceivableOffsetAmount_Amount],S.[ReceivableOffsetAmount_Currency],S.[WithholdingTaxAmount_Amount],S.[WithholdingTaxAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveQuotePricingDetail]
(
 @val [dbo].[QuotePricingDetail] READONLY
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
MERGE [dbo].[QuotePricingDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdvanceToDealer_Amount]=S.[AdvanceToDealer_Amount],[AdvanceToDealer_Currency]=S.[AdvanceToDealer_Currency],[APR]=S.[APR],[DownPaymentAmount_Amount]=S.[DownPaymentAmount_Amount],[DownPaymentAmount_Currency]=S.[DownPaymentAmount_Currency],[DownPaymentPercentageId]=S.[DownPaymentPercentageId],[InterestRate]=S.[InterestRate],[PurchasePrice_Amount]=S.[PurchasePrice_Amount],[PurchasePrice_Currency]=S.[PurchasePrice_Currency],[QuoteLeaseTypeId]=S.[QuoteLeaseTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdvanceToDealer_Amount],[AdvanceToDealer_Currency],[APR],[CreatedById],[CreatedTime],[DownPaymentAmount_Amount],[DownPaymentAmount_Currency],[DownPaymentPercentageId],[Id],[InterestRate],[PurchasePrice_Amount],[PurchasePrice_Currency],[QuoteLeaseTypeId])
    VALUES (S.[AdvanceToDealer_Amount],S.[AdvanceToDealer_Currency],S.[APR],S.[CreatedById],S.[CreatedTime],S.[DownPaymentAmount_Amount],S.[DownPaymentAmount_Currency],S.[DownPaymentPercentageId],S.[Id],S.[InterestRate],S.[PurchasePrice_Amount],S.[PurchasePrice_Currency],S.[QuoteLeaseTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

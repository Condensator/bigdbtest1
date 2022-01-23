SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePreQuoteLoanDetail]
(
 @val [dbo].[PreQuoteLoanDetail] READONLY
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
MERGE [dbo].[PreQuoteLoanDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [InterestPaydown_Amount]=S.[InterestPaydown_Amount],[InterestPaydown_Currency]=S.[InterestPaydown_Currency],[InterestPaydownSalesTax_Amount]=S.[InterestPaydownSalesTax_Amount],[InterestPaydownSalesTax_Currency]=S.[InterestPaydownSalesTax_Currency],[IsActive]=S.[IsActive],[IsComputationPerformed]=S.[IsComputationPerformed],[IsSalesTaxAssessed]=S.[IsSalesTaxAssessed],[LateFee_Amount]=S.[LateFee_Amount],[LateFee_Currency]=S.[LateFee_Currency],[OtherCharge_Amount]=S.[OtherCharge_Amount],[OtherCharge_Currency]=S.[OtherCharge_Currency],[PaydownReason]=S.[PaydownReason],[PrePaymentPenalty_Amount]=S.[PrePaymentPenalty_Amount],[PrePaymentPenalty_Currency]=S.[PrePaymentPenalty_Currency],[PreQuoteLoanId]=S.[PreQuoteLoanId],[PrincipalPaydown_Amount]=S.[PrincipalPaydown_Amount],[PrincipalPaydown_Currency]=S.[PrincipalPaydown_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[InterestPaydown_Amount],[InterestPaydown_Currency],[InterestPaydownSalesTax_Amount],[InterestPaydownSalesTax_Currency],[IsActive],[IsComputationPerformed],[IsSalesTaxAssessed],[LateFee_Amount],[LateFee_Currency],[OtherCharge_Amount],[OtherCharge_Currency],[PaydownReason],[PrePaymentPenalty_Amount],[PrePaymentPenalty_Currency],[PreQuoteId],[PreQuoteLoanId],[PrincipalPaydown_Amount],[PrincipalPaydown_Currency])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[InterestPaydown_Amount],S.[InterestPaydown_Currency],S.[InterestPaydownSalesTax_Amount],S.[InterestPaydownSalesTax_Currency],S.[IsActive],S.[IsComputationPerformed],S.[IsSalesTaxAssessed],S.[LateFee_Amount],S.[LateFee_Currency],S.[OtherCharge_Amount],S.[OtherCharge_Currency],S.[PaydownReason],S.[PrePaymentPenalty_Amount],S.[PrePaymentPenalty_Currency],S.[PreQuoteId],S.[PreQuoteLoanId],S.[PrincipalPaydown_Amount],S.[PrincipalPaydown_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

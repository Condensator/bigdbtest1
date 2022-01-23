SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePreQuotePaymentSummary]
(
 @val [dbo].[PreQuotePaymentSummary] READONLY
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
MERGE [dbo].[PreQuotePaymentSummaries] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractId]=S.[ContractId],[Current_Amount]=S.[Current_Amount],[Current_Currency]=S.[Current_Currency],[Delinquent_Amount]=S.[Delinquent_Amount],[Delinquent_Currency]=S.[Delinquent_Currency],[EffectiveDate]=S.[EffectiveDate],[Future_Amount]=S.[Future_Amount],[Future_Currency]=S.[Future_Currency],[IsActive]=S.[IsActive],[LastBilledDate]=S.[LastBilledDate],[Paid_Amount]=S.[Paid_Amount],[Paid_Currency]=S.[Paid_Currency],[ReceivableCode]=S.[ReceivableCode],[Remaining_Amount]=S.[Remaining_Amount],[Remaining_Currency]=S.[Remaining_Currency],[Total_Amount]=S.[Total_Amount],[Total_Currency]=S.[Total_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractId],[CreatedById],[CreatedTime],[Current_Amount],[Current_Currency],[Delinquent_Amount],[Delinquent_Currency],[EffectiveDate],[Future_Amount],[Future_Currency],[IsActive],[LastBilledDate],[Paid_Amount],[Paid_Currency],[PreQuoteId],[ReceivableCode],[Remaining_Amount],[Remaining_Currency],[Total_Amount],[Total_Currency])
    VALUES (S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[Current_Amount],S.[Current_Currency],S.[Delinquent_Amount],S.[Delinquent_Currency],S.[EffectiveDate],S.[Future_Amount],S.[Future_Currency],S.[IsActive],S.[LastBilledDate],S.[Paid_Amount],S.[Paid_Currency],S.[PreQuoteId],S.[ReceivableCode],S.[Remaining_Amount],S.[Remaining_Currency],S.[Total_Amount],S.[Total_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

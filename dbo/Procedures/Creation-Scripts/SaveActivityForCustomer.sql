SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveActivityForCustomer]
(
 @val [dbo].[ActivityForCustomer] READONLY
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
MERGE [dbo].[ActivityForCustomers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BillToId]=S.[BillToId],[Chapter]=S.[Chapter],[CollectionAgentId]=S.[CollectionAgentId],[ContactReference]=S.[ContactReference],[ContractId]=S.[ContractId],[CourtFilingId]=S.[CourtFilingId],[CurrencyId]=S.[CurrencyId],[CurrentChapter]=S.[CurrentChapter],[CustomerId]=S.[CustomerId],[DateContractCopySent]=S.[DateContractCopySent],[Fee_Amount]=S.[Fee_Amount],[Fee_Currency]=S.[Fee_Currency],[IsCustomerContacted]=S.[IsCustomerContacted],[JudgmentDate]=S.[JudgmentDate],[LeaseTerminationOption]=S.[LeaseTerminationOption],[NewCustomerId]=S.[NewCustomerId],[PaydownReason]=S.[PaydownReason],[PaymentAmount_Amount]=S.[PaymentAmount_Amount],[PaymentAmount_Currency]=S.[PaymentAmount_Currency],[PaymentDate]=S.[PaymentDate],[PaymentMode]=S.[PaymentMode],[PayoffAssetStatus]=S.[PayoffAssetStatus],[PersonContactedId]=S.[PersonContactedId],[PromiseToPayDate]=S.[PromiseToPayDate],[ReferenceInvoiceNumber]=S.[ReferenceInvoiceNumber],[SentTo]=S.[SentTo],[SourceUsed]=S.[SourceUsed],[TotalAmount_Amount]=S.[TotalAmount_Amount],[TotalAmount_Currency]=S.[TotalAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([BillToId],[Chapter],[CollectionAgentId],[ContactReference],[ContractId],[CourtFilingId],[CreatedById],[CreatedTime],[CurrencyId],[CurrentChapter],[CustomerId],[DateContractCopySent],[Fee_Amount],[Fee_Currency],[Id],[IsCustomerContacted],[JudgmentDate],[LeaseTerminationOption],[NewCustomerId],[PaydownReason],[PaymentAmount_Amount],[PaymentAmount_Currency],[PaymentDate],[PaymentMode],[PayoffAssetStatus],[PersonContactedId],[PromiseToPayDate],[ReferenceInvoiceNumber],[SentTo],[SourceUsed],[TotalAmount_Amount],[TotalAmount_Currency],[VendorId])
    VALUES (S.[BillToId],S.[Chapter],S.[CollectionAgentId],S.[ContactReference],S.[ContractId],S.[CourtFilingId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CurrentChapter],S.[CustomerId],S.[DateContractCopySent],S.[Fee_Amount],S.[Fee_Currency],S.[Id],S.[IsCustomerContacted],S.[JudgmentDate],S.[LeaseTerminationOption],S.[NewCustomerId],S.[PaydownReason],S.[PaymentAmount_Amount],S.[PaymentAmount_Currency],S.[PaymentDate],S.[PaymentMode],S.[PayoffAssetStatus],S.[PersonContactedId],S.[PromiseToPayDate],S.[ReferenceInvoiceNumber],S.[SentTo],S.[SourceUsed],S.[TotalAmount_Amount],S.[TotalAmount_Currency],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

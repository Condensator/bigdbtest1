SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveActivityForCollectionWorkList]
(
 @val [dbo].[ActivityForCollectionWorkList] READONLY
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
MERGE [dbo].[ActivityForCollectionWorkLists] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivityNote]=S.[ActivityNote],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[CheckNumber]=S.[CheckNumber],[CollectionAgentId]=S.[CollectionAgentId],[CollectionAgentReference]=S.[CollectionAgentReference],[CollectionWorkListId]=S.[CollectionWorkListId],[CommentId]=S.[CommentId],[ContactReference]=S.[ContactReference],[ContractId]=S.[ContractId],[IsCustomerContacted]=S.[IsCustomerContacted],[PaymentDate]=S.[PaymentDate],[PaymentMode]=S.[PaymentMode],[PersonContactedId]=S.[PersonContactedId],[PromiseToPayDate]=S.[PromiseToPayDate],[ReferenceInvoiceNumber]=S.[ReferenceInvoiceNumber],[SourceUsed]=S.[SourceUsed],[SubActivityType]=S.[SubActivityType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivityNote],[Amount_Amount],[Amount_Currency],[CheckNumber],[CollectionAgentId],[CollectionAgentReference],[CollectionWorkListId],[CommentId],[ContactReference],[ContractId],[CreatedById],[CreatedTime],[Id],[IsCustomerContacted],[PaymentDate],[PaymentMode],[PersonContactedId],[PromiseToPayDate],[ReferenceInvoiceNumber],[SourceUsed],[SubActivityType])
    VALUES (S.[ActivityNote],S.[Amount_Amount],S.[Amount_Currency],S.[CheckNumber],S.[CollectionAgentId],S.[CollectionAgentReference],S.[CollectionWorkListId],S.[CommentId],S.[ContactReference],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[Id],S.[IsCustomerContacted],S.[PaymentDate],S.[PaymentMode],S.[PersonContactedId],S.[PromiseToPayDate],S.[ReferenceInvoiceNumber],S.[SourceUsed],S.[SubActivityType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

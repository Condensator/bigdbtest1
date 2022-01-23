SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptAllocations_Extract]
(
 @val [dbo].[ReceiptAllocations_Extract] READONLY
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
MERGE [dbo].[ReceiptAllocations_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllocationAmount]=S.[AllocationAmount],[ContractId]=S.[ContractId],[Description]=S.[Description],[EntityType]=S.[EntityType],[InvoiceId]=S.[InvoiceId],[IsStatementInvoiceCalculationRequired]=S.[IsStatementInvoiceCalculationRequired],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityId]=S.[LegalEntityId],[ReceiptId]=S.[ReceiptId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AllocationAmount],[ContractId],[CreatedById],[CreatedTime],[Description],[EntityType],[InvoiceId],[IsStatementInvoiceCalculationRequired],[JobStepInstanceId],[LegalEntityId],[ReceiptId])
    VALUES (S.[AllocationAmount],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[Description],S.[EntityType],S.[InvoiceId],S.[IsStatementInvoiceCalculationRequired],S.[JobStepInstanceId],S.[LegalEntityId],S.[ReceiptId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

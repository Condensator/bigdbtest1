SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveUnappliedReceipts_Extract]
(
 @val [dbo].[UnappliedReceipts_Extract] READONLY
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
MERGE [dbo].[UnappliedReceipts_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionId]=S.[AcquisitionId],[AllocationReceiptId]=S.[AllocationReceiptId],[BankAccountId]=S.[BankAccountId],[BranchId]=S.[BranchId],[ContractId]=S.[ContractId],[ContractLegalEntityId]=S.[ContractLegalEntityId],[CostCenterId]=S.[CostCenterId],[Currency]=S.[Currency],[CurrentAmountApplied]=S.[CurrentAmountApplied],[CustomerId]=S.[CustomerId],[DealProductTypeId]=S.[DealProductTypeId],[DiscountingId]=S.[DiscountingId],[EntityType]=S.[EntityType],[InstrumentTypeId]=S.[InstrumentTypeId],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityId]=S.[LegalEntityId],[LineOfBusinessId]=S.[LineOfBusinessId],[OriginalAllocationAmountApplied]=S.[OriginalAllocationAmountApplied],[OriginalReceiptBalance]=S.[OriginalReceiptBalance],[ReceiptAllocationId]=S.[ReceiptAllocationId],[ReceiptGLTemplateId]=S.[ReceiptGLTemplateId],[ReceiptId]=S.[ReceiptId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionId],[AllocationReceiptId],[BankAccountId],[BranchId],[ContractId],[ContractLegalEntityId],[CostCenterId],[CreatedById],[CreatedTime],[Currency],[CurrentAmountApplied],[CustomerId],[DealProductTypeId],[DiscountingId],[EntityType],[InstrumentTypeId],[JobStepInstanceId],[LegalEntityId],[LineOfBusinessId],[OriginalAllocationAmountApplied],[OriginalReceiptBalance],[ReceiptAllocationId],[ReceiptGLTemplateId],[ReceiptId])
    VALUES (S.[AcquisitionId],S.[AllocationReceiptId],S.[BankAccountId],S.[BranchId],S.[ContractId],S.[ContractLegalEntityId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[CurrentAmountApplied],S.[CustomerId],S.[DealProductTypeId],S.[DiscountingId],S.[EntityType],S.[InstrumentTypeId],S.[JobStepInstanceId],S.[LegalEntityId],S.[LineOfBusinessId],S.[OriginalAllocationAmountApplied],S.[OriginalReceiptBalance],S.[ReceiptAllocationId],S.[ReceiptGLTemplateId],S.[ReceiptId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

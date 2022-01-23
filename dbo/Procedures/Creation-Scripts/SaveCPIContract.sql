SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPIContract]
(
 @val [dbo].[CPIContract] READONLY
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
MERGE [dbo].[CPIContracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdminFeeReceivableCodeId]=S.[AdminFeeReceivableCodeId],[BaseBillingReceivableCodeId]=S.[BaseBillingReceivableCodeId],[BaseFrequency]=S.[BaseFrequency],[BasePassThroughPercentage]=S.[BasePassThroughPercentage],[BasePayableCodeId]=S.[BasePayableCodeId],[BasePaymentFrequencyDays]=S.[BasePaymentFrequencyDays],[BillToId]=S.[BillToId],[CommencementDate]=S.[CommencementDate],[ContractId]=S.[ContractId],[CostCenterId]=S.[CostCenterId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[Description]=S.[Description],[DueDay]=S.[DueDay],[EntityType]=S.[EntityType],[InstrumentTypeId]=S.[InstrumentTypeId],[IsActive]=S.[IsActive],[IsInventory]=S.[IsInventory],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[NextStartDate]=S.[NextStartDate],[Number]=S.[Number],[OverageFrequency]=S.[OverageFrequency],[OveragePassThroughPercentage]=S.[OveragePassThroughPercentage],[OveragePayableCodeId]=S.[OveragePayableCodeId],[OveragePayableWithholdingTaxRate]=S.[OveragePayableWithholdingTaxRate],[OveragePaymentFrequencyDays]=S.[OveragePaymentFrequencyDays],[OverageReceivableCodeId]=S.[OverageReceivableCodeId],[PassThroughRemitToId]=S.[PassThroughRemitToId],[PassThroughVendorId]=S.[PassThroughVendorId],[RemitToId]=S.[RemitToId],[TerminationDate]=S.[TerminationDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdminFeeReceivableCodeId],[BaseBillingReceivableCodeId],[BaseFrequency],[BasePassThroughPercentage],[BasePayableCodeId],[BasePaymentFrequencyDays],[BillToId],[CommencementDate],[ContractId],[CostCenterId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[Description],[DueDay],[EntityType],[InstrumentTypeId],[IsActive],[IsInventory],[LegalEntityId],[LineofBusinessId],[NextStartDate],[Number],[OverageFrequency],[OveragePassThroughPercentage],[OveragePayableCodeId],[OveragePayableWithholdingTaxRate],[OveragePaymentFrequencyDays],[OverageReceivableCodeId],[PassThroughRemitToId],[PassThroughVendorId],[RemitToId],[TerminationDate])
    VALUES (S.[AdminFeeReceivableCodeId],S.[BaseBillingReceivableCodeId],S.[BaseFrequency],S.[BasePassThroughPercentage],S.[BasePayableCodeId],S.[BasePaymentFrequencyDays],S.[BillToId],S.[CommencementDate],S.[ContractId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[Description],S.[DueDay],S.[EntityType],S.[InstrumentTypeId],S.[IsActive],S.[IsInventory],S.[LegalEntityId],S.[LineofBusinessId],S.[NextStartDate],S.[Number],S.[OverageFrequency],S.[OveragePassThroughPercentage],S.[OveragePayableCodeId],S.[OveragePayableWithholdingTaxRate],S.[OveragePaymentFrequencyDays],S.[OverageReceivableCodeId],S.[PassThroughRemitToId],S.[PassThroughVendorId],S.[RemitToId],S.[TerminationDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

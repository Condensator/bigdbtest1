SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonAccrualContractDetails_Extract]
(
 @val [dbo].[NonAccrualContractDetails_Extract] READONLY
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
MERGE [dbo].[NonAccrualContractDetails_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingDate]=S.[AccountingDate],[AccountingStandard]=S.[AccountingStandard],[AcquisitionId]=S.[AcquisitionId],[BillingSuppressed]=S.[BillingSuppressed],[BookingGLTemplateId]=S.[BookingGLTemplateId],[BranchId]=S.[BranchId],[CanRecognizeDeferredRentalIncome]=S.[CanRecognizeDeferredRentalIncome],[ChunkId]=S.[ChunkId],[CommencementDate]=S.[CommencementDate],[ContractCurrencyCode]=S.[ContractCurrencyCode],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[CostCenterId]=S.[CostCenterId],[DealProductTypeId]=S.[DealProductTypeId],[DoubtfulCollectability]=S.[DoubtfulCollectability],[FixedTermReceivableCodeGLTemplateId]=S.[FixedTermReceivableCodeGLTemplateId],[FloatRateARReceivableGLTemplateId]=S.[FloatRateARReceivableGLTemplateId],[FloatRateIncomeGLTemplateId]=S.[FloatRateIncomeGLTemplateId],[HoldingStatus]=S.[HoldingStatus],[IncomeGLTemplateId]=S.[IncomeGLTemplateId],[InstrumentTypeId]=S.[InstrumentTypeId],[IsFailed]=S.[IsFailed],[IsFloatRateLease]=S.[IsFloatRateLease],[IsOverTermLease]=S.[IsOverTermLease],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseContractType]=S.[LeaseContractType],[LeaseFinanceId]=S.[LeaseFinanceId],[LegalEntityId]=S.[LegalEntityId],[LegalEntityNumber]=S.[LegalEntityNumber],[LineOfBusinessId]=S.[LineOfBusinessId],[MaturityDate]=S.[MaturityDate],[NonAccrualContractId]=S.[NonAccrualContractId],[NonAccrualDate]=S.[NonAccrualDate],[NonAccrualId]=S.[NonAccrualId],[NonAccrualTemplateId]=S.[NonAccrualTemplateId],[OTPIncomeGLTemplateId]=S.[OTPIncomeGLTemplateId],[OTPReceivableCodeGLTemplateId]=S.[OTPReceivableCodeGLTemplateId],[PartyNumber]=S.[PartyNumber],[PostDate]=S.[PostDate],[ReceivableAmendmentType]=S.[ReceivableAmendmentType],[SalesTaxRemittanceMethod]=S.[SalesTaxRemittanceMethod],[SequenceNumber]=S.[SequenceNumber],[SupplementalReceivableCodeGLTemplateId]=S.[SupplementalReceivableCodeGLTemplateId],[SyndicationType]=S.[SyndicationType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingDate],[AccountingStandard],[AcquisitionId],[BillingSuppressed],[BookingGLTemplateId],[BranchId],[CanRecognizeDeferredRentalIncome],[ChunkId],[CommencementDate],[ContractCurrencyCode],[ContractId],[ContractType],[CostCenterId],[CreatedById],[CreatedTime],[DealProductTypeId],[DoubtfulCollectability],[FixedTermReceivableCodeGLTemplateId],[FloatRateARReceivableGLTemplateId],[FloatRateIncomeGLTemplateId],[HoldingStatus],[IncomeGLTemplateId],[InstrumentTypeId],[IsFailed],[IsFloatRateLease],[IsOverTermLease],[JobStepInstanceId],[LeaseContractType],[LeaseFinanceId],[LegalEntityId],[LegalEntityNumber],[LineOfBusinessId],[MaturityDate],[NonAccrualContractId],[NonAccrualDate],[NonAccrualId],[NonAccrualTemplateId],[OTPIncomeGLTemplateId],[OTPReceivableCodeGLTemplateId],[PartyNumber],[PostDate],[ReceivableAmendmentType],[SalesTaxRemittanceMethod],[SequenceNumber],[SupplementalReceivableCodeGLTemplateId],[SyndicationType])
    VALUES (S.[AccountingDate],S.[AccountingStandard],S.[AcquisitionId],S.[BillingSuppressed],S.[BookingGLTemplateId],S.[BranchId],S.[CanRecognizeDeferredRentalIncome],S.[ChunkId],S.[CommencementDate],S.[ContractCurrencyCode],S.[ContractId],S.[ContractType],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[DealProductTypeId],S.[DoubtfulCollectability],S.[FixedTermReceivableCodeGLTemplateId],S.[FloatRateARReceivableGLTemplateId],S.[FloatRateIncomeGLTemplateId],S.[HoldingStatus],S.[IncomeGLTemplateId],S.[InstrumentTypeId],S.[IsFailed],S.[IsFloatRateLease],S.[IsOverTermLease],S.[JobStepInstanceId],S.[LeaseContractType],S.[LeaseFinanceId],S.[LegalEntityId],S.[LegalEntityNumber],S.[LineOfBusinessId],S.[MaturityDate],S.[NonAccrualContractId],S.[NonAccrualDate],S.[NonAccrualId],S.[NonAccrualTemplateId],S.[OTPIncomeGLTemplateId],S.[OTPReceivableCodeGLTemplateId],S.[PartyNumber],S.[PostDate],S.[ReceivableAmendmentType],S.[SalesTaxRemittanceMethod],S.[SequenceNumber],S.[SupplementalReceivableCodeGLTemplateId],S.[SyndicationType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

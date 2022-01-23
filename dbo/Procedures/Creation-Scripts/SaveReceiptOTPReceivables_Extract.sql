SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptOTPReceivables_Extract]
(
 @val [dbo].[ReceiptOTPReceivables_Extract] READONLY
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
MERGE [dbo].[ReceiptOTPReceivables_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountApplied]=S.[AmountApplied],[AmountAppliedForDepreciation]=S.[AmountAppliedForDepreciation],[AssetComponentType]=S.[AssetComponentType],[AssetId]=S.[AssetId],[Balance]=S.[Balance],[BranchId]=S.[BranchId],[ContractId]=S.[ContractId],[CostCenterId]=S.[CostCenterId],[IncomeGLTemplateId]=S.[IncomeGLTemplateId],[InstrumentTypeId]=S.[InstrumentTypeId],[IsAdjustmentReceivableDetail]=S.[IsAdjustmentReceivableDetail],[IsNonAccrual]=S.[IsNonAccrual],[IsReApplication]=S.[IsReApplication],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseFinanceId]=S.[LeaseFinanceId],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[NonAccrualDate]=S.[NonAccrualDate],[PaymentScheduleId]=S.[PaymentScheduleId],[ReceiptApplicationReceivableDetailId]=S.[ReceiptApplicationReceivableDetailId],[ReceiptId]=S.[ReceiptId],[ReceivableBalance]=S.[ReceivableBalance],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableDueDate]=S.[ReceivableDueDate],[ReceivableId]=S.[ReceivableId],[ReceivableIncomeType]=S.[ReceivableIncomeType],[SequenceNumber]=S.[SequenceNumber],[TotalDepreciationAmount]=S.[TotalDepreciationAmount],[TotalRentalAmount]=S.[TotalRentalAmount],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountApplied],[AmountAppliedForDepreciation],[AssetComponentType],[AssetId],[Balance],[BranchId],[ContractId],[CostCenterId],[CreatedById],[CreatedTime],[IncomeGLTemplateId],[InstrumentTypeId],[IsAdjustmentReceivableDetail],[IsNonAccrual],[IsReApplication],[JobStepInstanceId],[LeaseFinanceId],[LegalEntityId],[LineofBusinessId],[NonAccrualDate],[PaymentScheduleId],[ReceiptApplicationReceivableDetailId],[ReceiptId],[ReceivableBalance],[ReceivableDetailId],[ReceivableDueDate],[ReceivableId],[ReceivableIncomeType],[SequenceNumber],[TotalDepreciationAmount],[TotalRentalAmount])
    VALUES (S.[AmountApplied],S.[AmountAppliedForDepreciation],S.[AssetComponentType],S.[AssetId],S.[Balance],S.[BranchId],S.[ContractId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[IncomeGLTemplateId],S.[InstrumentTypeId],S.[IsAdjustmentReceivableDetail],S.[IsNonAccrual],S.[IsReApplication],S.[JobStepInstanceId],S.[LeaseFinanceId],S.[LegalEntityId],S.[LineofBusinessId],S.[NonAccrualDate],S.[PaymentScheduleId],S.[ReceiptApplicationReceivableDetailId],S.[ReceiptId],S.[ReceivableBalance],S.[ReceivableDetailId],S.[ReceivableDueDate],S.[ReceivableId],S.[ReceivableIncomeType],S.[SequenceNumber],S.[TotalDepreciationAmount],S.[TotalRentalAmount])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

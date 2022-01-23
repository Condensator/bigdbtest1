SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptDiscountingContracts_Extract]
(
 @val [dbo].[ReceiptDiscountingContracts_Extract] READONLY
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
MERGE [dbo].[ReceiptDiscountingContracts_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BookedResidual]=S.[BookedResidual],[BranchId]=S.[BranchId],[ContractId]=S.[ContractId],[CostCenterId]=S.[CostCenterId],[Currency]=S.[Currency],[CurrencyId]=S.[CurrencyId],[DiscountingContractId]=S.[DiscountingContractId],[DiscountingFinanceId]=S.[DiscountingFinanceId],[DiscountingId]=S.[DiscountingId],[FunderId]=S.[FunderId],[IncludeResidual]=S.[IncludeResidual],[InstrumentTypeId]=S.[InstrumentTypeId],[InterestPayableCodeId]=S.[InterestPayableCodeId],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityId]=S.[LegalEntityId],[LineOfBusinessId]=S.[LineOfBusinessId],[MaturityDate]=S.[MaturityDate],[PayableRemitToId]=S.[PayableRemitToId],[PaymentAllocation]=S.[PaymentAllocation],[PrincipalPayableCodeId]=S.[PrincipalPayableCodeId],[ResidualAmountUtilized]=S.[ResidualAmountUtilized],[ResidualBalance]=S.[ResidualBalance],[ResidualRepaymentId]=S.[ResidualRepaymentId],[SharedPercentage]=S.[SharedPercentage],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BookedResidual],[BranchId],[ContractId],[CostCenterId],[CreatedById],[CreatedTime],[Currency],[CurrencyId],[DiscountingContractId],[DiscountingFinanceId],[DiscountingId],[FunderId],[IncludeResidual],[InstrumentTypeId],[InterestPayableCodeId],[JobStepInstanceId],[LegalEntityId],[LineOfBusinessId],[MaturityDate],[PayableRemitToId],[PaymentAllocation],[PrincipalPayableCodeId],[ResidualAmountUtilized],[ResidualBalance],[ResidualRepaymentId],[SharedPercentage])
    VALUES (S.[BookedResidual],S.[BranchId],S.[ContractId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[CurrencyId],S.[DiscountingContractId],S.[DiscountingFinanceId],S.[DiscountingId],S.[FunderId],S.[IncludeResidual],S.[InstrumentTypeId],S.[InterestPayableCodeId],S.[JobStepInstanceId],S.[LegalEntityId],S.[LineOfBusinessId],S.[MaturityDate],S.[PayableRemitToId],S.[PaymentAllocation],S.[PrincipalPayableCodeId],S.[ResidualAmountUtilized],S.[ResidualBalance],S.[ResidualRepaymentId],S.[SharedPercentage])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

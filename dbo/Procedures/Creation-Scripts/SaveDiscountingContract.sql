SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDiscountingContract]
(
 @val [dbo].[DiscountingContract] READONLY
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
MERGE [dbo].[DiscountingContracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdditionalBookedResidual_Amount]=S.[AdditionalBookedResidual_Amount],[AdditionalBookedResidual_Currency]=S.[AdditionalBookedResidual_Currency],[AdditionalPaymentSold_Amount]=S.[AdditionalPaymentSold_Amount],[AdditionalPaymentSold_Currency]=S.[AdditionalPaymentSold_Currency],[AmendmentDate]=S.[AmendmentDate],[BookedResidual_Amount]=S.[BookedResidual_Amount],[BookedResidual_Currency]=S.[BookedResidual_Currency],[ContractId]=S.[ContractId],[DiscountRate]=S.[DiscountRate],[EarliestDueDate]=S.[EarliestDueDate],[EndDueDate]=S.[EndDueDate],[IncludeResidual]=S.[IncludeResidual],[IsActive]=S.[IsActive],[IsNewlyAdded]=S.[IsNewlyAdded],[PaidOffDate]=S.[PaidOffDate],[PaidOffId]=S.[PaidOffId],[PVOfAdditionalCashInflow_Amount]=S.[PVOfAdditionalCashInflow_Amount],[PVOfAdditionalCashInflow_Currency]=S.[PVOfAdditionalCashInflow_Currency],[PVOfCashInflow_Amount]=S.[PVOfCashInflow_Amount],[PVOfCashInflow_Currency]=S.[PVOfCashInflow_Currency],[ReleasedDate]=S.[ReleasedDate],[ResidualBalance_Amount]=S.[ResidualBalance_Amount],[ResidualBalance_Currency]=S.[ResidualBalance_Currency],[ResidualFactor]=S.[ResidualFactor],[TotalPaymentSold_Amount]=S.[TotalPaymentSold_Amount],[TotalPaymentSold_Currency]=S.[TotalPaymentSold_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdditionalBookedResidual_Amount],[AdditionalBookedResidual_Currency],[AdditionalPaymentSold_Amount],[AdditionalPaymentSold_Currency],[AmendmentDate],[BookedResidual_Amount],[BookedResidual_Currency],[ContractId],[CreatedById],[CreatedTime],[DiscountingFinanceId],[DiscountRate],[EarliestDueDate],[EndDueDate],[IncludeResidual],[IsActive],[IsNewlyAdded],[PaidOffDate],[PaidOffId],[PVOfAdditionalCashInflow_Amount],[PVOfAdditionalCashInflow_Currency],[PVOfCashInflow_Amount],[PVOfCashInflow_Currency],[ReleasedDate],[ResidualBalance_Amount],[ResidualBalance_Currency],[ResidualFactor],[TotalPaymentSold_Amount],[TotalPaymentSold_Currency])
    VALUES (S.[AdditionalBookedResidual_Amount],S.[AdditionalBookedResidual_Currency],S.[AdditionalPaymentSold_Amount],S.[AdditionalPaymentSold_Currency],S.[AmendmentDate],S.[BookedResidual_Amount],S.[BookedResidual_Currency],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DiscountingFinanceId],S.[DiscountRate],S.[EarliestDueDate],S.[EndDueDate],S.[IncludeResidual],S.[IsActive],S.[IsNewlyAdded],S.[PaidOffDate],S.[PaidOffId],S.[PVOfAdditionalCashInflow_Amount],S.[PVOfAdditionalCashInflow_Currency],S.[PVOfCashInflow_Amount],S.[PVOfCashInflow_Currency],S.[ReleasedDate],S.[ResidualBalance_Amount],S.[ResidualBalance_Currency],S.[ResidualFactor],S.[TotalPaymentSold_Amount],S.[TotalPaymentSold_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

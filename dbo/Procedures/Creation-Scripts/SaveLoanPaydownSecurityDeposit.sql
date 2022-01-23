SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanPaydownSecurityDeposit]
(
 @val [dbo].[LoanPaydownSecurityDeposit] READONLY
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
MERGE [dbo].[LoanPaydownSecurityDeposits] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountAppliedToPayDown_Amount]=S.[AmountAppliedToPayDown_Amount],[AmountAppliedToPayDown_Currency]=S.[AmountAppliedToPayDown_Currency],[AvailableAmount_Amount]=S.[AvailableAmount_Amount],[AvailableAmount_Currency]=S.[AvailableAmount_Currency],[IsActive]=S.[IsActive],[IsRefund]=S.[IsRefund],[PartyId]=S.[PartyId],[PayableCodeId]=S.[PayableCodeId],[PayableDate]=S.[PayableDate],[PayableRemitToId]=S.[PayableRemitToId],[SecurityDepositAllocationId]=S.[SecurityDepositAllocationId],[SecurityDepositApplicationId]=S.[SecurityDepositApplicationId],[SecurityDepositId]=S.[SecurityDepositId],[TransferToIncome_Amount]=S.[TransferToIncome_Amount],[TransferToIncome_Currency]=S.[TransferToIncome_Currency],[TransferToReceipt_Amount]=S.[TransferToReceipt_Amount],[TransferToReceipt_Currency]=S.[TransferToReceipt_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithholdingTaxRate]=S.[WithholdingTaxRate]
WHEN NOT MATCHED THEN
	INSERT ([AmountAppliedToPayDown_Amount],[AmountAppliedToPayDown_Currency],[AvailableAmount_Amount],[AvailableAmount_Currency],[CreatedById],[CreatedTime],[IsActive],[IsRefund],[LoanPaydownId],[PartyId],[PayableCodeId],[PayableDate],[PayableRemitToId],[SecurityDepositAllocationId],[SecurityDepositApplicationId],[SecurityDepositId],[TransferToIncome_Amount],[TransferToIncome_Currency],[TransferToReceipt_Amount],[TransferToReceipt_Currency],[WithholdingTaxRate])
    VALUES (S.[AmountAppliedToPayDown_Amount],S.[AmountAppliedToPayDown_Currency],S.[AvailableAmount_Amount],S.[AvailableAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsRefund],S.[LoanPaydownId],S.[PartyId],S.[PayableCodeId],S.[PayableDate],S.[PayableRemitToId],S.[SecurityDepositAllocationId],S.[SecurityDepositApplicationId],S.[SecurityDepositId],S.[TransferToIncome_Amount],S.[TransferToIncome_Currency],S.[TransferToReceipt_Amount],S.[TransferToReceipt_Currency],S.[WithholdingTaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

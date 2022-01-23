SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayoffSecurityDeposit]
(
 @val [dbo].[PayoffSecurityDeposit] READONLY
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
MERGE [dbo].[PayoffSecurityDeposits] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AppliedToPayoff_Amount]=S.[AppliedToPayoff_Amount],[AppliedToPayoff_Currency]=S.[AppliedToPayoff_Currency],[AppliedToReceivables_Amount]=S.[AppliedToReceivables_Amount],[AppliedToReceivables_Currency]=S.[AppliedToReceivables_Currency],[AvailableAmount_Amount]=S.[AvailableAmount_Amount],[AvailableAmount_Currency]=S.[AvailableAmount_Currency],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[IsActive]=S.[IsActive],[PartyId]=S.[PartyId],[PayableCodeId]=S.[PayableCodeId],[PayableDate]=S.[PayableDate],[PayableRemitToId]=S.[PayableRemitToId],[Refund]=S.[Refund],[SecurityDepositAllocationId]=S.[SecurityDepositAllocationId],[SecurityDepositApplicationId]=S.[SecurityDepositApplicationId],[TransferToIncome_Amount]=S.[TransferToIncome_Amount],[TransferToIncome_Currency]=S.[TransferToIncome_Currency],[TransferToReceipt_Amount]=S.[TransferToReceipt_Amount],[TransferToReceipt_Currency]=S.[TransferToReceipt_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithholdingTaxRate]=S.[WithholdingTaxRate]
WHEN NOT MATCHED THEN
	INSERT ([AppliedToPayoff_Amount],[AppliedToPayoff_Currency],[AppliedToReceivables_Amount],[AppliedToReceivables_Currency],[AvailableAmount_Amount],[AvailableAmount_Currency],[Balance_Amount],[Balance_Currency],[CreatedById],[CreatedTime],[IsActive],[PartyId],[PayableCodeId],[PayableDate],[PayableRemitToId],[PayoffId],[Refund],[SecurityDepositAllocationId],[SecurityDepositApplicationId],[TransferToIncome_Amount],[TransferToIncome_Currency],[TransferToReceipt_Amount],[TransferToReceipt_Currency],[WithholdingTaxRate])
    VALUES (S.[AppliedToPayoff_Amount],S.[AppliedToPayoff_Currency],S.[AppliedToReceivables_Amount],S.[AppliedToReceivables_Currency],S.[AvailableAmount_Amount],S.[AvailableAmount_Currency],S.[Balance_Amount],S.[Balance_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[PartyId],S.[PayableCodeId],S.[PayableDate],S.[PayableRemitToId],S.[PayoffId],S.[Refund],S.[SecurityDepositAllocationId],S.[SecurityDepositApplicationId],S.[TransferToIncome_Amount],S.[TransferToIncome_Currency],S.[TransferToReceipt_Amount],S.[TransferToReceipt_Currency],S.[WithholdingTaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

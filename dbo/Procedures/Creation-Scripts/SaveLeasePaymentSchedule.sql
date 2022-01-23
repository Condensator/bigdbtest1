SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeasePaymentSchedule]
(
 @val [dbo].[LeasePaymentSchedule] READONLY
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
MERGE [dbo].[LeasePaymentSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActualPayment_Amount]=S.[ActualPayment_Amount],[ActualPayment_Currency]=S.[ActualPayment_Currency],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BeginBalance_Amount]=S.[BeginBalance_Amount],[BeginBalance_Currency]=S.[BeginBalance_Currency],[Calculate]=S.[Calculate],[CustomerId]=S.[CustomerId],[Disbursement_Amount]=S.[Disbursement_Amount],[Disbursement_Currency]=S.[Disbursement_Currency],[DueDate]=S.[DueDate],[EndBalance_Amount]=S.[EndBalance_Amount],[EndBalance_Currency]=S.[EndBalance_Currency],[EndDate]=S.[EndDate],[Fee_Amount]=S.[Fee_Amount],[Fee_Currency]=S.[Fee_Currency],[Interest_Amount]=S.[Interest_Amount],[Interest_Currency]=S.[Interest_Currency],[InterestAccrued_Amount]=S.[InterestAccrued_Amount],[InterestAccrued_Currency]=S.[InterestAccrued_Currency],[IsActive]=S.[IsActive],[IsRenewal]=S.[IsRenewal],[IsVATProjected]=S.[IsVATProjected],[PaymentNumber]=S.[PaymentNumber],[PaymentStructure]=S.[PaymentStructure],[PaymentType]=S.[PaymentType],[Principal_Amount]=S.[Principal_Amount],[Principal_Currency]=S.[Principal_Currency],[ReceivableAdjustmentAmount_Amount]=S.[ReceivableAdjustmentAmount_Amount],[ReceivableAdjustmentAmount_Currency]=S.[ReceivableAdjustmentAmount_Currency],[StartDate]=S.[StartDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATAmount_Amount]=S.[VATAmount_Amount],[VATAmount_Currency]=S.[VATAmount_Currency],[VATonFee_Amount]=S.[VATonFee_Amount],[VATonFee_Currency]=S.[VATonFee_Currency]
WHEN NOT MATCHED THEN
	INSERT ([ActualPayment_Amount],[ActualPayment_Currency],[Amount_Amount],[Amount_Currency],[BeginBalance_Amount],[BeginBalance_Currency],[Calculate],[CreatedById],[CreatedTime],[CustomerId],[Disbursement_Amount],[Disbursement_Currency],[DueDate],[EndBalance_Amount],[EndBalance_Currency],[EndDate],[Fee_Amount],[Fee_Currency],[Interest_Amount],[Interest_Currency],[InterestAccrued_Amount],[InterestAccrued_Currency],[IsActive],[IsRenewal],[IsVATProjected],[LeaseFinanceDetailId],[PaymentNumber],[PaymentStructure],[PaymentType],[Principal_Amount],[Principal_Currency],[ReceivableAdjustmentAmount_Amount],[ReceivableAdjustmentAmount_Currency],[StartDate],[VATAmount_Amount],[VATAmount_Currency],[VATonFee_Amount],[VATonFee_Currency])
    VALUES (S.[ActualPayment_Amount],S.[ActualPayment_Currency],S.[Amount_Amount],S.[Amount_Currency],S.[BeginBalance_Amount],S.[BeginBalance_Currency],S.[Calculate],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[Disbursement_Amount],S.[Disbursement_Currency],S.[DueDate],S.[EndBalance_Amount],S.[EndBalance_Currency],S.[EndDate],S.[Fee_Amount],S.[Fee_Currency],S.[Interest_Amount],S.[Interest_Currency],S.[InterestAccrued_Amount],S.[InterestAccrued_Currency],S.[IsActive],S.[IsRenewal],S.[IsVATProjected],S.[LeaseFinanceDetailId],S.[PaymentNumber],S.[PaymentStructure],S.[PaymentType],S.[Principal_Amount],S.[Principal_Currency],S.[ReceivableAdjustmentAmount_Amount],S.[ReceivableAdjustmentAmount_Currency],S.[StartDate],S.[VATAmount_Amount],S.[VATAmount_Currency],S.[VATonFee_Amount],S.[VATonFee_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

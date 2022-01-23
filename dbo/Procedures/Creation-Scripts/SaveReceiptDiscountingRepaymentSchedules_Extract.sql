SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptDiscountingRepaymentSchedules_Extract]
(
 @val [dbo].[ReceiptDiscountingRepaymentSchedules_Extract] READONLY
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
MERGE [dbo].[ReceiptDiscountingRepaymentSchedules_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Balance]=S.[Balance],[ContractId]=S.[ContractId],[DiscountingFinanceId]=S.[DiscountingFinanceId],[DiscountingId]=S.[DiscountingId],[DueDate]=S.[DueDate],[EndDate]=S.[EndDate],[Interest]=S.[Interest],[InterestProcessed]=S.[InterestProcessed],[JobStepInstanceId]=S.[JobStepInstanceId],[PaymentScheduleId]=S.[PaymentScheduleId],[Principal]=S.[Principal],[PrincipalProcessed]=S.[PrincipalProcessed],[RepaymentScheduleId]=S.[RepaymentScheduleId],[SharedAmount]=S.[SharedAmount],[StartDate]=S.[StartDate],[TiedContractPaymentDetailId]=S.[TiedContractPaymentDetailId],[TiedPaymentAmountUtilized]=S.[TiedPaymentAmountUtilized],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Balance],[ContractId],[CreatedById],[CreatedTime],[DiscountingFinanceId],[DiscountingId],[DueDate],[EndDate],[Interest],[InterestProcessed],[JobStepInstanceId],[PaymentScheduleId],[Principal],[PrincipalProcessed],[RepaymentScheduleId],[SharedAmount],[StartDate],[TiedContractPaymentDetailId],[TiedPaymentAmountUtilized])
    VALUES (S.[Balance],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DiscountingFinanceId],S.[DiscountingId],S.[DueDate],S.[EndDate],S.[Interest],S.[InterestProcessed],S.[JobStepInstanceId],S.[PaymentScheduleId],S.[Principal],S.[PrincipalProcessed],S.[RepaymentScheduleId],S.[SharedAmount],S.[StartDate],S.[TiedContractPaymentDetailId],S.[TiedPaymentAmountUtilized])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCustomerBankAccountPaymentThreshold]
(
 @val [dbo].[CustomerBankAccountPaymentThreshold] READONLY
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
MERGE [dbo].[CustomerBankAccountPaymentThresholds] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BankAccountId]=S.[BankAccountId],[EmailId]=S.[EmailId],[IsActive]=S.[IsActive],[PaymentThreshold]=S.[PaymentThreshold],[PaymentThresholdAmount_Amount]=S.[PaymentThresholdAmount_Amount],[PaymentThresholdAmount_Currency]=S.[PaymentThresholdAmount_Currency],[ThresholdExceededEmailTemplateId]=S.[ThresholdExceededEmailTemplateId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BankAccountId],[CreatedById],[CreatedTime],[CustomerId],[EmailId],[IsActive],[PaymentThreshold],[PaymentThresholdAmount_Amount],[PaymentThresholdAmount_Currency],[ThresholdExceededEmailTemplateId])
    VALUES (S.[BankAccountId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[EmailId],S.[IsActive],S.[PaymentThreshold],S.[PaymentThresholdAmount_Amount],S.[PaymentThresholdAmount_Currency],S.[ThresholdExceededEmailTemplateId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

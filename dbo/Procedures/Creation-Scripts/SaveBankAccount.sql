SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBankAccount]
(
 @val [dbo].[BankAccount] READONLY
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
MERGE [dbo].[BankAccounts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountName]=S.[AccountName],[AccountNumber_CT]=S.[AccountNumber_CT],[AccountOnHoldCount]=S.[AccountOnHoldCount],[AccountType]=S.[AccountType],[ACHFailureCount]=S.[ACHFailureCount],[AuthorizationDate]=S.[AuthorizationDate],[AutomatedPaymentMethod]=S.[AutomatedPaymentMethod],[BankAccountCategoryId]=S.[BankAccountCategoryId],[BankBranchId]=S.[BankBranchId],[CurrencyId]=S.[CurrencyId],[DefaultAccountFor]=S.[DefaultAccountFor],[DefaultToAP]=S.[DefaultToAP],[ExternalPackageCheckBookID]=S.[ExternalPackageCheckBookID],[GLSegmentValue]=S.[GLSegmentValue],[IBAN]=S.[IBAN],[IsActive]=S.[IsActive],[IsExpired]=S.[IsExpired],[IsFromCustomerPortal]=S.[IsFromCustomerPortal],[IsOneTimeACHOnly]=S.[IsOneTimeACHOnly],[IsOwnersAuthorizationReceived]=S.[IsOwnersAuthorizationReceived],[IsPrimaryACH]=S.[IsPrimaryACH],[LastFourDigitAccountNumber]=S.[LastFourDigitAccountNumber],[LegalEntityAccountNumber]=S.[LegalEntityAccountNumber],[OnHold]=S.[OnHold],[PaymentProfileId]=S.[PaymentProfileId],[ReceiptGLTemplateId]=S.[ReceiptGLTemplateId],[RemittanceType]=S.[RemittanceType],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountName],[AccountNumber_CT],[AccountOnHoldCount],[AccountType],[ACHFailureCount],[AuthorizationDate],[AutomatedPaymentMethod],[BankAccountCategoryId],[BankBranchId],[CreatedById],[CreatedTime],[CurrencyId],[DefaultAccountFor],[DefaultToAP],[ExternalPackageCheckBookID],[GLSegmentValue],[IBAN],[IsActive],[IsExpired],[IsFromCustomerPortal],[IsOneTimeACHOnly],[IsOwnersAuthorizationReceived],[IsPrimaryACH],[LastFourDigitAccountNumber],[LegalEntityAccountNumber],[OnHold],[PaymentProfileId],[ReceiptGLTemplateId],[RemittanceType],[UniqueIdentifier])
    VALUES (S.[AccountName],S.[AccountNumber_CT],S.[AccountOnHoldCount],S.[AccountType],S.[ACHFailureCount],S.[AuthorizationDate],S.[AutomatedPaymentMethod],S.[BankAccountCategoryId],S.[BankBranchId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[DefaultAccountFor],S.[DefaultToAP],S.[ExternalPackageCheckBookID],S.[GLSegmentValue],S.[IBAN],S.[IsActive],S.[IsExpired],S.[IsFromCustomerPortal],S.[IsOneTimeACHOnly],S.[IsOwnersAuthorizationReceived],S.[IsPrimaryACH],S.[LastFourDigitAccountNumber],S.[LegalEntityAccountNumber],S.[OnHold],S.[PaymentProfileId],S.[ReceiptGLTemplateId],S.[RemittanceType],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

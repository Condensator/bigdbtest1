SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBankBranch]
(
 @val [dbo].[BankBranch] READONLY
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
MERGE [dbo].[BankBranches] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ABARoutingNumber_CT]=S.[ABARoutingNumber_CT],[ACHRoutingNumber]=S.[ACHRoutingNumber],[BankCode]=S.[BankCode],[BankName]=S.[BankName],[BusinessCalendarId]=S.[BusinessCalendarId],[CountryId]=S.[CountryId],[ElectronicNetworkSupportedForFinancialTransactions]=S.[ElectronicNetworkSupportedForFinancialTransactions],[GenerateBalancedACH]=S.[GenerateBalancedACH],[GenerateControlFile]=S.[GenerateControlFile],[InternalBankNumber_CT]=S.[InternalBankNumber_CT],[IsActive]=S.[IsActive],[IsFromCustomerPortal]=S.[IsFromCustomerPortal],[IsPAP]=S.[IsPAP],[NACHAFilePaddingOption]=S.[NACHAFilePaddingOption],[Name]=S.[Name],[OneTimeACHLeadDays]=S.[OneTimeACHLeadDays],[PortfolioId]=S.[PortfolioId],[RecurringACHPAPLeadDays]=S.[RecurringACHPAPLeadDays],[ShouldValidateTransitCodeLength]=S.[ShouldValidateTransitCodeLength],[SWIFTCode_CT]=S.[SWIFTCode_CT],[TransitCode_CT]=S.[TransitCode_CT],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ABARoutingNumber_CT],[ACHRoutingNumber],[BankCode],[BankName],[BusinessCalendarId],[CountryId],[CreatedById],[CreatedTime],[ElectronicNetworkSupportedForFinancialTransactions],[GenerateBalancedACH],[GenerateControlFile],[InternalBankNumber_CT],[IsActive],[IsFromCustomerPortal],[IsPAP],[NACHAFilePaddingOption],[Name],[OneTimeACHLeadDays],[PortfolioId],[RecurringACHPAPLeadDays],[ShouldValidateTransitCodeLength],[SWIFTCode_CT],[TransitCode_CT])
    VALUES (S.[ABARoutingNumber_CT],S.[ACHRoutingNumber],S.[BankCode],S.[BankName],S.[BusinessCalendarId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[ElectronicNetworkSupportedForFinancialTransactions],S.[GenerateBalancedACH],S.[GenerateControlFile],S.[InternalBankNumber_CT],S.[IsActive],S.[IsFromCustomerPortal],S.[IsPAP],S.[NACHAFilePaddingOption],S.[Name],S.[OneTimeACHLeadDays],S.[PortfolioId],S.[RecurringACHPAPLeadDays],S.[ShouldValidateTransitCodeLength],S.[SWIFTCode_CT],S.[TransitCode_CT])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

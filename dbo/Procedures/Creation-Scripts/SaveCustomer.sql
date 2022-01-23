SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCustomer]
(
 @val [dbo].[Customer] READONLY
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
MERGE [dbo].[Customers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[AlsoKnownAs]=S.[AlsoKnownAs],[AlternateCreditBureauId]=S.[AlternateCreditBureauId],[AnnualCreditReviewDate]=S.[AnnualCreditReviewDate],[ApprovedExchangeId]=S.[ApprovedExchangeId],[ApprovedRegulatorId]=S.[ApprovedRegulatorId],[AttorneyId]=S.[AttorneyId],[BankCreditExposureDate]=S.[BankCreditExposureDate],[BankCreditExposureDirect_Amount]=S.[BankCreditExposureDirect_Amount],[BankCreditExposureDirect_Currency]=S.[BankCreditExposureDirect_Currency],[BankCreditExposureIndirect_Amount]=S.[BankCreditExposureIndirect_Amount],[BankCreditExposureIndirect_Currency]=S.[BankCreditExposureIndirect_Currency],[BankLendingStrategy]=S.[BankLendingStrategy],[BaselRetail]=S.[BaselRetail],[BenefitsAndProtection]=S.[BenefitsAndProtection],[BondRatingId]=S.[BondRatingId],[BusinessBureauId]=S.[BusinessBureauId],[BusinessBureauNumber]=S.[BusinessBureauNumber],[BusinessStartDate]=S.[BusinessStartDate],[BusinessTypeId]=S.[BusinessTypeId],[BusinessTypeNAICSCodeId]=S.[BusinessTypeNAICSCodeId],[BusinessTypesSICsCodeId]=S.[BusinessTypesSICsCodeId],[CIPDocumentSourceForAddress]=S.[CIPDocumentSourceForAddress],[CIPDocumentSourceForName]=S.[CIPDocumentSourceForName],[CIPDocumentSourceForTaxIdOrSSN]=S.[CIPDocumentSourceForTaxIdOrSSN],[CIPDocumentSourceNameId]=S.[CIPDocumentSourceNameId],[ClabeNumber]=S.[ClabeNumber],[CollectionStatusId]=S.[CollectionStatusId],[Comment]=S.[Comment],[CompanyURL]=S.[CompanyURL],[ConsentDate]=S.[ConsentDate],[CreditDataReceivedDate]=S.[CreditDataReceivedDate],[CreditReviewFrequency]=S.[CreditReviewFrequency],[CreditScore]=S.[CreditScore],[CustomerClassId]=S.[CustomerClassId],[CustomerCreditBureauId]=S.[CustomerCreditBureauId],[CustomerRiskRating]=S.[CustomerRiskRating],[CustomerRiskRatingDates]=S.[CustomerRiskRatingDates],[CustomerRiskRatingScore]=S.[CustomerRiskRatingScore],[DebtorAttorneyId]=S.[DebtorAttorneyId],[DebtRatio]=S.[DebtRatio],[DeliverInvoiceViaEmail]=S.[DeliverInvoiceViaEmail],[DeliverInvoiceViaMail]=S.[DeliverInvoiceViaMail],[EFLendingStrategy]=S.[EFLendingStrategy],[ExtensionDate]=S.[ExtensionDate],[FacilitiesLevel4]=S.[FacilitiesLevel4],[FinancialDate]=S.[FinancialDate],[FinancialExpectedDate]=S.[FinancialExpectedDate],[FiscalYearEndMonth]=S.[FiscalYearEndMonth],[InactivationDate]=S.[InactivationDate],[InactivationReason]=S.[InactivationReason],[IncomeTaxStatus]=S.[IncomeTaxStatus],[InvoiceBillingCycle]=S.[InvoiceBillingCycle],[InvoiceComment]=S.[InvoiceComment],[InvoiceCommentBeginDate]=S.[InvoiceCommentBeginDate],[InvoiceCommentEndDate]=S.[InvoiceCommentEndDate],[InvoiceEmailBCC]=S.[InvoiceEmailBCC],[InvoiceEmailCC]=S.[InvoiceEmailCC],[InvoiceEmailTo]=S.[InvoiceEmailTo],[InvoiceGraceDays]=S.[InvoiceGraceDays],[InvoiceLeadDays]=S.[InvoiceLeadDays],[InvoiceTransitDays]=S.[InvoiceTransitDays],[IsBankrupt]=S.[IsBankrupt],[IsBureauReportingExempt]=S.[IsBureauReportingExempt],[IsBuyer]=S.[IsBuyer],[IsConsolidated]=S.[IsConsolidated],[IsCustomerPortalAccessBlock]=S.[IsCustomerPortalAccessBlock],[IsEPSMaster]=S.[IsEPSMaster],[IsFinancialDocumentRequired]=S.[IsFinancialDocumentRequired],[IsHNW]=S.[IsHNW],[IsLienFilingRequired]=S.[IsLienFilingRequired],[IsLimitedDisclosureParty]=S.[IsLimitedDisclosureParty],[IsManualReviewRequired]=S.[IsManualReviewRequired],[IsMaterialAndRelevantAdverseMedia]=S.[IsMaterialAndRelevantAdverseMedia],[IsMaterialAndRelevantPEP]=S.[IsMaterialAndRelevantPEP],[IsNonAccrualExempt]=S.[IsNonAccrualExempt],[IsNotificationviaEMail]=S.[IsNotificationviaEMail],[IsNotificationviaPhone]=S.[IsNotificationviaPhone],[IsNotificationviaSMS]=S.[IsNotificationviaSMS],[IsNSFChargeEligible]=S.[IsNSFChargeEligible],[IsPEP]=S.[IsPEP],[IsPostACHNotification]=S.[IsPostACHNotification],[IsPreACHNotification]=S.[IsPreACHNotification],[IsRelatedToLessor]=S.[IsRelatedToLessor],[IsRelatedtoPEP]=S.[IsRelatedtoPEP],[IsReturnACHNotification]=S.[IsReturnACHNotification],[IsSCRA]=S.[IsSCRA],[IsWithholdingTaxApplicable]=S.[IsWithholdingTaxApplicable],[JurisdictionOfSovereignId]=S.[JurisdictionOfSovereignId],[LastLoanReviewById]=S.[LastLoanReviewById],[LastPaynetExtractDate]=S.[LastPaynetExtractDate],[LateFeeTemplateId]=S.[LateFeeTemplateId],[LegalFormationTypeConfigId]=S.[LegalFormationTypeConfigId],[LegalNameValidationDate]=S.[LegalNameValidationDate],[LegalStatusId]=S.[LegalStatusId],[LicenseDate]=S.[LicenseDate],[LoanReviewCompletedBy]=S.[LoanReviewCompletedBy],[LoanReviewCompletedDate]=S.[LoanReviewCompletedDate],[LoanReviewDueDate]=S.[LoanReviewDueDate],[LoanReviewResponsibility]=S.[LoanReviewResponsibility],[ManagementLevel6]=S.[ManagementLevel6],[MedicalSpecialityId]=S.[MedicalSpecialityId],[MonthsAsOwner]=S.[MonthsAsOwner],[MonthsInBusiness]=S.[MonthsInBusiness],[NextReviewDate]=S.[NextReviewDate],[NumberOfBeds]=S.[NumberOfBeds],[ObligorRating]=S.[ObligorRating],[OccupancyRate]=S.[OccupancyRate],[OrganizationID]=S.[OrganizationID],[OriginationSourceType]=S.[OriginationSourceType],[OtherMiscLevel5]=S.[OtherMiscLevel5],[OwnershipLevel7]=S.[OwnershipLevel7],[OwnershipPattern]=S.[OwnershipPattern],[OwnershipType]=S.[OwnershipType],[OwnerStartDate]=S.[OwnerStartDate],[ParentPartyEIK]=S.[ParentPartyEIK],[ParentPartyName]=S.[ParentPartyName],[PartyType]=S.[PartyType],[PercentageOfGovernmentOwnership]=S.[PercentageOfGovernmentOwnership],[PostACHNotificationEmailTemplateId]=S.[PostACHNotificationEmailTemplateId],[PostACHNotificationEmailTo]=S.[PostACHNotificationEmailTo],[PreACHNotificationEmailTemplateId]=S.[PreACHNotificationEmailTemplateId],[PreACHNotificationEmailTo]=S.[PreACHNotificationEmailTo],[PricingIndicator]=S.[PricingIndicator],[PrimaryBusinessLevel1]=S.[PrimaryBusinessLevel1],[Priority]=S.[Priority],[Prospect]=S.[Prospect],[ReceiptHierarchyTemplateId]=S.[ReceiptHierarchyTemplateId],[ReceiverAttorneyId]=S.[ReceiverAttorneyId],[ReplacementAmount_Amount]=S.[ReplacementAmount_Amount],[ReplacementAmount_Currency]=S.[ReplacementAmount_Currency],[ReturnACHNotificationEmailTemplateId]=S.[ReturnACHNotificationEmailTemplateId],[ReturnACHNotificationEmailTo]=S.[ReturnACHNotificationEmailTo],[RevenueAmount_Amount]=S.[RevenueAmount_Amount],[RevenueAmount_Currency]=S.[RevenueAmount_Currency],[SalesForceCustomerName]=S.[SalesForceCustomerName],[SameDayCreditApprovals_Amount]=S.[SameDayCreditApprovals_Amount],[SameDayCreditApprovals_Currency]=S.[SameDayCreditApprovals_Currency],[SCRAEndDate]=S.[SCRAEndDate],[SCRAStartDate]=S.[SCRAStartDate],[SFDCId]=S.[SFDCId],[Status]=S.[Status],[StockSymbol]=S.[StockSymbol],[TaxExemptRuleId]=S.[TaxExemptRuleId],[TypeLevel2]=S.[TypeLevel2],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[AlsoKnownAs],[AlternateCreditBureauId],[AnnualCreditReviewDate],[ApprovedExchangeId],[ApprovedRegulatorId],[AttorneyId],[BankCreditExposureDate],[BankCreditExposureDirect_Amount],[BankCreditExposureDirect_Currency],[BankCreditExposureIndirect_Amount],[BankCreditExposureIndirect_Currency],[BankLendingStrategy],[BaselRetail],[BenefitsAndProtection],[BondRatingId],[BusinessBureauId],[BusinessBureauNumber],[BusinessStartDate],[BusinessTypeId],[BusinessTypeNAICSCodeId],[BusinessTypesSICsCodeId],[CIPDocumentSourceForAddress],[CIPDocumentSourceForName],[CIPDocumentSourceForTaxIdOrSSN],[CIPDocumentSourceNameId],[ClabeNumber],[CollectionStatusId],[Comment],[CompanyURL],[ConsentDate],[CreatedById],[CreatedTime],[CreditDataReceivedDate],[CreditReviewFrequency],[CreditScore],[CustomerClassId],[CustomerCreditBureauId],[CustomerRiskRating],[CustomerRiskRatingDates],[CustomerRiskRatingScore],[DebtorAttorneyId],[DebtRatio],[DeliverInvoiceViaEmail],[DeliverInvoiceViaMail],[EFLendingStrategy],[ExtensionDate],[FacilitiesLevel4],[FinancialDate],[FinancialExpectedDate],[FiscalYearEndMonth],[Id],[InactivationDate],[InactivationReason],[IncomeTaxStatus],[InvoiceBillingCycle],[InvoiceComment],[InvoiceCommentBeginDate],[InvoiceCommentEndDate],[InvoiceEmailBCC],[InvoiceEmailCC],[InvoiceEmailTo],[InvoiceGraceDays],[InvoiceLeadDays],[InvoiceTransitDays],[IsBankrupt],[IsBureauReportingExempt],[IsBuyer],[IsConsolidated],[IsCustomerPortalAccessBlock],[IsEPSMaster],[IsFinancialDocumentRequired],[IsHNW],[IsLienFilingRequired],[IsLimitedDisclosureParty],[IsManualReviewRequired],[IsMaterialAndRelevantAdverseMedia],[IsMaterialAndRelevantPEP],[IsNonAccrualExempt],[IsNotificationviaEMail],[IsNotificationviaPhone],[IsNotificationviaSMS],[IsNSFChargeEligible],[IsPEP],[IsPostACHNotification],[IsPreACHNotification],[IsRelatedToLessor],[IsRelatedtoPEP],[IsReturnACHNotification],[IsSCRA],[IsWithholdingTaxApplicable],[JurisdictionOfSovereignId],[LastLoanReviewById],[LastPaynetExtractDate],[LateFeeTemplateId],[LegalFormationTypeConfigId],[LegalNameValidationDate],[LegalStatusId],[LicenseDate],[LoanReviewCompletedBy],[LoanReviewCompletedDate],[LoanReviewDueDate],[LoanReviewResponsibility],[ManagementLevel6],[MedicalSpecialityId],[MonthsAsOwner],[MonthsInBusiness],[NextReviewDate],[NumberOfBeds],[ObligorRating],[OccupancyRate],[OrganizationID],[OriginationSourceType],[OtherMiscLevel5],[OwnershipLevel7],[OwnershipPattern],[OwnershipType],[OwnerStartDate],[ParentPartyEIK],[ParentPartyName],[PartyType],[PercentageOfGovernmentOwnership],[PostACHNotificationEmailTemplateId],[PostACHNotificationEmailTo],[PreACHNotificationEmailTemplateId],[PreACHNotificationEmailTo],[PricingIndicator],[PrimaryBusinessLevel1],[Priority],[Prospect],[ReceiptHierarchyTemplateId],[ReceiverAttorneyId],[ReplacementAmount_Amount],[ReplacementAmount_Currency],[ReturnACHNotificationEmailTemplateId],[ReturnACHNotificationEmailTo],[RevenueAmount_Amount],[RevenueAmount_Currency],[SalesForceCustomerName],[SameDayCreditApprovals_Amount],[SameDayCreditApprovals_Currency],[SCRAEndDate],[SCRAStartDate],[SFDCId],[Status],[StockSymbol],[TaxExemptRuleId],[TypeLevel2])
    VALUES (S.[ActivationDate],S.[AlsoKnownAs],S.[AlternateCreditBureauId],S.[AnnualCreditReviewDate],S.[ApprovedExchangeId],S.[ApprovedRegulatorId],S.[AttorneyId],S.[BankCreditExposureDate],S.[BankCreditExposureDirect_Amount],S.[BankCreditExposureDirect_Currency],S.[BankCreditExposureIndirect_Amount],S.[BankCreditExposureIndirect_Currency],S.[BankLendingStrategy],S.[BaselRetail],S.[BenefitsAndProtection],S.[BondRatingId],S.[BusinessBureauId],S.[BusinessBureauNumber],S.[BusinessStartDate],S.[BusinessTypeId],S.[BusinessTypeNAICSCodeId],S.[BusinessTypesSICsCodeId],S.[CIPDocumentSourceForAddress],S.[CIPDocumentSourceForName],S.[CIPDocumentSourceForTaxIdOrSSN],S.[CIPDocumentSourceNameId],S.[ClabeNumber],S.[CollectionStatusId],S.[Comment],S.[CompanyURL],S.[ConsentDate],S.[CreatedById],S.[CreatedTime],S.[CreditDataReceivedDate],S.[CreditReviewFrequency],S.[CreditScore],S.[CustomerClassId],S.[CustomerCreditBureauId],S.[CustomerRiskRating],S.[CustomerRiskRatingDates],S.[CustomerRiskRatingScore],S.[DebtorAttorneyId],S.[DebtRatio],S.[DeliverInvoiceViaEmail],S.[DeliverInvoiceViaMail],S.[EFLendingStrategy],S.[ExtensionDate],S.[FacilitiesLevel4],S.[FinancialDate],S.[FinancialExpectedDate],S.[FiscalYearEndMonth],S.[Id],S.[InactivationDate],S.[InactivationReason],S.[IncomeTaxStatus],S.[InvoiceBillingCycle],S.[InvoiceComment],S.[InvoiceCommentBeginDate],S.[InvoiceCommentEndDate],S.[InvoiceEmailBCC],S.[InvoiceEmailCC],S.[InvoiceEmailTo],S.[InvoiceGraceDays],S.[InvoiceLeadDays],S.[InvoiceTransitDays],S.[IsBankrupt],S.[IsBureauReportingExempt],S.[IsBuyer],S.[IsConsolidated],S.[IsCustomerPortalAccessBlock],S.[IsEPSMaster],S.[IsFinancialDocumentRequired],S.[IsHNW],S.[IsLienFilingRequired],S.[IsLimitedDisclosureParty],S.[IsManualReviewRequired],S.[IsMaterialAndRelevantAdverseMedia],S.[IsMaterialAndRelevantPEP],S.[IsNonAccrualExempt],S.[IsNotificationviaEMail],S.[IsNotificationviaPhone],S.[IsNotificationviaSMS],S.[IsNSFChargeEligible],S.[IsPEP],S.[IsPostACHNotification],S.[IsPreACHNotification],S.[IsRelatedToLessor],S.[IsRelatedtoPEP],S.[IsReturnACHNotification],S.[IsSCRA],S.[IsWithholdingTaxApplicable],S.[JurisdictionOfSovereignId],S.[LastLoanReviewById],S.[LastPaynetExtractDate],S.[LateFeeTemplateId],S.[LegalFormationTypeConfigId],S.[LegalNameValidationDate],S.[LegalStatusId],S.[LicenseDate],S.[LoanReviewCompletedBy],S.[LoanReviewCompletedDate],S.[LoanReviewDueDate],S.[LoanReviewResponsibility],S.[ManagementLevel6],S.[MedicalSpecialityId],S.[MonthsAsOwner],S.[MonthsInBusiness],S.[NextReviewDate],S.[NumberOfBeds],S.[ObligorRating],S.[OccupancyRate],S.[OrganizationID],S.[OriginationSourceType],S.[OtherMiscLevel5],S.[OwnershipLevel7],S.[OwnershipPattern],S.[OwnershipType],S.[OwnerStartDate],S.[ParentPartyEIK],S.[ParentPartyName],S.[PartyType],S.[PercentageOfGovernmentOwnership],S.[PostACHNotificationEmailTemplateId],S.[PostACHNotificationEmailTo],S.[PreACHNotificationEmailTemplateId],S.[PreACHNotificationEmailTo],S.[PricingIndicator],S.[PrimaryBusinessLevel1],S.[Priority],S.[Prospect],S.[ReceiptHierarchyTemplateId],S.[ReceiverAttorneyId],S.[ReplacementAmount_Amount],S.[ReplacementAmount_Currency],S.[ReturnACHNotificationEmailTemplateId],S.[ReturnACHNotificationEmailTo],S.[RevenueAmount_Amount],S.[RevenueAmount_Currency],S.[SalesForceCustomerName],S.[SameDayCreditApprovals_Amount],S.[SameDayCreditApprovals_Currency],S.[SCRAEndDate],S.[SCRAStartDate],S.[SFDCId],S.[Status],S.[StockSymbol],S.[TaxExemptRuleId],S.[TypeLevel2])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

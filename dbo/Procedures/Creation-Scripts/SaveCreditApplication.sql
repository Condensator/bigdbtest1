SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditApplication]
(
 @val [dbo].[CreditApplication] READONLY
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
MERGE [dbo].[CreditApplications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdditionalInformation]=S.[AdditionalInformation],[BillingAddressId]=S.[BillingAddressId],[Comments]=S.[Comments],[CostDetails]=S.[CostDetails],[CreditApplicationSourceType]=S.[CreditApplicationSourceType],[DealerEmail]=S.[DealerEmail],[DealerPhoneNumber]=S.[DealerPhoneNumber],[DealTypeId]=S.[DealTypeId],[EffectiveDate]=S.[EffectiveDate],[EquipmentDescription]=S.[EquipmentDescription],[EquipmentVendorId]=S.[EquipmentVendorId],[ExternalApplicationId]=S.[ExternalApplicationId],[IsCreateCustomer]=S.[IsCreateCustomer],[IsFromVendorPortal]=S.[IsFromVendorPortal],[IsHostedsolution]=S.[IsHostedsolution],[IsPaymentScheduleParameterChanged]=S.[IsPaymentScheduleParameterChanged],[IsPreApproved]=S.[IsPreApproved],[IsPricingPerformed]=S.[IsPricingPerformed],[IsSalesTaxExempt]=S.[IsSalesTaxExempt],[IsVATAssessedForPayable]=S.[IsVATAssessedForPayable],[IsVATAssessedForReceivable]=S.[IsVATAssessedForReceivable],[NoOfWorkItemsRemaining]=S.[NoOfWorkItemsRemaining],[PartyId]=S.[PartyId],[PreApprovalLOCId]=S.[PreApprovalLOCId],[ProgramId]=S.[ProgramId],[Status]=S.[Status],[SubmittedToCreditDate]=S.[SubmittedToCreditDate],[TaxRegistrationId]=S.[TaxRegistrationId],[TransactionTypeId]=S.[TransactionTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorContactId]=S.[VendorContactId],[VendorId]=S.[VendorId],[VendorUserId]=S.[VendorUserId]
WHEN NOT MATCHED THEN
	INSERT ([AdditionalInformation],[BillingAddressId],[Comments],[CostDetails],[CreatedById],[CreatedTime],[CreditApplicationSourceType],[DealerEmail],[DealerPhoneNumber],[DealTypeId],[EffectiveDate],[EquipmentDescription],[EquipmentVendorId],[ExternalApplicationId],[Id],[IsCreateCustomer],[IsFromVendorPortal],[IsHostedsolution],[IsPaymentScheduleParameterChanged],[IsPreApproved],[IsPricingPerformed],[IsSalesTaxExempt],[IsVATAssessedForPayable],[IsVATAssessedForReceivable],[NoOfWorkItemsRemaining],[PartyId],[PreApprovalLOCId],[ProgramId],[Status],[SubmittedToCreditDate],[TaxRegistrationId],[TransactionTypeId],[VendorContactId],[VendorId],[VendorUserId])
    VALUES (S.[AdditionalInformation],S.[BillingAddressId],S.[Comments],S.[CostDetails],S.[CreatedById],S.[CreatedTime],S.[CreditApplicationSourceType],S.[DealerEmail],S.[DealerPhoneNumber],S.[DealTypeId],S.[EffectiveDate],S.[EquipmentDescription],S.[EquipmentVendorId],S.[ExternalApplicationId],S.[Id],S.[IsCreateCustomer],S.[IsFromVendorPortal],S.[IsHostedsolution],S.[IsPaymentScheduleParameterChanged],S.[IsPreApproved],S.[IsPricingPerformed],S.[IsSalesTaxExempt],S.[IsVATAssessedForPayable],S.[IsVATAssessedForReceivable],S.[NoOfWorkItemsRemaining],S.[PartyId],S.[PreApprovalLOCId],S.[ProgramId],S.[Status],S.[SubmittedToCreditDate],S.[TaxRegistrationId],S.[TransactionTypeId],S.[VendorContactId],S.[VendorId],S.[VendorUserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

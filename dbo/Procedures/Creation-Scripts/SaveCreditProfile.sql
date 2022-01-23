SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditProfile]
(
 @val [dbo].[CreditProfile] READONLY
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
MERGE [dbo].[CreditProfiles] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquiredPortfolioId]=S.[AcquiredPortfolioId],[AcquisitionId]=S.[AcquisitionId],[ApprovedAmount_Amount]=S.[ApprovedAmount_Amount],[ApprovedAmount_Currency]=S.[ApprovedAmount_Currency],[BankQualified]=S.[BankQualified],[BusinessUnitId]=S.[BusinessUnitId],[CapitalStreamProductType]=S.[CapitalStreamProductType],[Comment]=S.[Comment],[CostCenterId]=S.[CostCenterId],[CountryId]=S.[CountryId],[CreditAppVerified]=S.[CreditAppVerified],[CreditCancelReasonCode]=S.[CreditCancelReasonCode],[CurrencyId]=S.[CurrencyId],[CustomerCreditScore]=S.[CustomerCreditScore],[CustomerId]=S.[CustomerId],[CustomerLookUpStatus]=S.[CustomerLookUpStatus],[DocumentMethod]=S.[DocumentMethod],[EquipmentVendorId]=S.[EquipmentVendorId],[HoldingStatus]=S.[HoldingStatus],[IsAdditionalApprovalComplete]=S.[IsAdditionalApprovalComplete],[IsCommitted]=S.[IsCommitted],[IsConduit]=S.[IsConduit],[IsConfidential]=S.[IsConfidential],[IsCostConfigUsed]=S.[IsCostConfigUsed],[IsCreditDataGatheringDone]=S.[IsCreditDataGatheringDone],[IsCreditInLW]=S.[IsCreditInLW],[IsCustomerCreationRequired]=S.[IsCustomerCreationRequired],[IsCustomerLookupComplete]=S.[IsCustomerLookupComplete],[IsFederalIncomeTaxExempt]=S.[IsFederalIncomeTaxExempt],[IsFutureFunding]=S.[IsFutureFunding],[IsHostedsolution]=S.[IsHostedsolution],[IsOFACReviewDone]=S.[IsOFACReviewDone],[IsPGChanged]=S.[IsPGChanged],[IsPreApproval]=S.[IsPreApproval],[IsPreApproved]=S.[IsPreApproved],[IsRevolving]=S.[IsRevolving],[IsSNCCode]=S.[IsSNCCode],[IsSyndicated]=S.[IsSyndicated],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[LineOfCreditId]=S.[LineOfCreditId],[ManagementSegment]=S.[ManagementSegment],[Number]=S.[Number],[OpportunityId]=S.[OpportunityId],[OriginationSourceId]=S.[OriginationSourceId],[OriginationSourceTypeId]=S.[OriginationSourceTypeId],[OriginationSourceUserId]=S.[OriginationSourceUserId],[PeakExposure_Amount]=S.[PeakExposure_Amount],[PeakExposure_Currency]=S.[PeakExposure_Currency],[PreApprovalLOCId]=S.[PreApprovalLOCId],[ProductAndServiceTypeConfigId]=S.[ProductAndServiceTypeConfigId],[ProgramId]=S.[ProgramId],[ProgramVendorOriginationSourceId]=S.[ProgramVendorOriginationSourceId],[ReferralBankerId]=S.[ReferralBankerId],[RegBDeclinationCode]=S.[RegBDeclinationCode],[ReplacementSchedule]=S.[ReplacementSchedule],[ReportStatus]=S.[ReportStatus],[RequestedAmount_Amount]=S.[RequestedAmount_Amount],[RequestedAmount_Currency]=S.[RequestedAmount_Currency],[ServicingRole]=S.[ServicingRole],[SFDCUniqueId]=S.[SFDCUniqueId],[ShellCustomerAddressId]=S.[ShellCustomerAddressId],[ShellCustomerContactId]=S.[ShellCustomerContactId],[ShellCustomerDetailId]=S.[ShellCustomerDetailId],[SingleSignOnIdentification]=S.[SingleSignOnIdentification],[SNCAgent]=S.[SNCAgent],[SNCRating]=S.[SNCRating],[SNCRatingDate]=S.[SNCRatingDate],[SNCRole]=S.[SNCRole],[Status]=S.[Status],[StatusDate]=S.[StatusDate],[ToleranceAmount_Amount]=S.[ToleranceAmount_Amount],[ToleranceAmount_Currency]=S.[ToleranceAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UsedAmount_Amount]=S.[UsedAmount_Amount],[UsedAmount_Currency]=S.[UsedAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AcquiredPortfolioId],[AcquisitionId],[ApprovedAmount_Amount],[ApprovedAmount_Currency],[BankQualified],[BusinessUnitId],[CapitalStreamProductType],[Comment],[CostCenterId],[CountryId],[CreatedById],[CreatedTime],[CreditAppVerified],[CreditCancelReasonCode],[CurrencyId],[CustomerCreditScore],[CustomerId],[CustomerLookUpStatus],[DocumentMethod],[EquipmentVendorId],[HoldingStatus],[IsAdditionalApprovalComplete],[IsCommitted],[IsConduit],[IsConfidential],[IsCostConfigUsed],[IsCreditDataGatheringDone],[IsCreditInLW],[IsCustomerCreationRequired],[IsCustomerLookupComplete],[IsFederalIncomeTaxExempt],[IsFutureFunding],[IsHostedsolution],[IsOFACReviewDone],[IsPGChanged],[IsPreApproval],[IsPreApproved],[IsRevolving],[IsSNCCode],[IsSyndicated],[LegalEntityId],[LineofBusinessId],[LineOfCreditId],[ManagementSegment],[Number],[OpportunityId],[OriginationSourceId],[OriginationSourceTypeId],[OriginationSourceUserId],[PeakExposure_Amount],[PeakExposure_Currency],[PreApprovalLOCId],[ProductAndServiceTypeConfigId],[ProgramId],[ProgramVendorOriginationSourceId],[ReferralBankerId],[RegBDeclinationCode],[ReplacementSchedule],[ReportStatus],[RequestedAmount_Amount],[RequestedAmount_Currency],[ServicingRole],[SFDCUniqueId],[ShellCustomerAddressId],[ShellCustomerContactId],[ShellCustomerDetailId],[SingleSignOnIdentification],[SNCAgent],[SNCRating],[SNCRatingDate],[SNCRole],[Status],[StatusDate],[ToleranceAmount_Amount],[ToleranceAmount_Currency],[UsedAmount_Amount],[UsedAmount_Currency])
    VALUES (S.[AcquiredPortfolioId],S.[AcquisitionId],S.[ApprovedAmount_Amount],S.[ApprovedAmount_Currency],S.[BankQualified],S.[BusinessUnitId],S.[CapitalStreamProductType],S.[Comment],S.[CostCenterId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[CreditAppVerified],S.[CreditCancelReasonCode],S.[CurrencyId],S.[CustomerCreditScore],S.[CustomerId],S.[CustomerLookUpStatus],S.[DocumentMethod],S.[EquipmentVendorId],S.[HoldingStatus],S.[IsAdditionalApprovalComplete],S.[IsCommitted],S.[IsConduit],S.[IsConfidential],S.[IsCostConfigUsed],S.[IsCreditDataGatheringDone],S.[IsCreditInLW],S.[IsCustomerCreationRequired],S.[IsCustomerLookupComplete],S.[IsFederalIncomeTaxExempt],S.[IsFutureFunding],S.[IsHostedsolution],S.[IsOFACReviewDone],S.[IsPGChanged],S.[IsPreApproval],S.[IsPreApproved],S.[IsRevolving],S.[IsSNCCode],S.[IsSyndicated],S.[LegalEntityId],S.[LineofBusinessId],S.[LineOfCreditId],S.[ManagementSegment],S.[Number],S.[OpportunityId],S.[OriginationSourceId],S.[OriginationSourceTypeId],S.[OriginationSourceUserId],S.[PeakExposure_Amount],S.[PeakExposure_Currency],S.[PreApprovalLOCId],S.[ProductAndServiceTypeConfigId],S.[ProgramId],S.[ProgramVendorOriginationSourceId],S.[ReferralBankerId],S.[RegBDeclinationCode],S.[ReplacementSchedule],S.[ReportStatus],S.[RequestedAmount_Amount],S.[RequestedAmount_Currency],S.[ServicingRole],S.[SFDCUniqueId],S.[ShellCustomerAddressId],S.[ShellCustomerContactId],S.[ShellCustomerDetailId],S.[SingleSignOnIdentification],S.[SNCAgent],S.[SNCRating],S.[SNCRatingDate],S.[SNCRole],S.[Status],S.[StatusDate],S.[ToleranceAmount_Amount],S.[ToleranceAmount_Currency],S.[UsedAmount_Amount],S.[UsedAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

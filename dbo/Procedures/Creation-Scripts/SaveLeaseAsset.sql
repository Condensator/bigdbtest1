SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseAsset]
(
 @val [dbo].[LeaseAsset] READONLY
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
MERGE [dbo].[LeaseAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccumulatedDepreciation_Amount]=S.[AccumulatedDepreciation_Amount],[AccumulatedDepreciation_Currency]=S.[AccumulatedDepreciation_Currency],[AcquisitionLocationId]=S.[AcquisitionLocationId],[AssessedUpfrontTax_Amount]=S.[AssessedUpfrontTax_Amount],[AssessedUpfrontTax_Currency]=S.[AssessedUpfrontTax_Currency],[AssetId]=S.[AssetId],[AssetImpairment_Amount]=S.[AssetImpairment_Amount],[AssetImpairment_Currency]=S.[AssetImpairment_Currency],[BillMaxInterim]=S.[BillMaxInterim],[BillToId]=S.[BillToId],[BookDepreciationTemplateId]=S.[BookDepreciationTemplateId],[BookedResidual_Amount]=S.[BookedResidual_Amount],[BookedResidual_Currency]=S.[BookedResidual_Currency],[BookedResidualFactor]=S.[BookedResidualFactor],[BranchAddressId]=S.[BranchAddressId],[CapitalizationType]=S.[CapitalizationType],[CapitalizedAdditionalCharge_Amount]=S.[CapitalizedAdditionalCharge_Amount],[CapitalizedAdditionalCharge_Currency]=S.[CapitalizedAdditionalCharge_Currency],[CapitalizedForId]=S.[CapitalizedForId],[CapitalizedIDC_Amount]=S.[CapitalizedIDC_Amount],[CapitalizedIDC_Currency]=S.[CapitalizedIDC_Currency],[CapitalizedInterimInterest_Amount]=S.[CapitalizedInterimInterest_Amount],[CapitalizedInterimInterest_Currency]=S.[CapitalizedInterimInterest_Currency],[CapitalizedInterimRent_Amount]=S.[CapitalizedInterimRent_Amount],[CapitalizedInterimRent_Currency]=S.[CapitalizedInterimRent_Currency],[CapitalizedProgressPayment_Amount]=S.[CapitalizedProgressPayment_Amount],[CapitalizedProgressPayment_Currency]=S.[CapitalizedProgressPayment_Currency],[CapitalizedSalesTax_Amount]=S.[CapitalizedSalesTax_Amount],[CapitalizedSalesTax_Currency]=S.[CapitalizedSalesTax_Currency],[CertificateOfAcceptanceNumber]=S.[CertificateOfAcceptanceNumber],[CertificateOfAcceptanceStatus]=S.[CertificateOfAcceptanceStatus],[CityTaxTypeId]=S.[CityTaxTypeId],[CountyTaxTypeId]=S.[CountyTaxTypeId],[CreditProfileEquipmentDetailId]=S.[CreditProfileEquipmentDetailId],[CustomerCost_Amount]=S.[CustomerCost_Amount],[CustomerCost_Currency]=S.[CustomerCost_Currency],[CustomerExpectedResidual_Amount]=S.[CustomerExpectedResidual_Amount],[CustomerExpectedResidual_Currency]=S.[CustomerExpectedResidual_Currency],[CustomerExpectedResidualFactor]=S.[CustomerExpectedResidualFactor],[CustomerGuaranteedResidual_Amount]=S.[CustomerGuaranteedResidual_Amount],[CustomerGuaranteedResidual_Currency]=S.[CustomerGuaranteedResidual_Currency],[CustomerGuaranteedResidualFactor]=S.[CustomerGuaranteedResidualFactor],[DeferredRentalIncome_Amount]=S.[DeferredRentalIncome_Amount],[DeferredRentalIncome_Currency]=S.[DeferredRentalIncome_Currency],[EligibleForResidualValueInsurance]=S.[EligibleForResidualValueInsurance],[ETCAdjustmentAmount_Amount]=S.[ETCAdjustmentAmount_Amount],[ETCAdjustmentAmount_Currency]=S.[ETCAdjustmentAmount_Currency],[FMV_Amount]=S.[FMV_Amount],[FMV_Currency]=S.[FMV_Currency],[FXTaxBasisAmount_Amount]=S.[FXTaxBasisAmount_Amount],[FXTaxBasisAmount_Currency]=S.[FXTaxBasisAmount_Currency],[GSTTaxPaidtoVendor_Amount]=S.[GSTTaxPaidtoVendor_Amount],[GSTTaxPaidtoVendor_Currency]=S.[GSTTaxPaidtoVendor_Currency],[HSTTaxPaidtoVendor_Amount]=S.[HSTTaxPaidtoVendor_Amount],[HSTTaxPaidtoVendor_Currency]=S.[HSTTaxPaidtoVendor_Currency],[InstallationDate]=S.[InstallationDate],[InsuranceAssessment_Amount]=S.[InsuranceAssessment_Amount],[InsuranceAssessment_Currency]=S.[InsuranceAssessment_Currency],[InterimInterestGeneratedTillDate]=S.[InterimInterestGeneratedTillDate],[InterimInterestProcessedAfterPayment]=S.[InterimInterestProcessedAfterPayment],[InterimInterestStartDate]=S.[InterimInterestStartDate],[InterimMarkup_Amount]=S.[InterimMarkup_Amount],[InterimMarkup_Currency]=S.[InterimMarkup_Currency],[InterimRent_Amount]=S.[InterimRent_Amount],[InterimRent_Currency]=S.[InterimRent_Currency],[InterimRentFactor]=S.[InterimRentFactor],[InterimRentGeneratedTillDate]=S.[InterimRentGeneratedTillDate],[InterimRentProcessedAfterPayment]=S.[InterimRentProcessedAfterPayment],[InterimRentStartDate]=S.[InterimRentStartDate],[IsActive]=S.[IsActive],[IsAdditionalChargeSoftAsset]=S.[IsAdditionalChargeSoftAsset],[IsApproved]=S.[IsApproved],[IsCollateralOnLoan]=S.[IsCollateralOnLoan],[IsEligibleForBilling]=S.[IsEligibleForBilling],[IsFailedSaleLeaseback]=S.[IsFailedSaleLeaseback],[IsLeaseAsset]=S.[IsLeaseAsset],[IsNewlyAdded]=S.[IsNewlyAdded],[IsPrepaidUpfrontTax]=S.[IsPrepaidUpfrontTax],[IsPrimary]=S.[IsPrimary],[IsSaleLeaseback]=S.[IsSaleLeaseback],[IsTaxAccountingActive]=S.[IsTaxAccountingActive],[IsTaxDepreciable]=S.[IsTaxDepreciable],[IsTransferAsset]=S.[IsTransferAsset],[LeaseRestructureId]=S.[LeaseRestructureId],[LeaseTaxAssessmentDetailId]=S.[LeaseTaxAssessmentDetailId],[Markup_Amount]=S.[Markup_Amount],[Markup_Currency]=S.[Markup_Currency],[MaturityPayment_Amount]=S.[MaturityPayment_Amount],[MaturityPayment_Currency]=S.[MaturityPayment_Currency],[MaturityPaymentFactor]=S.[MaturityPaymentFactor],[MaximumInterimDays]=S.[MaximumInterimDays],[NBV_Amount]=S.[NBV_Amount],[NBV_Currency]=S.[NBV_Currency],[OnRoadDate]=S.[OnRoadDate],[OriginalCapitalizedAmount_Amount]=S.[OriginalCapitalizedAmount_Amount],[OriginalCapitalizedAmount_Currency]=S.[OriginalCapitalizedAmount_Currency],[OTPDepreciationTerm]=S.[OTPDepreciationTerm],[OTPRent_Amount]=S.[OTPRent_Amount],[OTPRent_Currency]=S.[OTPRent_Currency],[OTPRentFactor]=S.[OTPRentFactor],[PayableInvoiceId]=S.[PayableInvoiceId],[PaymentDate]=S.[PaymentDate],[PreCapitalizationRent_Amount]=S.[PreCapitalizationRent_Amount],[PreCapitalizationRent_Currency]=S.[PreCapitalizationRent_Currency],[PrepaidUpfrontTax_Amount]=S.[PrepaidUpfrontTax_Amount],[PrepaidUpfrontTax_Currency]=S.[PrepaidUpfrontTax_Currency],[PreviousCapitalizedAdditionalCharge_Amount]=S.[PreviousCapitalizedAdditionalCharge_Amount],[PreviousCapitalizedAdditionalCharge_Currency]=S.[PreviousCapitalizedAdditionalCharge_Currency],[QSTorPSTTaxPaidtoVendor_Amount]=S.[QSTorPSTTaxPaidtoVendor_Amount],[QSTorPSTTaxPaidtoVendor_Currency]=S.[QSTorPSTTaxPaidtoVendor_Currency],[ReferenceNumber]=S.[ReferenceNumber],[Rent_Amount]=S.[Rent_Amount],[Rent_Currency]=S.[Rent_Currency],[RentFactor]=S.[RentFactor],[RequestedResidualPercentage]=S.[RequestedResidualPercentage],[ResidualValueInsurance_Amount]=S.[ResidualValueInsurance_Amount],[ResidualValueInsurance_Currency]=S.[ResidualValueInsurance_Currency],[ResidualValueInsuranceFactor]=S.[ResidualValueInsuranceFactor],[RVRecapAmount_Amount]=S.[RVRecapAmount_Amount],[RVRecapAmount_Currency]=S.[RVRecapAmount_Currency],[RVRecapFactor]=S.[RVRecapFactor],[SalesTaxAmount_Amount]=S.[SalesTaxAmount_Amount],[SalesTaxAmount_Currency]=S.[SalesTaxAmount_Currency],[SalesTaxRemittanceResponsibility]=S.[SalesTaxRemittanceResponsibility],[SpecificCostAdjustment_Amount]=S.[SpecificCostAdjustment_Amount],[SpecificCostAdjustment_Currency]=S.[SpecificCostAdjustment_Currency],[SpecificCostAdjustmentOnCommencement_Amount]=S.[SpecificCostAdjustmentOnCommencement_Amount],[SpecificCostAdjustmentOnCommencement_Currency]=S.[SpecificCostAdjustmentOnCommencement_Currency],[StateTaxTypeId]=S.[StateTaxTypeId],[SupplementalRent_Amount]=S.[SupplementalRent_Amount],[SupplementalRent_Currency]=S.[SupplementalRent_Currency],[SupplementalRentFactor]=S.[SupplementalRentFactor],[TaxBasisAmount_Amount]=S.[TaxBasisAmount_Amount],[TaxBasisAmount_Currency]=S.[TaxBasisAmount_Currency],[TaxDepEndDate]=S.[TaxDepEndDate],[TaxDepStartDate]=S.[TaxDepStartDate],[TaxDepTemplateId]=S.[TaxDepTemplateId],[TaxPaidtoVendor_Amount]=S.[TaxPaidtoVendor_Amount],[TaxPaidtoVendor_Currency]=S.[TaxPaidtoVendor_Currency],[TaxReservePercentage]=S.[TaxReservePercentage],[TerminationDate]=S.[TerminationDate],[ThirdPartyGuaranteedResidual_Amount]=S.[ThirdPartyGuaranteedResidual_Amount],[ThirdPartyGuaranteedResidual_Currency]=S.[ThirdPartyGuaranteedResidual_Currency],[ThirdPartyGuaranteedResidualFactor]=S.[ThirdPartyGuaranteedResidualFactor],[TRACPercentage]=S.[TRACPercentage],[TrueDownPayment_Amount]=S.[TrueDownPayment_Amount],[TrueDownPayment_Currency]=S.[TrueDownPayment_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontLossOnLease_Amount]=S.[UpfrontLossOnLease_Amount],[UpfrontLossOnLease_Currency]=S.[UpfrontLossOnLease_Currency],[UpfrontTaxSundryId]=S.[UpfrontTaxSundryId],[UsePayDate]=S.[UsePayDate],[ValueAsOfDate]=S.[ValueAsOfDate],[VendorRemitToId]=S.[VendorRemitToId]
WHEN NOT MATCHED THEN
	INSERT ([AccumulatedDepreciation_Amount],[AccumulatedDepreciation_Currency],[AcquisitionLocationId],[AssessedUpfrontTax_Amount],[AssessedUpfrontTax_Currency],[AssetId],[AssetImpairment_Amount],[AssetImpairment_Currency],[BillMaxInterim],[BillToId],[BookDepreciationTemplateId],[BookedResidual_Amount],[BookedResidual_Currency],[BookedResidualFactor],[BranchAddressId],[CapitalizationType],[CapitalizedAdditionalCharge_Amount],[CapitalizedAdditionalCharge_Currency],[CapitalizedForId],[CapitalizedIDC_Amount],[CapitalizedIDC_Currency],[CapitalizedInterimInterest_Amount],[CapitalizedInterimInterest_Currency],[CapitalizedInterimRent_Amount],[CapitalizedInterimRent_Currency],[CapitalizedProgressPayment_Amount],[CapitalizedProgressPayment_Currency],[CapitalizedSalesTax_Amount],[CapitalizedSalesTax_Currency],[CertificateOfAcceptanceNumber],[CertificateOfAcceptanceStatus],[CityTaxTypeId],[CountyTaxTypeId],[CreatedById],[CreatedTime],[CreditProfileEquipmentDetailId],[CustomerCost_Amount],[CustomerCost_Currency],[CustomerExpectedResidual_Amount],[CustomerExpectedResidual_Currency],[CustomerExpectedResidualFactor],[CustomerGuaranteedResidual_Amount],[CustomerGuaranteedResidual_Currency],[CustomerGuaranteedResidualFactor],[DeferredRentalIncome_Amount],[DeferredRentalIncome_Currency],[EligibleForResidualValueInsurance],[ETCAdjustmentAmount_Amount],[ETCAdjustmentAmount_Currency],[FMV_Amount],[FMV_Currency],[FXTaxBasisAmount_Amount],[FXTaxBasisAmount_Currency],[GSTTaxPaidtoVendor_Amount],[GSTTaxPaidtoVendor_Currency],[HSTTaxPaidtoVendor_Amount],[HSTTaxPaidtoVendor_Currency],[InstallationDate],[InsuranceAssessment_Amount],[InsuranceAssessment_Currency],[InterimInterestGeneratedTillDate],[InterimInterestProcessedAfterPayment],[InterimInterestStartDate],[InterimMarkup_Amount],[InterimMarkup_Currency],[InterimRent_Amount],[InterimRent_Currency],[InterimRentFactor],[InterimRentGeneratedTillDate],[InterimRentProcessedAfterPayment],[InterimRentStartDate],[IsActive],[IsAdditionalChargeSoftAsset],[IsApproved],[IsCollateralOnLoan],[IsEligibleForBilling],[IsFailedSaleLeaseback],[IsLeaseAsset],[IsNewlyAdded],[IsPrepaidUpfrontTax],[IsPrimary],[IsSaleLeaseback],[IsTaxAccountingActive],[IsTaxDepreciable],[IsTransferAsset],[LeaseFinanceId],[LeaseRestructureId],[LeaseTaxAssessmentDetailId],[Markup_Amount],[Markup_Currency],[MaturityPayment_Amount],[MaturityPayment_Currency],[MaturityPaymentFactor],[MaximumInterimDays],[NBV_Amount],[NBV_Currency],[OnRoadDate],[OriginalCapitalizedAmount_Amount],[OriginalCapitalizedAmount_Currency],[OTPDepreciationTerm],[OTPRent_Amount],[OTPRent_Currency],[OTPRentFactor],[PayableInvoiceId],[PaymentDate],[PreCapitalizationRent_Amount],[PreCapitalizationRent_Currency],[PrepaidUpfrontTax_Amount],[PrepaidUpfrontTax_Currency],[PreviousCapitalizedAdditionalCharge_Amount],[PreviousCapitalizedAdditionalCharge_Currency],[QSTorPSTTaxPaidtoVendor_Amount],[QSTorPSTTaxPaidtoVendor_Currency],[ReferenceNumber],[Rent_Amount],[Rent_Currency],[RentFactor],[RequestedResidualPercentage],[ResidualValueInsurance_Amount],[ResidualValueInsurance_Currency],[ResidualValueInsuranceFactor],[RVRecapAmount_Amount],[RVRecapAmount_Currency],[RVRecapFactor],[SalesTaxAmount_Amount],[SalesTaxAmount_Currency],[SalesTaxRemittanceResponsibility],[SpecificCostAdjustment_Amount],[SpecificCostAdjustment_Currency],[SpecificCostAdjustmentOnCommencement_Amount],[SpecificCostAdjustmentOnCommencement_Currency],[StateTaxTypeId],[SupplementalRent_Amount],[SupplementalRent_Currency],[SupplementalRentFactor],[TaxBasisAmount_Amount],[TaxBasisAmount_Currency],[TaxDepEndDate],[TaxDepStartDate],[TaxDepTemplateId],[TaxPaidtoVendor_Amount],[TaxPaidtoVendor_Currency],[TaxReservePercentage],[TerminationDate],[ThirdPartyGuaranteedResidual_Amount],[ThirdPartyGuaranteedResidual_Currency],[ThirdPartyGuaranteedResidualFactor],[TRACPercentage],[TrueDownPayment_Amount],[TrueDownPayment_Currency],[UpfrontLossOnLease_Amount],[UpfrontLossOnLease_Currency],[UpfrontTaxSundryId],[UsePayDate],[ValueAsOfDate],[VendorRemitToId])
    VALUES (S.[AccumulatedDepreciation_Amount],S.[AccumulatedDepreciation_Currency],S.[AcquisitionLocationId],S.[AssessedUpfrontTax_Amount],S.[AssessedUpfrontTax_Currency],S.[AssetId],S.[AssetImpairment_Amount],S.[AssetImpairment_Currency],S.[BillMaxInterim],S.[BillToId],S.[BookDepreciationTemplateId],S.[BookedResidual_Amount],S.[BookedResidual_Currency],S.[BookedResidualFactor],S.[BranchAddressId],S.[CapitalizationType],S.[CapitalizedAdditionalCharge_Amount],S.[CapitalizedAdditionalCharge_Currency],S.[CapitalizedForId],S.[CapitalizedIDC_Amount],S.[CapitalizedIDC_Currency],S.[CapitalizedInterimInterest_Amount],S.[CapitalizedInterimInterest_Currency],S.[CapitalizedInterimRent_Amount],S.[CapitalizedInterimRent_Currency],S.[CapitalizedProgressPayment_Amount],S.[CapitalizedProgressPayment_Currency],S.[CapitalizedSalesTax_Amount],S.[CapitalizedSalesTax_Currency],S.[CertificateOfAcceptanceNumber],S.[CertificateOfAcceptanceStatus],S.[CityTaxTypeId],S.[CountyTaxTypeId],S.[CreatedById],S.[CreatedTime],S.[CreditProfileEquipmentDetailId],S.[CustomerCost_Amount],S.[CustomerCost_Currency],S.[CustomerExpectedResidual_Amount],S.[CustomerExpectedResidual_Currency],S.[CustomerExpectedResidualFactor],S.[CustomerGuaranteedResidual_Amount],S.[CustomerGuaranteedResidual_Currency],S.[CustomerGuaranteedResidualFactor],S.[DeferredRentalIncome_Amount],S.[DeferredRentalIncome_Currency],S.[EligibleForResidualValueInsurance],S.[ETCAdjustmentAmount_Amount],S.[ETCAdjustmentAmount_Currency],S.[FMV_Amount],S.[FMV_Currency],S.[FXTaxBasisAmount_Amount],S.[FXTaxBasisAmount_Currency],S.[GSTTaxPaidtoVendor_Amount],S.[GSTTaxPaidtoVendor_Currency],S.[HSTTaxPaidtoVendor_Amount],S.[HSTTaxPaidtoVendor_Currency],S.[InstallationDate],S.[InsuranceAssessment_Amount],S.[InsuranceAssessment_Currency],S.[InterimInterestGeneratedTillDate],S.[InterimInterestProcessedAfterPayment],S.[InterimInterestStartDate],S.[InterimMarkup_Amount],S.[InterimMarkup_Currency],S.[InterimRent_Amount],S.[InterimRent_Currency],S.[InterimRentFactor],S.[InterimRentGeneratedTillDate],S.[InterimRentProcessedAfterPayment],S.[InterimRentStartDate],S.[IsActive],S.[IsAdditionalChargeSoftAsset],S.[IsApproved],S.[IsCollateralOnLoan],S.[IsEligibleForBilling],S.[IsFailedSaleLeaseback],S.[IsLeaseAsset],S.[IsNewlyAdded],S.[IsPrepaidUpfrontTax],S.[IsPrimary],S.[IsSaleLeaseback],S.[IsTaxAccountingActive],S.[IsTaxDepreciable],S.[IsTransferAsset],S.[LeaseFinanceId],S.[LeaseRestructureId],S.[LeaseTaxAssessmentDetailId],S.[Markup_Amount],S.[Markup_Currency],S.[MaturityPayment_Amount],S.[MaturityPayment_Currency],S.[MaturityPaymentFactor],S.[MaximumInterimDays],S.[NBV_Amount],S.[NBV_Currency],S.[OnRoadDate],S.[OriginalCapitalizedAmount_Amount],S.[OriginalCapitalizedAmount_Currency],S.[OTPDepreciationTerm],S.[OTPRent_Amount],S.[OTPRent_Currency],S.[OTPRentFactor],S.[PayableInvoiceId],S.[PaymentDate],S.[PreCapitalizationRent_Amount],S.[PreCapitalizationRent_Currency],S.[PrepaidUpfrontTax_Amount],S.[PrepaidUpfrontTax_Currency],S.[PreviousCapitalizedAdditionalCharge_Amount],S.[PreviousCapitalizedAdditionalCharge_Currency],S.[QSTorPSTTaxPaidtoVendor_Amount],S.[QSTorPSTTaxPaidtoVendor_Currency],S.[ReferenceNumber],S.[Rent_Amount],S.[Rent_Currency],S.[RentFactor],S.[RequestedResidualPercentage],S.[ResidualValueInsurance_Amount],S.[ResidualValueInsurance_Currency],S.[ResidualValueInsuranceFactor],S.[RVRecapAmount_Amount],S.[RVRecapAmount_Currency],S.[RVRecapFactor],S.[SalesTaxAmount_Amount],S.[SalesTaxAmount_Currency],S.[SalesTaxRemittanceResponsibility],S.[SpecificCostAdjustment_Amount],S.[SpecificCostAdjustment_Currency],S.[SpecificCostAdjustmentOnCommencement_Amount],S.[SpecificCostAdjustmentOnCommencement_Currency],S.[StateTaxTypeId],S.[SupplementalRent_Amount],S.[SupplementalRent_Currency],S.[SupplementalRentFactor],S.[TaxBasisAmount_Amount],S.[TaxBasisAmount_Currency],S.[TaxDepEndDate],S.[TaxDepStartDate],S.[TaxDepTemplateId],S.[TaxPaidtoVendor_Amount],S.[TaxPaidtoVendor_Currency],S.[TaxReservePercentage],S.[TerminationDate],S.[ThirdPartyGuaranteedResidual_Amount],S.[ThirdPartyGuaranteedResidual_Currency],S.[ThirdPartyGuaranteedResidualFactor],S.[TRACPercentage],S.[TrueDownPayment_Amount],S.[TrueDownPayment_Currency],S.[UpfrontLossOnLease_Amount],S.[UpfrontLossOnLease_Currency],S.[UpfrontTaxSundryId],S.[UsePayDate],S.[ValueAsOfDate],S.[VendorRemitToId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
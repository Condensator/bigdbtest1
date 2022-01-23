SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ResetStagingTempFields](@ModuleName varchar(50) , @ToolIdentifier int)
AS

BEGIN
IF(@ModuleName = 'CreateCustomer')
BEGIN
 UPDATE StgCustomer SET
 R_ParentPartyId=NULL,
 R_StateofIncorporationId=NULL,
 R_JurisdictionOfSovereignCountryId=NULL,
 R_LateFeeTemplateId=NULL,
 R_BusinessTypeId=NULL,
 R_PreACHNotificationEmailTemplateId=NULL,
 R_MedicalSpecialityId=NULL,
 R_LegalFormationTypeConfigId=NULL,
 R_CustomerApprovedExchangesConfigId=NULL,
 R_CustomerApprovedRegulatorConfigId=NULL,
 R_CountryId=NULL,
 R_ReceiptHierarchyTemplateId=NULL,
 R_CustomerClassId=NULL,
 R_NAICSCodeId=NULL,
 R_LanguageConfigId=NULL,
 R_StateTaxExemptionReasonId=NULL,
 R_CountryTaxExemptionReasonId=NULL,
 R_CIPDocumentSourceId=NULL,
 R_SICCodeId=NULL,
 R_CollectionStatusId=NULL,
 R_PortfolioId=NULL
 WHERE IsMigrated = 0;

 UPDATE StgCustomerAddress SET
 R_StateId=NULL,
 R_CountryId=NULL,
 R_HomeStateId=NULL,
 R_HomeCountryId=NULL
 FROM stgCustomer INNER JOIN stgCustomerAddress
 ON stgCustomer.Id = stgCustomerAddress.CustomerId
 WHERE StgCustomer.IsMigrated = 0

 UPDATE StgCustomerBillingPreference SET
 R_ReceivableTypeId=NULL
 FROM StgCustomer INNER JOIN StgCustomerBillingPreference
 ON StgCustomer.Id = StgCustomerBillingPreference.CustomerId
 WHERE StgCustomer.IsMigrated = 0

 UPDATE StgCustomerTaxRegistrationDetail SET
 R_StateId=NULL,
 R_CountryId=NULL
 FROM StgCustomer INNER JOIN StgCustomerTaxRegistrationDetail
 ON StgCustomer.Id = StgCustomerTaxRegistrationDetail.CustomerId
 WHERE StgCustomer.IsMigrated = 0

 UPDATE StgCustomerLateFeeSetup SET
 R_ReceivableTypeId=NULL
 FROM StgCustomer INNER JOIN StgCustomerLateFeeSetup
 ON StgCustomer.Id = StgCustomerLateFeeSetup.CustomerId
 WHERE StgCustomer.IsMigrated = 0

 UPDATE StgEmployeesAssignedToCustomer SET
 R_EmployeeId=NULL,
 R_RoleFunctionId=NULL
 FROM StgCustomer INNER JOIN StgEmployeesAssignedToCustomer
 ON StgCustomer.Id = StgEmployeesAssignedToCustomer.CustomerId
 WHERE StgCustomer.IsMigrated = 0

 UPDATE StgCustomerACHAssignment SET
 R_BankAccountNumber=NULL,
 R_BankBranchName=NULL,
 R_ReceivableTypeId=NULL
 FROM StgCustomer INNER JOIN StgCustomerACHAssignment
 ON StgCustomer.Id = StgCustomerACHAssignment.CustomerId
 WHERE StgCustomer.IsMigrated = 0

 UPDATE StgCustomerBankAccount SET
 R_BankBranchId=NULL,
 R_CurrencyId=NULL,
 R_ReceiptGLTemplateId=NULL,
 R_BankAccountCategoryId=NULL
 FROM StgCustomer INNER JOIN StgCustomerBankAccount
 ON StgCustomer.Id = StgCustomerBankAccount.CustomerId
 WHERE StgCustomer.IsMigrated = 0

 UPDATE StgCreditRiskGrade SET
 R_RatingModelConfigId=NULL,
 R_AdjustmentReasonConfigId=NULL,
 R_ContractId=NULL
 FROM StgCustomer INNER JOIN StgCreditRiskGrade
 ON StgCustomer.Id = StgCreditRiskGrade.CustomerId
 WHERE StgCustomer.IsMigrated = 0

 UPDATE StgCreditBureau SET
 R_BusinessBureauId=NULL
 FROM StgCustomer INNER JOIN StgCreditBureau
 ON StgCustomer.Id = StgCreditBureau.CustomerId
 WHERE StgCustomer.IsMigrated = 0

 UPDATE StgCustomerBondRating SET
 R_BondRatingId=NULL
 FROM StgCustomer INNER JOIN StgCustomerBondRating
 ON StgCustomer.Id = StgCustomerBondRating.CustomerId
 WHERE StgCustomer.IsMigrated = 0

 UPDATE StgFinancialStatement SET
 R_DocumentTypeId=NULL
 FROM StgCustomer INNER JOIN StgFinancialStatement
 ON StgCustomer.Id = StgFinancialStatement.CustomerId
 WHERE StgCustomer.IsMigrated =0
END

ELSE IF(@ModuleName = 'CreateCustomerThirdPartyRelationship')
BEGIN
 UPDATE StgCustomerThirdPartyRelationship SET
 R_ThirdPartyCustomerId=NULL,
 R_ThirdPartyAddressId=NULL,
 R_VendorId=NULL
 WHERE IsMigrated = 0
END
ELSE IF(@ModuleName = 'CreateVendorForCustomer')
BEGIN
 UPDATE StgVendor SET
 R_ParentVendorId=NULL,
 R_StateofIncorporationId=NULL,
 R_LineofBusinessId=NULL,
 R_IsUSBased=0,
 R_IsLegalEntityUSBased=0,
 R_LanguageConfigId=NULL,
 R_PortfolioId=NULL,
 R_ProgramId=NULL
 WHERE IsMigrated = 0

 UPDATE StgVendorProgramPromotion SET
 R_ProgramPromotionId=NULL
 FROM StgVendorProgramPromotion INNER JOIN StgVendor
 ON StgVendor.id = StgVendorProgramPromotion.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorLegalEntity SET
 R_LegalEntityId = NULL
 FROM StgVendorLegalEntity INNER JOIN StgVendor
 ON StgVendor.Id = StgVendorLegalEntity.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorAddress SET
 R_StateId=NULL,
 R_HomeStateId=NULL,
 R_CountryId=NULL,
 R_HomeCountryId=NULL
 FROM StgVendorAddress INNER JOIN StgVendor
 ON StgVendor.Id = StgVendorAddress.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorTaxRegistrationDetail SET
 R_StateId=NULL,
 R_CountryId=NULL
 FROM StgVendor INNER JOIN StgVendorTaxRegistrationDetail
 ON StgVendor.Id = StgVendorTaxRegistrationDetail.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorContact SET
 R_VendorId=NULL
 FROM StgVendorContact INNER JOIN StgVendor
 ON StgVendor.Id = StgVendorContact.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorBankAccount SET
 R_BankBranchId=NULL,
 R_CurrencyId=NULL,
 R_BankAccountCategoryId=NULL
 FROM StgVendorContact INNER JOIN StgVendor
 ON StgVendor.Id = StgVendorContact.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorRemitTo SET
 R_AddressUniqueIdentifier=NULL,
 R_ContactUniqueIdentifier=NULL,
 R_LogoId=NULL,
 R_UserGroupId=NULL
 FROM StgVendor INNER JOIN StgVendorRemitTo
 ON StgVendor.Id = StgVendorRemitTo.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorRemitToWireDetail SET
 R_BankAccountId=NULL
 FROM StgVendor INNER JOIN StgVendorRemitTo
 ON StgVendor.Id = StgVendorRemitTo.VendorId INNER JOIN stgVendorRemitToWireDetail
 ON StgVendorRemitToWireDetail.VendorRemitToId = StgVendorRemitTo.Id
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgEmployeesAssignedToVendor SET
 R_EmployeeId=NULL,
 R_RoleFunctionId=NULL
 FROM StgVendor INNER JOIN StgEmployeesAssignedToVendor
 ON StgVendor.Id = StgEmployeesAssignedToVendor.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgProgramVendorsAssignedToDealer SET
 R_ProgramId=NULL,
 R_LineofBusinessId=NULL,
 R_ProgramVendorId=NULL
 FROM StgVendor INNER JOIN StgProgramVendorsAssignedToDealer
 ON StgVendor.Id = StgProgramVendorsAssignedToDealer.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorPayoffTemplateAssignment SET
 R_PayOffTemplateId=NULL
 FROM StgVendor  INNER JOIN StgVendorPayoffTemplateAssignment
 ON StgVendor.Id = StgVendorPayoffTemplateAssignment.VendorId
 WHERE StgVendor.IsMigrated = 0
END
ELSE IF(@ModuleName = 'CreateVendor')
BEGIN
 UPDATE StgVendor SET
 R_ParentVendorId=NULL,
 R_StateofIncorporationId=NULL,
 R_LineofBusinessId=NULL,
 R_IsUSBased=0,
 R_IsLegalEntityUSBased=0,
 R_LanguageConfigId=NULL,
 R_PortfolioId=NULL,
 R_ProgramId=NULL
 WHERE IsMigrated = 0

 UPDATE StgVendorProgramPromotion SET
 R_ProgramPromotionId=NULL
 FROM StgVendor INNER JOIN StgVendorProgramPromotion
 ON StgVendor.id = StgVendorProgramPromotion.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorLegalEntity SET
 R_LegalEntityId = NULL
 FROM StgVendorLegalEntity INNER JOIN StgVendor
 ON StgVendor.Id = StgVendorLegalEntity.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorAddress SET
 R_StateId=NULL,
 R_HomeStateId=NULL,
 R_CountryId=NULL,
 R_HomeCountryId=NULL
 FROM StgVendor INNER JOIN StgVendorAddress
 ON StgVendor.Id = StgVendorAddress.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorContact SET
 R_VendorId=NULL
 FROM StgVendor INNER JOIN StgVendorContact
 ON StgVendor.Id = StgVendorContact.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorBankAccount SET
 R_BankBranchId=NULL,
 R_CurrencyId=NULL,
 R_BankAccountCategoryId=NULL
 FROM StgVendor  INNER JOIN StgVendorContact
 ON StgVendor.Id = StgVendorContact.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorRemitTo SET
 R_AddressUniqueIdentifier=NULL,
 R_ContactUniqueIdentifier=NULL,
 R_LogoId=NULL,
 R_UserGroupId=NULL
 FROM StgVendor INNER JOIN StgVendorRemitTo
 ON StgVendor.Id = StgVendorRemitTo.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorRemitToWireDetail SET
 R_BankAccountId=NULL
 FROM StgVendor INNER JOIN StgVendorRemitTo
 ON StgVendor.Id = StgVendorRemitTo.VendorId INNER JOIN stgVendorRemitToWireDetail
 ON StgVendorRemitToWireDetail.VendorRemitToId = StgVendorRemitTo.Id
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgEmployeesAssignedToVendor SET
 R_EmployeeId=NULL,
 R_RoleFunctionId=NULL
 FROM StgVendor INNER JOIN StgEmployeesAssignedToVendor
 ON StgVendor.Id = StgEmployeesAssignedToVendor.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgProgramVendorsAssignedToDealer SET
 R_ProgramId=NULL,
 R_LineofBusinessId=NULL,
 R_ProgramVendorId=NULL
 FROM StgVendor INNER JOIN StgProgramVendorsAssignedToDealer
 ON StgVendor.Id = StgProgramVendorsAssignedToDealer.VendorId
 WHERE StgVendor.IsMigrated = 0

 UPDATE StgVendorPayoffTemplateAssignment SET
 R_PayOffTemplateId=NULL
 FROM StgVendor INNER JOIN StgVendorPayoffTemplateAssignment
 ON StgVendor.Id = StgVendorPayoffTemplateAssignment.VendorId
 WHERE StgVendor.IsMigrated = 0
END
ELSE IF(@ModuleName = 'CreateCustomerLocation')
BEGIN
 UPDATE StgCustomerLocation SET
 R_LocationId=NULL,
 R_LocationCustomerId=NULL,
 R_CustomerId=NULL
 WHERE IsMigrated = 0
END
ELSE IF(@ModuleName = 'CreateBillToes')
BEGIN
 UPDATE StgBillTo SET
 R_CustomerId=NULL,
 R_PartyContactId=NULL,
 R_PartyAddressId=NULL,
 R_EmailTemplateId=NULL,
 R_LanguageConfigId=NULL,
 R_LocationId=NULL,
 R_JurisdictionId=NULL,
 R_JurisdictionDetailId=NULL,
 R_StatementInvoiceFormatId=NULL,
 R_StatementInvoiceEmailTemplateId=NULL
 WHERE IsMigrated = 0

 UPDATE StgBillToInvoiceFormat SET
 R_InvoiceFormatlId=NULL,
 R_InvoiceTypeLabellId=NULL,
 R_StatementInvoiceFormatId=NULL,
 R_InvoiceEmailTemplateId=NULL
 FROM StgBillTo INNER JOIN StgBillToInvoiceFormat
 ON StgBillTo.Id = StgBillToInvoiceFormat.BillToId
 WHERE StgBillTo.IsMigrated = 0

 UPDATE StgBillToInvoiceParameter SET
 R_InvoiceGroupingParameterId=NULL,
 R_BlendReceivableTypeId=NULL,
 R_ReceivableTypeLabelId=NULL,
 R_ReceivableTypeLanguageLabelId=NULL
 FROM StgBillTo INNER JOIN StgBillToInvoiceFormat
 ON StgBillTo.Id = StgBillToInvoiceFormat.BillToId
 WHERE StgBillTo.IsMigrated = 0

 UPDATE StgBillToInvoiceBodyDynamicContent SET
 R_InvoiceBodyDynamicContentId=NULL
 FROM StgBillTo INNER JOIN StgBillToInvoiceBodyDynamicContent
 ON StgBillTo.Id = StgBillToInvoiceBodyDynamicContent.BillToId
 WHERE StgBillTo.IsMigrated = 0

 UPDATE StgBillToInvoiceAddendumBodyDynamicContent SET
 R_InvoiceAddendumBodyDynamicContentId=NULL
 FROM StgBillTo INNER JOIN StgBillToInvoiceAddendumBodyDynamicContent
 ON StgBillTo.Id = StgBillToInvoiceAddendumBodyDynamicContent.BillToId
 WHERE StgBillTo.IsMigrated = 0

 UPDATE StgBillToAssetGroupByOption SET
 R_AssetGroupByOptionId=NULL
 FROM StgBillTo INNER JOIN StgBillToAssetGroupByOption
 ON StgBillTo.Id = StgBillToAssetGroupByOption.BillToId
 WHERE StgBillTo.IsMigrated = 0
END
ELSE IF(@ModuleName = 'CreateAsset')
BEGIN
 UPDATE StgASSET SET
  R_MaintenanceVendorId=NULL,
  R_LegalEntityId=NULL,
  R_AssetTypeId=NULL,
  R_ProductId=NULL,
  R_CustomerId=NULL,
  R_AssetCategoryId=NULL,
  R_ManufacturerId=NULL,
  R_ParentAssetId=NULL,
  R_AssetFeatureId=NULL,
  R_AssetUsageId=NULL,
  R_TitleTransferCodeId=NULL,
  R_StateId=NULL,
  R_SaleLeasebackCodeId=NULL,
  R_VendorAssetCategoryId=NULL,
  R_SalesTaxExemptionLevelId=NULL,
  R_AssetCatalogId=NULL,
  R_AssetBookValueAdjustmentGLTemplateId=NULL,
  R_BookDepreciationGLTemplateId=NULL,
  R_InstrumentTypeId=NULL,
  R_LineofBusinessId=NULL,
  R_CostCenterId=NULL,
  R_CurrencyId=NULL,
  R_MakeId=NULL,
  R_ModelId=NULL,
  R_InventoryRemarketerId=NULL,
  R_PropertyTaxReportId=NULL,
  R_StateTaxExemptionReasonId=NULL,
  R_CountryTaxExemptionReasonId=NULL
  WHERE IsMigrated = 0

  UPDATE StgAssetFeature SET
  R_MakeId=NULL,
  R_ModelId=NULL,
  R_AssetCatalogId=NULL,
  R_StateId=NULL,
  R_AssetTypeId=NULL,
  R_ProductId=NULL,
  R_AssetCategoryId=NULL,
  R_ManufacturerId=NULL,
  R_CurrencyId=NULL
  FROM StgAsset INNER JOIN StgAssetFeature
  ON StgAsset.Id = StgAssetFeature.AssetId
  WHERE StgAsset.IsMigrated = 0

  UPDATE StgAssetLocation SET
  R_LocationId = NULL
  FROM StgAsset INNER JOIN StgAssetLocation
  ON StgAsset.Id = StgAssetLocation.AssetId
  WHERE StgAsset.IsMigrated = 0

  UPDATE StgAssetMeter SET
  R_AssetMeterTypeId = NULL
  FROM StgAsset INNER JOIN StgAssetMeter
  ON StgAsset.Id = StgAssetMeter.AssetId
  WHERE StgAsset.IsMigrated = 0

  UPDATE StgAssetVehicleDetail SET
  R_AssetClassConfigId=NULL,
  R_FuelTypeConfigId=NULL,
  R_DriveTrainConfigId=NULL,
  R_BodyTypeConfigId=NULL,
  R_StateId=NULL,
  R_TitleCodeConfigId=NULL
  FROM StgAsset INNER JOIN StgAssetVehicleDetail
  ON StgAsset.Id = StgAssetVehicleDetail.Id
  WHERE StgAsset.IsMigrated = 0
END
ELSE IF(@ModuleName = 'CreateLeases')
BEGIN
Create table #LeaseIds(Id BIGINT);
Create table #LeaseBlendedItemIds(Id BIGINT);
Create table #LeaseSydicationIds(Id BIGINT);

 UPDATE StgLease SET
 R_BillToId=NULL,
 R_RemitToId=NULL,
 R_ReceiptHierarchyTemplateId=NULL,
 R_DealProductTypeId=NULL,
 R_DealTypeId=NULL,
 R_LineofBusinessId=NULL,
 R_CurrencyId=NULL,
 R_LegalEntityId=NULL,
 R_CustomerId=NULL,
 R_TaxProductTypeId=NULL,
 R_InstrumentTypeId=NULL,
 R_ReferralBankerId=NULL,
 R_CreditApprovedStructureId=NULL,
 R_CostCenterId=NULL,
 R_ProductAndServiceTypeConfigId=NULL,
 R_ProgramIndicatorConfigId=NULL,
 R_LanguageId=NULL,
 R_MasterAgreementId=NULL,
 R_AgreementTypeDetailId=NULL,
 R_TaxExemptRuleId=NULL,
 R_BranchId=NULL,
 R_OriginationSourceTypeId=NULL,
 R_OriginationSourceId=NULL,
 R_OriginationSourceUserId=NULL,
 R_AcquiredPortfolioId=NULL,
 R_OriginationFeeBlendedItemCodeId=NULL,
 R_OriginatorPayableRemitToId=NULL,
 R_ScrapePayableCodeId=NULL,
 R_OriginatingLineofBusinessId=NULL,
 R_ProgramVendorOriginationSourceId=NULL,
 R_DocFeeReceivableCodeId=NULL,
 R_ContractId=NULL,
 R_LeaseFinanceId=NULL,
 R_TaxExemptionReasonConfigId=NULL,
 R_StateTaxExemptionReasonConfigId=NULL,
 R_CustomerClass=NULL,
 R_AcquisitionId=NULL,
 R_CountryId=NULL,
 R_VendorPayableCodeId=NULL
 OUTPUT Inserted.Id Into #LeaseIds
 WHERE IsMigrated = 0 AND IsFailed = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)

 UPDATE StgLeaseFinanceDetail SET
 R_FixedTermReceivableCodeId=NULL,
 R_FloatRateARReceivableCodeId=NULL,
 R_OTPReceivableCodeId=NULL,
 R_OTPPayableCodeId=NULL,
 R_SupplementalReceivableCodeId=NULL,
 R_LeaseBookingGLTemplateId=NULL,
 R_LeaseIncomeGLTemplateId=NULL,
 R_PropertyTaxReceivableCodeId=NULL,
 R_FloatIncomeGLTemplateId=NULL,
 R_OTPIncomeGLTemplateId=NULL,
 R_DeferredTaxGLTemplateId=NULL,
 R_TaxDepExpenseGLTemplateId=NULL,
 R_TaxAssetSetupGLTemplateId=NULL,
 R_LeaseFinanceId=NULL,
 R_TaxDepDisposalTemplateId=NULL
 FROM StgLeaseFinanceDetail WITH (NOLOCK) INNER JOIN #LeaseIds WITH (NOLOCK)
 ON StgLeaseFinanceDetail.Id = #LeaseIds.Id

 UPDATE StgLeaseInterestRate SET
 R_FloatRateIndexId = NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseInterestRate WITH (NOLOCK)
 ON StgLeaseInterestRate.LeaseFinanceDetailId = #LeaseIds.Id

 UPDATE StgLeaseAsset SET
 R_AssetId=NULL,
 R_TaxDepTemplateId=NULL,
 R_BillToId=NULL,
 R_BookDepreciationTemplateId=NULL,
 R_AcquisitionLocationId=NULL,
 R_VendorRemitToId=NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseAsset WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseAsset.LeaseId

 UPDATE StgLeaseBlendedItem SET
 R_GlTransactionType=NULL,
 R_RecognitionGlTransactionType=NULL,
 R_ParentBlendedItemId=NULL,
 R_BlendedItemCodeId=NULL,
 R_ReceivableCodeId=NULL,
 R_PayableCodeId=NULL,
 R_LeaseAssetId=NULL,
 R_LocationId=NULL,
 R_BillToId=NULL,
 R_PayableRemitToId=NULL,
 R_BookingGLTemplateId=NULL,
 R_RecognitionGLTemplateId=NULL,
 R_TaxDepTemplateId=NULL,
 R_PartyId=NULL,
 R_ReceivableRemitToId=NULL
 Output Inserted.Id INTO #LeaseBlendedItemIds
 FROM #LeaseIds WITH (NOLOCK)  INNER JOIN StgLeaseBlendedItem WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseBlendedItem.LeaseId

 UPDATE StgLeaseBlendedItemAsset SET
 R_AssetId=NULL,
 R_LeaseAssetId=NULL
 FROM #LeaseBlendedItemIds WITH (NOLOCK) JOIN StgLeaseBlendedItemAsset WITH (NOLOCK)
 ON StgLeaseBlendedItemAsset.LeaseBlendedItemId = #LeaseBlendedItemIds.Id

 UPDATE StgEmployeesAssignedToLease SET
 R_RoleFunctionId=NULL,
 R_EmployeeId=NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgEmployeesAssignedToLease WITH (NOLOCK)
 ON #LeaseIds.Id = StgEmployeesAssignedToLease.LeaseId

 UPDATE StgLeaseContact SET
 R_PartyAddressId=NULL,
 R_PartyContactId=NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseContact WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseContact.LeaseId

 UPDATE StgLeaseBilling SET
 R_PreACHNotificationEmailTemplateId=NULL,
 R_ReceiptLegalEntityId=NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseBilling WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseBilling.Id

 UPDATE StgLeaseBillingPreference  SET
 R_ReceivableTypeId = NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseBillingPreference WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseBillingPreference.LeaseBillingId

 UPDATE StgLeaseACHAssignment SET
 R_ReceivableTypeId=NULL,   R_BankAccountId=NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseACHAssignment  WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseACHAssignment.LeaseBillingId

 UPDATE StgLeaseLateFee SET
 R_LateFeeTemplateId = NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseLateFee WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseLateFee.Id

 UPDATE StgLeaseLateFeeReceivableType SET
 R_ReceivableTypeId = NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseLateFeeReceivableType WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseLateFeeReceivableType.LeaseLateFeeId

 UPDATE StgLeaseRelatedContract SET
 R_ContractId = NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseRelatedContract WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseRelatedContract.LeaseId

 UPDATE StgLeaseInsuranceRequirement SET
 R_CoverageTypeConfigId = NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseInsuranceRequirement WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseInsuranceRequirement.LeaseId

 UPDATE StgLeaseBankAccountPaymentThreshold SET
 R_BankAccountId = NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseBankAccountPaymentThreshold WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseBankAccountPaymentThreshold.LeaseId

 UPDATE StgLeaseThirdPartyRelationship SET
 R_ThirdPartyId=NULL,
 R_ThirdPartyAddressId=NULL,
 R_ThirdPartyContactId=NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseThirdPartyRelationship WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseThirdPartyRelationship.LeaseId

 UPDATE StgLeaseSyndicationDetail SET
 R_RentalProceedsPayableCodeId=NULL,
 R_ProgressPaymentReimbursementCodeId=NULL,
 R_ScrapeReceivableCodeId=NULL,
 R_UpfrontSyndicationFeeCodeId=NULL,
 R_LoanPaydownGLTemplateId=NULL
 OUTPUT Inserted.Id INTO #LeaseSydicationIds
 FROM #LeaseIds WITH (NOLOCK)  INNER JOIN StgLeaseSyndicationDetail WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseSyndicationDetail.LeaseId

 UPDATE StgLeaseSyndicationServicingDetail SET
 R_RemitToId = NULL
 FROM StgLeaseSyndicationServicingDetail WITH (NOLOCK)
 INNER JOIN #LeaseSydicationIds WITH (NOLOCK)
 ON StgLeaseSyndicationServicingDetail.LeaseSyndicationDetailId = #LeaseSydicationIds.Id

 UPDATE StgLeaseSyndicationFundingSource SET
 R_FunderId=NULL,
 R_FunderRemitToId=NULL,
 R_FunderBillToId=NULL,
 R_FunderLocationId=NULL
 FROM StgLeaseSyndicationFundingSource WITH (NOLOCK)
 INNER JOIN #LeaseSydicationIds WITH (NOLOCK)
 ON #LeaseSydicationIds.Id = StgLeaseSyndicationFundingSource.LeaseSyndicationDetailId

 UPDATE StgLeaseAdditionalCharge SET
 R_FeeId=NULL,
 R_GLTemplateId=NULL,
 R_ReceivableCodeId=NULL
 FROM #LeaseIds WITH (NOLOCK) INNER JOIN StgLeaseAdditionalCharge WITH (NOLOCK)
 ON #LeaseIds.Id = StgLeaseAdditionalCharge.LeaseId

 DROP Table #LeaseIds
 DROP Table #LeaseBlendedItemIds
 DROP Table #LeaseSydicationIds
END
ELSE IF(@ModuleName = 'CreateLienFiling')
BEGIN
 UPDATE StgLienFilingContract SET
 R_LeaseFinanceId=NULL,
 R_LoanFinanceId=NULL,
 R_ContractId=NULL
 FROM StgLienFilingContract INNER JOIN StgLienFiling ON StgLienFiling.Id = StgLienFilingContract.Id
 WHERE StgLienFiling.IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)
END
ELSE IF(@ModuleName = 'CreateRecurringSundry')
BEGIN
 UPDATE StgSundryRecurring SET
 R_CustomerId=NULL,
 R_ContractId=NULL,
 R_InstrumentTypeId=NULL,
 R_SundryRecurringPaymentDetailId=NULL,
 R_LegalEntityId=NULL,
 R_LineofBusinessId=NULL,
 R_ReceivableCodeId=NULL,
 R_ReceivableGroupingOption=NULL,
 R_CurrencyId=NULL,
 R_BillToId=NULL,
 R_ReceivableRemitToId=NULL,
 R_ReceivableRemitToLegalEntityId=NULL,
 R_LocationId=NULL,
 R_VendorId=NULL,
 R_PayableCodeId=NULL,
 R_PayableRemitToId=NULL,
 R_ReceiptType=NULL,
 R_CostCenterId=NULL,
 R_BranchId=NULL
 WHERE IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)

 UPDATE StgSundryRecurringPaymentDetail SET
 R_AssetId=NULL,
 R_BillToId = NULL
 FROM StgSundryRecurring INNER JOIN StgSundryRecurringPaymentDetail
 ON StgSundryRecurring.Id = StgSundryRecurringPaymentDetail.SundryRecurringId
 WHERE StgSundryRecurring.IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)
END
ELSE IF(@ModuleName = 'CreateSundry')
BEGIN
	 SELECT Id INTO #stgSundry
	 FROM StgSundry
	 WHERE IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)

	 IF EXISTS(SELECT Id FROM #stgSundry)
	 BEGIN
		 DECLARE @BatchSize BIGINT = 5000;

		 WHILE(EXISTS(SELECT Id FROM #stgSundry))
		 BEGIN
			 CREATE TABLE #SundryInfo (Id BIGINT)

			 DELETE TOP (@BatchSize) FROM #stgSundry
			 OUTPUT deleted.Id
			 INTO #SundryInfo

			 IF EXISTS(SELECT Id FROM #SundryInfo)
			 BEGIN
				 UPDATE StgSundry SET
				 R_ContractId=NULL,
				 R_InstrumentTypeId=NULL,
				 R_SundryDetailId=NULL,
				 R_LegalEntityId=NULL,
				 R_ReceivableCodeId=NULL,
				 R_CustomerId=NULL,
				 R_ReceivableRemitToId=NULL,
				 R_ReceivableRemitToLegalEntityId=NULL,
				 R_LocationId=NULL,
				 R_VendorId=NULL,
				 R_PayableCodeId=NULL,
				 R_PayableRemitToId=NULL,
				 R_CurrencyId=NULL,
				 R_LineofBusinessId=NULL,
				 R_ReceiptType=NULL,
				 R_ReceivableGroupingOption=NULL,
				 R_BranchId=NULL,
				 R_CostCenterConfigId=NULL,
				 R_BillToId=NULL,
				 R_CountryId=NULL
				 FROM StgSundry
				 INNER JOIN #SundryInfo ON StgSundry.Id = #SundryInfo.Id

				 UPDATE StgSundryDetail SET
				 R_AssetId = NULL,
				 R_BillToId = NULL
				 FROM StgSundryDetail
				 INNER JOIN #SundryInfo ON StgSundryDetail.SundryId = #SundryInfo.Id
			 END

			 DROP TABLE #SundryInfo
		 END
	 END
END
ELSE  IF(@ModuleName = 'CreateSecurityDeposit')
BEGIN
 UPDATE StgSecurityDeposit SET
 R_LegalEntityId=NULL,
 R_CustomerId=NULL,
 R_InstrumentTypeId=NULL,
 R_CountryId=Null,
 R_CurrencyId=NULL,
 R_LineOfBusinessId=NULL,
 R_CostCenterId=NULL,
 R_BillToId=NULL,
 R_RemitToId=NULL,
 R_LocationId=NULL,
 R_ReceiptGLTemplateId=NULL,
 R_ContractId=NULL,
 R_ReceivableCodeId=NULL
 WHERE IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)

 UPDATE StgSecurityDepositAllocation SET
 R_ContractId=NULL
 FROM StgSecurityDeposit INNER JOIN StgSecurityDepositAllocation
 ON StgSecurityDeposit.Id = StgSecurityDepositAllocation.SecurityDepositId
 WHERE StgSecurityDeposit.IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)
END
ELSE IF(@ModuleName = 'DummySalesTaxAssessment')
BEGIN
 UPDATE StgSalesTaxAssessment SET
 R_ContractId=NULL,
 R_CustomerId=NULL,
 R_GLTemplateId=NULL
 FROM StgSalesTaxAssessment WITH(NOLOCK)
 WHERE IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)
END
ELSE IF(@ModuleName = 'InvoiceGeneration')
BEGIN
 UPDATE StgInvoiceGeneration SET
 R_ContractId=NULL,
 R_CustomerId=NULL
 WHERE IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)
END
ELSE IF(@ModuleName = 'CreateReceipts')
BEGIN
 UPDATE StgDummyReceipt SET
 R_ContractId=NULL,
 R_LegalEntityId=NULL,
 R_ReceiptTypeId=NULL,
 R_CurrencyId=NULL,
 R_ReceiptGLTemplateId=NULL,
 R_BankAccountId=NULL
 WHERE IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)
END
ELSE IF(@ModuleName = 'CreateChargeoffContract')
BEGIN
 UPDATE StgChargeoffContract SET
 R_ContractId=NULL,
 R_ChargeoffReasonConfigCodeId=NULL,
 R_ChargeoffId=NULL
 WHERE IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)
END
ELSE IF(@ModuleName = 'CreateComment')
BEGIN
 UPDATE StgComment SET
 R_AuthorId=NULL,
 R_CommentTypeId=NULL,
 R_FollowUpById=NULL,
 R_EntityId=NULL,
 R_CommentEntityTagId=NULL,
 R_AccessScopeId=NULL,
 R_AccessScopeName=NULL
 WHERE IsMigrated = 0

 UPDATE StgCommentTag SET
 R_CommentEntityTagId=NULL,
 R_EntityId=NULL,
 R_IsEntityTag=0,
 R_AccessScopeId=NULL,
 R_AccessScopeName=NULL
 FROM StgCommentTag INNER JOIN StgComment
 ON StgComment.Id = StgCommentTag.CommentId
 WHERE StgComment.IsMigrated = 0

 UPDATE StgCommentResponse SET
 R_UserId = NULL
 FROM StgComment INNER JOIN StgCommentResponse
 ON StgComment.Id = StgCommentResponse.CommentId
 WHERE StgComment.IsMigrated = 0

 UPDATE StgCommentUser SET
 R_UserLoginId=NULL
 FROM StgComment INNER JOIN StgCommentUser
 ON StgComment.Id = StgCommentUser.CommentId
 WHERE StgComment.IsMigrated = 0

 UPDATE StgCommentTypeSubType SET
 R_SubTypeId = NULL
 FROM StgComment INNER JOIN StgCommentTypeSubType
 ON StgComment.Id = StgCommentTypeSubType.CommentId
 WHERE StgComment.IsMigrated = 0
END
ELSE IF(@ModuleName = 'CreateActivity' OR @ModuleName = 'ValidateActivity')
BEGIN
 UPDATE stgActivity SET
R_StatusId = null,
R_ActivityTypeId = null,
R_PortfolioId = null,
R_OwnerUserId= null,
R_OwnerGroupId = null,
R_PersonContactId= null,
R_CurrencyId= null,
R_CustomerId = null,
R_LegalStatusId = null
WHERE IsMigrated = 0

UPDATE CD SET R_ContractId = null
FROM stgActivityContractDetail CD
JOIN stgActivity A ON CD.ActivityId = A.Id
WHERE A.IsMigrated = 0

UPDATE P
SET R_LegalReliefId = null,
R_CollectionAgencyOrAttorneyNumberId = null
FROM stgAgencyLegalPlacement P
JOIN stgActivity A ON P.Id = A.Id
WHERE IsMigrated = 0

UPDATE P
SET R_StateId = NULL,
R_CourtId = NULL,
R_TrusteeAppointedUniqueIdentifierId = NULL
FROM stgLegalRelief P
JOIN stgActivity A ON P.Id = A.Id
WHERE IsMigrated = 0

UPDATE POC
SET R_StateId = NULL,
R_OriginalPOCId = NULL
FROM stgLegalRelief P
JOIN stgActivity A ON P.Id = A.Id
JOIN stgLegalReliefProofOfClaim POC ON P.Id = POC.LegalReliefId
WHERE IsMigrated = 0


UPDATE PO
SET R_ContractId = NULL
FROM stgLegalRelief P
JOIN stgActivity A ON P.Id = A.Id
JOIN stgLegalReliefProofOfClaim POC ON P.Id = POC.LegalReliefId
JOIN stgLegalReliefPOCContract PO ON POC.Id = PO.LegalReliefProofOfClaimId
WHERE IsMigrated = 0

END
END

GO

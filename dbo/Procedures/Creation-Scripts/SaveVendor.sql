SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVendor]
(
 @val [dbo].[Vendor] READONLY
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
MERGE [dbo].[Vendors] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[ApprovalStatus]=S.[ApprovalStatus],[BusinessTypeId]=S.[BusinessTypeId],[ContingencyPercentage]=S.[ContingencyPercentage],[DeactivationDate]=S.[DeactivationDate],[DocFeeAmount_Amount]=S.[DocFeeAmount_Amount],[DocFeeAmount_Currency]=S.[DocFeeAmount_Currency],[DocFeePercentage]=S.[DocFeePercentage],[FATCA]=S.[FATCA],[FirstRightOfRefusal]=S.[FirstRightOfRefusal],[FlatFeeAmount_Amount]=S.[FlatFeeAmount_Amount],[FlatFeeAmount_Currency]=S.[FlatFeeAmount_Currency],[FundingApprovalLeadDays]=S.[FundingApprovalLeadDays],[HourlyAmount_Amount]=S.[HourlyAmount_Amount],[HourlyAmount_Currency]=S.[HourlyAmount_Currency],[InactivationReason]=S.[InactivationReason],[IsAMReviewRequired]=S.[IsAMReviewRequired],[IsContingencyPercentage]=S.[IsContingencyPercentage],[IsFlatFee]=S.[IsFlatFee],[IsForRemittance]=S.[IsForRemittance],[IsForVendorEdit]=S.[IsForVendorEdit],[IsForVendorLegalEntityAddition]=S.[IsForVendorLegalEntityAddition],[IsHourly]=S.[IsHourly],[IsManualCreditDecision]=S.[IsManualCreditDecision],[IsMunicipalityRoadTax]=S.[IsMunicipalityRoadTax],[IsNotQuotable]=S.[IsNotQuotable],[IsPercentageBasedDocFee]=S.[IsPercentageBasedDocFee],[IsPITAAgreement]=S.[IsPITAAgreement],[IsRelatedToLessor]=S.[IsRelatedToLessor],[IsRetained]=S.[IsRetained],[IsRoadTrafficOffice]=S.[IsRoadTrafficOffice],[IsVendorProgram]=S.[IsVendorProgram],[IsVendorRecourse]=S.[IsVendorRecourse],[IsWithholdingTaxApplicable]=S.[IsWithholdingTaxApplicable],[LEApprovalStatus]=S.[LEApprovalStatus],[LessorContactEmail]=S.[LessorContactEmail],[LineofBusinessId]=S.[LineofBusinessId],[MaximumResidualSharingAmount_Amount]=S.[MaximumResidualSharingAmount_Amount],[MaximumResidualSharingAmount_Currency]=S.[MaximumResidualSharingAmount_Currency],[MaximumResidualSharingPercentage]=S.[MaximumResidualSharingPercentage],[MaxQuoteExpirationDays]=S.[MaxQuoteExpirationDays],[NextReviewDate]=S.[NextReviewDate],[ParalegalName]=S.[ParalegalName],[Percentage1441]=S.[Percentage1441],[PITASignedDate]=S.[PITASignedDate],[ProgramId]=S.[ProgramId],[PSTorQSTNumber]=S.[PSTorQSTNumber],[PTMSExternalId]=S.[PTMSExternalId],[RejectionReasonCode]=S.[RejectionReasonCode],[RestrictPromotions]=S.[RestrictPromotions],[RVIFactor]=S.[RVIFactor],[SalesTaxRate]=S.[SalesTaxRate],[SecretaryName]=S.[SecretaryName],[Specialities]=S.[Specialities],[Status]=S.[Status],[Status1099]=S.[Status1099],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorCategoryId]=S.[VendorCategoryId],[VendorProgramType]=S.[VendorProgramType],[W8ExpirationDate]=S.[W8ExpirationDate],[W8IssueDate]=S.[W8IssueDate],[WebPage]=S.[WebPage],[Website]=S.[Website]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[ApprovalStatus],[BusinessTypeId],[ContingencyPercentage],[CreatedById],[CreatedTime],[DeactivationDate],[DocFeeAmount_Amount],[DocFeeAmount_Currency],[DocFeePercentage],[FATCA],[FirstRightOfRefusal],[FlatFeeAmount_Amount],[FlatFeeAmount_Currency],[FundingApprovalLeadDays],[HourlyAmount_Amount],[HourlyAmount_Currency],[Id],[InactivationReason],[IsAMReviewRequired],[IsContingencyPercentage],[IsFlatFee],[IsForRemittance],[IsForVendorEdit],[IsForVendorLegalEntityAddition],[IsHourly],[IsManualCreditDecision],[IsMunicipalityRoadTax],[IsNotQuotable],[IsPercentageBasedDocFee],[IsPITAAgreement],[IsRelatedToLessor],[IsRetained],[IsRoadTrafficOffice],[IsVendorProgram],[IsVendorRecourse],[IsWithholdingTaxApplicable],[LEApprovalStatus],[LessorContactEmail],[LineofBusinessId],[MaximumResidualSharingAmount_Amount],[MaximumResidualSharingAmount_Currency],[MaximumResidualSharingPercentage],[MaxQuoteExpirationDays],[NextReviewDate],[ParalegalName],[Percentage1441],[PITASignedDate],[ProgramId],[PSTorQSTNumber],[PTMSExternalId],[RejectionReasonCode],[RestrictPromotions],[RVIFactor],[SalesTaxRate],[SecretaryName],[Specialities],[Status],[Status1099],[Type],[VendorCategoryId],[VendorProgramType],[W8ExpirationDate],[W8IssueDate],[WebPage],[Website])
    VALUES (S.[ActivationDate],S.[ApprovalStatus],S.[BusinessTypeId],S.[ContingencyPercentage],S.[CreatedById],S.[CreatedTime],S.[DeactivationDate],S.[DocFeeAmount_Amount],S.[DocFeeAmount_Currency],S.[DocFeePercentage],S.[FATCA],S.[FirstRightOfRefusal],S.[FlatFeeAmount_Amount],S.[FlatFeeAmount_Currency],S.[FundingApprovalLeadDays],S.[HourlyAmount_Amount],S.[HourlyAmount_Currency],S.[Id],S.[InactivationReason],S.[IsAMReviewRequired],S.[IsContingencyPercentage],S.[IsFlatFee],S.[IsForRemittance],S.[IsForVendorEdit],S.[IsForVendorLegalEntityAddition],S.[IsHourly],S.[IsManualCreditDecision],S.[IsMunicipalityRoadTax],S.[IsNotQuotable],S.[IsPercentageBasedDocFee],S.[IsPITAAgreement],S.[IsRelatedToLessor],S.[IsRetained],S.[IsRoadTrafficOffice],S.[IsVendorProgram],S.[IsVendorRecourse],S.[IsWithholdingTaxApplicable],S.[LEApprovalStatus],S.[LessorContactEmail],S.[LineofBusinessId],S.[MaximumResidualSharingAmount_Amount],S.[MaximumResidualSharingAmount_Currency],S.[MaximumResidualSharingPercentage],S.[MaxQuoteExpirationDays],S.[NextReviewDate],S.[ParalegalName],S.[Percentage1441],S.[PITASignedDate],S.[ProgramId],S.[PSTorQSTNumber],S.[PTMSExternalId],S.[RejectionReasonCode],S.[RestrictPromotions],S.[RVIFactor],S.[SalesTaxRate],S.[SecretaryName],S.[Specialities],S.[Status],S.[Status1099],S.[Type],S.[VendorCategoryId],S.[VendorProgramType],S.[W8ExpirationDate],S.[W8IssueDate],S.[WebPage],S.[Website])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

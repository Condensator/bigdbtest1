SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLienFiling]
(
 @val [dbo].[LienFiling] READONLY
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
MERGE [dbo].[LienFilings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AltFilingType]=S.[AltFilingType],[AltNameDesignation]=S.[AltNameDesignation],[AmendmentAction]=S.[AmendmentAction],[AmendmentRecordDate]=S.[AmendmentRecordDate],[AmendmentType]=S.[AmendmentType],[AttachmentId]=S.[AttachmentId],[AttachmentType]=S.[AttachmentType],[AttachmentURL]=S.[AttachmentURL],[AuthorizingCustomerId]=S.[AuthorizingCustomerId],[AuthorizingFunderId]=S.[AuthorizingFunderId],[AuthorizingLegalEntityId]=S.[AuthorizingLegalEntityId],[AuthorizingPartyType]=S.[AuthorizingPartyType],[BusinessUnitId]=S.[BusinessUnitId],[CollateralClassification]=S.[CollateralClassification],[CollateralText]=S.[CollateralText],[ContinuationDate]=S.[ContinuationDate],[ContinuationRecordId]=S.[ContinuationRecordId],[ContractId]=S.[ContractId],[CountyId]=S.[CountyId],[CustomerId]=S.[CustomerId],[DateOfMaturity]=S.[DateOfMaturity],[Description]=S.[Description],[Division]=S.[Division],[EntityType]=S.[EntityType],[FilingAlias]=S.[FilingAlias],[FinancingStatementDate]=S.[FinancingStatementDate],[FinancingStatementFileNumber]=S.[FinancingStatementFileNumber],[FirstDebtorId]=S.[FirstDebtorId],[FLTaxStamp]=S.[FLTaxStamp],[HistoricalExpirationDate]=S.[HistoricalExpirationDate],[IncludeSerialNumberInAssetInformation]=S.[IncludeSerialNumberInAssetInformation],[InDebType]=S.[InDebType],[InitialFileDate]=S.[InitialFileDate],[InitialFileNumber]=S.[InitialFileNumber],[InternalComment]=S.[InternalComment],[IsAssignee]=S.[IsAssignee],[IsAutoContinuation]=S.[IsAutoContinuation],[IsFinancialStatementRequiredForRealEstate]=S.[IsFinancialStatementRequiredForRealEstate],[IsFloridaDocumentaryStampTax]=S.[IsFloridaDocumentaryStampTax],[IsManualUpdate]=S.[IsManualUpdate],[IsNoFixedDate]=S.[IsNoFixedDate],[IsRenewalRecordGenerated]=S.[IsRenewalRecordGenerated],[IsUpdateFilingRequired]=S.[IsUpdateFilingRequired],[JurisdictionId]=S.[JurisdictionId],[LienCollateralTemplateId]=S.[LienCollateralTemplateId],[LienDebtorAltCapacity]=S.[LienDebtorAltCapacity],[LienFilingStatus]=S.[LienFilingStatus],[LienRefNumber]=S.[LienRefNumber],[LienTransactions]=S.[LienTransactions],[MaximumIndebtednessAmount_Amount]=S.[MaximumIndebtednessAmount_Amount],[MaximumIndebtednessAmount_Currency]=S.[MaximumIndebtednessAmount_Currency],[OriginalDebtorName]=S.[OriginalDebtorName],[OriginalFilingRecordId]=S.[OriginalFilingRecordId],[OriginalSecuredPartyName]=S.[OriginalSecuredPartyName],[PrincipalAmount_Amount]=S.[PrincipalAmount_Amount],[PrincipalAmount_Currency]=S.[PrincipalAmount_Currency],[RecordOwnerNameAndAddress]=S.[RecordOwnerNameAndAddress],[RecordType]=S.[RecordType],[SecuredFunderId]=S.[SecuredFunderId],[SecuredLegalEntityId]=S.[SecuredLegalEntityId],[SecuredPartyType]=S.[SecuredPartyType],[SigningDate]=S.[SigningDate],[SigningPlace]=S.[SigningPlace],[StateId]=S.[StateId],[SubmissionStatus]=S.[SubmissionStatus],[TransactionType]=S.[TransactionType],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AltFilingType],[AltNameDesignation],[AmendmentAction],[AmendmentRecordDate],[AmendmentType],[AttachmentId],[AttachmentType],[AttachmentURL],[AuthorizingCustomerId],[AuthorizingFunderId],[AuthorizingLegalEntityId],[AuthorizingPartyType],[BusinessUnitId],[CollateralClassification],[CollateralText],[ContinuationDate],[ContinuationRecordId],[ContractId],[CountyId],[CreatedById],[CreatedTime],[CustomerId],[DateOfMaturity],[Description],[Division],[EntityType],[FilingAlias],[FinancingStatementDate],[FinancingStatementFileNumber],[FirstDebtorId],[FLTaxStamp],[HistoricalExpirationDate],[IncludeSerialNumberInAssetInformation],[InDebType],[InitialFileDate],[InitialFileNumber],[InternalComment],[IsAssignee],[IsAutoContinuation],[IsFinancialStatementRequiredForRealEstate],[IsFloridaDocumentaryStampTax],[IsManualUpdate],[IsNoFixedDate],[IsRenewalRecordGenerated],[IsUpdateFilingRequired],[JurisdictionId],[LienCollateralTemplateId],[LienDebtorAltCapacity],[LienFilingStatus],[LienRefNumber],[LienTransactions],[MaximumIndebtednessAmount_Amount],[MaximumIndebtednessAmount_Currency],[OriginalDebtorName],[OriginalFilingRecordId],[OriginalSecuredPartyName],[PrincipalAmount_Amount],[PrincipalAmount_Currency],[RecordOwnerNameAndAddress],[RecordType],[SecuredFunderId],[SecuredLegalEntityId],[SecuredPartyType],[SigningDate],[SigningPlace],[StateId],[SubmissionStatus],[TransactionType],[Type])
    VALUES (S.[AltFilingType],S.[AltNameDesignation],S.[AmendmentAction],S.[AmendmentRecordDate],S.[AmendmentType],S.[AttachmentId],S.[AttachmentType],S.[AttachmentURL],S.[AuthorizingCustomerId],S.[AuthorizingFunderId],S.[AuthorizingLegalEntityId],S.[AuthorizingPartyType],S.[BusinessUnitId],S.[CollateralClassification],S.[CollateralText],S.[ContinuationDate],S.[ContinuationRecordId],S.[ContractId],S.[CountyId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DateOfMaturity],S.[Description],S.[Division],S.[EntityType],S.[FilingAlias],S.[FinancingStatementDate],S.[FinancingStatementFileNumber],S.[FirstDebtorId],S.[FLTaxStamp],S.[HistoricalExpirationDate],S.[IncludeSerialNumberInAssetInformation],S.[InDebType],S.[InitialFileDate],S.[InitialFileNumber],S.[InternalComment],S.[IsAssignee],S.[IsAutoContinuation],S.[IsFinancialStatementRequiredForRealEstate],S.[IsFloridaDocumentaryStampTax],S.[IsManualUpdate],S.[IsNoFixedDate],S.[IsRenewalRecordGenerated],S.[IsUpdateFilingRequired],S.[JurisdictionId],S.[LienCollateralTemplateId],S.[LienDebtorAltCapacity],S.[LienFilingStatus],S.[LienRefNumber],S.[LienTransactions],S.[MaximumIndebtednessAmount_Amount],S.[MaximumIndebtednessAmount_Currency],S.[OriginalDebtorName],S.[OriginalFilingRecordId],S.[OriginalSecuredPartyName],S.[PrincipalAmount_Amount],S.[PrincipalAmount_Currency],S.[RecordOwnerNameAndAddress],S.[RecordType],S.[SecuredFunderId],S.[SecuredLegalEntityId],S.[SecuredPartyType],S.[SigningDate],S.[SigningPlace],S.[StateId],S.[SubmissionStatus],S.[TransactionType],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

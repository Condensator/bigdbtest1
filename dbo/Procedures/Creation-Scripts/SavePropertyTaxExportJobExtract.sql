SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePropertyTaxExportJobExtract]
(
 @val [dbo].[PropertyTaxExportJobExtract] READONLY
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
MERGE [dbo].[PropertyTaxExportJobExtracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionDate]=S.[AcquisitionDate],[Alias]=S.[Alias],[AsOfDate]=S.[AsOfDate],[AssetCatalogId]=S.[AssetCatalogId],[AssetCategoryId]=S.[AssetCategoryId],[AssetClassCode]=S.[AssetClassCode],[AssetID]=S.[AssetID],[AssetLocationId]=S.[AssetLocationId],[AssetLocationStateId]=S.[AssetLocationStateId],[AssetStatus]=S.[AssetStatus],[AssetUsageCondition]=S.[AssetUsageCondition],[BankQualified]=S.[BankQualified],[ContractId]=S.[ContractId],[ContractOriginationSourceType]=S.[ContractOriginationSourceType],[ContractSyndicationType]=S.[ContractSyndicationType],[CustomerId]=S.[CustomerId],[Description]=S.[Description],[DisposedDate]=S.[DisposedDate],[FileName]=S.[FileName],[FinancialType]=S.[FinancialType],[InServiceDate]=S.[InServiceDate],[IsContractOriginationServiced]=S.[IsContractOriginationServiced],[IsEligibleForPropertyTax]=S.[IsEligibleForPropertyTax],[IsFederalIncomeTaxExempt]=S.[IsFederalIncomeTaxExempt],[IsSubmitted]=S.[IsSubmitted],[IsSyndicationResponsibilityRemitOnly]=S.[IsSyndicationResponsibilityRemitOnly],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseContractType]=S.[LeaseContractType],[LegalEntityId]=S.[LegalEntityId],[LienDate]=S.[LienDate],[LocationEffectiveFromDate]=S.[LocationEffectiveFromDate],[ManufacturerId]=S.[ManufacturerId],[ModelYear]=S.[ModelYear],[PreviousLeaseNumber]=S.[PreviousLeaseNumber],[ProductId]=S.[ProductId],[PropertyTaxCost_Amount]=S.[PropertyTaxCost_Amount],[PropertyTaxCost_Currency]=S.[PropertyTaxCost_Currency],[PropertyTaxReportCode]=S.[PropertyTaxReportCode],[PropertyTaxResponsibility]=S.[PropertyTaxResponsibility],[SerialNumber]=S.[SerialNumber],[SourceModule]=S.[SourceModule],[StateCode]=S.[StateCode],[SubStatus]=S.[SubStatus],[TaskChunkServiceInstanceId]=S.[TaskChunkServiceInstanceId],[TypeId]=S.[TypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionDate],[Alias],[AsOfDate],[AssetCatalogId],[AssetCategoryId],[AssetClassCode],[AssetID],[AssetLocationId],[AssetLocationStateId],[AssetStatus],[AssetUsageCondition],[BankQualified],[ContractId],[ContractOriginationSourceType],[ContractSyndicationType],[CreatedById],[CreatedTime],[CustomerId],[Description],[DisposedDate],[FileName],[FinancialType],[InServiceDate],[IsContractOriginationServiced],[IsEligibleForPropertyTax],[IsFederalIncomeTaxExempt],[IsSubmitted],[IsSyndicationResponsibilityRemitOnly],[JobStepInstanceId],[LeaseContractType],[LegalEntityId],[LienDate],[LocationEffectiveFromDate],[ManufacturerId],[ModelYear],[PreviousLeaseNumber],[ProductId],[PropertyTaxCost_Amount],[PropertyTaxCost_Currency],[PropertyTaxReportCode],[PropertyTaxResponsibility],[SerialNumber],[SourceModule],[StateCode],[SubStatus],[TaskChunkServiceInstanceId],[TypeId])
    VALUES (S.[AcquisitionDate],S.[Alias],S.[AsOfDate],S.[AssetCatalogId],S.[AssetCategoryId],S.[AssetClassCode],S.[AssetID],S.[AssetLocationId],S.[AssetLocationStateId],S.[AssetStatus],S.[AssetUsageCondition],S.[BankQualified],S.[ContractId],S.[ContractOriginationSourceType],S.[ContractSyndicationType],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[Description],S.[DisposedDate],S.[FileName],S.[FinancialType],S.[InServiceDate],S.[IsContractOriginationServiced],S.[IsEligibleForPropertyTax],S.[IsFederalIncomeTaxExempt],S.[IsSubmitted],S.[IsSyndicationResponsibilityRemitOnly],S.[JobStepInstanceId],S.[LeaseContractType],S.[LegalEntityId],S.[LienDate],S.[LocationEffectiveFromDate],S.[ManufacturerId],S.[ModelYear],S.[PreviousLeaseNumber],S.[ProductId],S.[PropertyTaxCost_Amount],S.[PropertyTaxCost_Currency],S.[PropertyTaxReportCode],S.[PropertyTaxResponsibility],S.[SerialNumber],S.[SourceModule],S.[StateCode],S.[SubStatus],S.[TaskChunkServiceInstanceId],S.[TypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

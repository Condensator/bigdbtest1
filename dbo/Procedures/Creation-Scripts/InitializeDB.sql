SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[InitializeDB]
(
@TargetVendorDatabaseName sysname=null
,@TargetAuditDatabaseName sysname=null
)
As
DECLARE @VendorDatabaseName NVARCHAR(200) = @TargetVendorDatabaseName + '.[dbo]';
DECLARE @AuditDatabaseName NVARCHAR(200) = @TargetAuditDatabaseName + '.[dbo]';
if(@TargetVendorDatabaseName != '')
BEGIN

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalAttachmentDetails')
	BEGIN
		DROP Synonym PortalAttachmentDetails
	END
	DECLARE @AttachmentDetailSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalAttachmentDetails FOR DatabaseName.AttachmentDetails';
	SET @AttachmentDetailSynonym = REPLACE(@AttachmentDetailSynonym, 'DatabaseName', @VendorDatabaseName);
	EXEC sp_executesql @AttachmentDetailSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentEntityConfigs')
	BEGIN
		DROP Synonym PortalDocumentEntityConfigs
	END
	DECLARE @DocumentEntityConfigSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentEntityConfigs FOR DatabaseName.DocumentEntityConfigs';
	SET @DocumentEntityConfigSynonym = REPLACE(@DocumentEntityConfigSynonym, 'DatabaseName', @VendorDatabaseName);
	EXEC sp_executesql @DocumentEntityConfigSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentExtractionScriptConfigs')
	BEGIN
		DROP Synonym PortalDocumentExtractionScriptConfigs
	END
	DECLARE @DocumentExtractionScriptConfigSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentExtractionScriptConfigs FOR DatabaseName.DocumentExtractionScriptConfigs';
	SET @DocumentExtractionScriptConfigSynonym = REPLACE(@DocumentExtractionScriptConfigSynonym, 'DatabaseName', @VendorDatabaseName);
	EXEC sp_executesql @DocumentExtractionScriptConfigSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentGroupDetails')
	BEGIN
		DROP Synonym PortalDocumentGroupDetails
	END
	DECLARE @DocumentGroupDetailSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentGroupDetails FOR DatabaseName.DocumentGroupDetails';
	SET @DocumentGroupDetailSynonym = REPLACE(@DocumentGroupDetailSynonym, 'DatabaseName', @VendorDatabaseName);
	EXEC sp_executesql @DocumentGroupDetailSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentGroups')
	BEGIN
		DROP Synonym PortalDocumentGroups
	END
	DECLARE @DocumentGroupSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentGroups FOR DatabaseName.DocumentGroups';
	SET @DocumentGroupSynonym = REPLACE(@DocumentGroupSynonym, 'DatabaseName', @VendorDatabaseName);
	EXEC sp_executesql @DocumentGroupSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalWorkItemDocumentGroupStatusConfigs')
	BEGIN
		DROP Synonym PortalWorkItemDocumentGroupStatusConfigs
	END
	DECLARE @WorkItemDocumentGroupStatusConfigSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalWorkItemDocumentGroupStatusConfigs FOR DatabaseName.WorkItemDocumentGroupStatusConfigs';
	SET @WorkItemDocumentGroupStatusConfigSynonym = REPLACE(@WorkItemDocumentGroupStatusConfigSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @WorkItemDocumentGroupStatusConfigSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalWorkItemDocumentGroupConfigs')
	BEGIN
		DROP Synonym PortalWorkItemDocumentGroupConfigs
	END
	DECLARE @WorkItemDocumentGroupConfigSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalWorkItemDocumentGroupConfigs FOR DatabaseName.WorkItemDocumentGroupConfigs';
	SET @WorkItemDocumentGroupConfigSynonym = REPLACE(@WorkItemDocumentGroupConfigSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @WorkItemDocumentGroupConfigSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentHeaders')
	BEGIN
		DROP Synonym PortalDocumentHeaders
	END
	DECLARE @DocumentHeaderSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentHeaders FOR DatabaseName.DocumentHeaders';
	SET @DocumentHeaderSynonym = REPLACE(@DocumentHeaderSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentHeaderSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentInstances')
	BEGIN
		DROP Synonym PortalDocumentInstances
	END
	DECLARE @DocumentInstanceSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentInstances FOR DatabaseName.DocumentInstances';
	SET @DocumentInstanceSynonym = REPLACE(@DocumentInstanceSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentInstanceSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentRequirements')
	BEGIN
		DROP Synonym PortalDocumentRequirements
	END
	DECLARE @DocumentRequirementSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentRequirements FOR DatabaseName.DocumentRequirements';
	SET @DocumentRequirementSynonym = REPLACE(@DocumentRequirementSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentRequirementSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentPackDetails')
	BEGIN
		DROP Synonym PortalDocumentPackDetails
	END
	DECLARE @DocumentPackDetailSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentPackDetails FOR DatabaseName.DocumentPackDetails';
	SET @DocumentPackDetailSynonym = REPLACE(@DocumentPackDetailSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentPackDetailSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentPacks')
	BEGIN
		DROP Synonym PortalDocumentPacks
	END
	DECLARE @DocumentPackSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentPacks FOR DatabaseName.DocumentPacks';
	SET @DocumentPackSynonym = REPLACE(@DocumentPackSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentPackSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentEntityRelationConfigs')
	BEGIN
		DROP Synonym PortalDocumentEntityRelationConfigs
	END
	DECLARE @DocumentEntityRelationConfigSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentEntityRelationConfigs FOR DatabaseName.DocumentEntityRelationConfigs';
	SET @DocumentEntityRelationConfigSynonym = REPLACE(@DocumentEntityRelationConfigSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentEntityRelationConfigSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentStatusConfigs')
	BEGIN
		DROP Synonym PortalDocumentStatusConfigs
	END
	DECLARE @DocumentStatusConfigSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentStatusConfigs FOR DatabaseName.DocumentStatusConfigs';
	SET @DocumentStatusConfigSynonym = REPLACE(@DocumentStatusConfigSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentStatusConfigSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentStatusForTypes')
	BEGIN
		DROP Synonym PortalDocumentStatusForTypes
	END
	DECLARE @DocumentStatusForTypeSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentStatusForTypes FOR DatabaseName.DocumentStatusForTypes';
	SET @DocumentStatusForTypeSynonym = REPLACE(@DocumentStatusForTypeSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentStatusForTypeSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentStatusHistories')
	BEGIN
		DROP Synonym PortalDocumentStatusHistories
	END
	DECLARE @DocumentStatusHistorySynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentStatusHistories FOR DatabaseName.DocumentStatusHistories';
	SET @DocumentStatusHistorySynonym = REPLACE(@DocumentStatusHistorySynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentStatusHistorySynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentTemplates')
	BEGIN
		DROP Synonym PortalDocumentTemplates
	END
	DECLARE @DocumentTemplateSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentTemplates FOR DatabaseName.DocumentTemplates';
	SET @DocumentTemplateSynonym = REPLACE(@DocumentTemplateSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentTemplateSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentTypePermissions')
	BEGIN
		DROP Synonym PortalDocumentTypePermissions
	END
	DECLARE @DocumentTypePermissionSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentTypePermissions FOR DatabaseName.DocumentTypePermissions';
	SET @DocumentTypePermissionSynonym = REPLACE(@DocumentTypePermissionSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentTypePermissionSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentTypes')
	BEGIN
		DROP Synonym PortalDocumentTypes
	END
	DECLARE @DocumentTypeSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentTypes FOR DatabaseName.DocumentTypes';
	SET @DocumentTypeSynonym = REPLACE(@DocumentTypeSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentTypeSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentPackAttachments')
	BEGIN
		DROP Synonym PortalDocumentPackAttachments
	END
	DECLARE @DocumentPackAttachmentSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentPackAttachments FOR DatabaseName.DocumentPackAttachments';
	SET @DocumentPackAttachmentSynonym = REPLACE(@DocumentPackAttachmentSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentPackAttachmentSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentEntitySiteConfigs')
	BEGIN
		DROP Synonym PortalDocumentEntitySiteConfigs
	END
	DECLARE @DocumentEntitySiteConfigSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentEntitySiteConfigs FOR DatabaseName.DocumentEntitySiteConfigs';
	SET @DocumentEntitySiteConfigSynonym = REPLACE(@DocumentEntitySiteConfigSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentEntitySiteConfigSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentBusinessEntityConfigs')
	BEGIN
		DROP Synonym PortalDocumentBusinessEntityConfigs
	END
	DECLARE @DocumentBusinessEntityConfigSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentBusinessEntityConfigs FOR DatabaseName.DocumentBusinessEntityConfigs';
	SET @DocumentBusinessEntityConfigSynonym = REPLACE(@DocumentBusinessEntityConfigSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentBusinessEntityConfigSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentBusinessEntityRelationConfigs')
	BEGIN
		DROP Synonym PortalDocumentBusinessEntityRelationConfigs
	END
	DECLARE @DocumentBusinessEntityRelationConfigSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentBusinessEntityRelationConfigs FOR DatabaseName.DocumentBusinessEntityRelationConfigs';
	SET @DocumentBusinessEntityRelationConfigSynonym = REPLACE(@DocumentBusinessEntityRelationConfigSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentBusinessEntityRelationConfigSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentTypeSiteDetails')
	BEGIN
		DROP Synonym PortalDocumentTypeSiteDetails
	END
	DECLARE @DocumentTypeSiteDetailSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentTypeSiteDetails FOR DatabaseName.DocumentTypeSiteDetails';
	SET @DocumentTypeSiteDetailSynonym = REPLACE(@DocumentTypeSiteDetailSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentTypeSiteDetailSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentTemplateDetails')
	BEGIN
		DROP Synonym PortalDocumentTemplateDetails
	END
	DECLARE @DocumentTemplateDetailSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentTemplateDetails FOR DatabaseName.DocumentTemplateDetails';
	SET @DocumentTemplateDetailSynonym = REPLACE(@DocumentTemplateDetailSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentTemplateDetailSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentStatusSiteConfigs')
	BEGIN
		DROP Synonym PortalDocumentStatusSiteConfigs
	END
	DECLARE @DocumentStatusSiteConfigSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentStatusSiteConfigs FOR DatabaseName.DocumentStatusSiteConfigs';
	SET @DocumentStatusSiteConfigSynonym = REPLACE(@DocumentStatusSiteConfigSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentStatusSiteConfigSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentSiteDetails')
	BEGIN
		DROP Synonym PortalDocumentSiteDetails
	END
	DECLARE @DocumentSiteDetailSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentSiteDetails FOR DatabaseName.DocumentSiteDetails';
	SET @DocumentSiteDetailSynonym = REPLACE(@DocumentSiteDetailSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentSiteDetailSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentAttachments')
	BEGIN
		DROP Synonym PortalDocumentAttachments
	END
	DECLARE @DocumentAttachmentSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentAttachments FOR DatabaseName.DocumentAttachments';
	SET @DocumentAttachmentSynonym = REPLACE(@DocumentAttachmentSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @DocumentAttachmentSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalUsers')
	BEGIN
		DROP Synonym PortalUsers
	END
	DECLARE @UserSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalUsers FOR DatabaseName.Users';
	SET @UserSynonym = REPLACE(@UserSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @UserSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalCreditApplications')
	BEGIN
		DROP Synonym PortalCreditApplications
	END
	DECLARE @CreditApplicationSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalCreditApplications FOR DatabaseName.CreditApplications';
	SET @CreditApplicationSynonym = REPLACE(@CreditApplicationSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @CreditApplicationSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalCreditApplicationThirdPartyRelationships')
	BEGIN
		DROP Synonym PortalCreditApplicationThirdPartyRelationships
	END
	DECLARE @CreditApplicationThirdPartySynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalCreditApplicationThirdPartyRelationships FOR DatabaseName.CreditApplicationThirdPartyRelationships';
	SET @CreditApplicationThirdPartySynonym = REPLACE(@CreditApplicationThirdPartySynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @CreditApplicationThirdPartySynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalCustomers')
	BEGIN
		DROP Synonym PortalCustomers
	END
	DECLARE @CustomerSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalCustomers FOR DatabaseName.Customers';
	SET @CustomerSynonym = REPLACE(@CustomerSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @CustomerSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalOpportunities')
	BEGIN
		DROP Synonym PortalOpportunities
	END
	DECLARE @OpportunitySynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalOpportunities FOR DatabaseName.Opportunities';
	SET @OpportunitySynonym = REPLACE(@OpportunitySynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @OpportunitySynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalParties')
	BEGIN
		DROP Synonym PortalParties
	END
	DECLARE @PartySynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalParties FOR DatabaseName.Parties';
	SET @PartySynonym = REPLACE(@PartySynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @PartySynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalFileStores')
	BEGIN
		DROP Synonym PortalFileStores
	END
	DECLARE @FileStoreSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalFileStores FOR DatabaseName.FileStores';
	SET @FileStoreSynonym = REPLACE(@FileStoreSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @FileStoreSynonym;

	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalDocumentRequirementCloneConfigs')
	BEGIN
		DROP Synonym PortalDocumentRequirementCloneConfigs
	END
	DECLARE @PortalDocumentRequirementCloneConfigs NVARCHAR(MAX) = 'CREATE SYNONYM PortalDocumentRequirementCloneConfigs FOR DatabaseName.DocumentRequirementCloneConfigs';
	SET @PortalDocumentRequirementCloneConfigs = REPLACE(@PortalDocumentRequirementCloneConfigs, 'DatabaseName', @VendorDatabaseName);
	EXEC sp_executesql @PortalDocumentRequirementCloneConfigs;
	
	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalSiteConfigs')
	BEGIN
		DROP Synonym PortalSiteConfigs
	END
	DECLARE @SiteConfigsSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalSiteConfigs FOR DatabaseName.SiteConfigs';
	SET @SiteConfigsSynonym = REPLACE(@SiteConfigsSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @SiteConfigsSynonym;
	
	IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'PortalLanguageConfigs')
	BEGIN
		DROP Synonym PortalLanguageConfigs
	END
	DECLARE @LanguageConfigsSynonym NVARCHAR(MAX) = 'CREATE SYNONYM PortalLanguageConfigs FOR DatabaseName.LanguageConfigs';
	SET @LanguageConfigsSynonym = REPLACE(@LanguageConfigsSynonym, 'DatabaseName',@VendorDatabaseName);
	EXEC sp_executesql @LanguageConfigsSynonym;

end

if(@TargetAuditDatabaseName != '')
begin
	--Synonyms for Audit Database
	IF OBJECT_ID('CDC_ReturnCDCColumnDataNames') IS NOT NULL
	BEGIN
		DROP SYNONYM [dbo].[CDC_ReturnCDCColumnDataNames]
	END
		DECLARE @CDC_ReturnCDCColumnDataNames NVARCHAR(MAX) = 'CREATE SYNONYM CDC_ReturnCDCColumnDataNames FOR DatabaseName.ReturnCDCColumnDataNames';
		SET @CDC_ReturnCDCColumnDataNames = REPLACE(@CDC_ReturnCDCColumnDataNames, 'DatabaseName', @AuditDatabaseName);
		EXEC sp_executesql @CDC_ReturnCDCColumnDataNames;

	IF OBJECT_ID('CDC_CDCResults') IS NOT NULL
	BEGIN
		DROP SYNONYM [dbo].CDC_CDCResults
	END
		DECLARE @CDC_CDCResults NVARCHAR(MAX) = 'CREATE SYNONYM CDC_CDCResults FOR DatabaseName.CDCResults';
		SET @CDC_CDCResults = REPLACE(@CDC_CDCResults, 'DatabaseName', @AuditDatabaseName);
		EXEC sp_executesql @CDC_CDCResults;

	IF OBJECT_ID('CDC_CDCTableList') IS NOT NULL
	BEGIN
		DROP SYNONYM [dbo].CDC_CDCTableList
	END
		DECLARE @CDC_CDCTableList NVARCHAR(MAX) = 'CREATE SYNONYM CDC_CDCTableList FOR DatabaseName.CDCTableList';
		SET @CDC_CDCTableList = REPLACE(@CDC_CDCTableList, 'DatabaseName', @AuditDatabaseName);
		EXEC sp_executesql @CDC_CDCTableList;
		

	IF OBJECT_ID('CDC_ReturnCDCColumnDataValues') IS NOT NULL
	BEGIN
		DROP SYNONYM [dbo].CDC_ReturnCDCColumnDataValues
	END
		DECLARE @CDC_ReturnCDCColumnDataValues NVARCHAR(MAX) = 'CREATE SYNONYM CDC_ReturnCDCColumnDataValues FOR DatabaseName.ReturnCDCColumnDataValues';
		SET @CDC_ReturnCDCColumnDataValues = REPLACE(@CDC_ReturnCDCColumnDataValues, 'DatabaseName', @AuditDatabaseName);
		EXEC sp_executesql @CDC_ReturnCDCColumnDataValues;

	IF OBJECT_ID('CDC_RunCDCAnalysis') IS NOT NULL
	BEGIN
		DROP SYNONYM [dbo].CDC_RunCDCAnalysis
	END
	DECLARE @CDC_RunCDCAnalysis NVARCHAR(MAX) = 'CREATE SYNONYM CDC_RunCDCAnalysis FOR DatabaseName.RunCDCAnalysis';
	SET @CDC_RunCDCAnalysis = REPLACE(@CDC_RunCDCAnalysis, 'DatabaseName', @AuditDatabaseName);
	EXEC sp_executesql @CDC_RunCDCAnalysis;

	IF OBJECT_ID('CDC_GetCombinedChangedData') IS NOT NULL
	BEGIN
		DROP SYNONYM [dbo].CDC_GetCombinedChangedData
	END
	DECLARE @CDC_GetCombinedChangeData NVARCHAR(MAX) = 'CREATE SYNONYM CDC_GetCombinedChangedData FOR DatabaseName.GetCombinedChangedData';
	SET @CDC_GetCombinedChangeData = REPLACE(@CDC_GetCombinedChangeData, 'DatabaseName', @AuditDatabaseName);
	EXEC sp_executesql @CDC_GetCombinedChangeData;
END

GO

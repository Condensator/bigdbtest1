SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[MigrateBillToes]
(	
	@UserId BIGINT,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET = NULL,
	@ProcessedRecords BIGINT OUT,
	@FailedRecords BIGINT OUT
)
AS
--DECLARE @UserId BIGINT;
--DECLARE @FailedRecords BIGINT;
--DECLARE @ProcessedRecords BIGINT;
--DECLARE @CreatedTime DATETIMEOFFSET;
--DECLARE @ModuleIterationStatusId BIGINT;
--SET @UserId = 1;
--SET @CreatedTime = SYSDATETIMEOFFSET();	
--SELECT @ModuleIterationStatusId=MAX(ModuleIterationStatusId) from stgProcessingLog;
BEGIN
SET NOCOUNT ON
BEGIN TRY
BEGIN TRANSACTION
SET XACT_ABORT ON
SET @FailedRecords = 0
SET @ProcessedRecords =0
DECLARE @ErrorLogs ErrorMessageList;
DECLARE @TaxDataSourceIsVertex NVarChar(10)
SELECT @TaxDataSourceIsVertex  = Value FROM GlobalParameters WHERE Category='SalesTax' AND Name ='IsTaxSourceVertex'
DECLARE @Module VARCHAR(50) = NULL
DECLARE @SQL Nvarchar(max) =''		
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module , NULL
CREATE TABLE #CreatedBillToes
		(
			[Action] NVARCHAR(10) NOT NULL
			,[Id] BIGINT NOT NULL
			,BillToId BIGINT NOT NULL
		);
CREATE TABLE #createdTaxExemptRuleId
		(
			[Action] NVARCHAR(10) NOT NULL
			,[Id] BIGINT NOT NULL
			,BillToId BIGINT NOT NULL
			,[Code] NVARCHAR(50) NULL
		);
CREATE TABLE #createdLocationId
		(
			[LocationId] BIGINT NOT NULL
			,[BillToId] BIGINT NOT NULL
		);

SELECT 
	InvoiceGroupingParameterId = InvoiceGroupingParameters.Id
	,BlendedReceivableTypeId = CAST(NULL AS BIGINT)
	,ReceivableTypeLabelId = ReceivableTypeLabelConfigs.Id
	,ReceivableTypeLanguageLabelId = ReceivableTypeLanguageLabels.Id
	,AllowBlending = CASE WHEN InvoiceGroupingParameters.AllowBlending = 1 THEN 'Yes' ELSE 'No' END 
INTO #BillToInvoiceParameter
FROM InvoiceGroupingParameters
INNER JOIN ReceivableCategories ON ReceivableCategories.Id=InvoiceGroupingParameters.ReceivableCategoryId 
	AND InvoiceGroupingParameters.IsActive=1
INNER JOIN ReceivableTypes ON ReceivableTypes.Id = InvoiceGroupingParameters.ReceivableTypeId 
	AND ReceivableCategories.IsActive=1 
	AND ReceivableCategories.IsInvoiceGenerate=1 
	AND ReceivableTypes.IsActive=1
INNER JOIN LanguageConfigs ON LanguageConfigs.Name ='English'
LEFT JOIN ReceivableCategories As BlendedReceivableType ON InvoiceGroupingParameters.BlendReceivableCategoryId = BlendedReceivableType.Id
LEFT JOIN ReceivableTypeLabelConfigs ON ReceivableTypeLabelConfigs.InvoiceGroupingParameterId = InvoiceGroupingParameters.Id 
	AND ReceivableTypeLabelConfigs.IsDefault=1
LEFT JOIN ReceivableTypeLanguageLabels ON ReceivableTypeLanguageLabels.ReceivableTypeLabelConfigId = ReceivableTypeLabelConfigs.Id
AND LanguageConfigs.Id = ReceivableTypeLanguageLabels.LanguageConfigId
WHERE (BlendedReceivableType.Id Is NULL) OR (BlendedReceivableType.Id Is NOT NULL AND InvoiceGroupingParameters.IsDefault=1) ;
SELECT 
	ReceivableCategoryId = ReceivableCategories.Id
	, InvoiceFormatId = InvoiceFormats.Id
	, VATInvoiceFormatId = VATInvoiceFormat.Id
	, InvoiceTypeLabelId = InvoiceTypeLabelConfigs.Id
	, ReceivableCategoryname = ReceivableCategories.Name
	, InvoiceOutput = 'PDF'
	, InvoiceEmailTemplateId = NULL
INTO #BillToInvoiceFormat
FROM ReceivableCategories
INNER JOIN InvoiceTypes ON ReceivableCategories.InvoiceTypeId = InvoiceTypes.Id 
	AND ReceivableCategories.IsActive=1 
	AND ReceivableCategories.IsInvoiceGenerate=1
INNER JOIN InvoiceFormats ON InvoiceTypes.Id= InvoiceFormats.InvoiceTypeId  AND IsStatementFormat = 0
	AND InvoiceFormats.IsActive=1 AND IsVATInvoiceFormat=0
LEFT JOIN InvoiceFormats VATInvoiceFormat ON InvoiceTypes.Id= VATInvoiceFormat.InvoiceTypeId 
	AND VATInvoiceFormat.IsStatementFormat = 0
	AND VATInvoiceFormat.IsActive=1
	AND VATInvoiceFormat.IsVATInvoiceFormat=1
	AND VATInvoiceFormat.IsDefault=1
INNER JOIN InvoiceTypeLabelConfigs ON  InvoiceTypeLabelConfigs.InvoiceTypeId=InvoiceTypes.Id 
	AND InvoiceTypeLabelConfigs.IsActive=1
	AND (InvoiceFormats.InvoiceLanguageId=1 OR InvoiceFormats.InvoiceLanguageId Is NULL) 
	AND InvoiceFormats.IsDefault=1
	AND InvoiceTypeLabelConfigs.IsDefault=1
GROUP BY InvoiceFormats.Id,VATInvoiceFormat.Id,InvoiceTypeLabelConfigs.Id,ReceivableCategories.Id,ReceivableCategories.Name;
--declare @CreatedTime DATETIMEOFFSET = SYSDATETIMEOFFSET();
--Set @ProcessedRecords = (SELECT COUNT(Id) FROM stgBillTo  WHERE IsMigrated = 0)
Update stgBillTo  set IsFailed=0  WHERE IsMigrated = 0 
Set @ProcessedRecords =ISNULL(@@rowCount,0)
SELECT #BillToInvoiceFormat.*,stgBillTo.Id AS BillToId
INTO 
#IndividualBillToInvoiceFormat
FROM #BillToInvoiceFormat
CROSS JOIN stgBillTo
WHERE stgBillTo.IsFailed = 0 AND IsMigrated = 0
--- Updating the Party Id column based on CustomerPartyNumber
Update 
	BillTo
Set 
	BillTo.R_CustomerId = [Party].Id
From
	stgBillTo BillTo
	Join Parties [Party] on [Party].PartyNumber = BillTo.CustomerPartyNumber
	Join Customers [Cust] on Cust.Id = Party.Id
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
--If we not add this validation if same billto name exist in ph-1 target db then it will thorw the error in insert stmt. 
--Duplicate Billto name validation with target DB
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'BillToExistsInTarget' 
From stgBillTo BillTo
Join BillToes on BillToes.Name = BillTo.Code
	And BillToes.CustomerId = BillTo.R_CustomerId
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
	And BillToes.IsActive = 1
--Setting the Failed status before start updating the target ids.
--Call the SP to create Processing logs for these errors
--exec [dbo].[CreateProcessingLog] @ErrorLogs,@UserId,@CreatedTime
--Update the records as Failed
Update stgBillTo
	Set [IsFailed]=1
From stgBillTo BillTo
Join @ErrorLogs [Errors]
	On [Errors].StagingRootEntityId = BillTo.[Id]
--- Updating the Party Contact Id column based on ContactUniqueIdentifier,R_CustomerId
Update 
	BillTo
Set 
	BillTo.R_PartyContactId = [PartyContact].Id
From
	stgBillTo BillTo
	Join PartyContacts [PartyContact] on [PartyContact].PartyId = BillTo.R_CustomerId
		And [PartyContact].UniqueIdentifier = BillTo.ContactUniqueIdentifier
	Join PartyContactTypes [ContactType] on [ContactType].PartyContactId = [PartyContact].Id
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
	And BillTo.R_CustomerId > 0
	And Len(BillTo.ContactUniqueIdentifier)>0
	And [ContactType].ContactType ='Billing' AND [ContactType].IsActive = 1
--- Updating the Party Address Id column based on AddressUniqueIdentifier,R_CustomerId
Update 
	BillTo
Set 
	BillTo.R_PartyAddressId = [PartyAddress].Id
From
	stgBillTo BillTo
	Join PartyAddresses [PartyAddress] on [PartyAddress].PartyId = BillTo.R_CustomerId
		And [PartyAddress].[UniqueIdentifier] = BillTo.[AddressUniqueIdentifier]
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
	And BillTo.R_CustomerId > 0
--- Updating the Pre-ACH EmailTemplate Id column based on IsPreACHNotification,PreACHNotificationEmailTemplate
Update 
	BillTo 
Set 
	BillTo.R_EmailTemplateId = EmailTemplates.Id
From
	stgBillTo BillTo
	Join EmailTemplates on EmailTemplates.Name = BillTo.[PreACHNotificationEmailTemplateName]
	join EmailTemplateTypes on  EmailTemplateTypes.Id= EmailTemplates.EmailTemplateTypeId
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
	And EmailTemplateTypes.Name = 'ACHPreNotification' 
	And BillTo.IsPreACHNotification = 1
	And BillTo.[PreACHNotificationEmailTemplateName] is not null

--- Updating the Post-ACH EmailTemplate Id column based on IsPostACHNotification,PostACHNotificationEmailTemplate
Update 
	BillTo 
Set 
	BillTo.R_PostACHNotificationEmailTemplateId = EmailTemplates.Id
From
	stgBillTo BillTo
	Join EmailTemplates on EmailTemplates.Name = BillTo.[PostACHNotificationEmailTemplateName]
	join EmailTemplateTypes on  EmailTemplateTypes.Id= EmailTemplates.EmailTemplateTypeId
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
	And EmailTemplateTypes.Name = 'ACHPostNotification' 
	And BillTo.IsPostACHNotification = 1
	And BillTo.[PostACHNotificationEmailTemplateName] is not null

--- Updating the ACH Return EmailTemplate Id column based on IsReturnACHNotification,ReturnACHNotificationEmailTemplate
Update 
	BillTo 
Set 
	BillTo.R_ReturnACHNotificationEmailTemplateId = EmailTemplates.Id
From
	stgBillTo BillTo
	Join EmailTemplates on EmailTemplates.Name = BillTo.[ReturnACHNotificationEmailTemplateName]
	join EmailTemplateTypes on  EmailTemplateTypes.Id= EmailTemplates.EmailTemplateTypeId
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
	And EmailTemplateTypes.Name = 'ACHReturnNotification' 
	And BillTo.IsReturnACHNotification = 1
	And BillTo.[ReturnACHNotificationEmailTemplateName] is not null

--- Updating the LanguageConfig Id column based on LanguageConfigName
Update 
	BillTo
Set 
	BillTo.R_LanguageConfigId = LanguageConfigs.Id
From
	stgBillTo BillTo
	Join LanguageConfigs on LanguageConfigs.Name = BillTo.LanguageConfigName
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
	And BillTo.LanguageConfigName is not null
Update 
	BillTo
Set 
	BillTo.R_LanguageConfigId = LanguageConfigs.Id
From
	stgBillTo BillTo
	Join LanguageConfigs on LanguageConfigs.Name = 'English'
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
	AND BillTo.LanguageConfigName IS NULL
Update 
	BillTo
Set 
	BillTo.[R_StatementInvoiceFormatId]= [IF].Id
FROM 
	stgBillTo BillTo
	Join InvoiceFormats [IF]  on [BillTo].StatementInvoiceFormat = [IF].Name
WHERE 
	[BillTo].IsMigrated = 0
	And BillTo.IsFailed=0 
	And Len(BillTo.[StatementInvoiceFormat]) > 0
	And [IF].isactive=1
	AND BillTo.GenerateStatementInvoice = 1
	And [IF].IsStatementFormat=1
Update
     BillTo
Set
    BillTo.[R_StatementInvoiceEmailTemplateId] = [IF].Id
FROM
    stgBillTo BillTo
	JOIN EmailTemplates [IF] on [BillTo].StatementInvoiceEmailTemplate = [IF].Name
WHERE 
	[BillTo].IsMigrated = 0
	And BillTo.IsFailed=0 
	And [IF].isactive=1
   	AND BillTo.GenerateStatementInvoice = 1
--Updating the [R_InvoiceGroupingParameterId] based on [ReceivableType] ,[ReceivableCategory],[BlendedReceivableCategory]
Update 
	[BIP]
Set 
	[BIP].[R_InvoiceGroupingParameterId]= [IP].Id
FROM 
	[InvoiceGroupingParameters] [IP]
	Join ReceivableTypes [RT] On [RT].Id = [IP].ReceivableTypeId
	Join ReceivableCategories [RC] On [RC].Id = [IP].ReceivableCategoryId
	Join stgBillToInvoiceParameter [BIP] On [BIP].[ReceivableType] = [RT].Name
		And [BIP].[ReceivableCategory] = [RC].Name
	Join stgBillTo BillTo on [BillTo].Id = [BIP].BillToId
WHERE 
	[BillTo].IsMigrated = 0
	And BillTo.IsFailed=0 
	And [IP].isactive=1
	And RC.IsInvoiceGenerate = 1
--Updating the [R_BlendReceivableTypeId]
Update 
	[BIP]
Set 
	[BIP].[R_BlendReceivableTypeId]= [RC].Id
FROM 
	ReceivableTypes [RC] 
	Join stgBillToInvoiceParameter [BIP] On [BIP].[BlendedReceivableType] = [RC].Name
	Join stgBillTo BillTo on [BillTo].Id = [BIP].BillToId
WHERE 
	[BillTo].IsMigrated = 0
	And BillTo.IsFailed=0 
	And Len([BIP].[BlendedReceivableType]) > 0
	And [RC].Isactive=1
--Updating the [R_ReceivableTypeLabelId]
Update 
	[BIP]
Set 
	[BIP].[R_ReceivableTypeLabelId]= [RTL].Id
FROM 
	ReceivableTypeLabelConfigs [RTL] 
	Join stgBillToInvoiceParameter [BIP] On [BIP].[ReceivableTypeLabel] = [RTL].Name
	Join stgBillTo BillTo on [BillTo].Id = [BIP].BillToId
WHERE 
	[BillTo].IsMigrated = 0
	And BillTo.IsFailed=0 
	And Len([BIP].[ReceivableTypeLabel]) > 0
	And [RTL].isactive=1
--Updating the [R_ReceivableTypeLanguageLabelId]
Update 
	[BIP]
Set 
	[BIP].[R_ReceivableTypeLanguageLabelId]= [RTL].Id
FROM 
	ReceivableTypeLanguageLabels [RTL] 
	Join stgBillToInvoiceParameter [BIP] On [BIP].[ReceivableTypeLanguageInvoiceLabel] = [RTL].InvoiceLabel
	Join stgBillTo BillTo on [BillTo].Id = [BIP].BillToId
WHERE 
	[BillTo].IsMigrated = 0
	And BillTo.IsFailed=0 
	And Len([BIP].[ReceivableTypeLanguageInvoiceLabel]) > 0
	And [RTL].isactive=1
--Updating Invoice Format details
Update 
	[BIF]
Set 
	[BIF].[R_InvoiceFormatlId]= [IF].Id
FROM 
	InvoiceFormats [IF] 
	Join stgBillToInvoiceFormat [BIF] On [BIF].[InvoiceFormatName] = [IF].Name --??Join invoice type
	Join stgBillTo BillTo on [BillTo].Id = [BIF].BillToId
WHERE 
	[BillTo].IsMigrated = 0
	And BillTo.IsFailed=0 
	And Len([BIF].[InvoiceFormatName]) > 0
	And [IF].isactive=1
Update 
	[BIF]
Set 
	[BIF].[R_InvoiceTypeLabellId]= [ILC].Id
FROM 
	InvoiceTypeLabelConfigs [ILC]
	JOIN stgBillToInvoiceFormat [BIF] On [BIF].[InvoiceTypeLabel] = [ILC].Name
	JOIN InvoiceTypes [IT] On [ILC].InvoiceTypeId = IT.Id 
	JOIN stgBillTo BillTo on [BillTo].Id = [BIF].BillToId
WHERE 
	[BillTo].IsMigrated = 0
	And BillTo.IsFailed=0 
	And Len([BIF].[InvoiceTypeLabel]) > 0
	And [ILC].IsActive=1
Update 
	BillTo
Set 
	BillTo.R_LocationId = Locations.Id
From
	stgBillTo BillTo
	Join Locations on Locations.Code= BillTo.LocationCode AND Locations.IsActive = 1 AND Locations.CustomerId = R_CustomerId
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
	And BillTo.LocationCode IS NOT NULL
Update 
	stgBillTo 
Set 
   stgBillTo.R_JurisdictionId = Jurisdictions.Id
   ,stgBillTo.R_JurisdictionDetailId = JurisdictionDetails.Id
From  
	Jurisdictions 
	Join States On States.Id = Jurisdictions.StateId 
	Join Countries On Countries.Id = Jurisdictions.CountryId 
	Join Counties On Counties.Id = Jurisdictions.CountyId
	Join Cities On Cities.Id = Jurisdictions.CityId
	Join JurisdictionDetails On JurisdictionDetails.JurisdictionId = Jurisdictions.Id
	Join stgBillTo BillTo ON States.ShortName = BillTo.JurisdictionStateShortName AND Countries.ShortName = BillTo.JurisdictionCountryShortName
	AND States.ShortName = BillTo.JurisdictionStateShortName AND Counties.Name = BillTo.JurisdictionCountyName
Where 
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
	And BillTo.R_JurisdictionId IS NULL AND Jurisdictions.IsActive = 1 AND BillTo.LocationCode IS NOT NULL
	And BillTo.JurisdictionCountryShortName IS NOT NULL AND BillTo.JurisdictionStateShortName IS NOT NULL
	And BillTo.JurisdictionCityName IS NOT NULL AND BillTo.JurisdictionCityName IS NOT NULL 
	And @TaxDataSourceIsVertex != 'True' 
Update 
	BillTo
Set  
   TaxAreaId = Locations.TaxAreaId
  ,UpfrontTaxMode = Locations.UpfrontTaxMode
  ,TaxAreaVerifiedTillDate = Locations.TaxAreaVerifiedTillDate
  ,TaxBasisType = Locations.TaxBasisType
  ,R_JurisdictionId = CASE WHEN R_LocationId IS NOT NULL  THEN Locations.JurisdictionId END
  ,R_JurisdictionDetailId = CASE WHEN R_LocationId IS NOT NULL THEN Locations.JurisdictionDetailId END
From
	stgBillTo BillTo
	JOIN Locations ON Locations.Id = R_LocationId
Where
	BillTo.IsMigrated = 0
	And BillTo.IsFailed=0 
Update 
	[BIF]
Set 
	[BIF].[R_InvoiceEmailTemplateId]= EmailTemplates.Id
FROM 
	stgBillToInvoiceFormat [BIF] 
	Join stgBillTo BillTo on [BillTo].Id = [BIF].BillToId
	Join EmailTemplates On EmailTemplates.Name = [BIF].InvoiceEmailTemplateName
	Join EmailTemplateTypes on EmailTemplates.EmailTemplateTypeId = EmailTemplateTypes.Id AND EmailTemplateTypes.Name = 'Invoice'
WHERE 
	[BillTo].IsMigrated = 0
	And BillTo.IsFailed=0 
	And EmailTemplates.IsActive = 1
-----Validations starts here....
--Customer validation
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'CustomerInvalid' 
from stgBillTo BillTo  
where IsMigrated = 0 
And BillTo.IsFailed=0 
And BillTo.[R_CustomerId] is null
--Contact person invalid
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'ContactPersonInvalid'
from stgBillTo BillTo 
where IsMigrated = 0 
And BillTo.IsFailed=0 
And BillTo.[R_PartyContactId] is null
	And Len(BillTo.[ContactUniqueIdentifier])>0
--Contact Address invalid
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'ContactAddressInvalid'
from stgBillTo BillTo 
where IsMigrated = 0 
And BillTo.IsFailed=0 
And BillTo.[R_PartyAddressId] is null
--Email Template invalid
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'ACHNotificationInvalid'
from stgBillTo BillTo
where IsMigrated = 0 
And BillTo.IsFailed=0 
	And BillTo.[IsPreACHNotification] = 1
	And BillTo.[R_EmailTemplateId] is null

Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'ACHPostNotificationInvalid'
from stgBillTo BillTo
where IsMigrated = 0 
And BillTo.IsFailed=0 
	And BillTo.[IsPostACHNotification] = 1
	And BillTo.[R_PostACHNotificationEmailTemplateId] is null

Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'ACHReturnNotificationInvalid'
from stgBillTo BillTo
where IsMigrated = 0 
And BillTo.IsFailed=0 
	And BillTo.[IsReturnACHNotification] = 1
	And BillTo.[R_ReturnACHNotificationEmailTemplateId] is null
--Language Config invalid
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'LanguageInvalid' 
from stgBillTo BillTo
where IsMigrated = 0 
And BillTo.IsFailed=0 
And BillTo.[R_LanguageConfigId] is null
--Statement Frequency invalid
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'StatementFrequency should be null when GenerateStatementInvoice is false' 
from stgBillTo BillTo  
where IsMigrated = 0 
And BillTo.IsFailed=0 
AND BillTo.GenerateStatementInvoice = 0 AND BillTo.StatementFrequency !='_'
--Statement Invoice Format invalid
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'StatementInvoiceFormatInvalid' 
from stgBillTo BillTo  
where IsMigrated = 0 
And BillTo.IsFailed=0 
And GenerateStatementInvoice = 1
AND R_StatementInvoiceFormatId is null
--Statement Invoice Output Format invalid
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'StatementInvoiceOutputFormatInvalid' 
from stgBillTo BillTo  
where IsMigrated = 0 
And BillTo.IsFailed=0 
And BillTo.GenerateStatementInvoice = 1
AND BillTo.StatementInvoiceOutputFormat is null OR StatementInvoiceOutputFormat='_'
--Generate Summary and Generate Statement Invoice cannot be true
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'Either GenerateStatementInvoice or GenerateSummaryInvoice should to be true' 
from stgBillTo BillTo  
where IsMigrated = 0 
And BillTo.IsFailed=0 
And GenerateStatementInvoice = 1
AND GenerateSummaryInvoice = 1
--Invoice Parameter validation
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select [BillToInvoiceParameter].BillToId,@ModuleIterationStatusId,'InvoiceParam-ReceivabletypeInvalid' 
From
stgBillToInvoiceParameter BillToInvoiceParameter
Join stgBillTo BillTo on BillTo.Id = [BillToInvoiceParameter].BillToId
Where
BillTo.IsMigrated = 0
And BillTo.IsFailed=0 
And Len([ReceivableType])>0
And [BillToInvoiceParameter].[R_InvoiceGroupingParameterId] is null
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select [BillToInvoiceParameter].BillToId,@ModuleIterationStatusId,'InvoiceParam-BlendedReceivableTypeInvalid'
From
stgBillToInvoiceParameter BillToInvoiceParameter
Join stgBillTo BillTo on BillTo.Id = [BillToInvoiceParameter].BillToId
Where
BillTo.IsMigrated = 0
And BillTo.IsFailed=0 
And Len([BlendedReceivableType])>0
And [BillToInvoiceParameter].[R_BlendReceivableTypeId] is null
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select [BillToInvoiceParameter].BillToId,@ModuleIterationStatusId,'InvoiceParam-ReceivabletypelabelInvalid'
From
stgBillToInvoiceParameter BillToInvoiceParameter
Join stgBillTo BillTo on BillTo.Id = [BillToInvoiceParameter].BillToId
Where
BillTo.IsMigrated = 0
And BillTo.IsFailed=0 
And Len([ReceivableTypeLabel])>0
And [BillToInvoiceParameter].[R_ReceivableTypeLabelId] is null
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select [BillToInvoiceParameter].BillToId,@ModuleIterationStatusId,'InvoiceParam-LanguageInvoiceLabelInvalid'
From
stgBillToInvoiceParameter BillToInvoiceParameter
Join stgBillTo BillTo on BillTo.Id = [BillToInvoiceParameter].BillToId
Where
BillTo.IsMigrated = 0
And BillTo.IsFailed=0 
And Len([ReceivableTypeLanguageInvoiceLabel])>0
And [BillToInvoiceParameter].[R_ReceivableTypeLanguageLabelId] is null
--Invoice Format validation
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select [BillToInvoiceFormat].BillToId,@ModuleIterationStatusId,'InvoiceFormat-FormatNameInvalid'
From
stgBillToInvoiceFormat BillToInvoiceFormat
Join stgBillTo BillTo on BillTo.Id = [BillToInvoiceFormat].BillToId
Where
BillTo.IsMigrated = 0
And BillTo.IsFailed=0 
And Len([BillToInvoiceFormat].[InvoiceFormatName])>0
And [BillToInvoiceFormat].[R_InvoiceFormatlId] is null
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select [BillToInvoiceFormat].BillToId,@ModuleIterationStatusId,'InvoiceFormat-TypeLabelInvalid'
From
stgBillToInvoiceFormat BillToInvoiceFormat
Join stgBillTo BillTo on BillTo.Id = [BillToInvoiceFormat].BillToId
Where
BillTo.IsMigrated = 0
And BillTo.IsFailed=0 
And Len([BillToInvoiceFormat].[InvoiceTypeLabel])>0
And  [BillToInvoiceFormat].[R_InvoiceTypeLabellId] is null
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select [BillToInvoiceFormat].BillToId,@ModuleIterationStatusId,'InvoiceFormat-Summary Level Invoice is required'
From
stgBillToInvoiceFormat BillToInvoiceFormat
INNER JOIN stgBillTo BillTo on BillTo.Id = [BillToInvoiceFormat].BillToId
INNER JOIN InvoiceTypeLabelConfigs Config on  Config.Id = [BillToInvoiceFormat].R_InvoiceTypeLabellId
INNER JOIN InvoiceTypes Types on Types.Id =  Config.InvoiceTypeId
WHERE BillTo.GenerateSummaryInvoice = 1 AND (Types.Name = 'Rental' OR Types.Name ='CommercialLoanPaymentNotice')
AND Config.IsDefault = 1 AND Config.IsActive = 1 AND [BillToInvoiceFormat].InvoiceFormatName NOT IN ('SummaryInvoice')
UPDATE #IndividualBillToInvoiceFormat SET InvoiceFormatId = CASE WHEN Format.Id IS NOT NULL THEN Format.Id ELSE NULL END
FROM #IndividualBillToInvoiceFormat 
INNER JOIN stgBillTo BillTo On #IndividualBillToInvoiceFormat.BillToId = [BillTo].Id
INNER JOIN InvoiceTypeLabelConfigs Config on Config.Id =  InvoiceTypeLabelId
INNER JOIN InvoiceTypes Types on Config.InvoiceTypeId = Types.Id AND (Types.Name ='Rental' OR Types.Name ='CommercialLoanPaymentNotice')
LEFT JOIN InvoiceFormats Format on Format.InvoiceTypeId = Types.Id AND Format.ReportName In ('SummaryInvoice')
WHERE [BillTo].GenerateStatementInvoice = 1 AND Format.IsActive = 1 AND Config.IsActive = 1
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select [BillToInvoiceFormat].BillToId,@ModuleIterationStatusId,'InvoiceFormat- No Active Summary Level Invoice Present'
From
#IndividualBillToInvoiceFormat [BillToInvoiceFormat]
WHERE InvoiceFormatId IS NULL
--Invoice Body Dynamic Contents
Update 
	stgBillToInvoiceBodyDynamicContent 
SET 
	 R_InvoiceBodyDynamicContentId = dynamiccontents.Id
FROM 
	stgBillToInvoiceBodyDynamicContent content
	 JOIN stgBillTo BillTo on [BillTo].Id = content.BillToId
	 JOIN InvoiceBodyDynamicContents dynamiccontents ON content.AttributeName = dynamiccontents.AttributeName AND content.EntityName = dynamiccontents.EntityName
WHERE 
	[BillTo].IsMigrated = 0 AND content.R_InvoiceBodyDynamicContentId IS NULL AND BillTo.UseDynamicContentForInvoiceBody = 1
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select content.BillToId,@ModuleIterationStatusId,'InvoiceBody-AttributeAndEntityNameInvalid'
From
stgBillToInvoiceBodyDynamicContent content
JOIN stgBillTo BillTo on BillTo.Id = content.BillToId
WHERE
BillTo.IsMigrated = 0
AND BillTo.UseDynamicContentForInvoiceBody = 1 
AND Content.R_InvoiceBodyDynamicContentId IS NULL
--Invoice Addendum Body Dynamic Contents
Update 
	stgBillToInvoiceAddendumBodyDynamicContent 
SET 
	 R_InvoiceAddendumBodyDynamicContentId = dynamiccontents.Id
FROM 
	stgBillToInvoiceAddendumBodyDynamicContent content
	JOIN stgBillTo BillTo on [BillTo].Id = content.BillToId
	JOIN InvoiceAddendumBodyDynamicContents dynamiccontents ON content.AttributeName = dynamiccontents.AttributeName AND content.EntityName = dynamiccontents.EntityName
WHERE 
	[BillTo].IsMigrated = 0 AND content.R_InvoiceAddendumBodyDynamicContentId IS NULL AND BillTo.GenerateInvoiceAddendum = 1  AND BillTo.UseDynamicContentForInvoiceAddendumBody =1
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select content.BillToId,@ModuleIterationStatusId,'InvoiceAddendumBody-AttributeAndEntityNameInvalid'
From
stgBillToInvoiceAddendumBodyDynamicContent content
JOIN stgBillTo BillTo on BillTo.Id = content.BillToId
WHERE
[BillTo].IsMigrated = 0 AND R_InvoiceAddendumBodyDynamicContentId IS NULL AND 
BillTo.GenerateInvoiceAddendum = 1  AND BillTo.UseDynamicContentForInvoiceAddendumBody =1
--Asset Group By Options
Update 
	stgBillToAssetGroupByOption 
SET 
	 R_AssetGroupByOptionId = options.Id
FROM 
	stgBillToAssetGroupByOption Asset
	JOIN stgBillTo BillTo on [BillTo].Id = Asset.BillToId
	JOIN AssetGroupByOptions options ON Asset.AttributeName = options.AttributeName AND Asset.EntityName = options.EntityName
WHERE 
	[BillTo].IsMigrated = 0 AND Asset.R_AssetGroupByOptionId IS NULL AND BillTo.GenerateInvoiceAddendum = 1  AND BillTo.AssetGroupByOption = 1
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Asset.BillToId,@ModuleIterationStatusId,'AssetGroupByOption-AttributeAndEntityNameInvalid'
From
stgBillToAssetGroupByOption Asset
JOIN stgBillTo BillTo on BillTo.Id = Asset.BillToId
WHERE
BillTo.IsMigrated = 0 AND
BillTo.GenerateInvoiceAddendum = 1  AND BillTo.AssetGroupByOption = 1
AND Asset.R_AssetGroupByOptionId IS NULL
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'AssetGroupByOption- Only one grouping option must be selected'
From
stgBillTo BillTo
WHERE 
BillTo.IsMigrated = 0 AND
BillTo.GenerateInvoiceAddendum = 1  AND BillTo.AssetGroupByOption = 1 AND 
(Select COUNT(*)
From
stgBillToAssetGroupByOption Asset
WHERE Asset.R_AssetGroupByOptionId IS NOT NULL AND Asset.IncludeInInvoice = 1 AND BillTo.Id = Asset.BillToId) > 1
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'AssetGroupByOption- One grouping option must be selected'
From
stgBillTo BillTo
WHERE BillTo.GenerateInvoiceAddendum = 1  AND BillTo.AssetGroupByOption = 1 AND BillTo.IsMigrated = 0 AND NOT EXISTS
(
Select *
From
stgBillToAssetGroupByOption Asset
WHERE Asset.R_AssetGroupByOptionId IS NOT NULL AND Asset.IncludeInInvoice = 1 AND BillTo.Id = Asset.BillToId
)
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'BillTo-UpFrontTaxMode should be none or unknown'
From
stgBillTo BillTo 
WHERE
BillTo.IsMigrated = 0 AND R_LocationId IS NULL AND LocationCode IS NULL AND
(BillTo.TaxBasisType = '_' OR BillTo.TaxBasisType = 'Stream') AND (BillTo.UpfrontTaxMode !='_' OR BillTo.UpfrontTaxMode !='None')
AND @TaxDataSourceIsVertex ! = 'True'
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'BillTo- LocationCode Invalid'
From
stgBillTo BillTo  
WHERE
BillTo.IsMigrated = 0 AND R_LocationId IS NULL AND LocationCode IS NOT NULL
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'BillTo- Jurisdication Details Not Required'
From
stgBillTo BillTo
WHERE
BillTo.IsMigrated = 0 AND BillTo.JurisdictionCountryShortName IS NOT NULL AND R_LocationId IS NOT NULL
AND BillTo.JurisdictionCityName IS NOT NULL AND BillTo.JurisdictionCountryShortName IS NOT NULL
--BillTo StatementInvoiceFormat Conditional mandatory Validation
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'BillTo- StatementInvoiceFormat is Required when GenerateStatementInvoice is true'
From
stgBillTo BillTo
WHERE
BillTo.IsMigrated = 0 AND BillTo.IsFailed=0 AND BillTo.StatementInvoiceFormat IS NULL AND BillTo.GenerateStatementInvoice=1
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'BillTo- Jurisdication Details Invalid'
From
stgBillTo BillTo
WHERE
BillTo.IsMigrated = 0 AND BillTo.R_JurisdictionId IS NULL AND BillTo.JurisdictionCountryShortName IS NOT NULL AND R_LocationId IS NULL
AND BillTo.JurisdictionCityName IS NOT NULL AND BillTo.JurisdictionCountryShortName IS NOT NULL AND @TaxDataSourceIsVertex = 'False'
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'BillToInvoiceFormat - InvoiceEmailTemplateName Invalid' 
from stgBillTo BillTo
Join stgBillToInvoiceFormat BillToInvoiceFormat On BillTo.Id = BillToInvoiceFormat.BillToId
where IsMigrated = 0 
And BillTo.IsFailed=0 
And BillToInvoiceFormat.[R_InvoiceEmailTemplateId] is null And BillToInvoiceFormat.InvoiceEmailTemplateName is not null
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select Id,@ModuleIterationStatusId,'Tax Area Verified Till Date should not be greater than System Date' 
from stgBillTo BillTo
where IsMigrated = 0 
And BillTo.IsFailed=0 
And BillTo.[TaxAreaVerifiedTillDate] >=	CONVERT(date,@CreatedTime)
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'IncludeInInvoice cannot be false for Attributes Amount and InvoiceTotal' 
from stgBillTo BillTo
join stgBillToInvoiceBodyDynamicContent BI on BillTo.Id = BI.BillToId
where IsMigrated = 0 
And BillTo.IsFailed=0 
And ((BI.AttributeName = 'Amount' AND BI.IncludeInInvoice = 0) OR (BI.AttributeName = 'InvoiceTotal' AND BI.IncludeInInvoice = 0))
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'AssetGroupByOption should have the same value as GenerateInvoiceAddendum' 
from stgBillTo BillTo
where IsMigrated = 0 And BillTo.IsFailed=0  AND BillTo.GenerateInvoiceAddendum != BillTo.AssetGroupByOption
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'UseDynamicContentForInvoiceBody cannot be true when GenerateInvoiceAddendum is false' 
from stgBillTo BillTo
where IsMigrated = 0 And BillTo.IsFailed=0  AND BillTo.UseDynamicContentForInvoiceBody = 1 AND GenerateInvoiceAddendum = 0
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
Select BillTo.Id,@ModuleIterationStatusId,'UseLocationAddressForBilling cannot be true when SplitLeaseRentalInvoiceByLocation is false' 
from stgBillTo BillTo
where IsMigrated = 0 And BillTo.IsFailed=0  AND BillTo.UseLocationAddressForBilling = 1 AND SplitLeaseRentalInvoiceByLocation = 0
--Call the SP to create Processing logs for these errors
--exec [dbo].[CreateProcessingLog] @ErrorLogs,@UserId,@CreatedTime
--Update the records as Failed
Update stgBillTo
	Set [IsFailed]=1
From stgBillTo BillTo
Join @ErrorLogs [Errors]
	On [Errors].StagingRootEntityId = BillTo.[Id]
-----Validations ends here....
-- Only one Primary BillTo Start --
UPDATE stgBillTo SET IsPrimary = 0
WHERE Id <> ALL (SELECT MAX(Id) From stgBillTo 
WHERE stgBillTo.IsMigrated = 0 AND stgBillTo.IsFailed = 0 AND stgBillTo.IsPrimary = 1
GROUP BY R_CustomerId)
-- Only one Primary BillTo End --
--Bulk copy to Target tables from Intermediate Table
MERGE BillToes As BillTo
USING(SELECT * FROM stgBillTo BillTo Where BillTo.IsMigrated = 0 And BillTo.[IsFailed]=0) As BillToesToMigrate
ON 1 = 0
WHEN NOT MATCHED 
THEN
INSERT(
		Name
		,CustomerBillToName
		,InvoiceComment
		,IsPrimary
		,GenerateSummaryInvoice
		,UseLocationAddressForBilling
		,SplitRentalInvoiceByAsset
		,SplitCreditsByOriginalInvoice
		,SplitByReceivableAdjustments
		,SplitRentalInvoiceByContract
		,SplitLeaseRentalInvoiceByLocation
		,SplitReceivableDueDate
		,SplitCustomerPurchaseOrderNumber
		,DeliverInvoiceViaEmail
		,DeliverInvoiceViaMail
		,SendEmailNotificationTo
		,SendCCEmailNotificationTo
		,SendBccEmailNotificationTo
		,IsActive
		,InvoiceNumberLabel
		,InvoiceDateLabel
		,InvoiceCommentBeginDate
		,InvoiceCommentEndDate
		,UseDynamicContentForInvoiceBody
		,GenerateInvoiceAddendum
		,UseDynamicContentForInvoiceAddendumBody
		,AssetGroupByOption
		,IsPreACHNotification
		,PreACHNotificationEmailTo
		,IsPostACHNotification
		,PostACHNotificationEmailTo
		,IsReturnACHNotification
		,ReturnACHNotificationEmailTo
		,CreatedById
		,CreatedTime
		,CustomerId
		,BillingContactPersonId
		,BillingAddressId
		,PreACHNotificationEmailTemplateId
		,PostACHNotificationEmailTemplateId
		,ReturnACHNotificationEmailTemplateId
		,LanguageConfigId
		,GenerateStatementInvoice
		,TaxBasisType
		,UpfrontTaxMode
		,JurisdictionId
		,LocationId
		,JurisdictionDetailId
		,TaxAreaId
		,TaxAreaVerifiedTillDate
		,BillToName
		,StatementFrequency
		,StatementDueDay
		,StatementInvoiceFormatId
		,StatementInvoiceEmailTemplateId
		,StatementInvoiceOutputFormat)
VALUES
( 
	[Code]
	,[CustomerBillToName]
	,[InvoiceComment]
	,[IsPrimary]
	,[GenerateSummaryInvoice]
	,[UseLocationAddressForBilling]
	,[SplitRentalInvoiceByAsset]
	,[SplitCreditsByOriginalInvoice]
	,[SplitByReceivableAdjustments]
	,[SplitRentalInvoiceByContract]
	,[SplitLeaseRentalinvoiceByLocation]
	,[SplitReceivableDueDate]
	,[SplitCustomerPurchaseOrderNumber]
	,[DeliverInvoiceViaEmail]
	,[DeliverInvoiceViaMail]
	,[SendEmailNotificationTo]
	,[SendCCEmailNotificationTo]
	,[SendBccEmailNotificationTo]
	, 1
	,[InvoiceNumberLabel]
	,[InvoiceDateLabel]
	,[InvoiceCommentBeginDate]
	,[InvoiceCommentEndDate]
	,[UseDynamicContentForInvoiceBody]
	,[GenerateInvoiceAddendum]
	,[UseDynamicContentForInvoiceAddendumBody]
	,[AssetGroupByOption]
	,[IsPreACHNotification]
	,[PreACHNotificationEmailTo]
	,[IsPostACHNotification]
	,[PostACHNotificationEmailTo]
	,[IsReturnACHNotification]
	,[ReturnACHNotificationEmailTo]
	,@UserId
	,@CreatedTime
	,[R_CustomerId]
	,[R_PartyContactId]
	,[R_PartyAddressId]
	,[R_EmailTemplateId]
	,[R_PostACHNotificationEmailTemplateId]
	,[R_ReturnACHNotificationEmailTemplateId]
	,[R_LanguageConfigId]
	,GenerateStatementInvoice
	,TaxBasisType
	,UpfrontTaxMode
	,R_JurisdictionId
	,R_LocationId
	,R_JurisdictionDetailId
	,TaxAreaId
	,TaxAreaVerifiedTillDate
	,BillToName
	,StatementFrequency
	,StatementDueDay
	,R_StatementInvoiceFormatId
	,R_StatementInvoiceEmailTemplateId
	,StatementInvoiceOutputFormat
)
OUTPUT $ACTION, INSERTED.Id,BillToesToMigrate.Id  INTO #CreatedBillToes;
	Insert into [BillToInvoiceParameters]
	(
		IsActive
		,CreatedById
		,CreatedTime
		,InvoiceGroupingParameterId
		,BlendWithReceivableTypeId
		,ReceivableTypeLabelId
		,BillToId
		,ReceivableTypeLanguageLabelId
		,AllowBlending
	)
	Select
		1 [IsActive]
		,@UserId
		,@CreatedTime
		,[InvoiceGroupingParameterId]
		,BlendedReceivableTypeId
		,[ReceivableTypeLabelId]
		,cbt.Id
		,[ReceivableTypeLanguageLabelId]
		,[AllowBlending]
	From
		#BillToInvoiceParameter
		CROSS JOIN #CreatedBillToes cbt		
		INSERT INTO [BillToInvoiceFormats]
		(
			ReceivableCategory
			,InvoiceOutputFormat
			,IsActive
			,CreatedById
			,CreatedTime
			,InvoiceFormatId
			,InvoiceTypeLabelId
			,BillToId
			,InvoiceEmailTemplateId
			,ReceivableCategoryId
		)
		SELECT 
			ReceivableCategoryname
			,InvoiceOutput
			,1 [Active]
			,@UserId
			,@CreatedTime
			,InvoiceFormatId
			,InvoiceTypeLabelId
			,cbt.Id
			,InvoiceEmailTemplateId
			,ReceivableCategoryId
		From		
		#IndividualBillToInvoiceFormat
		INNER JOIN #CreatedBillToes cbt on cbt.BillToId = #IndividualBillToInvoiceFormat.BillToId
		;

	Update BillToInvoiceFormats Set InvoiceFormatId = R_InvoiceFormatlId, InvoiceTypeLabelId = R_InvoiceTypeLabellId,  InvoiceOutputFormat = pbif.InvoiceOutputFormat, InvoiceEmailTemplateId = pbif.R_InvoiceEmailTemplateId
	FROM BillToInvoiceFormats bif
	INNER JOIN #CreatedBillToes ON #CreatedBillToes.Id=bif.BillToId
	INNER JOIN stgBillToInvoiceFormat pbif On pbif.BillToId = #CreatedBillToes.BillToId
		AND pbif.ReceivableCategory=bif.ReceivableCategory

	Update BillToInvoiceParameters Set ReceivableTypeLanguageLabelId = R_ReceivableTypeLanguageLabelId
	FROM BillToInvoiceParameters bip
	INNER JOIN #CreatedBillToes ON #CreatedBillToes.Id=bip.BillToId
	INNER JOIN stgBillToInvoiceParameter pbip On pbip.BillToId = #CreatedBillToes.BillToId 
		AND bip.InvoiceGroupingParameterId = pbip.R_InvoiceGroupingParameterId 

	Update BillToInvoiceParameters 
		Set AllowBlending = SBIP.AllowBlending
	FROM BillToInvoiceParameters BIP
	INNER JOIN #CreatedBillToes CB ON CB.Id= BIP.BillToId
	INNER JOIN stgBillToInvoiceParameter SBIP On SBIP.BillToId = CB.BillToId 
		AND BIP.InvoiceGroupingParameterId = SBIP.R_InvoiceGroupingParameterId 
	WHERE SBIP.AllowBlending IS NOT NULL AND SBIP.AllowBlending <> ''
	;

	Update BillToInvoiceParameters 
		Set BlendWithReceivableTypeId = SBIP.R_BlendReceivableTypeId
	FROM BillToInvoiceParameters BIP
	INNER JOIN #CreatedBillToes CB ON CB.Id= BIP.BillToId
	INNER JOIN stgBillToInvoiceParameter SBIP On SBIP.BillToId = CB.BillToId 
		AND BIP.InvoiceGroupingParameterId = SBIP.R_InvoiceGroupingParameterId 
	WHERE SBIP.AllowBlending IS NOT NULL AND SBIP.AllowBlending <> ''
	;

------Insert invoice parameter
----Insert into [BillToInvoiceParameters](
----	IsActive
----	,CreatedById
----	,CreatedTime
----	,InvoiceGroupingParameterId
----	,BlendReceivableCategoryId
----	,ReceivableTypeLabelId
----	,BillToId
----	,ReceivableTypeLanguageLabelId
----	)
----Select
----	1 [IsActive]
----	,@UserId
----	,@CreatedTime
----	,[R_InvoiceGroupingParameterId]
----	,[R_BlendReceivableCategoryId]
----	,[R_ReceivableTypeLabelId]
----	,[TargetBillTo].Id [BillToId]
----	,[R_ReceivableTypeLanguageLabelId]
----From
----	stgBillToInvoiceParameter [BIP]
----	Join stgBillTo On [BillTo].Id = [BIP].[BillToId]
----	Join BillToes [TargetBillTo] 
----		on [TargetBillTo].CustomerId = [BillTo].R_CustomerId
----		And [TargetBillTo].Name = [BillTo].[Code]
----Where 
----	[BillTo].IsMigrated = 0 
----	And [BillTo].[IsFailed]=0
------Insert invoice format
----Insert into [BillToInvoiceFormats](
----ReceivableCategory
----,InvoiceOutputFormat
----,IsActive
----,CreatedById
----,CreatedTime
----,InvoiceFormatId
----,InvoiceTypeLabelId
----,BillToId
----,InvoiceEmailTemplateId
----)
----Select 
----	[ReceivableCategory]
----	,[InvoiceOutputFormat]
----	,1 [Active]
----	,@UserId
----	,@CreatedTime
----	,[R_InvoiceFormatlId]
----	,[R_InvoiceTypeLabellId]
----	,[TargetBillTo].Id [BillToId]
----	,NULL [EmailTemplateId]
----From
----	stgBillToInvoiceFormat [BIF]
----	Join stgBillTo On [BillTo].Id = [BIF].[BillToId]
----	Join BillToes [TargetBillTo] 
----		on [TargetBillTo].CustomerId = [BillTo].R_CustomerId
----		And [TargetBillTo].Name = [BillTo].[Code]
----Where 
----	[BillTo].IsMigrated = 0 
----	And [BillTo].[IsFailed]=0
	DECLARE @LocationCode INT;
	SET @LocationCode  = CONVERT(INT, (SELECT current_value FROM sys.sequences WHERE NAME = 'Location'))
	MERGE TaxExemptRules As TaxExemptRule
	USING(SELECT #CreatedBillToes.Id FROM #CreatedBillToes
		  INNER JOIN stgBillTo BillTo ON #CreatedBillToes.BillToId = BillTo.Id
		  INNER JOIN PartyAddresses ON BillTo.R_PartyAddressId = PartyAddresses.Id
		  WHERE (R_LocationId IS NULL) AND (R_JurisdictionId IS NOT NULL OR BillTo.TaxAreaId IS NOT NULL))As BillToesToMigrate
	ON 1 = 0
	WHEN NOT MATCHED 
	THEN
	INSERT(
		  EntityType
		 ,IsCountryTaxExempt
		 ,IsStateTaxExempt
		 ,CreatedById
		 ,CreatedTime
		 ,IsCityTaxExempt
		 ,IsCountyTaxExempt
		 )
	VALUES
		 (
		 'Location'
		 ,0
		 ,0
		 ,@userId
		 ,@CreatedTime
		 ,0
		 ,0
	)
	OUTPUT $ACTION, INSERTED.Id,BillToesToMigrate.Id,NULL  INTO #createdTaxExemptRuleId;
	UPDATE #createdTaxExemptRuleId SET Code = @LocationCode,@LocationCode = @LocationCode + 1 
	Merge Locations As Location
	USING(SELECT RuleId.Code As Code, RuleId.Id AS RuleId, #CreatedBillToes.Id As BillToId, BillTo.TaxAreaVerifiedTillDate, BillTo.TaxAreaId BillToTaxAreaId,
		  BillTo.R_JurisdictionId, BillTo.R_JurisdictionDetailId, BillTo.TaxBasisType, BillTo.R_CustomerId, BillTo.R_PartyContactId, BillTo.UpfrontTaxMode, Parties.PortfolioId, PartyAddresses.* FROM #CreatedBillToes
		  INNER JOIN stgBillTo BillTo ON #CreatedBillToes.BillToId = BillTo.Id
		  INNER JOIN Parties ON BillTo.R_CustomerId = Parties.Id
		  INNER JOIN PartyAddresses ON BillTo.R_PartyAddressId = PartyAddresses.Id
		  INNER JOIN #createdTaxExemptRuleId RuleId ON #CreatedBillToes.Id = RuleId.BillToId 
		  WHERE (R_LocationId IS NULL) AND (R_JurisdictionId IS NOT NULL OR (BillTo.TaxAreaId IS NOT NULL AND BillTo.TaxAreaId > 0))) AS BillToesToMigrate
	ON 1 = 0
	WHEN NOT MATCHED 
	THEN 
	INSERT(
		   Code
	 	   ,CustomerId
		   ,AddressLine1
		   ,AddressLine2
		   ,Division
		   ,City
		   ,StateId
		   ,PostalCode
		   ,IsActive
		   ,ContactPersonId
		   ,TaxAreaVerifiedTillDate
		   ,TaxAreaId
		   ,JurisdictionId
		   ,JurisdictionDetailId
		   ,TaxBasisType
		   ,UpfrontTaxMode
		   ,ApprovalStatus
		   ,IncludedPostalCodeInLocationLookup
		   ,AddressLine3
		   ,Neighborhood
		   ,SubdivisionOrMunicipality
		   ,CreatedById
		   ,CreatedTime
		   ,TaxExemptRuleId
		   ,PortfolioId
		   ,CountryTaxExemptionRate
		   ,StateTaxExemptionRate
		   ,DivisionTaxExemptionRate
		   ,CityTaxExemptionRate)
	VALUES(
		   Code
		   ,R_CustomerId
		   ,AddressLine1
		   ,AddressLine2
		   ,Division
		   ,City
		   ,StateId
		   ,PostalCode
		   ,1
		   ,R_PartyContactId		
		   ,TaxAreaVerifiedTillDate
		   ,BillToTaxAreaId
		   ,R_JurisdictionId
		   ,R_JurisdictionDetailId
		   ,TaxBasisType
		   ,UpfrontTaxMode
		   ,'Approved'
		   ,0
		   ,AddressLine3
		   ,Neighborhood
		   ,SubdivisionOrMunicipality
		   ,@UserId
		   ,@CreatedTime
		   ,RuleId
		   ,PortfolioId
		   ,CAST(0.00 AS Decimal(10, 6))
		   ,CAST(0.00 AS Decimal(10, 6))
		   ,CAST(0.00 AS Decimal(10, 6))
		   ,CAST(0.00 AS Decimal(10, 6)))
		OUTPUT INSERTED.Id,BillToesToMigrate.BillToId  INTO #createdLocationId;
	UPDATE BillToes SET LocationId = #createdLocationId.LocationId 
	FROM BillToes 
	INNER JOIN #createdLocationId ON BillToes.Id = #createdLocationId.BillToId
	SET @SQL = 'ALTER SEQUENCE Location RESTART WITH ' + CONVERT(NVARCHAR(20),@LocationCode+1)
	EXEC sp_executesql @sql
	--Insert  BillToInvoiceBodyDynamicContents
	INSERT INTO [dbo].[BillToInvoiceBodyDynamicContents]
           ([IncludeInInvoice]
           ,[IsActive]
           ,[CreatedById]
           ,[CreatedTime]
           ,[InvoiceBodyDynamicContentId]
           ,[BillToId])
	SELECT 
		    CASE WHEN (IBDC.AttributeName = 'Amount' OR IBDC.AttributeName = 'InvoiceTotal') THEN 1 ELSE 0 END
           ,1
           ,@UserId
           ,@CreatedTime
           ,IBDC.Id
           ,CBT.Id
	FROM InvoiceBodyDynamicContents IBDC
	CROSS JOIN #CreatedBillToes CBT
	JOIN stgBillTo BillTo ON BillTo.Id = CBT.BillToId 
	WHERE BillTo.UseDynamicContentForInvoiceBody = 1 AND IBDC.IsActive = 1
	UPDATE BillToInvoiceBodyDynamicContents SET IncludeInInvoice=SBI.IncludeInInvoice
	FROM BillToInvoiceBodyDynamicContents TBI
	INNER JOIN #CreatedBillToes CBT ON TBI.BillToId = CBT.Id 
	INNER JOIN StgBillTo BillTo ON BillTo.Id = CBT.BillToId 
	INNER JOIN stgBillToInvoiceBodyDynamicContent SBI ON SBI.BillToId = CBT.BillToId 
	AND SBI.R_InvoiceBodyDynamicContentId = TBI.InvoiceBodyDynamicContentId
	WHERE BillTo.UseDynamicContentForInvoiceBody = 1
	--insert BillToInvoiceAddendumBodyDynamicContents
	INSERT INTO [dbo].[BillToInvoiceAddendumBodyDynamicContents]
           ([IncludeInInvoice]
           ,[IsActive]
           ,[CreatedById]
           ,[CreatedTime]
           ,[InvoiceAddendumBodyDynamicContentId]
           ,[BillToId])
	SELECT
           0
           ,1
           ,@UserId
           ,@CreatedTime
           ,IADBDC.Id
           ,CBT.Id
		   FROM 
		   InvoiceAddendumBodyDynamicContents IADBDC
		   CROSS JOIN #CreatedBillToes CBT
		   JOIN stgBillTo BillTo ON  BillTo.Id = CBT.BillToId 
	       WHERE BillTo.GenerateInvoiceAddendum = 1  AND BillTo.UseDynamicContentForInvoiceAddendumBody = 1 AND IADBDC.IsActive = 1
		UPDATE BillToInvoiceAddendumBodyDynamicContents SET IncludeInInvoice=SABI.IncludeInInvoice
		FROM BillToInvoiceAddendumBodyDynamicContents TABI
		INNER JOIN #CreatedBillToes CBT ON TABI.BillToId = CBT.Id 
		INNER JOIN StgBillTo BillTo ON BillTo.Id = CBT.BillToId 
		INNER JOIN stgBillToInvoiceAddendumBodyDynamicContent SABI ON SABI.BillToId = CBT.BillToId  AND SABI.R_InvoiceAddendumBodyDynamicContentId = TABI.InvoiceAddendumBodyDynamicContentId
		WHERE BillTo.GenerateInvoiceAddendum = 1  AND BillTo.UseDynamicContentForInvoiceAddendumBody = 1
	--insert BillToAssetGroupByOptions
		INSERT INTO [dbo].[BillToAssetGroupByOptions]
           ([IncludeInInvoice]
           ,[IsActive]
           ,[CreatedById]
           ,[CreatedTime]
           ,[AssetGroupByOptionId]
           ,[BillToId])
		   SELECT 
		    0
           ,1
           ,@UserId
           ,@CreatedTime
           ,AGBO.Id
           ,CBT.Id	
		    FROM
			AssetGroupByOptions AGBO
		   CROSS JOIN #CreatedBillToes CBT
		   JOIN stgBillTo BillTo ON  BillTo.Id = CBT.BillToId 
	       WHERE BillTo.GenerateInvoiceAddendum = 1  AND BillTo.AssetGroupByOption = 1 AND IsActive = 1 
		UPDATE BillToAssetGroupByOptions SET IncludeInInvoice=SAGO.IncludeInInvoice
		FROM BillToAssetGroupByOptions TAGO
		INNER JOIN #CreatedBillToes CBT ON TAGO.BillToId = CBT.Id 
		INNER JOIN StgBillTo BillTo ON BillTo.Id = CBT.BillToId 
		INNER JOIN stgBillToAssetGroupByOption SAGO ON SAGO.BillToId = CBT.BillToId AND SAGO.R_AssetGroupByOptionId = TAGO.AssetGroupByOptionId
		WHERE BillTo.GenerateInvoiceAddendum = 1  AND BillTo.AssetGroupByOption = 1
		--set other primary to zero
		UPDATE BillToes SET IsPrimary = 0 
		FROM BillToes TargetBillTo 	
		JOIN stgBillTo BillTo ON TargetBillTo.CustomerId = BillTo.R_CustomerId
		WHERE BillTo.IsPrimary = 1 AND TargetBillTo.IsPrimary = 1 AND TargetBillTo.Name ! = BillTo.Code	AND BillTo.IsMigrated=0 AND IsFailed=0
		DROP TABLE #CreatedBillToes;
		DROP TABLE #BillToInvoiceParameter;
		DROP TABLE #BillToInvoiceFormat;
		DROP TABLE #createdTaxExemptRuleId;
		DROP TABLE #IndividualBillToInvoiceFormat;
		DROP TABLE #createdLocationId;
--Success Log Message
Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message,Type)
Select 
	[BillTo].Id,@ModuleIterationStatusId,'Success','Information'
From
stgBillTo BillTo 
	Join BillToes [TargetBillTo] 
		on [TargetBillTo].CustomerId = [BillTo].R_CustomerId
		And [TargetBillTo].Name = [BillTo].[Code]
Where
	[BillTo].IsMigrated = 0 
	And [BillTo].[IsFailed]=0
	--Call the SP to create Processing logs for these errors
exec [dbo].[CreateProcessingLog] @ErrorLogs,@UserId,@CreatedTime
--Updating the records as Migrated=True
Update [BillTo]
	Set [BillTo].IsMigrated = 1
From
stgBillTo BillTo
	Join BillToes [TargetBillTo] 
		on [TargetBillTo].CustomerId = [BillTo].R_CustomerId
		And [TargetBillTo].Name = [BillTo].[Code]
Where
	[BillTo].IsMigrated = 0 
	And [BillTo].[IsFailed]=0
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLog ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateBillToes'
	Insert into @ErrorLog(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLog,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		set @FailedRecords = @FailedRecords+@ProcessedRecords;
	END;  
	IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END;  
END CATCH
Set @FailedRecords = @FailedRecords+(SELECT Count(Distinct StagingRootEntityId) From @Errorlogs where Type = 'Error')
SET XACT_ABORT OFF
SET NOCOUNT OFF
END

GO

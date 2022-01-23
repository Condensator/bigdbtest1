SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DocumentStatusExceptionReasonsReport]
(
@EntityType NVARCHAR(100) = NULL,
@EntityId NVARCHAR(40) = NULL,
@StatusAsofDateFrom DATETIMEOFFSET = NULL,
@StatusAsofDateTo DATETIMEOFFSET = NULL,
@Status NVARCHAR(250) =NULL,
@StatusChangedBy NVARCHAR(250)  = NULL,
@docType NVARCHAR(100) = NULL,
@CUSNAME NVARCHAR(250) = NULL,
@SEQNUM NVARCHAR(40) = NULL,
@ORIGINATIONSOURCE NVARCHAR(250) = NULL,
@LOBs NVARCHAR(40) = NULL,
@Exception BIT = NULL,
@StatusLastChangedBy NVARCHAR(250)  = NULL,
@SiteId NVARCHAR(40) = NULL,
@AccessibleLegalEntityIds NVARCHAR(Max) = NULL
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON
DECLARE @COMMONSQL NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @RelatedEntitySQL NVARCHAR(MAX)
SET @SQL = ''
CREATE TABLE #Temp(Id BIGINT IDENTITY(1,1),EntityId BIGINT,EntityTypeId BIGINT,UserFriendlyName NVARCHAR(100),status NVARCHAR(250),StatusAsOfDate NVARCHAR(50),StatusChangedBy NVARCHAR(250),StatusComment NVARCHAR(MAX),DocumentInstanceId BIGINT,EntityType NVARCHAR(100),DocName NVARCHAR(100),ExceptionReason NVARCHAR(MAX),StatusLastChangedBy NVARCHAR(250),EntityNaturalId NVARCHAR(250));
DECLARE @DocumentDetails NVARCHAR(MAX)
SELECT * INTO #AccessibleLegalEntities FROM ConvertCSVToBigIntTable(@AccessibleLegalEntityIds, ',')
SET @DocumentDetails = 'SELECT DISTINCT
DocumentInstances.EntityId
,DocumentTypes.EntityId as ''EntityTypeId''
,EntityConfigs.UserFriendlyName
,DocumentStatusSubSystemConfigs.Status
,DocumentStatusHistories.AsOfDate
,Users.FullName as ''StatusChangedBy''
,ISNULL(DocumentStatusHistories.Comment,'''') as ''StatusComment''
,DocumentInstances.Id as ''DocumentInstanceId''
,EntityConfigs.Name as ''EntityType''
,DocumentTypes.Name as ''DocName''
,DocumentInstances.ExceptionComment AS ''ExceptionReason''
,STATUSLASTCHANGEDBYUSER AS ''StatusLastChangedBy''
,DocumentInstances.EntityNaturalId
FROM DocumentStatusHistories
JOIN DocumentInstances as DocumentInstances ON DocumentStatusHistories.DocumentInstanceId = DocumentInstances.Id
JOIN DocumentTypes ON DocumentInstances.DocumentTypeId = DocumentTypes.Id
JOIN DocumentEntityConfigs ON DocumentTypes.EntityId = DocumentEntityConfigs.Id
JOIN EntityConfigs on DocumentEntityConfigs.Id=EntityConfigs.Id
JOIN DocumentStatusConfigs  ON DocumentStatusHistories.StatusId = DocumentStatusConfigs.Id
JOIN DocumentStatusSubSystemConfigs ON DocumentStatusSubSystemConfigs.DocumentStatusConfigId = DocumentStatusConfigs.Id
AND DocumentStatusSubSystemConfigs.SubsystemId = ''CURRENTSITEID''
JOIN Users  ON DocumentStatusHistories.StatusChangedById = Users.Id
LASTUPDATEDUSERCONDITION
WHERE DocumentInstances.IsActive = 1 AND DocumentTypes.IsActive = 1 AND DocumentStatusSubSystemConfigs.IsActive = 1 AND DocumentStatusConfigs.IsActive =1
AND AsOfDate  BETWEEN ''FROMDATE''  AND ''TODATE'''
SET @DocumentDetails = REPLACE(@DocumentDetails,'''CURRENTSITEID''',@SiteId)
SET @DocumentDetails = REPLACE(@DocumentDetails,'LASTUPDATEDUSERCONDITION',' JOIN (SELECT MaxId,DocumentStatusHistories.StatusChangedById AS LastChangedUserId ,TempInstanceId FROM
(SELECT MAX(Id) AS MaxId ,DocumentStatusHistories.DocumentInstanceId As TempInstanceId FROM DocumentStatusHistories
GROUP BY DocumentStatusHistories.DocumentInstanceId) AS TempDocumentHistories
JOIN DocumentStatusHistories on TempDocumentHistories.MaxId = DocumentStatusHistories.Id) AS LastUpdatedDocumentHistories
ON DocumentStatusHistories.Id = LastUpdatedDocumentHistories.MaxId
JOIN Users AS LastUpdatedUser ON LastUpdatedUser.Id = LastUpdatedDocumentHistories.LastChangedUserId')
SET @DocumentDetails = REPLACE(@DocumentDetails,'STATUSLASTCHANGEDBYUSER','LastUpdatedUser.FullName')
SET @DocumentDetails = REPLACE(@DocumentDetails,'FROMDATE',@StatusAsofDateFrom)
SET @DocumentDetails = REPLACE(@DocumentDetails,'TODATE',@StatusAsofDateTo)
IF(@Status IS NOT NULL)
BEGIN
SET @DocumentDetails = @DocumentDetails + '
AND  DocumentStatusSubSystemConfigs.Status = ''STATUSCONDITION'''
SET @DocumentDetails = REPLACE(@DocumentDetails,'STATUSCONDITION',@Status)
END
IF(@StatusChangedBy IS NOT NULL)
BEGIN
SET @DocumentDetails = @DocumentDetails + '
AND  Users.FullName = ''STATUSCHANGEDBYCONDITION'''
SET @DocumentDetails = REPLACE(@DocumentDetails,'STATUSCHANGEDBYCONDITION',@StatusChangedBy)
END
IF(@docType IS NOT NULL)
BEGIN
SET @DocumentDetails = @DocumentDetails + '
AND  DocumentTypes.Name = ''DOCTYPECONDITION'''
SET @DocumentDetails = REPLACE(@DocumentDetails,'DOCTYPECONDITION',@docType)
END
IF(@EntityType IS NOT NULL)
BEGIN
SET @DocumentDetails = @DocumentDetails + '
AND  EntityConfigs.Name = ''ENTITYTYPECONDITION'''
SET @DocumentDetails = REPLACE(@DocumentDetails,'ENTITYTYPECONDITION',@EntityType)
END
IF(@EntityId IS NOT NULL)
BEGIN
SET @DocumentDetails = @DocumentDetails + '
AND  DocumentInstances.EntityId = ''ENTITYIDCONDITION'''
SET @DocumentDetails = REPLACE(@DocumentDetails,'ENTITYIDCONDITION',@EntityId)
END
IF(@Exception IS NOT NULL)
BEGIN
SET @DocumentDetails = @DocumentDetails + '
AND  DocumentStatusConfigs.IsException = ''EXCEPTIONCONDITION'''
SET @DocumentDetails = REPLACE(@DocumentDetails,'EXCEPTIONCONDITION',@Exception)
END
IF(@StatusLastChangedBy IS NOT NULL)
BEGIN
SET @DocumentDetails = @DocumentDetails + '
AND  LastUpdatedUser.Fullname  = ''STATUSLASTCHANGEDBYCONDITION'''
SET @DocumentDetails = REPLACE(@DocumentDetails,'STATUSLASTCHANGEDBYCONDITION',@StatusLastChangedBy)
END
INSERT INTO #Temp (EntityId,EntityTypeId,UserFriendlyName,status,StatusAsOfDate,StatusChangedBy,StatusComment,DocumentInstanceId,EntityType,DocName,ExceptionReason,StatusLastChangedBy,EntityNaturalId)
EXEC SP_EXECUTESQL @DocumentDetails
SET @RelatedEntitySQL = 'SELECT DISTINCT
DocumentTypes.Name as ''Document Type''
,EntityConfigs.UserFriendlyName AS ''EntityType''
, DocumentInstances.EntityId AS ''EntityId''
,''CUSTOMERNAME'' AS ''Customer Name''
,''SEQUENCENUMBER''  AS ''Sequence Number''
,DocumentStatusSubSystemConfigs.Status  AS ''DOC Status''
,''ORIGINATIONSOURCE'' AS ''Origination Source''
,''LINEOFBUSINESS'' AS ''Line of Business''
,DocumentStatusHistories.AsOfDate
,Users.FullName AS ''ChangedBy''
,ISNULL(DocumentStatusHistories.Comment,'''') AS ''StatusComment''
,DocumentInstances.ExceptionComment AS ''ExceptionReason''
,STATUSLASTCHANGEDBYUSER AS ''StatusLastChangedBy''
,DocumentInstances.EntityNaturalId
FROM DocumentStatusHistories
JOIN DocumentInstances as DocumentInstances ON DocumentStatusHistories.DocumentInstanceId = DocumentInstances.Id
JOIN DocumentTypes ON DocumentInstances.DocumentTypeId = DocumentTypes.Id
JOIN DocumentEntityConfigs ON DocumentTypes.EntityId = DocumentEntityConfigs.Id
JOIN EntityConfigs on DocumentEntityConfigs.Id=EntityConfigs.Id
JOIN DocumentStatusConfigs  ON DocumentStatusHistories.StatusId = DocumentStatusConfigs.Id
JOIN DocumentStatusSubSystemConfigs ON DocumentStatusSubSystemConfigs.DocumentStatusConfigId = DocumentStatusConfigs.Id
AND DocumentStatusSubSystemConfigs.SubsystemId = ''CURRENTSITEID''
JOIN Users  ON DocumentStatusHistories.StatusChangedById = Users.Id
LASTUPDATEDUSERCONDITION
ENTITYJOINCONDITION
AND DocumentInstances.IsActive = 1 AND DocumentTypes.IsActive = 1 AND DocumentStatusSubSystemConfigs.IsActive = 1 AND DocumentStatusConfigs.IsActive =1
AND AsOfDate  BETWEEN ''FROMDATE''  AND ''TODATE'''
SET @RelatedEntitySQL = REPLACE(@RelatedEntitySQL,'''CURRENTSITEID''',@SiteId)
SET @RelatedEntitySQL = REPLACE(@RelatedEntitySQL,'LASTUPDATEDUSERCONDITION',' JOIN (SELECT MaxId,DocumentStatusHistories.StatusChangedById AS LastChangedUserId ,TempInstanceId FROM
(SELECT MAX(Id) AS MaxId ,DocumentStatusHistories.DocumentInstanceId As TempInstanceId FROM DocumentStatusHistories
GROUP BY DocumentStatusHistories.DocumentInstanceId) AS TempDocumentHistories
JOIN DocumentStatusHistories on TempDocumentHistories.MaxId = DocumentStatusHistories.Id) AS LastUpdatedDocumentHistories
ON DocumentStatusHistories.Id = LastUpdatedDocumentHistories.MaxId
JOIN Users AS LastUpdatedUser ON LastUpdatedUser.Id = LastUpdatedDocumentHistories.LastChangedUserId')
SET @RelatedEntitySQL = REPLACE(@RelatedEntitySQL,'STATUSLASTCHANGEDBYUSER','LastUpdatedUser.FullName')
SET @RelatedEntitySQL = REPLACE(@RelatedEntitySQL,'FROMDATE',@StatusAsofDateFrom)
SET @RelatedEntitySQL = REPLACE(@RelatedEntitySQL,'TODATE',@StatusAsofDateTo)
IF(@Status IS NOT NULL)
BEGIN
SET @RelatedEntitySQL = @RelatedEntitySQL + '
AND  DocumentStatusSubSystemConfigs.Status = ''STATUSCONDITION'''
SET @RelatedEntitySQL = REPLACE(@RelatedEntitySQL,'STATUSCONDITION',@Status)
END
IF(@StatusChangedBy IS NOT NULL)
BEGIN
SET @RelatedEntitySQL = @RelatedEntitySQL + '
AND  Users.FullName = ''STATUSCHANGEDBYCONDITION'''
SET @RelatedEntitySQL = REPLACE(@RelatedEntitySQL,'STATUSCHANGEDBYCONDITION',@StatusChangedBy)
END
IF(@docType IS NOT NULL)
BEGIN
SET @RelatedEntitySQL = @RelatedEntitySQL + '
AND  DocumentTypes.Name = ''DOCTYPECONDITION'''
SET @RelatedEntitySQL = REPLACE(@RelatedEntitySQL,'DOCTYPECONDITION',@docType)
END
IF(@Exception IS NOT NULL)
BEGIN
SET @RelatedEntitySQL = @RelatedEntitySQL + '
AND  DocumentStatusConfigs.IsException = ''EXCEPTIONCONDITION'''
SET @RelatedEntitySQL = REPLACE(@RelatedEntitySQL,'EXCEPTIONCONDITION',@Exception)
END
IF(@StatusLastChangedBy IS NOT NULL)
BEGIN
SET @RelatedEntitySQL = @RelatedEntitySQL + '
AND  LastUpdatedUser.Fullname  = ''STATUSLASTCHANGEDBYCONDITION'''
SET @RelatedEntitySQL = REPLACE(@RelatedEntitySQL,'STATUSLASTCHANGEDBYCONDITION',@StatusLastChangedBy)
END
CREATE TABLE #FinalResult(DocType NVARCHAR(100),EntityType NVARCHAR(100),EntityId BIGINT,CustName NVARCHAR(250),SeqNumber NVARCHAR(100),status NVARCHAR(250),originSource NVARCHAR(250),LOB NVARCHAR(100),StatusAsOfDate NVARCHAR(50),ChangedBy NVARCHAR(250),Comment NVARCHAR(MAX),ExceptionReason NVARCHAR(MAX),StatusLastChangedBy NVARCHAR(250),EntityNaturalId NVARCHAR(250));
SET @COMMONSQL = '
INSERT INTO
#FinalResult(DocType ,EntityType ,EntityId ,CustName,SeqNumber ,status ,originSource,LOB,StatusAsOfDate,ChangedBy,Comment,ExceptionReason,StatusLastChangedBy,EntityNaturalId)
SELECT
DocumentTypes.Name as ''Document Type''
,#temp.UserFriendlyName AS ''EntityType''
,ISNULL(#temp.EntityId,0) AS ''EntityId''
,''CUSTOMERNAME'' AS ''Customer Name''
,''SEQUENCENUMBER'' AS ''Sequence Number''
,ISNULL(#temp.Status,null) AS ''DOC Status''
,''ORIGINATIONSOURCE'' AS ''Origination Source''
,''LINEOFBUSINESS'' AS ''Line of Business''
,#temp.StatusAsOfDate
,#temp.StatusChangedBy AS ''ChangedBy''
,ISNULL(#temp.StatusComment,'''') AS ''StatusComment''
,#temp.ExceptionReason AS ''ExceptionReason''
,#temp.StatusLastChangedBy AS ''StatusLastChangedBy''
,#temp.EntityNaturalId
FROM #temp
JOIN documentInstances ON #temp.DocumentInstanceId = DocumentInstances.Id
JOIN DocumentTypes ON DocumentInstances.DocumentTypeId = DocumentTypes.Id
JOIN DocumentEntityConfigs ON DocumentEntityConfigs.Id = DocumentTypes.EntityId
JOIN EntityConfigs ON DocumentEntityConfigs.Id=EntityConfigs.Id
'
--Customer
IF ((@SEQNUM IS NULL or @SEQNUM = '') AND (@ORIGINATIONSOURCE IS NULL or @ORIGINATIONSOURCE = '') AND (@LOBs IS NULL or @LOBs =''))
BEGIN
SET @SQL = @COMMONSQL + ' JOIN Parties ON DocumentInstances.EntityId = Parties.Id AND EntityConfigs.Name =''Customer''
WHERE 1=1 '
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Parties.PartyNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','''''')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','''''')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
END
--LegalEntity
IF ((@SEQNUM IS NULL OR @SEQNUM = '') AND (@ORIGINATIONSOURCE IS NULL OR @ORIGINATIONSOURCE = '') AND (@LOBs IS NULL OR @LOBs ='') AND (@CUSNAME IS NULL OR @CUSNAME = ''))
BEGIN
SET @SQL = @SQL+
@COMMONSQL + 'JOIN LegalEntities ON DocumentInstances.EntityId = LegalEntities.Id AND EntityConfigs.Name =''LegalEntity'' INNER JOIN #AccessibleLegalEntities ALE ON LegalEntities.Id = ALE.Id'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(LegalEntities.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','''''')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','''''')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','''''')
END
--LoanFinance
SET @SQL = @SQL+
@COMMONSQL + 'INNER JOIN LoanFinances ON  DocumentInstances.EntityId = LoanFinances.Id AND EntityConfigs.Name =''LoanFinance''
INNER JOIN Parties ON LoanFinances.CustomerId = Parties.Id AND Parties.CurrentRole = ''Customer''
INNER JOIN Contracts ON LoanFinances.ContractId = Contracts.Id
INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
INNER JOIN ContractOriginations ON ContractOriginations.Id = LoanFinances.ContractOriginationId
LEFT JOIN Parties AS OriginationSources ON ContractOriginations.OriginationSourceId = OriginationSources.Id
WHERE LoanFinances.IsCurrent = 1 AND LineOfBusinesses.IsActive = 1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(LoanFinances.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
IF (@EntityType  = 'LoanFinance' and @SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL +
'UNION ' +
@RelatedEntitySQL
SET @SQL = REPLACE(@SQL,'ENTITYJOINCONDITION',
'INNER JOIN ContractThirdPartyRelationships ON DocumentInstances.EntityId = ContractThirdPartyRelationships.Id
AND EntityConfigs.Name =''ContractThirdPartyRelationship''
INNER JOIN Contracts ON ContractThirdPartyRelationships.ContractId = Contracts.Id
INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
LEFT JOIN Parties AS LoanParties ON LoanParties.Id = LoanFinances.CustomerId
LEFT JOIN ContractOriginations AS LoanOrigination ON LoanOrigination.Id = LoanFinances.ContractOriginationId
LEFT JOIN Parties AS LoanOriginatonSource ON	LoanOriginatonSource.Id = LoanOrigination.OriginationSourceId
WHERE ContractThirdPartyRelationships.IsActive =1 AND LineOfBusinesses.IsActive =1'	)
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(LoanParties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(LoanOriginatonSource.PartyName AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND LoanParties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LoanOriginatonSource.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
END
--ProposalThirdPartyRelationship
IF (@SEQNUM IS NULL OR @SEQNUM = '')
BEGIN
SET @SQL = @SQL+
@COMMONSQL+ 'INNER JOIN ProposalThirdPartyRelationships ON DocumentInstances.EntityId = ProposalThirdPartyRelationships.Id
AND EntityConfigs.Name =''ProposalThirdPartyRelationship''
INNER JOIN Proposals ON ProposalThirdPartyRelationships.ProposalId = Proposals.Id
INNER JOIN CustomerThirdPartyRelationships ON ProposalThirdPartyRelationships.ThirdPartyRelationshipId = CustomerThirdPartyRelationships.Id
INNER JOIN Parties ON CustomerThirdPartyRelationships.CustomerId = Parties.Id
INNER JOIN Opportunities ON Proposals.Id = Opportunities.Id
INNER JOIN LineOfBusinesses ON Opportunities.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN Parties AS OriginationSources ON	Opportunities.OriginationSourceId = OriginationSources.Id
WHERE ProposalThirdPartyRelationships.IsActive = 1 AND CustomerThirdPartyRelationships.IsActive = 1 AND LineOfBusinesses.IsActive = 1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(ProposalThirdPartyRelationships.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
END
--ContractThirdPartyRelationship
SET @SQL = @SQL+
@COMMONSQL + 'INNER JOIN ContractThirdPartyRelationships ON DocumentInstances.EntityId = ContractThirdPartyRelationships.Id
AND EntityConfigs.Name =''ContractThirdPartyRelationship''
INNER JOIN Contracts ON ContractThirdPartyRelationships.ContractId = Contracts.Id
INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
LEFT JOIN Parties AS LeaseParties ON LeaseParties.Id = LeaseFinances.CustomerId
LEFT JOIN ContractOriginations AS LeaseOrigination ON LeaseOrigination.Id = LeaseFinances.ContractOriginationId
LEFT JOIN Parties AS LeaseOriginatonSource ON LeaseOriginatonSource.Id = LeaseOrigination.OriginationSourceId
LEFT JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
LEFT JOIN Parties AS LoanParties ON LoanParties.Id = LoanFinances.CustomerId
LEFT JOIN ContractOriginations AS LoanOrigination ON LoanOrigination.Id = LoanFinances.ContractOriginationId
LEFT JOIN Parties AS LoanOriginatonSource ON	LoanOriginatonSource.Id = LoanOrigination.OriginationSourceId
LEFT JOIN LeveragedLeases ON Contracts.Id = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent = 1
LEFT JOIN Parties AS LeveragedLeaseParties ON LeveragedLeaseParties.Id = LeveragedLeases.CustomerId
LEFT JOIN ContractOriginations AS LeveragedLeaseOrigination ON LeveragedLeaseOrigination.Id = LeveragedLeases.ContractOriginationId
LEFT JOIN Parties AS LeveragedLeaseOriginatonSource ON LeveragedLeaseOriginatonSource.Id = LeveragedLeaseOrigination.OriginationSourceId
WHERE ContractThirdPartyRelationships.IsActive =1 AND LineOfBusinesses.IsActive =1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(ContractThirdPartyRelationships.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CASE
WHEN Contracts.ContractType = ''Lease'' THEN CAST(LeaseParties.PartyName AS NVARCHAR)
WHEN Contracts.ContractType = ''LeveragedLease'' THEN CAST(LeveragedLeaseParties.PartyName AS NVARCHAR)
ELSE CAST(LoanParties.PartyName AS NVARCHAR) END')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CASE
WHEN Contracts.ContractType = ''Lease'' THEN CAST(LeaseOriginatonSource.PartyName AS NVARCHAR)
WHEN Contracts.ContractType = ''LeveragedLease'' THEN CAST(LeveragedLeaseOriginatonSource.PartyName AS NVARCHAR)
ELSE CAST(LoanOriginatonSource.PartyName AS NVARCHAR) END')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  CASE
WHEN Contracts.ContractType = ''Lease'' THEN LeaseParties.PartyName
WHEN Contracts.ContractType = ''LeveragedLease'' THEN LeveragedLeaseParties.PartyName
ELSE LoanParties.PartyName END = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  CASE
WHEN Contracts.ContractType = ''Lease'' THEN LeaseOriginatonSource.PartyName
WHEN Contracts.ContractType = ''LeveragedLease'' THEN LeveragedLeaseOriginatonSource.PartyName
ELSE LoanOriginatonSource.PartyName END = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
--Funder
IF ((@SEQNUM IS NULL or @SEQNUM = '') AND (@ORIGINATIONSOURCE IS NULL or @ORIGINATIONSOURCE = '') AND (@LOBs IS NULL or @LOBs =''))
BEGIN
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN Funders ON DocumentInstances.EntityId = Funders.Id
AND EntityConfigs.Name =''Funder''
INNER JOIN Parties ON Funders.Id = Parties.Id'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Funders.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','''''')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','''''')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
END
--Vendor
IF ((@SEQNUM IS NULL or @SEQNUM = '') AND (@ORIGINATIONSOURCE IS NULL or @ORIGINATIONSOURCE = '') AND (@LOBs IS NULL OR @LOBs = ''))
BEGIN
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN Vendors ON DocumentInstances.EntityId = Vendors.Id
AND EntityConfigs.Name =''Vendor''
INNER JOIN Parties ON Vendors.Id = Parties.Id
LEFT JOIN LineOfBusinesses ON Vendors.LineOfBusinessId = LineOfBusinesses.Id
AND LineOfBusinesses.IsActive = 1
WHERE 1=1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Vendors.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','''''')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
--IF(@LOBs IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  LineOfBusinesses.Name = ''LOBCONDITION'''
--	SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
--END
END
--LeaseFinance
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN LeaseFinances ON DocumentInstances.EntityId = LeaseFinances.Id AND EntityConfigs.Name =''LeaseFinance''
INNER JOIN Parties ON LeaseFinances.CustomerId = Parties.Id AND Parties.CurrentRole = ''Customer''
INNER JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
INNER JOIN ContractOriginations ON ContractOriginations.Id = LeaseFinances.ContractOriginationId
LEFT JOIN Parties AS OriginationSources ON ContractOriginations.OriginationSourceId = OriginationSources.Id
WHERE LeaseFinances.IsCurrent = 1 AND LineOfBusinesses.IsActive = 1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(LeaseFinances.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
IF (@EntityType  = 'LeaseFinance' and @SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL +
'UNION ' +
@RelatedEntitySQL
SET @SQL = REPLACE(@SQL,'ENTITYJOINCONDITION',
'INNER JOIN ContractThirdPartyRelationships ON DocumentInstances.EntityId = ContractThirdPartyRelationships.Id
AND EntityConfigs.Name =''ContractThirdPartyRelationship''
INNER JOIN Contracts ON ContractThirdPartyRelationships.ContractId = Contracts.Id
INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
LEFT JOIN Parties AS LeaseParties ON LeaseParties.Id = LeaseFinances.CustomerId
LEFT JOIN ContractOriginations AS LeaseOrigination ON LeaseOrigination.Id = LeaseFinances.ContractOriginationId
LEFT JOIN Parties AS LeaseOriginatonSource ON LeaseOriginatonSource.Id = LeaseOrigination.OriginationSourceId
LEFT JOIN LeveragedLeases ON Contracts.Id = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent = 1
LEFT JOIN Parties AS LeveragedLeaseParties ON LeveragedLeaseParties.Id = LeveragedLeases.CustomerId
LEFT JOIN ContractOriginations AS LeveragedLeaseOrigination ON LeveragedLeaseOrigination.Id = LeveragedLeases.ContractOriginationId
LEFT JOIN Parties AS LeveragedLeaseOriginatonSource ON LeveragedLeaseOriginatonSource.Id = LeveragedLeaseOrigination.OriginationSourceId
WHERE ContractThirdPartyRelationships.IsActive =1 AND LineOfBusinesses.IsActive =1'	)
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CASE
WHEN Contracts.ContractType = ''Lease'' THEN CAST(LeaseParties.PartyName AS NVARCHAR)
ELSE  CAST(LeveragedLeaseParties.PartyName AS NVARCHAR) END')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CASE
WHEN Contracts.ContractType = ''Lease'' THEN CAST(LeaseOriginatonSource.PartyName AS NVARCHAR)
ELSE CAST(LeveragedLeaseOriginatonSource.PartyName AS NVARCHAR) END')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  CASE
WHEN Contracts.ContractType = ''Lease'' THEN LeaseParties.PartyName
ELSE LeveragedLeaseParties.PartyName  END = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  CASE
WHEN Contracts.ContractType = ''Lease'' THEN LeaseOriginatonSource.PartyName
ELSE  LeveragedLeaseOriginatonSource.PartyName END = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
END
--CreditApplication
IF (@SEQNUM IS NULL or @SEQNUM = '')
BEGIN
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN CreditApplications ON DocumentInstances.EntityId = CreditApplications.Id
AND EntityConfigs.Name =''CreditApplication''
INNER JOIN Opportunities ON CreditApplications.Id = Opportunities.Id
INNER JOIN LineOfBusinesses ON Opportunities.LineOfBusinessId = LineOfBusinesses.Id
INNER JOIN Parties ON Opportunities.CustomerId = Parties.Id
LEFT JOIN Parties AS OriginationSources ON Opportunities.OriginationSourceId = OriginationSources.Id
WHERE LineOfBusinesses.IsActive = 1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(CreditApplications.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
IF (@EntityType  = 'CreditApplication' and @EntityId IS NOT NULL)
BEGIN
SET @SQL = @SQL +
'UNION ' +
@RelatedEntitySQL
SET @SQL = REPLACE(@SQL,'ENTITYJOINCONDITION',
'INNER JOIN CreditApplicationThirdPartyRelationships ON DocumentInstances.EntityId = CreditApplicationThirdPartyRelationships.Id
AND EntityConfigs.Name =''CreditApplicationThirdPartyRelationship''
INNER JOIN CreditApplications ON CreditApplicationThirdPartyRelationships.CreditApplicationId = CreditApplications.Id
INNER JOIN Opportunities ON CreditApplications.Id = Opportunities.Id
INNER JOIN Parties ON Opportunities.CustomerId = Parties.Id
INNER JOIN LineOfBusinesses ON Opportunities.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN Parties AS OriginationSources ON Opportunities.OriginationSourceId = OriginationSources.Id
WHERE CreditApplicationThirdPartyRelationships.IsActive = 1 AND LineOfBusinesses.IsActive = 1 AND CreditApplications.Id = ''VALUE'''	)
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''VALUE''',@EntityId)
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
END
END
--DisbursementRequest
IF ((@SEQNUM IS NULL OR @SEQNUM = '') AND (@ORIGINATIONSOURCE IS NULL OR @ORIGINATIONSOURCE = '') AND (@LOBs IS NULL OR @LOBs ='') AND (@CUSNAME IS NULL OR @CUSNAME = ''))
BEGIN
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN DisbursementRequests ON DocumentInstances.EntityId = DisbursementRequests.Id
AND EntityConfigs.Name =''DisbursementRequest'''
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(DisbursementRequests.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','''''')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','''''')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','''''')
END
--Proposals
IF (@SEQNUM IS NULL OR @SEQNUM = '')
BEGIN
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN Proposals ON DocumentInstances.EntityId = Proposals.Id
AND EntityConfigs.Name =''Proposal''
INNER JOIN Opportunities ON Proposals.Id = Opportunities.Id
INNER JOIN LineOfBusinesses ON Opportunities.LineOfBusinessId = LineOfBusinesses.Id
INNER JOIN Parties ON Opportunities.CustomerId = Parties.Id
LEFT JOIN Parties AS OriginationSources ON	Opportunities.OriginationSourceId = OriginationSources.Id
WHERE LineOfBusinesses.IsActive = 1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Proposals.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
IF (@EntityType  = 'Proposal' and @EntityId IS NOT NULL)
BEGIN
SET @SQL = @SQL +
'UNION ' +
@RelatedEntitySQL
SET @SQL = REPLACE(@SQL,'ENTITYJOINCONDITION',
'INNER JOIN ProposalThirdPartyRelationships ON DocumentInstances.EntityId = ProposalThirdPartyRelationships.Id
AND EntityConfigs.Name =''ProposalThirdPartyRelationship''
INNER JOIN Proposals ON ProposalThirdPartyRelationships.ProposalId = Proposals.Id
INNER JOIN CustomerThirdPartyRelationships ON ProposalThirdPartyRelationships.ThirdPartyRelationshipId = CustomerThirdPartyRelationships.Id
INNER JOIN Parties ON CustomerThirdPartyRelationships.CustomerId = Parties.Id
INNER JOIN Opportunities ON Proposals.Id = Opportunities.Id
INNER JOIN LineOfBusinesses ON Opportunities.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN Parties AS OriginationSources ON	Opportunities.OriginationSourceId = OriginationSources.Id
WHERE ProposalThirdPartyRelationships.IsActive = 1 AND CustomerThirdPartyRelationships.IsActive = 1 AND LineOfBusinesses.IsActive = 1 AND Proposals.Id = ''VALUE''')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''VALUE''',@EntityId)
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
END
END
--CreditProfile
IF (@SEQNUM IS NULL OR @SEQNUM = '')
BEGIN
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN CreditProfiles ON DocumentInstances.EntityId = CreditProfiles.Id
AND EntityConfigs.Name =''CreditProfile''
INNER JOIN LineOfBusinesses ON CreditProfiles.LineOfBusinessId = LineOfBusinesses.Id
INNER JOIN Parties ON CreditProfiles.CustomerId = Parties.Id
LEFT JOIN Parties AS OriginationSources ON	CreditProfiles.OriginationSourceId = OriginationSources.Id
WHERE LineOfBusinesses.IsActive = 1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(CreditProfiles.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
IF (@EntityType  = 'CreditProfile' and @EntityId IS NOT NULL)
BEGIN
SET @SQL = @SQL +
'UNION ' +
@RelatedEntitySQL
SET @SQL = REPLACE(@SQL,'ENTITYJOINCONDITION',
'INNER JOIN CreditProfileThirdPartyRelationships ON DocumentInstances.EntityId = CreditProfileThirdPartyRelationships.Id
AND EntityConfigs.Name =''CreditProfileThirdPartyRelationship''
INNER JOIN CreditProfiles ON CreditProfileThirdPartyRelationships.CreditProfileId = CreditProfiles.Id
INNER JOIN Parties ON CreditProfiles.CustomerId = Parties.Id
INNER JOIN LineOfBusinesses ON CreditProfiles.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN Parties AS OriginationSources ON CreditProfiles.OriginationSourceId = OriginationSources.Id
WHERE CreditProfileThirdPartyRelationships.IsActive = 1 AND LineOfBusinesses.IsActive = 1 AND CreditProfiles.Id = ''VALUE''')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''VALUE''',@EntityId)
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
END
END
--AppraisalRequest
IF ((@SEQNUM IS NULL OR @SEQNUM = '') AND (@ORIGINATIONSOURCE IS NULL OR @ORIGINATIONSOURCE = '') AND (@LOBs IS NULL OR @LOBs ='') AND (@CUSNAME IS NULL OR @CUSNAME = ''))
BEGIN
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN AppraisalRequests ON DocumentInstances.EntityId = AppraisalRequests.Id
AND EntityConfigs.Name =''AppraisalRequest'''
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(AppraisalRequests.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','''''')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','''''')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','''''')
END
--MaturityMonitor
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN MaturityMonitors ON DocumentInstances.EntityId = MaturityMonitors.Id
AND EntityConfigs.Name =''MaturityMonitor''
INNER JOIN Contracts ON MaturityMonitors.ContractId = Contracts.Id
INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
LEFT JOIN Parties AS LeaseParties ON LeaseParties.Id = LeaseFinances.CustomerId
LEFT JOIN ContractOriginations AS LeaseOrigination ON LeaseOrigination.Id = LeaseFinances.ContractOriginationId
LEFT JOIN Parties AS LeaseOriginatonSource ON LeaseOriginatonSource.Id = LeaseOrigination.OriginationSourceId
LEFT JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
LEFT JOIN Parties AS LoanParties ON LoanParties.Id = LoanFinances.CustomerId
LEFT JOIN ContractOriginations AS LoanOrigination ON LoanOrigination.Id = LoanFinances.ContractOriginationId
LEFT JOIN Parties AS LoanOriginatonSource ON	LoanOriginatonSource.Id = LoanOrigination.OriginationSourceId
LEFT JOIN LeveragedLeases ON Contracts.Id = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent = 1
LEFT JOIN Parties AS LeveragedLeaseParties ON LeveragedLeaseParties.Id = LeveragedLeases.CustomerId
LEFT JOIN ContractOriginations AS LeveragedLeaseOrigination ON LeveragedLeaseOrigination.Id = LeveragedLeases.ContractOriginationId
LEFT JOIN Parties AS LeveragedLeaseOriginatonSource ON LeveragedLeaseOriginatonSource.Id = LeveragedLeaseOrigination.OriginationSourceId
WHERE LineOfBusinesses.IsActive = 1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(MaturityMonitors.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CASE
WHEN Contracts.ContractType = ''Lease'' THEN CAST(LeaseParties.PartyName AS NVARCHAR)
WHEN Contracts.ContractType = ''LeveragedLease'' THEN CAST(LeveragedLeaseParties.PartyName AS NVARCHAR)
ELSE CAST(LoanParties.PartyName AS NVARCHAR) END')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CASE
WHEN Contracts.ContractType = ''Lease'' THEN CAST(LeaseOriginatonSource.PartyName AS NVARCHAR)
WHEN Contracts.ContractType = ''LeveragedLease'' THEN CAST(LeveragedLeaseOriginatonSource.PartyName AS NVARCHAR)
ELSE CAST(LoanOriginatonSource.PartyName AS NVARCHAR) END')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  CASE
WHEN Contracts.ContractType = ''Lease'' THEN LeaseParties.PartyName
WHEN Contracts.ContractType = ''LeveragedLease'' THEN LeveragedLeaseParties.PartyName
ELSE LoanParties.PartyName END = ''CUSNAMECONDITION'' '
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  CASE
WHEN Contracts.ContractType = ''Lease'' THEN LeaseOriginatonSource.PartyName
WHEN Contracts.ContractType = ''LeveragedLease'' THEN LeveragedLeaseOriginatonSource.PartyName
ELSE LoanOriginatonSource.PartyName END = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
----LoanAmendment
--SET @SQL = @SQL
--			+@COMMONSQL+ 'INNER JOIN LoanAmendments ON DocumentInstances.EntityId = LoanAmendments.Id
--				   AND EntityConfigs.Name =''LoanAmendment''
--				   INNER JOIN LoanFinances ON LoanAmendments.LoanFinanceId = LoanFinances.Id
--				   INNER JOIN Contracts ON LoanFinances.ContractId = Contracts.Id
--				   INNER JOIN Parties ON LoanFinances.CustomerId = Parties.Id
--				   INNER JOIN ContractOriginations ON ContractOriginations.Id = LoanFinances.ContractOriginationId
--				   INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
--				   LEFT JOIN Parties AS OriginationSources ON ContractOriginations.OriginationSourceId = OriginationSources.Id
--				   WHERE LoanFinances.IsCurrent = 1 AND LineOfBusinesses.IsActive = 1'
--SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(LoanAmendments.Id AS NVARCHAR)')
--SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
--SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
--SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
--SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
--IF(@CUSNAME IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  Parties.PartyName = ''CUSNAMECONDITION'''
--	SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
--END
--IF(@SEQNUM IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
--	SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
--END
--IF(@ORIGINATIONSOURCE IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
--	SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
--END
--IF(@LOBs IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  LineOfBusinesses.Name = ''LOBCONDITION'''
--	SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
--END
--Assumption
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN Assumptions ON DocumentInstances.EntityId = Assumptions.Id
AND EntityConfigs.Name =''Assumption''
INNER JOIN Contracts ON Assumptions.ContractId = Contracts.Id
INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
LEFT JOIN Parties AS LeaseParties ON LeaseParties.Id = LeaseFinances.CustomerId
LEFT JOIN ContractOriginations AS LeaseOrigination ON LeaseOrigination.Id = LeaseFinances.ContractOriginationId
LEFT JOIN Parties AS LeaseOriginatonSource ON LeaseOriginatonSource.Id = LeaseOrigination.OriginationSourceId
LEFT JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
LEFT JOIN Parties AS LoanParties ON LoanParties.Id = LoanFinances.CustomerId
LEFT JOIN ContractOriginations AS LoanOrigination ON LoanOrigination.Id = LoanFinances.ContractOriginationId
LEFT JOIN Parties AS LoanOriginatonSource ON	LoanOriginatonSource.Id = LoanOrigination.OriginationSourceId
LEFT JOIN LeveragedLeases ON Contracts.Id = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent = 1
LEFT JOIN Parties AS LeveragedLeaseParties ON LeveragedLeaseParties.Id = LeveragedLeases.CustomerId
LEFT JOIN ContractOriginations AS LeveragedLeaseOrigination ON LeveragedLeaseOrigination.Id = LeveragedLeases.ContractOriginationId
LEFT JOIN Parties AS LeveragedLeaseOriginatonSource ON LeveragedLeaseOriginatonSource.Id = LeveragedLeaseOrigination.OriginationSourceId
WHERE LineOfBusinesses.IsActive = 1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Assumptions.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CASE
WHEN Contracts.ContractType = ''Lease'' THEN CAST(LeaseParties.PartyName AS NVARCHAR)
WHEN Contracts.ContractType = ''LeveragedLease'' THEN CAST(LeveragedLeaseParties.PartyName AS NVARCHAR)
ELSE CAST(LoanParties.PartyName AS NVARCHAR) END')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CASE
WHEN Contracts.ContractType = ''Lease'' THEN CAST(LeaseOriginatonSource.PartyName AS NVARCHAR)
WHEN Contracts.ContractType = ''LeveragedLease'' THEN CAST(LeveragedLeaseOriginatonSource.PartyName AS NVARCHAR)
ELSE CAST(LoanOriginatonSource.PartyName AS NVARCHAR) END')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  CASE
WHEN Contracts.ContractType = ''Lease'' THEN LeaseParties.PartyName
WHEN Contracts.ContractType = ''LeveragedLease'' THEN LeveragedLeaseParties.PartyName
ELSE LoanParties.PartyName END = ''CUSNAMECONDITION'' '
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  CASE
WHEN Contracts.ContractType = ''Lease'' THEN LeaseOriginatonSource.PartyName
WHEN Contracts.ContractType = ''LeveragedLease'' THEN LeveragedLeaseOriginatonSource.PartyName
ELSE LoanOriginatonSource.PartyName END = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
----LeaseAmendment
--SET @SQL = @SQL
--			+@COMMONSQL+ 'INNER JOIN LeaseAmendments ON DocumentInstances.EntityId = LeaseAmendments.Id
--				   AND EntityConfigs.Name =''LeaseAmendment''
--				   INNER JOIN LeaseFinances ON LeaseAmendments.CurrentLeaseFinanceId = LeaseFinances.Id
--				   INNER JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
--				   INNER JOIN Parties ON LeaseFinances.CustomerId = Parties.Id
--				   INNER JOIN ContractOriginations ON ContractOriginations.Id = LeaseFinances.ContractOriginationId
--				   INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
--				   LEFT JOIN Parties AS OriginationSources ON ContractOriginations.OriginationSourceId = OriginationSources.Id
--				   WHERE LeaseFinances.IsCurrent = 1 AND LineOfBusinesses.IsActive = 1'
--SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(LeaseAmendments.Id AS NVARCHAR)')
--SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
--SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
--SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
--SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
--IF(@CUSNAME IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  Parties.PartyName = ''CUSNAMECONDITION'''
--	SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
--END
--IF(@SEQNUM IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
--	SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
--END
--IF(@ORIGINATIONSOURCE IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  OriginationSources.PartyName= ''ORIGINATIONSOURCECONDITION'''
--	SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
--END
--IF(@LOBs IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  LineOfBusinesses.Name = ''LOBCONDITION'''
--	SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
--END
--CollectionWorkList
IF ((@SEQNUM IS NULL OR @SEQNUM = '') AND (@ORIGINATIONSOURCE IS NULL OR @ORIGINATIONSOURCE = '') AND (@LOBs IS NULL OR @LOBs ='') AND (@CUSNAME IS NULL OR @CUSNAME = ''))
BEGIN
SET @SQL = @SQL
+@COMMONSQL + 'INNER JOIN CollectionWorkLists ON DocumentInstances.EntityId = CollectionWorkLists.Id
AND EntityConfigs.Name =''CollectionWorkList''
INNER JOIN Parties ON CollectionWorkLists.CustomerId = Parties.Id
WHERE 1=1 '
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(CollectionWorkLists.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','''''')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','''''')
--IF(@CUSNAME IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  Parties.PartyName = ''CUSNAMECONDITION'''
--	SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
--END
END
--AssetSale
IF ((@SEQNUM IS NULL OR @SEQNUM = '') AND (@ORIGINATIONSOURCE IS NULL OR @ORIGINATIONSOURCE = '') AND (@CUSNAME IS NULL OR @CUSNAME = '') AND (@LOBs IS NULL OR @LOBs = ''))
BEGIN
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN AssetSales ON DocumentInstances.EntityId = AssetSales.Id
AND EntityConfigs.Name =''AssetSale''
LEFT JOIN LineOfBusinesses ON AssetSales.LineOfBusinessId = LineOfBusinesses.Id
AND LineOfBusinesses.IsActive = 1
WHERE 1=1 '
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(AssetSales.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','''''')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','''''')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
--IF(@LOBs IS NOT NULL)
--BEGIN
--SET @SQL = @SQL + '
--	AND  LineOfBusinesses.Name = ''LOBCONDITION'''
--	SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
--END
END
--ContractTermination
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN ContractTerminations ON DocumentInstances.EntityId = ContractTerminations.Id
AND EntityConfigs.Name =''ContractTermination''
INNER JOIN Contracts ON ContractTerminations.ContractId = Contracts.Id
INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
LEFT JOIN Parties AS LeaseParties ON LeaseParties.Id = LeaseFinances.CustomerId
LEFT JOIN ContractOriginations AS LeaseOrigination ON LeaseOrigination.Id = LeaseFinances.ContractOriginationId
LEFT JOIN Parties AS LeaseOriginatonSource ON LeaseOriginatonSource.Id = LeaseOrigination.OriginationSourceId
LEFT JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
LEFT JOIN Parties AS LoanParties ON LoanParties.Id = LoanFinances.CustomerId
LEFT JOIN ContractOriginations AS LoanOrigination ON LoanOrigination.Id = LoanFinances.ContractOriginationId
LEFT JOIN Parties AS LoanOriginatonSource ON	LoanOriginatonSource.Id = LoanOrigination.OriginationSourceId
LEFT JOIN LeveragedLeases ON Contracts.Id = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent = 1
LEFT JOIN Parties AS LeveragedLeaseParties ON LeveragedLeaseParties.Id = LeveragedLeases.CustomerId
LEFT JOIN ContractOriginations AS LeveragedLeaseOrigination ON LeveragedLeaseOrigination.Id = LeveragedLeases.ContractOriginationId
LEFT JOIN Parties AS LeveragedLeaseOriginatonSource ON LeveragedLeaseOriginatonSource.Id = LeveragedLeaseOrigination.OriginationSourceId
WHERE LineOfBusinesses.IsActive = 1'
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(ContractTerminations.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CASE
WHEN Contracts.ContractType = ''Lease'' THEN CAST(LeaseParties.PartyName AS NVARCHAR)
WHEN Contracts.ContractType = ''LeveragedLease'' THEN CAST(LeveragedLeaseParties.PartyName AS NVARCHAR)
ELSE CAST(LoanParties.PartyName AS NVARCHAR) END')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CASE
WHEN Contracts.ContractType = ''Lease'' THEN CAST(LeaseOriginatonSource.PartyName AS NVARCHAR)
WHEN Contracts.ContractType = ''LeveragedLease'' THEN CAST(LeveragedLeaseOriginatonSource.PartyName AS NVARCHAR)
ELSE CAST(LoanOriginatonSource.PartyName AS NVARCHAR) END')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  CASE
WHEN Contracts.ContractType = ''Lease'' THEN LeaseParties.PartyName
WHEN Contracts.ContractType = ''LeveragedLease'' THEN LeveragedLeaseParties.PartyName
ELSE LoanParties.PartyName END = ''CUSNAMECONDITION'' '
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  CASE
WHEN Contracts.ContractType = ''Lease'' THEN LeaseOriginatonSource.PartyName
WHEN Contracts.ContractType = ''LeveragedLease'' THEN LeveragedLeaseOriginatonSource.PartyName
ELSE LoanOriginatonSource.PartyName END = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
--CreditProfileThirdPartyRelationship
IF (@SEQNUM IS NULL OR @SEQNUM = '')
BEGIN
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN CreditProfileThirdPartyRelationships ON DocumentInstances.EntityId = CreditProfileThirdPartyRelationships.Id
AND EntityConfigs.Name =''CreditProfileThirdPartyRelationship''
INNER JOIN CreditProfiles ON CreditProfileThirdPartyRelationships.CreditProfileId = CreditProfiles.Id
INNER JOIN Parties ON CreditProfiles.CustomerId = Parties.Id
INNER JOIN LineOfBusinesses ON CreditProfiles.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN Parties AS OriginationSources ON CreditProfiles.OriginationSourceId = OriginationSources.Id
WHERE CreditProfileThirdPartyRelationships.IsActive = 1 AND LineOfBusinesses.IsActive = 1 '
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(CreditProfileThirdPartyRelationships.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
END
--Payoff
SET @SQL = @SQL
+@COMMONSQL + 'INNER JOIN Payoffs ON DocumentInstances.EntityId = Payoffs.Id
AND EntityConfigs.Name =''Payoff''
INNER JOIN LeaseFinances ON Payoffs.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Parties ON LeaseFinances.CustomerId = Parties.Id
INNER JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
INNER JOIN ContractOriginations ON ContractOriginations.Id = LeaseFinances.ContractOriginationId
INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN Parties AS OriginationSources ON ContractOriginations.OriginationSourceId = OriginationSources.Id
WHERE LeaseFinances.IsCurrent = 1 AND LineOfBusinesses.IsActive = 1 '
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Payoffs.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
--Paydown
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN LoanPaydowns ON DocumentInstances.EntityId = LoanPaydowns.Id
AND EntityConfigs.Name =''Paydown''
INNER JOIN LoanFinances ON LoanPaydowns.LoanFinanceId = LoanFinances.Id
INNER JOIN Parties ON LoanFinances.CustomerId = Parties.Id
INNER JOIN Contracts ON LoanFinances.ContractId = Contracts.Id
INNER JOIN ContractOriginations ON ContractOriginations.Id = LoanFinances.ContractOriginationId
INNER JOIN LineOfBusinesses ON Contracts.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN Parties AS OriginationSources ON ContractOriginations.OriginationSourceId = OriginationSources.Id
WHERE LoanFinances.IsCurrent = 1 AND LineOfBusinesses.IsActive = 1 '
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(LoanPaydowns.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@SEQNUM IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Contracts.SequenceNumber = ''SEQUENCENUMBERCONDITION'''
SET @SQL = REPLACE(@SQL,'SEQUENCENUMBERCONDITION',@SEQNUM)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
--CreditApplicationThirdPartyRelationship
IF (@SEQNUM IS NULL OR @SEQNUM = '')
BEGIN
SET @SQL = @SQL
+@COMMONSQL+ 'INNER JOIN CreditApplicationThirdPartyRelationships ON DocumentInstances.EntityId = CreditApplicationThirdPartyRelationships.Id
AND EntityConfigs.Name =''CreditApplicationThirdPartyRelationship''
INNER JOIN CreditApplications ON CreditApplicationThirdPartyRelationships.CreditApplicationId = CreditApplications.Id
INNER JOIN Opportunities ON CreditApplications.Id = Opportunities.Id
INNER JOIN Parties ON Opportunities.CustomerId = Parties.Id
INNER JOIN LineOfBusinesses ON Opportunities.LineOfBusinessId = LineOfBusinesses.Id
LEFT JOIN Parties AS OriginationSources ON Opportunities.OriginationSourceId = OriginationSources.Id
WHERE CreditApplicationThirdPartyRelationships.IsActive = 1 AND LineOfBusinesses.IsActive = 1 '
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(CreditApplicationThirdPartyRelationships.Id AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''CUSTOMERNAME''','CAST(Parties.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''SEQUENCENUMBER''','''''')
SET @SQL = REPLACE(@SQL,'''ORIGINATIONSOURCE''','CAST(OriginationSources.PartyName AS NVARCHAR)')
SET @SQL = REPLACE(@SQL,'''LINEOFBUSINESS''','CAST(LineOfBusinesses.Name AS NVARCHAR)')
IF(@CUSNAME IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  Parties.PartyName = ''CUSNAMECONDITION'''
SET @SQL = REPLACE(@SQL,'CUSNAMECONDITION',@CUSNAME)
END
IF(@ORIGINATIONSOURCE IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  OriginationSources.PartyName = ''ORIGINATIONSOURCECONDITION'''
SET @SQL = REPLACE(@SQL,'ORIGINATIONSOURCECONDITION',@ORIGINATIONSOURCE)
END
IF(@LOBs IS NOT NULL)
BEGIN
SET @SQL = @SQL + '
AND  LineOfBusinesses.Name = ''LOBCONDITION'''
SET @SQL = REPLACE(@SQL,'LOBCONDITION',@LOBs)
END
END
EXEC SP_EXECUTESQL @SQL
SELECT  DISTINCT * FROM #FinalResult ORDER BY StatusAsOfDate
DROP TABLE #Temp
DROP TABLE #FinalResult
DROP TABLE #AccessibleLegalEntities
END--procedure ends

GO

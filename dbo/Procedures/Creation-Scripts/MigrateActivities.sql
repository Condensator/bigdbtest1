SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[MigrateActivities]
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
--SELECT @ModuleIterationStatusId=MAX(ModuleIterationStatusId) FROM stgProcessingLog;  
BEGIN  
SET NOCOUNT ON  
BEGIN TRY  
BEGIN TRANSACTION  
SET XACT_ABORT ON  
SET @FailedRecords = 0  
SET @ProcessedRecords =0  
DECLARE @ErrorLogs ErrorMessageList;  
  
DECLARE @Module VARCHAR(50) = NULL  
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)  
EXEC ResetStagingTempFields @Module , NULL  
  
UPDATE stgActivity  SET IsFailed=0  WHERE IsMigrated = 0  
Set @ProcessedRecords =ISNULL(@@rowCount,0)  
CREATE TABLE #CreatedActivities  
(  
 [Action] NVARCHAR(10) NOT NULL  
 ,[Id] BIGINT NOT NULL  
 ,ActivityId BIGINT NOT NULL  
);  
  
CREATE TABLE #CreatedEntity  
(  
  [Action] NVARCHAR(10) NOT NULL  
 ,[Id] BIGINT NOT NULL  
 ,[ActivityId] BIGINT NOT NULL  
); 

CREATE TABLE #CreatedLegalRelief  
(  
  [Action] NVARCHAR(10) NOT NULL  
 ,[Id] BIGINT NOT NULL  
 ,[ActivityId] BIGINT NOT NULL  
); 

CREATE TABLE #CreatedPlacement  
(  
  [Action] NVARCHAR(10) NOT NULL  
 ,[Id] BIGINT NOT NULL  
 ,[ActivityId] BIGINT NOT NULL  
); 
  
CREATE TABLE #InsertedLegalStatus  
(  
    [CustomerId] BIGINT NOT NULL  
    ,[LegalStatusId] BIGINT NOT NULL  
    ,[AssignmentDate] DATE NOT NULL  
    ,ActivityId BIGINT NOT NULL  
);  
  
---ValidateActivity  
EXEC ValidateActivity @UserId,@ModuleIterationStatusId, @CreatedTime,1,@ProcessedRecords,@FailedRecords  
  
--Legal Relief Creation  
CREATE TABLE #CreatedLegalReliefProofOfClaims  
(  
  [Id] BIGINT NOT NULL  
 ,LegalReliefProofOfClaimId BIGINT NOT NULL  
 ,ClaimNumber NVARCHAR(40)  
);  
  
MERGE LegalReliefs As LegalRelief  
USING(SELECT LegalRelief.*,Activity.R_CustomerId, Activity.CurrencyCode FROM stgLegalRelief LegalRelief  
INNER JOIN stgActivity Activity ON Activity.Id = LegalRelief.Id  
Where Activity.IsMigrated = 0 And Activity.[IsFailed]=0  
AND Activity.ActivityType IN ('Bankruptcy','Receivership')) As LegalReliefsToMigrate  
ON 1 = 0  
WHEN NOT MATCHED  
THEN  
INSERT  
        ([LegalReliefType]  
        ,[Active]  
        ,[LegalReliefRecordNumber]  
        ,[FundsReceived_Amount]  
        ,[FundsReceived_Currency]  
        ,[FilingDate]  
        ,[POCDeadlineDate]  
        ,[ReaffirmationDate]  
        ,[ConfirmationDate]  
        ,[Notes]  
        ,[Status]  
        ,[TrusteeAppointed]  
        ,[DebtorinPossession]  
        ,[BankruptcyNoticeNumber]  
        ,[ConversionDate]  
        ,[DebtorNotes]  
        ,[TrusteeName]  
        ,[Address1]  
        ,[Address2]  
        ,[City]  
        ,[Zip]  
        ,[OfficePhone]  
        ,[CellPhone]  
        ,[FaxNumber]  
        ,[EMailId]  
        ,[TrusteeNotes]  
        ,[BarDate]  
        ,[ReceiverName]  
        ,[WebPage]  
        ,[StateCourtDistrict]  
        ,[ReceiverOfficePhone]  
        ,[ReceiverDirectPhone]  
        ,[ReceiverEmailId]  
        ,[CreatedById]  
        ,[CreatedTime]  
        ,[CourtId]  
        ,[StateId]  
        ,[CustomerId]  
        ,[PartyContactId]  
        ,[AddressLine3]  
        ,[Neighborhood]  
        ,[SubdivisionOrMunicipality]  
  ,[PlacedwithOutsideCounsel])  
     VALUES  
         ([LegalReliefType]  
        ,1  
        ,[LegalReliefRecordNumber]  
        ,0.00  
        ,CurrencyCode  
        ,[FilingDate]  
        ,[POCDeadlineDate]  
        ,[ReaffirmationDate]  
        ,[ConfirmationDate]  
        ,[Notes]  
        ,[Status]  
        ,[TrusteeAppointed]  
        ,[DebtorinPossession]  
        ,[BankruptcyNoticeNumber]  
        ,[ConversionDate]  
        ,[DebtorNotes]  
        ,[TrusteeName]  
        ,[Address1]  
        ,[Address2]  
        ,[City]  
        ,[Zip]  
        ,[OfficePhone]  
        ,[CellPhone]  
        ,[FaxNumber]  
        ,[EMailId]  
        ,[TrusteeNotes]  
        ,[BarDate]  
        ,[ReceiverName]  
        ,[WebPage]  
        ,[StateCourtDistrict]  
        ,[ReceiverOfficePhone]  
        ,[ReceiverDirectPhone]  
        ,[ReceiverEmailId]  
        ,@UserId  
        ,@CreatedTime  
        ,[R_CourtId]  
        ,[R_StateId]  
        ,[R_CustomerId]  
        ,[R_TrusteeAppointedUniqueIdentifierId]  
        ,[AddressLine3]  
        ,[Neighborhood]  
        ,[SubdivisionOrMunicipality]  
  ,0)  
OUTPUT $ACTION, INSERTED.Id,LegalReliefsToMigrate.Id  INTO #CreatedLegalRelief;  
  
INSERT  INTO [dbo].[LegalReliefBankruptcyChapters]  
           ([Chapter]  
           ,[Date]  
           ,[Active]  
           ,[CreatedById]  
           ,[CreatedTime]  
           ,[LegalReliefId])  
SELECT  
  Activity.Chapter  
 ,LegalRelief.FilingDate  
 ,1  
 ,@UserId  
 ,@CreatedTime  
 ,LegalReliefIds.Id  
FROM stgLegalRelief LegalRelief  
INNER JOIN stgActivity Activity ON LegalRelief.Id = Activity.Id  
INNER JOIN #CreatedLegalRelief LegalReliefIds ON LegalRelief.Id = LegalReliefIds.ActivityId;  
  
INSERT  INTO [dbo].[LegalReliefContracts]  
           ([Date]  
           ,[Intention]  
           ,[Active]  
           ,[CreatedById]  
           ,[CreatedTime]  
           ,[ContractId]  
           ,[LegalReliefId])  
SELECT ActivityContractDetail.LegalReliefIntentionDate  
      ,ActivityContractDetail.LegalReliefIntention  
      ,1  
   ,@UserId  
   ,@CreatedTime  
      ,ActivityContractDetail.R_ContractId  
      ,LegalReliefIds.Id  
FROM stgLegalRelief LegalRelief  
INNER JOIN stgActivityContractDetail ActivityContractDetail ON LegalRelief.Id = ActivityContractDetail.ActivityId  
INNER JOIN #CreatedLegalRelief LegalReliefIds ON LegalRelief.Id = LegalReliefIds.ActivityId;  
  
MERGE LegalReliefProofOfClaims As LegalReliefProofOfClaim  
USING(SELECT  
  [Date]  
 ,[FilingDate]  
 ,[ClaimNumber]  
 ,CurrencyCode  
 ,LegalReliefProofOfClaim.Status  
 ,[R_StateId]  
 ,[R_OriginalPOCId]  
 ,LegalReliefIds.Id [LegalReliefId]  
 ,LegalReliefProofOfClaim.Id  
FROM stgLegalReliefProofOfClaim LegalReliefProofOfClaim  
INNER JOIN #CreatedLegalRelief LegalReliefIds ON LegalReliefProofOfClaim.LegalReliefId = LegalReliefIds.ActivityId  
INNER JOIN stgActivity Activity ON Activity.Id = LegalReliefIds.ActivityId) As LegalReliefProofOfClaimsToMigrate  
ON 1 = 0  
WHEN NOT MATCHED  
THEN  
INSERT  
([Date]  
,[FilingDate]  
,[ClaimNumber]  
,[TotalAmount_Amount]  
,[TotalAmount_Currency]  
,[Status]  
,[Active]  
,[CreatedById]  
,[CreatedTime]  
,[StateId]  
,[OriginalPOCId]  
,[LegalReliefId])  
VALUES(  
  [Date]  
 ,[FilingDate]  
 ,[ClaimNumber]  
 ,0.00  
 ,CurrencyCode  
 ,Status  
 ,1  
 ,@UserId  
 ,@CreatedTime  
 ,[R_StateId]  
 ,[R_OriginalPOCId]  
 ,LegalReliefId)  
OUTPUT inserted.Id,LegalReliefProofOfClaimsToMigrate.Id,inserted.ClaimNumber INTO #CreatedLegalReliefProofOfClaims;  
  
INSERT INTO [dbo].[LegalReliefPOCContracts]  
           ([Amount_Amount]  
           ,[Amount_Currency]  
           ,[Include]  
           ,[Active]  
           ,[CreatedById]  
           ,[CreatedTime]  
           ,[ContractId]  
           ,[AcceleratedBalanceDetailId]  
           ,[LegalReliefProofOfClaimId])  
     SELECT  
            ISNULL(A.Balance_Amount, 0.00)  
           ,ISNULL(A.Balance_Currency,TaxPaidtoVendor_Currency)  
           ,Include  
           ,1  
           ,@UserId  
           ,SYSDATETIMEOFFSET()  
           ,R_ContractId  
           ,A.Id  
           ,POC.Id  
FROM stgLegalReliefPOCContract PC  
INNER JOIN Contracts C ON PC.R_ContractId = C.Id  
INNER JOIN #CreatedLegalReliefProofOfClaims POC ON PC.LegalReliefProofOfClaimId = POC.LegalReliefProofOfClaimId  
LEFT JOIN AcceleratedBalanceDetails A ON PC.R_ContractId = A.ContractId AND A.Status = 'Active'  
  
INSERT INTO [dbo].[LegalReliefPOCAmounts]  
            ([Amount_Amount]  
           ,[Amount_Currency]  
           ,[Active]  
           ,[CreatedById]  
           ,[CreatedTime]  
           ,[CurrencyId]  
           ,[LegalReliefProofOfClaimId])  
SELECT   
ISNULL(SUM(A.Balance_Amount),0.00),  
TaxPaidtoVendor_Currency,  
1,  
@UserId,  
SYSDATETIMEOFFSET(),  
C.Id,  
POC.Id  
FROM  stgLegalReliefPOCContract PC  
INNER JOIN Contracts Con ON PC.R_ContractId = Con.Id  
INNER JOIN #CreatedLegalReliefProofOfClaims POC ON PC.LegalReliefProofOfClaimId = POC.LegalReliefProofOfClaimId  
INNER JOIN Currencies C ON C.Name = Con.TaxPaidtoVendor_Currency  
LEFT JOIN AcceleratedBalanceDetails A ON PC.R_ContractId = A.ContractId AND A.Status = 'Active'  
WHERE Include = 1  
GROUP BY TaxPaidtoVendor_Currency, C.Id,POC.Id  
  
UPDATE LRPC Set R_OriginalPOCId = LRP.Id  
 FROM stgLegalRelief LR  
 INNER JOIN stgActivity A ON LR.Id = A.Id  
 INNER JOIN stgLegalReliefProofOfClaim LRPC ON LR.Id = LRPC.LegalReliefId  
 INNER JOIN #CreatedLegalReliefProofOfClaims LRP ON UPPER(LRPC.OriginalPOCClaimNumber) = UPPER(LRP.ClaimNumber)  
 WHERE A.IsMigrated = 0 AND A.IsFailed = 0  
  
UPDATE LRP Set OriginalPOCId = LRPC.R_OriginalPOCId  
 FROM stgLegalReliefProofOfClaim LRPC   
 INNER JOIN LegalReliefProofOfClaims LRP ON UPPER(LRPC.ClaimNumber) = UPPER(LRP.ClaimNumber)
 
UPDATE LP Set R_LegalReliefId = LR.Id
	FROM stgAgencyLegalPlacement LP
	INNER JOIN LegalReliefs LR ON LP.LegalReliefRecordNumber = LR.LegalReliefRecordNumber
	WHERE LP.PlacementType = 'Legal' AND PlacementPurpose  IN ('Bankruptcy','Receivership')
  
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message) 
SELECT LR.Id,@ModuleIterationStatusId,'Invalid Original POC Claim Number' 
FROM stgLegalRelief LR INNER JOIN stgLegalReliefProofOfClaim POC ON LR.Id = POC.LegalReliefId 
WHERE OriginalPOCClaimNumber IS NOT NULL AND R_OriginalPOCId IS NULL  
  
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
SELECT Id,@ModuleIterationStatusId,'Incorrect Legal Relief Record Number'
FROM stgAgencyLegalPlacement
WHERE LegalReliefRecordNumber IS NOT NULL AND R_LegalReliefId IS NULL AND PlacementType = 'Legal' AND PlacementPurpose  IN ('Bankruptcy','Receivership') AND Status IN ('FirstPlacement','SecondPlacement','ThirdPlacement')
  
Update Activity Set [IsFailed] = 1  
FROM stgActivity Activity  
Join @ErrorLogs [Errors] On [Errors].StagingRootEntityId = Activity.[Id]  
  
--Placement Insertion  
MERGE [dbo].[AgencyLegalPlacements] As Placement  
USING(SELECT AgencyLegalPlacement.*,Activity.R_CustomerId  
FROM stgAgencyLegalPlacement AgencyLegalPlacement  
INNER JOIN stgActivity Activity ON Activity.Id = AgencyLegalPlacement.Id  
WHERE Activity.IsMigrated = 0 And Activity.[IsFailed]=0  
AND Activity.ActivityType IN ('AgencyPlacement','LegalPlacement')) As PlacementsToMigrate  
ON 1 = 0  
WHEN NOT MATCHED  
THEN  
INSERT  
    ([PlacementNumber]  
    ,[PlacementType]  
    ,[PlacementPurpose]  
    ,[DateOfPlacement]  
    ,[FeeStructure]  
    ,[Fee_Amount]  
    ,[Fee_Currency]  
    ,[ContingencyPercentage]  
    ,[AgencyFileNumber]  
    ,[Status]  
    ,[IsActive]  
    ,[CreatedById]  
    ,[CreatedTime]  
    ,[CustomerId]  
    ,[LegalReliefId]  
    ,[BusinessUnitId]  
 ,[VendorId]  
 )  
VALUES(  
 [PlacementNumber]  
 ,[PlacementType]  
 ,ISNULL([PlacementPurpose], '_')  
 ,[DateOfPlacement]  
 ,ISNULL([FeeStructure], '_')  
 ,ISNULL([Fee_Amount], 0.00)  
 ,[Fee_Currency]  
 ,ISNULL([ContingencyPercentage], 0.00)  
 ,[AgencyFileNumber]  
 ,[Status]  
 ,1  
 ,@UserId  
 ,@CreatedTime  
 ,[R_CustomerId]  
 ,[R_LegalReliefId]  
 ,(SELECT TOP 1 Id FROM BusinessUnits WHERE IsActive = 1 AND IsDefault = 1)  
 ,R_CollectionAgencyOrAttorneyNumberId)  
OUTPUT $ACTION, INSERTED.Id,PlacementsToMigrate.Id INTO #CreatedPlacement;  
  
INSERT INTO [dbo].[AgencyLegalPlacementContracts]  
           ([IsActive]  
           ,[FundsReceived_Amount]  
           ,[FundsReceived_Currency]  
           ,[CreatedById]  
           ,[CreatedTime]  
           ,[ContractId]  
           ,[AgencyLegalPlacementId])  
SELECT  
 1  
 ,0.00  
 ,C.GSTTaxPaidtoVendor_Currency  
 ,@UserId  
 ,@CreatedTime  
 ,ActivityContractDetail.R_ContractId  
 ,PlacementIds.Id  
FROM stgAgencyLegalPlacement Placement  
INNER JOIN stgActivity Activity ON Placement.Id = Activity.Id  
INNER JOIN stgActivityContractDetail ActivityContractDetail ON Activity.Id = ActivityContractDetail.ActivityId  
INNER JOIN Contracts C ON ActivityContractDetail.R_ContractId = C.Id  
INNER JOIN #CreatedPlacement PlacementIds ON Placement.Id = PlacementIds.ActivityId;  
  
---Update Funds Received  
WITH CTE_ContractDetails AS(  
SELECT ContractId,  
       DateOfPlacement,   
    ALPC.Id As AgencyLegalPlacementContractId  
FROM #CreatedPlacement PlacementIds   
INNER JOIN AgencyLegalPlacements ALP ON PlacementIds.Id = ALP.Id  
INNER JOIN AgencyLegalPlacementContracts ALPC ON ALP.Id = ALPC.AgencyLegalPlacementId  
WHERE ContractId IS NOT NULL AND ALP.IsActive = 1 AND ALPC.IsActive = 1)  
SELECT C.ContractId,  
       SUM(RARD.AmountApplied_Amount) + SUM(RARD.TaxApplied_Amount) AS FundsReceived,  
       C.AgencyLegalPlacementContractId  
INTO #FundsReceived  
FROM ReceiptApplicationReceivableDetails RARD  
INNER JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.ID  
INNER JOIN Receipts R ON RA.ReceiptId = R.Id  
INNER JOIN Receivabledetails RD ON RARD.ReceivabledetailId = RD.Id  
INNER JOIN Receivables Rec ON RD.ReceivableId = Rec.Id  
INNER JOIN CTE_ContractDetails C ON Rec.EntityId = C.ContractId  
INNER JOIN AgencyLegalPlacementContracts ALPC ON ALPC.ContractId = C.ContractId AND ALPC.IsActive = 1  
INNER JOIN #CreatedPlacement PlacementIds ON ALPC.AgencyLegalPlacementId = PlacementIds.Id  
WHERE R.PostDate >= C.DateOfPlacement AND  Rec.EntityType = 'CT' AND  
RARD.IsActive = 1  AND RD.IsActive =1 AND Rec.IsActive = 1 AND Rec.IsDummy = 0  
Group BY C.ContractId, C.AgencyLegalPlacementContractId  
  
UPDATE ALP    
SET FundsReceived_Amount = FR.FundsReceived,  
 AcceleratedBalanceDetailId = ABD.Id  
FROM #FundsReceived FR  
INNER JOIN AgencyLegalPlacementContracts ALP ON FR.ContractId = ALP.ContractId AND FR.AgencyLegalPlacementContractId = ALP.Id  
LEFT JOIN AcceleratedBalanceDetails ABD ON ABD.ContractId = ALP.ContractId  
  
INSERT INTO [dbo].[AgencyLegalPlacementAmounts]  
           ([Balance_Amount]  
           ,[Balance_Currency]  
           ,[FundsReceived_Amount]  
           ,[FundsReceived_Currency]  
           ,[IsActive]  
           ,[CreatedById]  
           ,[CreatedTime]  
           ,[CurrencyId]  
           ,[AgencyLegalPlacementId]  
     )  
SELECT   
     ISNULL(SUM(AB.Balance_Amount), 0)  
    ,ALPC.FundsReceived_Currency  
    ,SUM(ALPC.FundsReceived_Amount)  
    ,ALPC.FundsReceived_Currency  
    ,1  
    ,@UserId  
    ,@CreatedTime  
    ,C.Id  
    ,ALPC.AgencyLegalPlacementId  
FROM AgencyLegalPlacementContracts ALPC   
INNER JOIN #CreatedPlacement PlacementIds ON ALPC.AgencyLegalPlacementId = PlacementIds.Id  
INNER JOIN Currencies C ON ALPC.FundsReceived_Currency = C.Name  
LEFT JOIN AcceleratedBalanceDetails AB ON ALPC.AcceleratedBalanceDetailId = AB.Id   
WHERE ALPC.IsActive =1 AND C.IsActive = 1   
GROUP BY ALPC.AgencyLegalPlacementId,ALPC.FundsReceived_Currency,C.Id  
  
-- Update Legal Relief  
  
UPDATE LR SET PlacedwithOutsideCounsel = 1, Attorney = P.PartyName  
FROM stgActivity A  
INNER JOIN stgAgencyLegalPlacement LP ON A.Id = LP.Id  
INNER JOIN LegalReliefs LR ON LP.R_LegalReliefId = LR.Id  
INNER JOIN Parties P ON LP.CollectionAgencyNumberOrAttorneyNumber = P.PartyNumber AND P.CurrentRole = 'Vendor'   
WHERE R_LegalReliefId IS NOT NULL AND IsMigrated = 0 AND IsFailed = 0 AND LP.PlacementType = 'Legal' AND LP.PlacementPurpose = 'Bankruptcy'  

--Bulk copy to Target tables FROM Intermediate Table  
 MERGE Activities As Activity  
USING(SELECT * FROM stgActivity Activity Where Activity.IsMigrated = 0 And Activity.[IsFailed]=0) As ActivitiesToMigrate  
ON 1 = 0  
WHEN NOT MATCHED  
THEN  
INSERT  
    ([Name]  
    ,[Description]  
    ,[FollowUpDate]  
    ,[IsActive]  
    ,[CreatedById]  
    ,[CreatedTime]  
    ,[OwnerId]  
    ,[ActivityTypeId]  
    ,[StatusId]  
    ,[IsFollowUpRequired]  
    ,[OwnerGroupId]  
    ,[PortfolioId]  
    ,[CloseFollowUp]  
    ,[ClosingComments]  
 ,[DefaultPermission]  
 ,[EntityNaturalId]  
 ,[EntityId]  
 ,[CreatedDate]  
    ,[CompletionDate]  
 ,[InitiatedTransactionEntityId])  
VALUES  
    ([Name]  
    ,[Description]  
    ,[FollowUpDate]  
    ,1  
    ,@UserId  
    ,@CreatedTime  
    ,R_OwnerUserId  
    ,R_ActivityTypeId  
    ,R_StatusId  
    ,[IsFollowUpRequired]  
    ,R_OwnerGroupId  
    ,R_PortfolioId  
    ,[CloseFollowUp]  
    ,[ClosingComments]  
 ,'F'  
 ,CustomerNumber  
 ,R_CustomerId  
 ,[CreatedDate]  
    ,[CompletionDate]  
 ,0)  
OUTPUT $ACTION, INSERTED.Id,ActivitiesToMigrate.Id As ActivityId  INTO #CreatedActivities;  
  
INSERT INTO #CreatedEntity
SELECT * FROM #CreatedLegalRelief 
UNION
SELECT * FROM #CreatedPlacement 
  
UPDATE Activities SET InitiatedTransactionEntityId = Entity.Id  
FROM #CreatedEntity Entity  
INNER JOIN #CreatedActivities Activity ON Entity.ActivityId = Activity.ActivityId  
INNER JOIN Activities ON Activity.Id = Activities.Id;  
  
INSERT INTO [dbo].[ActivityForCustomers]  
           ([Id]  
           ,[IsCustomerContacted]  
           ,[ContactReference]  
           ,[CurrentChapter]  
           ,[CreatedById]  
           ,[CreatedTime]  
           ,[CustomerId]  
           ,[PersonContactedId]  
           ,[CurrencyId]  
     ,[PaymentMode]  
     ,[PaymentAmount_Amount]  
     ,[PaymentAmount_Currency]  
     ,[ReferenceInvoiceNumber]  
     ,[Chapter]  
     ,[Fee_Amount]  
     ,[Fee_Currency]  
     ,[TotalAmount_Amount]  
     ,[TotalAmount_Currency]  
     ,[LeaseTerminationOption]  
     ,[PaydownReason]  
     ,[PayoffAssetStatus]  
           )  
SELECT A.Id  
       ,Activity.IsCustomerContacted  
       ,Activity.ContactReference  
       ,'_'  
       ,@UserId  
       ,@CreatedTime  
       ,Activity.R_CustomerId  
       ,Activity.R_PersonContactId  
       ,Activity.R_CurrencyId  
    ,'_'  
    ,0.00  
    ,Activity.CurrencyCode  
    ,0  
    ,ISNULL(Activity.Chapter, '_')  
    ,0.00  
    ,Activity.CurrencyCode  
    ,0.00  
    ,Activity.CurrencyCode  
    ,'_'  
    ,'_'  
    ,'_'  
FROM stgActivity Activity  
INNER JOIN #CreatedActivities A ON Activity.Id = A.ActivityId  
  
INSERT INTO [dbo].[ActivityContractDetails]  
           ([IsActive]  
           ,[CreatedById]  
           ,[CreatedTime]  
           ,[ContractId]  
           ,[ActivityForCustomerId]  
           ,[TerminationReason]  
           ,[FullPayoff])  
SELECT 1  
   ,@UserId  
      ,@CreatedTime  
   ,R_ContractId  
   ,A.Id  
   ,'_'  
   ,0  
FROM stgActivityContractDetail ActivityContractDetail  
JOIN #CreatedActivities A ON ActivityContractDetail.ActivityId = A.ActivityId   
  
-- Legal Status Updation  
MERGE Customers As Customer  
USING(SELECT Activity.* , LegalRelief.FilingDate AssignmentDate  
FROM #CreatedLegalRelief ActivityIds  
INNER JOIN stgActivity Activity ON ActivityIds.ActivityId = Activity.Id AND IsMigrated = 0 AND IsFailed = 0
INNER JOIN stgLegalRelief LegalRelief ON Activity.Id = LegalRelief.Id AND (ActivityType = 'Bankruptcy' OR (ActivityType ='Receivership' AND LegalRelief.Status = 'Active'))) As Activity  
ON Customer.Id = Activity.R_CustomerId  
WHEN MATCHED  
THEN  
UPDATE SET LegalStatusId = Activity.R_LegalStatusId  
OUTPUT inserted.Id , inserted.LegalStatusId, ISNULL(Activity.AssignmentDate, GETDATE()), Activity.Id INTO #InsertedLegalStatus;  
  
SELECT CustomerId INTO #ExistingLegalStatusCustomers FROM #InsertedLegalStatus;  
  
MERGE Customers As Customer  
USING(SELECT Activity.* , AgencyLegalPlacement.DateOfPlacement AssignmentDate  
FROM #CreatedPlacement ActivityIds  
INNER JOIN stgActivity Activity ON ActivityIds.ActivityId = Activity.Id  
INNER JOIN stgAgencyLegalPlacement AgencyLegalPlacement ON Activity.Id = AgencyLegalPlacement.Id  
WHERE IsMigrated = 0 AND IsFailed = 0 AND R_CustomerId NOT IN (SELECT CustomerId FROM #ExistingLegalStatusCustomers)) As Activity  
ON Customer.Id = Activity.R_CustomerId  
WHEN MATCHED  
THEN  
UPDATE SET LegalStatusId = Activity.R_LegalStatusId  
OUTPUT inserted.Id , inserted.LegalStatusId, Activity.AssignmentDate, Activity.Id INTO #InsertedLegalStatus;  
  
-- Legal Status History Insertion  
  
INSERT INTO [dbo].[LegalStatusHistories]  
           ([AssignmentDate]  
           ,[IsActive]  
           ,[SourceModule]  
           ,[CreatedById]  
           ,[CreatedTime]  
           ,[LegalStatusId]  
           ,[CustomerId])  
SELECT AssignmentDate  
    ,1  
    ,'ActivityCenter'  
    ,@UserId  
    ,@CreatedTime  
    ,LegalStatusId  
    , CustomerId  
FROM #InsertedLegalStatus  
  
--Success Log Message  
INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message,Type)  
SELECT Activity.Id,@ModuleIterationStatusId,'Success','Information'  
FROM stgActivity Activity  
WHERE Id in (SELECT ActivityId FROM #CreatedActivities);  
  
exec [dbo].[CreateProcessingLog] @ErrorLogs,@UserId,@CreatedTime  
  
 --Updating the records as Migrated=True  
UPDATE Activity SET Activity.IsMigrated = 1  
FROM stgActivity Activity  
WHERE Id in ( SELECT ActivityId FROM #CreatedActivities);  
  
DROP TABLE #CreatedActivities;  
  
COMMIT TRANSACTION  
END TRY  
BEGIN CATCH  
 DECLARE @ErrorMessage Nvarchar(max);  
 DECLARE @ErrorLine Nvarchar(max);  
 DECLARE @ErrorSeverity INT;  
 DECLARE @ErrorState INT;  
 DECLARE @ErrorLog ErrorMessageList;  
 DECLARE @ModuleName Nvarchar(max) = 'MigrateActivities'  
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
Set @FailedRecords = (SELECT COUNT(DISTINCT StagingRootEntityId) FROM stgProcessingLog l  
inner join stgProcessingLogDetail lg on l.Id = lg.ProcessingLogId  
where Type = 'Error' AND  l.ModuleIterationStatusId = @ModuleIterationStatusId)  
SET XACT_ABORT OFF  
SET NOCOUNT OFF  
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateLocations]
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
SET XACT_ABORT ON

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
DECLARE @TaxSourceTypeNonVertex NVARCHAR(10);
DECLARE @SkipTaxAssessment NVARCHAR(10);
DECLARE @IsTaxSourceVertex NVARCHAR(10);

SET @TaxSourceTypeVertex = 'Vertex';
SET @TaxSourceTypeNonVertex = 'NonVertex';
Select @SkipTaxAssessment = ISNULL(Value,'False') From GlobalParameters Where Name = 'SkipTaxAssessment' AND Category = 'SalesTax'
Select @IsTaxSourceVertex = ISNULL(Value,'False') From GlobalParameters Where Name = 'IsTaxSourceVertex' AND Category = 'SalesTax'


IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
SET @FailedRecords = 0
SET @ProcessedRecords = 0
DECLARE @TakeCount INT = 50000
DECLARE @SkipCount INT = 0
DECLARE @MaxLocationId INT = 0
DECLARE @BatchCount INT = 0
DECLARE @Number INT = 0
DECLARE @SQL Nvarchar(max) =''		
	DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgLocation IntermediateLocation WHERE IsMigrated = 0)
	CREATE TABLE #ErrorLogs
		(
			Id BIGINT NOT NULL IDENTITY PRIMARY KEY,
			StagingRootEntityId BIGINT,
			Result NVARCHAR(10),
			Message NVARCHAR(MAX)
		)
    CREATE TABLE #FailedProcessingLogs
		(
			MergeAction NVARCHAR(20),
			InsertedId BIGINT,
			ErrorId BIGINT
		)
	WHILE @SkipCount < @TotalRecordsCount
	 BEGIN
	 BEGIN TRY
	 BEGIN TRANSACTION		
		CREATE TABLE #CreatedLocationIds
		(
			MergeAction NVARCHAR(20),
			InsertedId BIGINT,
			LocationId BIGINT,
		)
		CREATE TABLE #CreatedProcessingLogs
		(
			MergeAction NVARCHAR(20),
			InsertedId BIGINT
		)				
		CREATE TABLE #InsertedTaxExemptRuleIds
		(
			Id BIGINT,
			LocationId BIGINT
		)
		CREATE TABLE #JurisdictionIds
		(
			JurisdictionId BIGINT,
			JurisdictionDetailId BIGINT,
			LocationId BIGINT
		)
		SELECT 
			TOP(@TakeCount) * INTO #LocationSubset 
		FROM 
			stgLocation IntermediateLocation
		WHERE
			IntermediateLocation.Id > @MaxLocationId AND IntermediateLocation.IsMigrated = 0 
		ORDER BY 
			IntermediateLocation.Id
		SELECT 
		   IntermediateLocation.Id [LocationId]
		  ,Party.PartyNumber [PartyNumber]
		  ,IntermediateLocation.[Code]
		  ,IntermediateLocation.[Name]
		  ,IntermediateLocation.[AddressLine1]
		  ,IntermediateLocation.[AddressLine2]
		  ,IntermediateLocation.[Division]
		  ,IntermediateLocation.[City]
		  ,IntermediateLocation.[PostalCode]
		  ,State.ShortName [State]
		  ,Country.ShortName [Country]
		  ,IntermediateLocation.[Description]
		  ,IntermediateLocation.[TaxAreaVerifiedTillDate]
		  ,IsNull(IntermediateLocation.[TaxAreaId],0) TaxAreaId
		  ,IntermediateLocation.[IncludedPostalCodeInLocationLookup]
		  ,IntermediateLocation.[TaxBasisType]
		  ,IntermediateLocation.[UpfrontTaxMode]
		  ,0.0 As [CountryTaxExemptionRate]
		  ,0.0 As [StateTaxExemptionRate]
		  ,0.0 As [CountyTaxExemptionRate]
		  ,0.0 As [CityTaxExemptionRate]
		  ,IntermediateLocation.[IsMigrated]
		  ,IntermediateLocation.[PartyContactUniqueIdentifier]
		  ,IntermediateLocation.[AddressLine3]
		  ,IntermediateLocation.[Neighborhood]
		  ,IntermediateLocation.[SubdivisionOrMunicipality]
		  ,PartyContacts.Id [ContactPersonId]
		  ,PartyContacts.IsActive [ContactPersonStatus]
		  ,State.IsActive [StateIsActive]
		  ,State.Id [StateId]
		  ,Country.Id [CountryId]
		  ,Customer.Status [Status]
		  ,Customer.Id [CustomerId]
		  ,Country.IsPostalCodeMandatory [IsPostalCodeMandatory]
		  ,Portfolios.Id [PortfolioId]
		  ,CAST(CASE WHEN Country.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupported
		  ,Customer.TaxExemptRuleId [TaxExemptRuleId]
		  ,TaxExemptionReason.Id AS [TaxExemptionReasonId]
		  ,StateTaxExemptionReason.Id AS [StateTaxExemptionReasonId]
		  ,IntermediateLocation.[CountryExemptionNumber]
      	  ,IntermediateLocation.[StateExemptionNumber]
		  ,IntermediateLocation.[IsCountryTaxExempt]
		  ,IntermediateLocation.[IsStateTaxExempt]
		  ,IntermediateLocation.[IsCityTaxExempt]
		  ,IntermediateLocation.[IsCountyTaxExempt]
		  ,Vendor.Id [VendorId]
		  ,VendorAddress.Id [VendorAddressId]
		  ,IntermediateLocation.[VendorNumber]
		  ,IntermediateLocation.VendorAddressUniqueIdentifier
		  ,IntermediateLocation.VendorAddressCreatedDate
		  ,IntermediateLocation.Latitude
		  ,IntermediateLocation.Longitude
		   INTO #LocationsMappedWithTarget
		FROM 
			#LocationSubset IntermediateLocation
		LEFT JOIN Parties Party
			ON IntermediateLocation.PartyNumber = Party.PartyNumber
		LEFT JOIN Customers Customer
			ON Customer.Id = Party.Id
		LEFT JOIN Countries Country
			ON Country.ShortName = IntermediateLocation.Country
		LEFT JOIN States State
			ON State.ShortName = IntermediateLocation.State 
			   AND Country.Id = State.CountryId		
		LEFT JOIN PartyContacts 
			ON PartyContacts.UniqueIdentifier = IntermediateLocation.PartyContactUniqueIdentifier
		LEFT JOIN Portfolios
			ON Portfolios.Name = IntermediateLocation.PortfolioName
		LEFT JOIN TaxExemptionReasonConfigs TaxExemptionReason ON TaxExemptionReason.EntityType ='Location' AND TaxExemptionReason.Reason = IntermediateLocation.TaxExemptionReason
		LEFT JOIN TaxExemptionReasonConfigs StateTaxExemptionReason ON StateTaxExemptionReason.EntityType ='Location' AND StateTaxExemptionReason.Reason = IntermediateLocation.StateTaxExemptionReason
		LEFT JOIN Parties Vendor
			ON IntermediateLocation.VendorNumber = Vendor.PartyNumber
		LEFT JOIN PartyAddresses VendorAddress
			ON VendorAddress.UniqueIdentifier=IntermediateLocation.VendorAddressUniqueIdentifier AND VendorAddress.PartyId=Vendor.Id
		WHERE
			IntermediateLocation.Id > @MaxLocationId  
		ORDER BY 
			IntermediateLocation.Id
		SELECT @MaxLocationId = MAX(LocationId) FROM #LocationsMappedWithTarget;
		SELECT @BatchCount = ISNULL(COUNT(LocationId),0) FROM #LocationsMappedWithTarget;
		SELECT
			 IsCountryTaxExempt = CASE WHEN (location.IsVertexSupported = 1 AND TaxExemptRule.IsCountryTaxExempt IS NOT NULL) THEN TaxExemptRule.IsCountryTaxExempt ELSE location.IsCountryTaxExempt END
			,IsStateTaxExempt = CASE WHEN (location.IsVertexSupported = 1 AND TaxExemptRule.IsStateTaxExempt IS NOT NULL) THEN TaxExemptRule.IsStateTaxExempt ELSE location.IsStateTaxExempt END
			,IsCityTaxExempt = CASE WHEN (location.IsVertexSupported = 1 AND TaxExemptRule.IsCityTaxExempt IS NOT NULL) THEN TaxExemptRule.IsCityTaxExempt ELSE location.IsCityTaxExempt END
			,IsCountyTaxExempt = CASE WHEN (location.IsVertexSupported = 1 AND TaxExemptRule.IsCountyTaxExempt IS NOT NULL) THEN TaxExemptRule.IsCountyTaxExempt ELSE location.IsCountyTaxExempt END
			,TaxExemptionReasonId = CASE WHEN (location.IsVertexSupported = 1  AND  LocationTaxExemptionReason.Id IS NOT NULL) THEN LocationTaxExemptionReason.Id ELSE location.TaxExemptionReasonId END
			,StateTaxExemptionReasonId = CASE WHEN (location.IsVertexSupported = 1 AND LocationStateTaxExemptionReason.Id IS NOT NULL) THEN LocationStateTaxExemptionReason.Id ELSE location.StateTaxExemptionReasonId END
			,CountryExemptionNumber = CASE WHEN location.IsVertexSupported = 1 THEN NULL ELSE location.CountryExemptionNumber END
			,StateExemptionNumber = CASE WHEN location.IsVertexSupported = 1 THEN NULL ELSE location.StateExemptionNumber END 
			,location.LocationId AS [LocationId]
			,location.[Code]
		INTO #TaxExemptDetails
		FROM #LocationsMappedWithTarget location
		LEFT JOIN TaxExemptRules TaxExemptRule ON location.TaxExemptRuleId = TaxExemptRule.Id
		LEFT JOIN TaxExemptionReasonConfigs CustomerTaxExemptionReason ON TaxExemptRule.TaxExemptionReasonId = CustomerTaxExemptionReason.Id
		LEFT JOIN TaxExemptionReasonConfigs LocationTaxExemptionReason ON LocationTaxExemptionReason.EntityType ='Location' AND LocationTaxExemptionReason.Reason = CustomerTaxExemptionReason.Reason
		LEFT JOIN TaxExemptionReasonConfigs CustomerStateTaxExemptionReason ON TaxExemptRule.StateTaxExemptionReasonId = CustomerStateTaxExemptionReason.Id
		LEFT JOIN TaxExemptionReasonConfigs LocationStateTaxExemptionReason ON LocationStateTaxExemptionReason.EntityType ='Location' AND LocationStateTaxExemptionReason.Reason = CustomerStateTaxExemptionReason.Reason
		INSERT INTO #ErrorLogs
		SELECT
		   Location.LocationId
		  ,'Error'
		  ,('The State does not belong to the Country for Location Code :'+location.Code) AS Message
		FROM 
			#LocationsMappedWithTarget location 
		where location.StateId is null
		INSERT INTO #ErrorLogs
		SELECT
		   Location.LocationId
		  ,'Error'
		  ,('The Customer does not have a TaxExemptRule for IsVertexSupported = 1 for Location Code :'+location.Code) AS Message
		FROM 
			#LocationsMappedWithTarget location 
		LEFT JOIN #TaxExemptDetails ON #TaxExemptDetails.LocationId = location.LocationId
		WHERE 
			#TaxExemptDetails.LocationId IS NULL AND location.IsVertexSupported = 1
		INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('The Combination of Location Code :'+#LocationsMappedWithTarget.Code + ' and CustomerId :'+ CONVERT(NVARCHAR(10), #LocationsMappedWithTarget.CustomerId )+ ' must be unique.' ) AS Message
		FROM 
			#LocationsMappedWithTarget 
		LEFT JOIN Locations ON Locations.Code = #LocationsMappedWithTarget.Code
			      AND Locations.CustomerId = #LocationsMappedWithTarget.CustomerId
		WHERE 
			Locations.Code IS NOT NULL 
		INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('Contact Person was not found for Location: ' + #LocationsMappedWithTarget.Code + 'With filter ' + CONVERT(NVARCHAR(10),PartyContactUniqueIdentifier)) AS Message
		FROM 
			#LocationsMappedWithTarget
		WHERE
			 PartyContactUniqueIdentifier IS NOT NULL AND ContactPersonId IS NULL
	   INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('Vendor Address  was not found with Unique Identifier: ' + #LocationsMappedWithTarget.VendorAddressUniqueIdentifier + ' and vendor # :' + CONVERT(NVARCHAR(10),ISNULL(VendorNumber,'NULL'))) AS Message
		FROM 
			#LocationsMappedWithTarget
		WHERE
			 VendorAddressUniqueIdentifier IS NOT NULL AND VendorAddressId IS NULL
		 INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('Vendor was not found with Vendor # :' + #LocationsMappedWithTarget.VendorNumber) AS Message
		FROM 
			#LocationsMappedWithTarget
		WHERE
			 VendorNumber IS NOT NULL AND VendorId IS NULL
		INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('Selected Contact Person must be Active for Location : ' + #LocationsMappedWithTarget.Code) AS Message
		FROM 
			#LocationsMappedWithTarget
		WHERE
			 ContactPersonStatus IS NOT NULL AND ContactPersonStatus <> 1
		INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('Selected State must be Active for Location : ' + #LocationsMappedWithTarget.Code) AS Message
		FROM 
			#LocationsMappedWithTarget
		WHERE
			 StateIsActive = 0
		INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('Selected Customer status must be Active or Pending for Location : ' + #LocationsMappedWithTarget.Code) AS Message
		FROM 
			#LocationsMappedWithTarget
		WHERE
			 CustomerId IS NOT NULL AND Status != 'Active' AND Status != 'Pending'
		INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('Postal Code is required for Location : ' + #LocationsMappedWithTarget.Code) AS Message
		FROM 
			#LocationsMappedWithTarget
		WHERE
			 IsPostalCodeMandatory = 1 AND PostalCode IS NULL AND (Latitude IS NULL AND Longitude IS NULL)
		INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('Invalid Portfolio Name for Location : ' + #LocationsMappedWithTarget.Code) AS Message
		FROM 
			#LocationsMappedWithTarget
		WHERE
			 PortfolioId IS NULL
		INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('Invalid Country Exception Reason for Location : ' + #TaxExemptDetails.Code) AS Message
		FROM 
			#TaxExemptDetails
		WHERE
			 IsCountryTaxExempt = 1 AND TaxExemptionReasonId IS NULL
		INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('Invalid State Exemption Reason for Location : ' + #TaxExemptDetails.Code) AS Message
		FROM 
			#TaxExemptDetails
		WHERE
			IsStateTaxExempt = 1 AND StateTaxExemptionReasonId IS NULL
        INSERT INTO #ErrorLogs
		SELECT
		   LocationId
		  ,'Error'
		  ,('VendorAddressCreated Date is not provided for Location : ' + #LocationsMappedWithTarget.Code) AS Message
		FROM 
			#LocationsMappedWithTarget
		WHERE
			 VendorId IS NOT NULL AND  VendorAddressId IS NOT NULL AND  VendorAddressCreatedDate IS NULL
		INSERT INTO #JurisdictionIds SELECT distinct Null,Null,L.LocationId
		FROM #LocationsMappedWithTarget L 
		--NonVertex
		UPDATE #JurisdictionIds  
		SET JurisdictionId = J.Id,
			JurisdictionDetailId = CASE WHEN JD.PostalCode = L.PostalCode  AND L.IncludedPostalCodeInLocationLookup = 1 THEN JD.ID 
			ELSE NULL END			 
		FROM #JurisdictionIds 
		JOIN #LocationsMappedWithTarget L ON #JurisdictionIds.LocationId=L.LocationId
		JOIN  States S on L.State = S.ShortName
		JOIN Countries C on S.CountryId = C.Id and L.Country = C.ShortName
		JOIN Cities city on L.City = city.Name
		left JOIN Counties division on L.Division = division.Name
		LEFT JOIN Jurisdictions J on J.CityId = city.Id and J.CountyId = division.Id 
		and J.stateId = S.Id and J.CountryId = C.Id and J.IsActive=1
		LEFT JOIN JurisdictionDetails JD on JD.JurisdictionId = J.Id 
		and JD.PostalCode = L.PostalCode 
		and JD.IsActive = 1
		where c.TaxSourceType = @TaxSourceTypeNonVertex
		;WITH CTE_JurisdictionDetail AS
		(
		  Select J.ID JusridictionId,Max(JD.ID) JurisdictionDetailId from Jurisdictions J 
		  LEFT JOIN JurisdictionDetails JD on JD.JurisdictionId = J.Id and JD.IsActive = 1 and J.IsActive=1
		  JOIN #JurisdictionIds #J on #J.JurisdictionId = J.ID
		  Where #J.JurisdictionDetailId is NULL
		  group by J.ID
		)
		UPDATE #JurisdictionIds  SET JurisdictionDetailId = cte.JurisdictionDetailId 
		FROM #JurisdictionIds J 
		JOIN CTE_JurisdictionDetail cte ON J.JurisdictionId = cte.JusridictionId
		WHERE J.JurisdictionDetailId IS NULL
		INSERT INTO #ErrorLogs
		SELECT
		   L.LocationId
		  ,'Error'
		  ,('No Jurisdiction found with combination [ Division, City, State, Country ] : [ ' + ISNULL(L.Division, 'NULL') +', '+ ISNULL(L.city, 'NULL') +', '+ ISNULL(L.State, 'NULL') +', '+ ISNULL(L.Country, 'NULL') +' ] for Location : ' + L.Code) AS Message
		FROM 
		#LocationsMappedWithTarget L		
		LEFT JOIN #JurisdictionIds J on J.LocationId = L.LocationId
		LEFT JOIN Countries c on c.Id = L.CountryId
		WHERE @SkipTaxAssessment = 'False'
			 AND (@IsTaxSourceVertex = 'False' OR (l.IsVertexSupported = 0))
			 AND ISNULL(c.TaxSourceType,'Vertex') != 'VAT'
			 AND J.JurisdictionId IS NULL 
	    INSERT INTO #ErrorLogs
		SELECT
		   L.LocationId
		  ,'Error'
		  ,('TaxAreaId is required for Vertex supported Location  [ Location Code ]: [' + L.Code + ' ]') AS Message
		FROM 
		#LocationsMappedWithTarget L		
		WHERE @SkipTaxAssessment = 'False' And @IsTaxSourceVertex = 'True' And
		l.IsVertexSupported = 1 and ( l.TaxAreaId = 0 or l.TaxAreaId IS NULL or l.TaxAreaId = '')
        INSERT INTO #ErrorLogs
		SELECT
		   l.LocationId
		  ,'Error'
		  ,('The UpFront Tax Mode: '+l.UpfrontTaxMode+' ,is Invalid for the Following TaxBasisType: '+l.TaxBasisType+' ,for the Location :'+l.Code) AS Message
		FROM 
			 #LocationsMappedWithTarget l
			 where l.TaxBasisType='ST' and l.UpfrontTaxMode!='None'
	    INSERT INTO #ErrorLogs
		SELECT
		   l.LocationId
		  ,'Error'
		  ,('The UpFront Tax Mode: '+l.UpfrontTaxMode+' ,is Invalid for the Following TaxBasisType: '+l.TaxBasisType+' ,for the Location :'+l.Code) AS Message
		FROM 
			 #LocationsMappedWithTarget l
			 where (l.TaxBasisType='UC' OR l.TaxBasisType='UR') and (l.UpfrontTaxMode ='None' OR l.UpfrontTaxMode='_') 		

	    INSERT INTO #ErrorLogs
		SELECT
		   L.LocationId
		  ,'Error'
		  ,('Coordinates can be used only for Vertex Supported Location Creation [ Location Code ]: [' + L.Code + ' ]') AS Message
		FROM 
		#LocationsMappedWithTarget L
		WHERE (l.Latitude IS NOT NULL OR l.Longitude IS NOT NULL )
		AND l.IsVertexSupported = 0

	    INSERT INTO #ErrorLogs
		SELECT
		   L.LocationId
		  ,'Error'
		  ,('Latitude is required for given Longitude [ Location Code ]: [' + L.Code + ' ]') AS Message
		FROM 
		#LocationsMappedWithTarget L
		WHERE l.Latitude IS NULL AND l.Longitude IS NOT NULL
		
	    INSERT INTO #ErrorLogs
		SELECT
		   L.LocationId
		  ,'Error'
		  ,('Longitude is required for given Latitude [ Location Code ]: [' + L.Code + ' ]') AS Message
		FROM 
		#LocationsMappedWithTarget L
		WHERE l.Latitude IS NOT NULL AND l.Longitude IS  NULL

		INSERT INTO #ErrorLogs
		SELECT 
			L.LocationId
			,'Error'
			,('AddressLine1 is required for Location [Location code]: ['+L.Code+']') AS Message
		FROM #LocationsMappedWithTarget L
		WHERE l.Longitude IS  NULL AND l.Longitude IS  NULL AND l.AddressLine1 IS NULL

		 INSERT INTO #ErrorLogs
		SELECT
		   l.LocationId
		  ,'Error'
		  ,('The Tax Basis Type: '+ISNULL(l.TaxBasisType,' ')+' ,is Invalid for the Following Location : '+l.Code) AS Message
		FROM 
			 #LocationsMappedWithTarget l
			 where l.IsVertexSupported = 0 and (l.TaxBasisType ='None' OR l.TaxBasisType='_' OR l.TaxBasisType IS NULL) 
			 AND (Select name from GlobalParameters where name = 'IsTaxSourceVertex' AND value = 'False' AND Category = 'SalesTax') IS NOT NULL


		MERGE INTO TaxExemptRules
		USING (SELECT TaxExemptDetail.*,StagingRootEntityId
			   FROM  #LocationsMappedWithTarget location
			   INNER JOIN #TaxExemptDetails TaxExemptDetail ON location.LocationId = TaxExemptDetail.LocationId 
			   LEFT JOIN #ErrorLogs ON location.LocationId = #ErrorLogs.StagingRootEntityId
		WHERE location.[LocationId] IS NOT NULL) AS AE
		ON 1 = 0
		WHEN NOT MATCHED AND AE.StagingRootEntityId IS NULL THEN
		INSERT
			([EntityType]
			,[IsCountryTaxExempt]
			,[IsStateTaxExempt]
			,[IsCityTaxExempt]
			,[IsCountyTaxExempt]
			,[CreatedById]
			,[CreatedTime]
			,[TaxExemptionReasonId]
			,[StateTaxExemptionReasonId]
			,[CountryExemptionNumber]
			,[StateExemptionNumber])
		VALUES
			('Location'
			,IsCountryTaxExempt
			,IsStateTaxExempt
			,IsCityTaxExempt
			,IsCountyTaxExempt
			,@UserId
			,@CreatedTime
			,TaxExemptionReasonId
			,StateTaxExemptionReasonId
			,CountryExemptionNumber
			,StateExemptionNumber)
			OUTPUT inserted.Id,AE.LocationId INTO #InsertedTaxExemptRuleIds;
		MERGE Locations AS Location
		USING (SELECT
				#LocationsMappedWithTarget.* , #ErrorLogs.StagingRootEntityId,Tax.Id AS TaxId,J.JurisdictionId JurisdictionId , J.JurisdictionDetailId JurisdictionDetailId
			   FROM
				#LocationsMappedWithTarget
				LEFT JOIN #InsertedTaxExemptRuleIds Tax ON #LocationsMappedWithTarget.LocationId = Tax.LocationId
				LEFT JOIN #JurisdictionIds J on #LocationsMappedWithTarget.LocationId = J.LocationId
			   LEFT JOIN #ErrorLogs
					  ON #LocationsMappedWithTarget.LocationId = #ErrorLogs.StagingRootEntityId) AS LocationsToMigrate
		ON (Location.Code = LocationsToMigrate.[Code] AND Location.CustomerId = LocationsToMigrate.CustomerId)
		WHEN MATCHED AND LocationsToMigrate.StagingRootEntityId IS NULL THEN
			UPDATE SET Location.Code = LocationsToMigrate.Code
		WHEN NOT MATCHED AND LocationsToMigrate.StagingRootEntityId IS NULL
		THEN
			INSERT
           ([Code]
           ,[Name]
           ,[AddressLine1]
           ,[AddressLine2]
           ,[Division]
           ,[City]
           ,[PostalCode]
           ,[Description]
           ,[TaxAreaVerifiedTillDate]
           ,[IsActive]
           ,[TaxAreaId]
           ,[ApprovalStatus]
           ,[IncludedPostalCodeInLocationLookup]
           ,[TaxBasisType]
           ,[UpfrontTaxMode]
           ,[CountryTaxExemptionRate]
           ,[StateTaxExemptionRate]
           ,[DivisionTaxExemptionRate]
           ,[CityTaxExemptionRate]
		   ,[AddressLine3]
		   ,[Neighborhood]
		   ,[SubdivisionOrMunicipality]
           ,[CreatedById]
           ,[CreatedTime]
           ,[UpdatedById]
           ,[UpdatedTime]
           ,[CustomerId]
           ,[StateId]
           ,[JurisdictionId]
		   ,[ContactPersonId]
		   ,[TaxExemptRuleId]
		   ,[PortfolioId]
		   ,[JurisdictionDetailId]
		   ,[VendorId]
		   ,[Latitude]
		   ,[Longitude])
     VALUES
           (LocationsToMigrate.Code
           ,LocationsToMigrate.Name
           ,LocationsToMigrate.AddressLine1
           ,LocationsToMigrate.AddressLine2
		   ,LocationsToMigrate.Division
           ,LocationsToMigrate.City           
           ,LocationsToMigrate.PostalCode
		   ,LocationsToMigrate.Description
		   ,LocationsToMigrate.TaxAreaVerifiedTillDate		   
           ,1     
		   ,CASE WHEN LocationsToMigrate.IsVertexSupported = 0 THEN 0 ELSE LocationsToMigrate.TaxAreaId END     --TaxAreaId   
           ,'Approved'
           ,LocationsToMigrate.IncludedPostalCodeInLocationLookup
           ,LocationsToMigrate.TaxBasisType
           ,ISNULL(LocationsToMigrate.UpfrontTaxMode,'_')
           ,LocationsToMigrate.CountryTaxExemptionRate
           ,LocationsToMigrate.StateTaxExemptionRate
           ,LocationsToMigrate.CountyTaxExemptionRate
           ,LocationsToMigrate.CityTaxExemptionRate
		   ,LocationsToMigrate.AddressLine3
		   ,LocationsToMigrate.Neighborhood
		   ,LocationsToMigrate.SubdivisionOrMunicipality
		   ,@UserId
           ,@CreatedTime
           ,NULL
		   ,NULL
           ,LocationsToMigrate.CustomerId
           ,LocationsToMigrate.StateId
           ,CASE WHEN LocationsToMigrate.IsVertexSupported = 0 THEN LocationsToMigrate.JurisdictionId ELSE NULL END
		   ,LocationsToMigrate.ContactPersonId
		   ,LocationsToMigrate.TaxId
		   ,LocationsToMigrate.PortfolioId
		   ,CASE WHEN LocationsToMigrate.IsVertexSupported = 0 THEN LocationsToMigrate.JurisdictionDetailId ELSE NULL END
		   ,LocationsToMigrate.VendorId
		   ,LocationsToMigrate.Latitude
		   ,LocationsToMigrate.Longitude)
		OUTPUT $action, Inserted.Id, LocationsToMigrate.LocationId INTO #CreatedLocationIds;
		UPDATE stgLocation SET IsMigrated = 1 WHERE Id IN (SELECT LocationId FROM #CreatedLocationIds)
		INSERT INTO LocationTaxAreaHistories
			 (
				TaxAreaId
				,TaxAreaEffectiveDate
				,CreatedById
				,CreatedTime
				,UpdatedById
				,UpdatedTime
				,LocationId
			 )
		SELECT
				LocationMappedWithTarget.TaxAreaId
				,LocationMappedWithTarget.TaxAreaVerifiedTillDate
				,@UserId
				,@CreatedTime
				,NULL
				,NULL
				,CreatedLocation.InsertedId
		FROM #CreatedLocationIds CreatedLocation
			 INNER JOIN #LocationsMappedWithTarget LocationMappedWithTarget ON CreatedLocation.LocationId = LocationMappedWithTarget.LocationId
		INSERT INTO VendorLocationHistories
			 (
				CreatedDate
				,LocationId
				,PartyAddressId
				,VendorId
				,CreatedById
				,CreatedTime
				,UpdatedById
				,UpdatedTime
				,IsActive
			 )
		SELECT
				 LocationMappedWithTarget.VendorAddressCreatedDate
				,CreatedLocation.InsertedId
				,LocationMappedWithTarget.VendorAddressId
				,LocationMappedWithTarget.VendorId
				,@UserId
				,@CreatedTime
				,NULL
				,NULL
				,1
		FROM #CreatedLocationIds CreatedLocation
			 INNER JOIN #LocationsMappedWithTarget LocationMappedWithTarget ON CreatedLocation.LocationId = LocationMappedWithTarget.LocationId
			 Where LocationMappedWithTarget.VendorId IS NOT NULL AND LocationMappedWithTarget.VendorAddressId IS NOT NULL
			 AND LocationMappedWithTarget.VendorAddressCreatedDate IS NOT NULL
		MERGE stgProcessingLog AS ProcessingLog
		USING (SELECT
				LocationId
			   FROM
				#CreatedLocationIds
			  ) AS ProcessedLocations
		ON (ProcessingLog.StagingRootEntityId = ProcessedLocations.LocationId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime
		WHEN NOT MATCHED THEN
		INSERT
			(
				StagingRootEntityId
			   ,CreatedById
			   ,CreatedTime
			   ,ModuleIterationStatusId
			)
		VALUES
			(
				ProcessedLocations.LocationId
			   ,@UserId
			   ,@CreatedTime
			   ,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;
		INSERT INTO 
			stgProcessingLogDetail
			(
				Message
			   ,Type
			   ,CreatedById
			   ,CreatedTime	
			   ,ProcessingLogId
			)
		SELECT
		    'Successful'
		   ,'Information'
		   ,@UserId
		   ,@CreatedTime
		   ,InsertedId
		FROM
			#CreatedProcessingLogs
	IF EXISTS(SELECT LocationId FROM #CreatedLocationIds)
	BEGIN
	SET @Number = (SELECT MAX(LocationId) FROM #CreatedLocationIds)
	SET @SQL = 'ALTER SEQUENCE Location RESTART WITH ' + CONVERT(NVARCHAR(20),@Number+1)
	EXEC sp_executesql @sql
	END
	SET @SkipCount = @SkipCount + @TakeCount
MERGE stgProcessingLog AS ProcessingLog
		USING (SELECT
				 DISTINCT StagingRootEntityId
			   FROM
				#ErrorLogs 
			  ) AS ErrorLocations
		ON (ProcessingLog.StagingRootEntityId = ErrorLocations.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime
		WHEN NOT MATCHED THEN
		INSERT
			(
				StagingRootEntityId
			   ,CreatedById
			   ,CreatedTime
			   ,ModuleIterationStatusId
			)
		VALUES
			(
				ErrorLocations.StagingRootEntityId
			   ,@UserId
			   ,@CreatedTime
			   ,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id,ErrorLocations.StagingRootEntityId INTO #FailedProcessingLogs;	
		DECLARE @TotalRecordsFailed INT = (SELECT  COUNT( DISTINCT InsertedId) FROM #FailedProcessingLogs)
		INSERT INTO 
			stgProcessingLogDetail
			(
				Message
			   ,Type
			   ,CreatedById
			   ,CreatedTime	
			   ,ProcessingLogId
			)
		SELECT
		    #ErrorLogs.Message
		   ,#ErrorLogs.Result
		   ,@UserId
		   ,@CreatedTime
		   ,#FailedProcessingLogs.InsertedId
		FROM
			#ErrorLogs
		INNER JOIN #FailedProcessingLogs
				ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.ErrorId
	SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogs)
	DELETE #FailedProcessingLogs
	DELETE #ErrorLogs
COMMIT TRANSACTION
    DROP TABLE #CreatedLocationIds
    DROP TABLE #LocationSubset
    DROP TABLE #LocationsMappedWithTarget
    DROP TABLE #CreatedProcessingLogs
    DROP TABLE #InsertedTaxExemptRuleIds
	DROP TABLE #JurisdictionIds
	DROP TABLE #TaxExemptDetails
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'LocationMigration'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords+@BatchCount;
	END;  
	IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END;  
END CATCH
END 
  	SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount
	SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogs)
	DROP TABLE #ErrorLogs	
	DROP TABLE #FailedProcessingLogs	
SET NOCOUNT OFF
SET XACT_ABORT OFF
END

GO

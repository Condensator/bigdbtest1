SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[MigrateCustomerLocations]
(
@UserId BIGINT,
@ModuleIterationStatusId BIGINT,
@CreatedTime  DATETIMEOFFSET,
@ProcessedRecords BIGINT  OUTPUT,
@FailedRecords BIGINT OUTPUT
)
AS
BEGIN
	SET XACT_ABORT ON

	SET NOCOUNT ON

	DECLARE @ErrorLogs ErrorMessageList

	-- Update Target Ids in Intermediate table
	DECLARE @Module VARCHAR(50) = NULL

	SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)

	EXEC ResetStagingTempFields @Module , NULL

	CREATE TABLE #CustomerLocationTemp
	(
		CustomerLocationId  BIGINT,
		TaxBasisType		NVARCHAR(30),
		ContractId			BIGINT,
		UpfrontTaxAssessedInLegacySystem BIT
	)

	UPDATE stgCustomerLocation  SET IsFailed=0  WHERE IsMigrated = 0
		SET @ProcessedRecords =ISNULL(@@rowCount,0)

	UPDATE CustomerLocation
		SET CustomerLocation.R_CustomerId = Parties.Id
	FROM stgCustomerLocation CustomerLocation
	JOIN Parties ON CustomerLocation.CustomerPartyNumber = Parties.PartyNumber
	WHERE CustomerLocation.IsMigrated = 0 AND CustomerLocation.IsFailed = 0

	UPDATE CustomerLocation
		SET CustomerLocation.R_LocationId = Locations.Id, CustomerLocation.R_LocationCustomerId = Locations.CustomerId
	FROM stgCustomerLocation CustomerLocation
	JOIN Locations ON CustomerLocation.LocationCode = Locations.Code
	WHERE CustomerLocation.IsMigrated = 0 AND CustomerLocation.IsFailed = 0

	UPDATE CustomerLocation
		SET CustomerLocation.R_ContractId = Contracts.Id
	FROM stgCustomerLocation CustomerLocation
	JOIN Contracts ON CustomerLocation.SequenceNumber = Contracts.SequenceNumber
	WHERE CustomerLocation.IsMigrated = 0 AND CustomerLocation.IsFailed = 0

	-- Validation
	Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
	SELECT CustomerLocation.Id,@ModuleIterationStatusId,'Customer Party Number is invalid or does not exist'
	FROM stgCustomerLocation CustomerLocation
	WHERE CustomerLocation.IsMigrated = 0 AND CustomerLocation.IsFailed = 0
	AND CustomerLocation.R_CustomerId IS NULL

	Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
	SELECT CustomerLocation.Id,@ModuleIterationStatusId,'Location code is invalid or does not exist'
	FROM stgCustomerLocation CustomerLocation
	WHERE CustomerLocation.IsMigrated = 0 AND CustomerLocation.IsMigrated = 0
	AND CustomerLocation.R_LocationId IS NULL

	Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
	SELECT CustomerLocation.Id,@ModuleIterationStatusId,'Customer associated to Location code should be same as of customer or without any customer'
	FROM stgCustomerLocation CustomerLocation
	WHERE CustomerLocation.IsMigrated = 0 AND CustomerLocation.IsMigrated = 0
	AND CustomerLocation.R_LocationCustomerId IS NOT NULL
	AND CustomerLocation.R_LocationCustomerId <> CustomerLocation.R_CustomerId

	INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
	SELECT CustomerLocation.Id, @ModuleIterationStatusId, ('There must be only one current location for a Customer(' + CONVERT(NVARCHAR, CustomerLocation.CustomerPartyNumber) + ')')
	FROM stgCustomerLocation CustomerLocation
	JOIN (SELECT MAX(CustomerLocation.CustomerPartyNumber) AS CustomerPartyNumber
	FROM stgCustomerLocation CustomerLocation
	WHERE
	CustomerLocation.IsMigrated = 0 AND CustomerLocation.IsCurrent = 1
	GROUP BY CustomerLocation.R_CustomerId
	HAVING COUNT(CustomerLocation.Id) > 1) AS TempCustomerLocation
	ON CustomerLocation.CustomerPartyNumber = TempCustomerLocation.CustomerPartyNumber
	WHERE CustomerLocation.IsMigrated = 0 AND IsFailed = 0

	Insert into @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message)
	SELECT CustomerLocation.Id,@ModuleIterationStatusId,'Contract Sequence Number is invalid or does not exist'
	FROM stgCustomerLocation CustomerLocation
	WHERE CustomerLocation.IsMigrated = 0 AND CustomerLocation.IsFailed = 0
	AND CustomerLocation.R_ContractId IS NULL AND CustomerLocation.SequenceNumber IS NOT NULL

	BEGIN TRY
	BEGIN TRANSACTION;

		EXEC [dbo].[CreateProcessingLog] @ErrorLogs,@UserId,@CreatedTime
		UPDATE stgCustomerLocation 
			SET [IsFailed] = 1
		From stgCustomerLocation CustomerLocation
		JOIN @ErrorLogs [Errors] On [Errors].StagingRootEntityId = CustomerLocation.[Id]
		DELETE FROM @ErrorLogs


		MERGE CustomerLocations 
			USING(Select * FROM stgCustomerLocation WHERE IsMigrated = 0 AND IsFailed = 0) AS CustomersLocationToMigrate
        ON 1=0  
        WHEN NOT MATCHED 
        THEN  
		INSERT 
		(EffectiveFromDate
		,IsCurrent
		,UpfrontTaxMode
		,TaxBasisType
		,IsActive
		,CreatedById
		,CreatedTime
		,LocationId
		,CustomerId)
		VALUES
		(
			 CustomersLocationToMigrate.EffectiveFromDate
			,CustomersLocationToMigrate.IsCurrent
			,CustomersLocationToMigrate.UpfrontTaxMode
			,CustomersLocationToMigrate.TaxBasisType
			,1
			,@UserId
			,@CreatedTime
			,CustomersLocationToMigrate.R_LocationId
			,CustomersLocationToMigrate.R_CustomerId
		)
		OUTPUT INSERTED.Id AS CustomerLocationId, INSERTED.TaxBasisType, CustomersLocationToMigrate.R_ContractId AS ContractId,
		CustomersLocationToMigrate.UpfrontTaxAssessedInLegacySystem INTO #CustomerLocationTemp
		;

		INSERT INTO ContractCustomerLocations(
			 TaxBasisType
			,UpfrontTaxAssessedInLegacySystem
			,CustomerLocationId
			,ContractId
			,CreatedById
			,CreatedTime
		)
		SELECT
			 TaxBasisType
			,UpfrontTaxAssessedInLegacySystem
			,CustomerLocationId
			,ContractId
			,@UserId
			,@CreatedTime
		FROM #CustomerLocationTemp
		WHERE TaxBasisType IS NOT NULL AND ContractId IS NOT NULL

		INSERT INTO @ErrorLogs(StagingRootEntityId,ModuleIterationStatusId,Message,Type)
		SELECT CustomerLocation.Id,@ModuleIterationStatusId,'Success','Information'
		FROM stgCustomerLocation CustomerLocation
		JOIN CustomerLocations TargetCustomerLocation
		ON TargetCustomerLocation.CustomerId = CustomerLocation.R_CustomerId
		AND TargetCustomerLocation.LocationId = CustomerLocation.R_LocationId
		WHERE
		CustomerLocation.IsMigrated = 0
		AND CustomerLocation.[IsFailed]=0
		EXEC [dbo].[CreateProcessingLog] @ErrorLogs,@UserId,@CreatedTime
		DELETE FROM @ErrorLogs
		UPDATE
		CustomerLocation
		SET CustomerLocation.IsMigrated = 1
		FROM stgCustomerLocation CustomerLocation
		JOIN CustomerLocations TargetCustomerLocation
		ON TargetCustomerLocation.CustomerId = CustomerLocation.R_CustomerId
		AND TargetCustomerLocation.LocationId = CustomerLocation.R_LocationId
		WHERE CustomerLocation.IsMigrated = 0 AND CustomerLocation.IsFailed = 0
	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage Nvarchar(max);
		DECLARE @ErrorLine Nvarchar(max);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		DECLARE @ErrorLog ErrorMessageList;
		DECLARE @ModuleName Nvarchar(max) = 'MigrateCustomerLocations'
		Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
		SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
		IF (XACT_STATE()) = -1
		BEGIN
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		set @FailedRecords = @FailedRecords+@ProcessedRecords;
		END;
		IF (XACT_STATE()) = 1
		BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);
		END;
	END CATCH
	SELECT @FailedRecords = COUNT(Distinct StagingRootEntityId) From @ErrorLogs
	SET NOCOUNT OFF
	SET XACT_ABORT OFF
END

GO

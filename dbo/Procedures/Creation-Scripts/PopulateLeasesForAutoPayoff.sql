SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PopulateLeasesForAutoPayoff]
(
@JobStepInstanceId BIGINT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@EntityType NVARCHAR(30),
@FilterOption NVARCHAR(10),
@CustomerId BIGINT NULL,
@ContractId BIGINT NULL,
@LegalEntityIds LegalEntityIdsForAutoPayoff READONLY,
@AllFilterOption NVARCHAR(10),
@OneFilterOption NVARCHAR(10),
@CustomerEntityType NVARCHAR(15),
@LeaseEntityType NVARCHAR(10),
@SystemDate DATE,
@MaturityDateOption NVARCHAR(18),
@LastPaymentDueDateOption NVARCHAR(18),
@ReceiptPostedStatus NVARCHAR(6),
@ReceiptLeaseEntityType NVARCHAR(10),
@ReceiptCustomerEntityType NVARCHAR(10),
@CommencedBookingStatus NVARCHAR(10),
@FixedTermPaymentType NVARCHAR(10),
@OTPPaymentType NVARCHAR(10),
@SupplementPaymentType NVARCHAR(10),
@PurchaseContractOption NVARCHAR(10),
@MaturityMonitorResponse NVARCHAR(25),
@MaturityMonitorStatus NVARCHAR(10),
@PayoffInactiveStatus NVARCHAR(30),
@PayoffReversedStatus NVARCHAR(30)
)
AS
BEGIN	
	SET NOCOUNT ON	
	DECLARE @True BIT = 1
	DECLARE @False BIT = 0
	DECLARE @AutoPayoffTemplateCursor CURSOR
	DECLARE @AutoPayoffTemplateParameterCursor CURSOR
	DECLARE @AutoPayoffTemplateId BIGINT
	DECLARE @PayoffTemplateId BIGINT
	DECLARE @ParameterDetailId BIGINT
	DECLARE @ParameterConfigQualificationQuery NVARCHAR(200)		
	DECLARE @ThresholdDaysOption NVARCHAR(18) 
	DECLARE @ThresholdDays BIGINT
	DECLARE @ContractEPO BIT = 0
	DECLARE @ContractIds AS ContractIdsForAutoPayoff	
	DECLARE @FilteredContracts AS ContractIdsForAutoPayoff
	DECLARE @ActivePayoffTemplateLOBs BIGINT
	CREATE TABLE #AutopayoffEnums ([Name] NVARCHAR(100),[Value] NVARCHAR(100));
	INSERT INTO #AutopayoffEnums 
	(
		[Name],
		[Value]
	) 
    VALUES 
		('MaturityDateOption', @MaturityDateOption),
		('LastPaymentDueDateOption', @LastPaymentDueDateOption),
		('ReceiptPostedStatus', @ReceiptPostedStatus),
		('ReceiptLeaseEntityType', @ReceiptLeaseEntityType),
		('ReceiptCustomerEntityType', @ReceiptCustomerEntityType),
		('MaturityMonitorResponse', @MaturityMonitorResponse),
		('MaturityMonitorStatus', @MaturityMonitorStatus)	
	SELECT 
		Contracts.Id AS ContractId,			
		LegalEntityId = LeaseFinances.LegalEntityId,
		LeaseFinances.Id LeaseFinanceId,
		LeaseFinanceDetails.MaturityDate,
		CASE
			WHEN PP.Value = 'True'
				THEN BU.CurrentBusinessDate
			WHEN PP.Value ='False'  
				THEN @SystemDate
		END AS ComputedCurrentBusinessDate
	INTO #QualifiedContracts
	FROM 
		LeaseFinances
		INNER JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
		INNER JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
		INNER JOIN @LegalEntityIds legalEntity ON LeaseFinances.LegalEntityId = legalEntity.Id
		INNER JOIN LegalEntities LE ON LeaseFinances.LegalEntityId = LE.Id
		INNER JOIN BusinessUnits BU ON LE.BusinessUnitId = BU.Id
		INNER JOIN Portfolios P ON BU.PortfolioId = P.Id
		INNER JOIN PortfolioParameters PP ON P.Id = PP.PortfolioId
		INNER JOIN PortfolioParameterConfigs PPC ON PP.PortfolioParameterConfigId = PPC.Id 
			AND PPC.Name = 'IsBusinessDateApplicable' 
			AND PPC.Category = 'BusinessUnit'
		WHERE 
		LeaseFinances.IsCurrent = @True 		
		AND LeaseFinances.BookingStatus = @CommencedBookingStatus	
		AND Contracts.BackgroundProcessingPending = @False
		AND (
				@FilterOption = @AllFilterOption
				OR (
					@EntityType = @CustomerEntityType
					AND @FilterOption = @OneFilterOption
					AND LeaseFinances.CustomerId = @CustomerId
					)
				OR (
					@EntityType = @LeaseEntityType
					AND @FilterOption = @OneFilterOption
					AND Contracts.Id = @ContractId
					)
				)

	SELECT
		#QualifiedContracts.ContractId,
		Payoffs.AutoPayoffTemplateId 
	INTO #ContractPayoffQuotes
	FROM
		Payoffs
		INNER JOIN LeaseFinances ON Payoffs.LeaseFinanceId = LeaseFinances.Id
		INNER JOIN #QualifiedContracts ON LeaseFinances.ContractId = #QualifiedContracts.ContractId
	WHERE
		Payoffs.Status <> @PayoffInactiveStatus
		AND Payoffs.Status <>  @PayoffReversedStatus
	SELECT 
		LeaseFinanceId INTO #ContractsWithEPOs
	FROM
		(SELECT
			LeaseContractOptions.LeaseFinanceId,
			ROW_NUMBER() OVER (PARTITION BY LeaseContractOptions.LeaseFinanceId ORDER BY LeaseContractOptions.OptionDate,LeaseContractOptions.Id DESC) RowNumber
		FROM
			LeaseContractOptions
		INNER JOIN #QualifiedContracts
			ON LeaseContractOptions.LeaseFinanceId = #QualifiedContracts.LeaseFinanceId
		WHERE
			LeaseContractOptions.ContractOption = @PurchaseContractOption AND
			LeaseContractOptions.IsActive = @True AND
			LeaseContractOptions.IsEarly = @True AND
			LeaseContractOptions.OptionDate IS NOT NULL AND
			LeaseContractOptions.OptionDate <= #QualifiedContracts.MaturityDate) AS LeaseCOP
	WHERE 
		LeaseCOP.RowNumber = 1
		SELECT 
			APT.Id, 
			APT.PayoffTemplateId,
			APT.ThresholdDaysOption,
			APT.ThresholdDays,
			COUNT(PayOffTemplateLOBs.Id) ActiveLOBs INTO #QualifiedAutoPayoffTemplates
		FROM 
			AutoPayoffTemplates APT
		INNER JOIN PayOffTemplates
			ON APT.PayoffTemplateId = PayOffTemplates.Id
		LEFT JOIN PayOffTemplateLOBs
			ON PayOffTemplates.Id = PayOffTemplateLOBs.PayOffTemplateId AND
			   PayOffTemplateLOBs.IsActive = @True
		WHERE 
			APT.IsActive = @True
		GROUP BY 
			APT.Id, 
			APT.PayoffTemplateId,
			APT.ThresholdDaysOption,
			APT.ThresholdDays	
	SET @AutoPayoffTemplateCursor = CURSOR FOR 
		SELECT 
			Id, 
			PayoffTemplateId,
			ThresholdDaysOption,
			ThresholdDays,
			ActiveLOBs
		FROM 
			#QualifiedAutoPayoffTemplates
    OPEN @AutoPayoffTemplateCursor 
		FETCH NEXT FROM @AutoPayoffTemplateCursor 
		INTO @AutoPayoffTemplateId,
			@PayoffTemplateId,
			@ThresholdDaysOption,
			@ThresholdDays,
			@ActivePayoffTemplateLOBs
    WHILE @@FETCH_STATUS = 0
    BEGIN		      
		INSERT INTO @FilteredContracts 
		(
			Id
		)
		SELECT 
			AL.ContractId 
			FROM #QualifiedContracts AL
				JOIN Contracts C ON C.Id = AL.ContractId
				JOIN PayOffTemplates PT ON PT.Id = @PayoffTemplateId
				JOIN LeaseFinances LF ON AL.ContractId = LF.ContractId 
					AND IsCurrent = @True
				JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id AND LFD.IsFloatRateLease = PT.ApplicableforFloatRateContract 
				JOIN LeasePaymentSchedules LPS ON LFD.Id = LPS.LeaseFinanceDetailId 
					AND LFD.NumberOfPayments = LPS.PaymentNumber
				LEFT JOIN PayOffTemplateLOBs PTLOB ON C.LineofBusinessId = PTLOB.LineofBusinessId 
					AND PTLOB.PayOffTemplateId = PT.Id 
					AND PTLOB.IsActive = @TRUE
				LEFT JOIN #ContractsWithEPOs
					ON LF.Id = #ContractsWithEPOs.LeaseFinanceId
				INNER JOIN AutoPayoffTemplateLegalEntities APTLE ON AL.LegalEntityId  = APTLE.LegalEntityId
					AND APTLE.IsActive = @True 
					AND APTLE.AutoPayoffTemplateId = @AutoPayoffTemplateId
				LEFT JOIN #ContractPayoffQuotes ON C.Id = #ContractPayoffQuotes.ContractId 
					AND #ContractPayoffQuotes.AutoPayoffTemplateId = @AutoPayoffTemplateId
			WHERE 
				(PT.IsEPOApplicable = @False OR ((PT.IsApplicableWhenEPOAvailable = @True AND #ContractsWithEPOs.LeaseFinanceId IS NOT NULL) OR (PT.IsApplicableWhenEPOAvailable = @False AND #ContractsWithEPOs.LeaseFinanceId IS NULL)))
				AND LPS.IsActive = @True 
				AND LPS.PaymentType = @FixedTermPaymentType
				AND 
				(
					(@ThresholdDaysOption = @MaturityDateOption 
						AND (DATEADD(DAY, -@ThresholdDays, LFD.MaturityDate) <= AL.ComputedCurrentBusinessDate))
					OR
					(@ThresholdDaysOption = @LastPaymentDueDateOption 
						AND DATEADD(DAY, -@ThresholdDays, LPS.DueDate) <= AL.ComputedCurrentBusinessDate) 
					OR
					@ThresholdDaysOption = '_'
				)
				AND (PT.FRRApplicable = @False OR PT.FRROption = C.FirstRightOfRefusal)
				AND #ContractPayoffQuotes.ContractId IS NULL
				AND (PTLOB.Id IS NOT NULL OR @ActivePayoffTemplateLOBs = 0)
		   SELECT 
				APTPD.Id,
				APTPC.QualificationQuery INTO #QualifiedParameterDetails
			FROM 
				AutoPayoffTemplateParameterDetails APTPD 
				JOIN AutoPayoffTemplateParameterConfigs APTPC ON APTPD.ParameterId = APTPC.Id
			WHERE APTPD.AutoPayoffTemplateId = @AutoPayoffTemplateId AND APTPD.IsActive = @True
			ORDER BY APTPC.[Order] ASC 
		SET @AutoPayoffTemplateParameterCursor = CURSOR FOR 
			SELECT 
				Id,
				QualificationQuery 
			FROM 
				#QualifiedParameterDetails
		OPEN @AutoPayoffTemplateParameterCursor 
			FETCH NEXT FROM @AutoPayoffTemplateParameterCursor 
			INTO @ParameterDetailId,
				 @ParameterConfigQualificationQuery
		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO @ContractIds
				EXEC @ParameterConfigQualificationQuery 
					@InputContractIds = @FilteredContracts,
					@ParameterDetailId = @ParameterDetailId
			DELETE FROM @FilteredContracts					
			INSERT INTO @FilteredContracts (Id)
				SELECT 
					Id 
				FROM 
					@ContractIds
			DELETE FROM @ContractIds
			FETCH NEXT FROM @AutoPayoffTemplateParameterCursor 
				INTO @ParameterDetailId, 
					@ParameterConfigQualificationQuery
		END;		
		INSERT INTO AutoPayoffContracts 
		(
			JobStepInstanceId,
			IsProcessed,
			IsActive,
			AutoPayoffTemplateId,
			ContractId,
			CreatedById,
			CreatedTime,
			PayoffEffectiveDate
		)
		SELECT @JobStepInstanceId,
				@False,
				@True,
				@AutoPayoffTemplateId,
				Id,
				@CreatedById,
				@CreatedTime,
				QC.MaturityDate
		FROM 
			@FilteredContracts FC
		JOIN #QualifiedContracts QC ON FC.Id = QC.ContractId
		DELETE FROM @FilteredContracts
		DROP TABLE #QualifiedParameterDetails
		CLOSE @AutoPayoffTemplateParameterCursor ;
		DEALLOCATE @AutoPayoffTemplateParameterCursor;		
		FETCH NEXT FROM @AutoPayoffTemplateCursor
			INTO @AutoPayoffTemplateId,
				@PayoffTemplateId,
				@ThresholdDaysOption,
				@ThresholdDays,
				@ActivePayoffTemplateLOBs
    END;	
	SELECT 
		APC.ContractId,
		MIN(APT.Id) AutoPayoffTemplateId
	INTO #PayoffQuotesToActivate
	FROM 
		AutoPayoffContracts APC
		INNER JOIN AutoPayoffTemplates APT ON APC.AutoPayoffTemplateId = APT.Id
	WHERE APC.IsActive = @True 
		AND APT.ActivatePayoffQuote = @True
		AND APC.JobStepInstanceId = @JobStepInstanceId
	GROUP BY APC.ContractId
	UPDATE AutoPayoffContracts 
	SET IsActive = @False 
	FROM 
		AutoPayoffContracts APC
		JOIN #PayoffQuotesToActivate ON APC.ContractId = #PayoffQuotesToActivate.ContractId 
			AND APC.AutoPayoffTemplateId <> #PayoffQuotesToActivate.AutoPayoffTemplateId 
			AND APC.JobStepInstanceId = @JobStepInstanceId
    CLOSE @AutoPayoffTemplateCursor ;
    DEALLOCATE @AutoPayoffTemplateCursor;	
	DROP TABLE #AutopayoffEnums	
	DROP TABLE #QualifiedContracts
	DROP TABLE #ContractPayoffQuotes
	DROP TABLE #PayoffQuotesToActivate
    DROP TABLE #ContractsWithEPOs
	SET NOCOUNT OFF
END

GO

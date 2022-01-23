SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetLeaseDetailsForCustomerService]
(	
 	@CustomerNumber nvarchar(50),
	@UserId BIGINT,
	@Yes NVARCHAR(10),
	@No NVARCHAR(10),
	@AccessibleLegalEntities NVARCHAR(MAX)
)
AS
SET NOCOUNT ON
BEGIN

	DECLARE @CustomerId bigint
	CREATE TABLE #CapitalizedForContract (ContractId BIGINT,CapitalizeCost DECIMAL(16,2));
	CREATE TABLE #NetInvestmentForContract (ContractId BIGINT,NBV DECIMAL(16,2));
	CREATE TABLE #LessorNBVForContract (ContractId BIGINT,LessorNBV DECIMAL(16,2));
	CREATE TABLE #PrimaryAndSecondaryCollectorForContract (ContractId BIGINT,PrimaryCollector NVARCHAR(MAX));
	
	SET @CustomerId = (Select Id From Parties With (NoLock) where PartyNumber =  @CustomerNumber)
	SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',')

	SELECT c.Id ContractId INTO #ValidContractIds
	FROM LeaseFinances lf
	INNER JOIN Contracts c ON lf.ContractId = c.Id
		AND lf.IsCurrent=1 AND lf.CustomerId = @CustomerId AND c.IsConfidential = 0 

	INSERT INTO #ValidContractIds	
	SELECT C.[Id] ContractId FROM [dbo].[Contracts] AS C
	INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON C.[Id] = EAC.[ContractId]
	INNER JOIN [dbo].[EmployeesAssignedToParties] AS EACU ON EAC.[EmployeeAssignedToPartyId] = EACU.[Id]
	WHERE EACU.[EmployeeId] = @UserId AND C.[IsConfidential] = 1  AND EACU.PartyId = @CustomerId

	INSERT INTO #ValidContractIds	
	SELECT CAH.ContractId FROM ContractAssumptionHistories CAH
	INNER JOIN Assumptions A ON A.Id = CAH.AssumptionId AND CAH.CustomerId = @CustomerId
	GROUP BY CAH.ContractId

	SELECT LF.ContractId, LF.Id LeaseFinanceId INTO #Contracts
	FROM #ValidContractIds vc 
	INNER JOIN LeaseFinances as LF ON vc.ContractId = LF.ContractId 
	JOIN #AccessibleLegalEntityIds ALE ON LF.LegalEntityId = ALE.Id
	INNER JOIN LeasefinanceDetails AS LFD ON LF.Id = LFD.Id AND LF.IsCurrent = 1

    SELECT 
	    CASE WHEN LFD.InterimRentBillingType = 'Capitalize' THEN 
		  CASE WHEN LFD.CreateSoftAssetsForInterimRent = 1 and LA.CapitalizationType = 'CapitalizedInterimRent' THEN 
			 SUM(LA.NBV_Amount) 
		  ELSE 
			 SUM(LA.CapitalizedInterimRent_Amount) 
		  END 
	    ELSE 
		    0 
	    END CapitalizeCost
	    ,c.ContractId
	INTO #CapitalizedCost
    FROM dbo.#Contracts c  
    INNER JOIN LeasefinanceDetails AS LFD ON c.LeaseFinanceId = LFD.Id
    INNER JOIN LeaseAssets AS LA ON c.LeaseFinanceId = LA.LeaseFinanceId AND LA.IsActive = 1
    GROUP BY c.ContractId,LFD.InterimRentBillingType,LFD.CreateSoftAssetsForInterimRent,LA.CapitalizationType

	INSERT INTO #CapitalizedForContract(CapitalizeCost,ContractId) 
		SELECT SUM(a.CapitalizeCost) CapitalizeCost ,a.ContractId FROM #CapitalizedCost as a GROUP BY a.ContractId
		
    SELECT CASE WHEN LFD.InterimRentBillingType = 'Capitalize' and LFD.CreateSoftAssetsForInterimRent =  0 THEN 
	   SUM(LA.NBV_Amount) - SUM(ISNULL(CapContract.CapitalizeCost,0))
    ELSE SUM(LA.NBV_Amount) 
    END NetInvestment,
	c.ContractId
	INTO #NBV
    FROM dbo.#Contracts c  
    INNER JOIN LeasefinanceDetails AS LFD ON c.LeaseFinanceId = LFD.Id
    INNER JOIN LeaseAssets AS LA  ON c.LeaseFinanceId = LA.LeaseFinanceId AND LA.IsActive = 1 AND LA.CapitalizationType = '_'
    LEFT JOIN #CapitalizedForContract AS CapContract ON c.ContractId = CapContract.ContractId 
    GROUP BY c.ContractId ,LFD.InterimRentBillingType  ,LFD.CreateSoftAssetsForInterimRent

	INSERT INTO #NetInvestmentForContract(NBV,ContractId) 
		SELECT SUM(c.NetInvestment) NetInvestment ,c.ContractId FROM #NBV  as c GROUP BY c.ContractId
	
	SELECT 
	c.ContractId,
	PrimaryCollector.FullName [PrimaryCollector]
	INTO #CollectionDetails
	FROM #Contracts c
	INNER JOIN CollectionWorkListContractDetails ON c.ContractId = CollectionWorkListContractDetails.ContractId
	INNER JOIN CollectionWorkLists ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
	INNER JOIN Users [PrimaryCollector] ON CollectionWorkLists.PrimaryCollectorId = PrimaryCollector.Id
	WHERE CollectionWorkLists.Status = 'Open' 
	AND CollectionWorkLists.CustomerId = @CustomerId

	INSERT INTO #PrimaryAndSecondaryCollectorForContract(ContractId,PrimaryCollector)
	SELECT #CollectionDetails.ContractId,PrimaryCollector
	FROM #CollectionDetails
	INNER JOIN  LeaseFinances AS LF 
		ON #CollectionDetails.ContractId = LF.ContractId
		AND LF.IsCurrent = 1

	INSERT INTO #LessorNBVForContract(LessorNBV,ContractId)
		SELECT 
		   SUM(LFD.Markup_Amount) + SUM(ISNULL(NBVContract.NBV,0)) + SUM(ISNULL(CapContract.CapitalizeCost,0)) as NetInvestment
		   ,c.ContractId
		FROM dbo.#Contracts c  
		INNER JOIN LeaseFinanceDetails AS LFD 
		   ON c.LeaseFinanceId = LFD.Id 
		LEFT JOIN #NetInvestmentForContract AS NBVContract
		   ON c.ContractId = NBVContract.ContractId
		LEFT JOIN #CapitalizedForContract AS CapContract 
		   ON c.ContractId = CapContract.ContractId
	GROUP BY c.ContractId

	SELECT MIN(serdtl.Id) ServicingDetailId , LF.Id LFId
	INTO #ContractOriginationServices
	FROM  Leasefinances lf
	JOIN dbo.#Contracts c ON lf.Id = c.LeaseFinanceId
	JOIN ContractOriginations cntorg   on LF.ContractOriginationId = cntorg.Id
	LEFT JOIN ContractOriginationServicingDetails cntorgser ON cntorg.id=cntorgser.ContractOriginationId
	LEFT JOIN ServicingDetails serdtl ON cntorgser.ServicingDetailId=serdtl.id   AND serdtl.IsActive=1
	GROUP BY LF.Id

	SELECT DISTINCT    
		C.SequenceNumber as SequenceNumber ,     
		C.Alias as Alias ,      
		LE.Name as LegalEntityName  ,    
		LOB.Name as LineOfBusiness  ,    
		LeaseF.BookingStatus as Status ,    
		DPT.Name as ProductType  ,    
		LessorNBVContract.LessorNBV as NetInvestment ,    
		LeaseFD.CustomerExpectedResidual_Amount as ResidualValue ,    
		LeaseFD.TermInMonths as Term ,    
		Cast(0 as decimal(16,2)) as RemainingTerm ,    
		LeaseFD.CommencementDate as CommencementDate ,    
		LeaseFD.MaturityDate as MaturityDate ,    
		LeaseFD.PaymentFrequency as Frequency,    
		LeaseFD.IsAdvance as ADVorARR ,    
		CS.Name as CollectionStatus ,    
		CASE WHEN  C.IsNonAccrual = 0 THEN @Yes ELSE @No END as IsAccrual ,    
		c.Id as ContractId ,      
		CurrCod.ISO as Currency,    
		C.SyndicationType ,    
		PS.PrimaryCollector ,
		ISNULL(ccd.OverallDPD,0) as OverallDPD  ,  
		ISNULL(ServicingDetails.IsnonNotification,0) as IsNonNotification
	FROM dbo.#Contracts ct
	INNER JOIN Contracts C ON ct.ContractId = C.Id
	INNER JOIN LeaseFinances LeaseF ON c.Id = LeaseF.ContractId AND LeaseF.IsCurrent = 1 
	INNER JOIN  LeaseFinanceDetails LeaseFD ON LeaseF.Id = LeaseFD.Id    
	INNER JOIN Customers Cus  ON LeaseF.CustomerId = Cus.Id    
	INNER JOIN LegalEntities LE  ON LeaseF.LegalEntityId = LE.Id     
	INNER JOIN  LineofBusinesses LOB ON C.LineofBusinessId = LOB.Id    
	INNER JOIN  Currencies cur ON C.CurrencyId = cur.Id     
	INNER JOIN CurrencyCodes CurrCod  ON cur.CurrencyCodeId = CurrCod.Id    
	LEFT JOIN ContractCollectionDetails ccd on ccd.ContractId = C.Id
	LEFT JOIN CollectionStatus CS ON CS.Id = Cus.CollectionStatusId 
	LEFT JOIN #LessorNBVForContract as LessorNBVContract ON LessorNBVContract.ContractId = C.Id    
	LEFT JOIN #PrimaryAndSecondaryCollectorForContract PS ON PS.ContractId = C.Id    
	LEFT JOIN DealProductTypes DPT ON C.DealProductTypeId = DPT.Id    
	LEFT JOIN #ContractOriginationServices T on LeaseF.Id = T.LFId
	LEFT JOIN ServicingDetails on T.ServicingDetailId = ServicingDetails.Id

	DROP TABLE #ContractOriginationServices,#Contracts

END

GO

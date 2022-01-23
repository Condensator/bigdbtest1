SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetTaxRatesForNonVertex](
     @TaxLocationIdentifier TaxLocationIdentifier READONLY,
	 @IsCountryTaxExemptAtContract BIT ,
	 @IsStateTaxExemptAtContract BIT ,
	 @IsCountyTaxExemptAtContract BIT ,
	 @IsCityTaxExemptAtContract BIT,
	 @CountryJurisdictionLevel NVARCHAR(8),
	 @CountyJurisdictionLevel NVARCHAR(7),
	 @CityJurisdictionLevel NVARCHAR(5),
	 @StateJurisdictionLevel NVARCHAR(6),
	 @ReceivableTypeId BIGINT)
AS
     BEGIN
	 SET NOCOUNT ON

				
			SELECT s.Id AS StateId,
				   c.Id AS CountryId,
				   city.Id AS CityId,
				   county.Id AS CountyId,
				   td.LineItemNumber AS [LineItemNumber],
				   td.DueDate,
				   td.LocationId,
				   loc.TaxBasisType,
				   loc.UpfrontTaxMode,
				   td.StateTaxtypeId,
				   td.CityTaxTypeId,
				   td.CountyTaxTypeId,
				   c.ShortName,
				   td.IsCountryTaxExempt,
				   td.IsStateTaxExempt,
				   td.IsCountyTaxExempt,
				   td.IsCityTaxExempt
			INTO #LocationMapping
			FROM dbo.Jurisdictions AS l
				  INNER JOIN @TaxLocationIdentifier AS td ON l.Id = td.JurisdictionId
				  INNER JOIN dbo.Locations AS Loc ON td.LocationId = Loc.Id
				  INNER JOIN dbo.States AS s ON l.StateId = s.Id
				  INNER JOIN dbo.Countries AS c ON l.CountryId = c.Id
				  INNER JOIN dbo.Cities AS city ON l.CityId = city.Id
				  INNER JOIN dbo.Counties AS county ON l.CountyId = county.Id
				;
				

			 SELECT DISTINCT
				 tr.Id AS TaxRateId,
				 lm.DueDate,
				 tr.TaxImpositionTypeId,
				 j.Id JurisdictionId,
				 tit.TaxJurisdictionLevel JurisdictionLevel,
				 tit.Name ImpositionType,
				 tt.Name TaxType,
				 lm.IsCountryTaxExempt,
				 lm.IsCountyTaxExempt,
				 lm.IsCityTaxExempt,
				 lm.IsStateTaxExempt,
				 lm.[LineItemNumber],
				 lm.TaxBasisType,
				 lm.UpfrontTaxMode,
				 tt.Id TaxTypeId,
				 lm.StateTaxtypeId,
				 lm.CityTaxTypeId,
				 lm.CountyTaxTypeId,
				 lm.ShortName CountryShortName,
				 DTRT.TaxTypeId DefaultTaxTypeId,
				 tit.TaxTypeId ImpositionTaxTypeId
			 INTO #ConsolidatedTaxRates
			 FROM #LocationMapping AS lm
			 INNER JOIN dbo.TaxImpositionTypes AS tit ON lm.CountryId = tit.CountryId AND tit.IsActive = 1 
			 INNER JOIN dbo.TaxTypes AS tt ON tit.TaxTypeId = tt.Id
			 INNER JOIN dbo.TaxRates AS tr ON tit.Id = tr.TaxImpositionTypeId AND tr.IsActive = 1
			 INNER JOIN dbo.DefaultTaxTypeForReceivableTypes DTRT ON DTRT.CountryId = lm.CountryId AND (@ReceivableTypeId is null or @ReceivableTypeId =0 or DTRT.ReceivableTypeId = @ReceivableTypeId)
			 INNER JOIN 
						(SELECT DISTINCT Id ,JurisdictionId 
							FROM (SELECT 
									trh.JurisdictionId, trh.Id CityLevel,trh2.Id CountryLevel,trh3.Id StateLevel,trh4.Id CountyLevel
								   FROM	  (SELECT j.Id JurisdictionId, t.Id,t.CountryId,t.StateId,t.CityId,t.CountyId FROM dbo.Jurisdictions j
								  INNER JOIN  dbo.TaxRateHeaders AS t ON j.TaxRateHeaderId = t.Id WHERE t.IsActive = 1) trh
								  INNER JOIN dbo.TaxRateHeaders trh2 ON trh.CountryId = trh2.CountryId AND trh2.CityId IS NULL AND trh2.StateId IS NULL  AND trh2.CountyId IS NULL AND trh2.IsActive = 1 
								  INNER JOIN dbo.TaxRateHeaders trh3 ON trh.StateId = trh3.StateId AND trh.CountryId = trh3.CountryId  AND trh3.CityId IS NULL  AND trh3.CountyId IS NULL AND trh3.IsActive = 1
								  INNER JOIN dbo.TaxRateHeaders trh4 ON trh.CountyId = trh4.CountyId AND trh4.CityId IS NULL AND trh.StateId = trh4.StateId AND trh4.CountryId = trh.CountryId AND  trh4.IsActive = 1
								   ) AS T
							  UNPIVOT ( ID FOR Ids IN (CityLevel,CountryLevel,StateLevel,CountyLevel)) AS UP
						   ) AS trh ON tr.TaxRateHeaderId = trh.Id 
							AND tr.Id = ANY (SELECT TaxRateId FROM TaxRateDetails 
							WHERE IsActive = 1 AND TaxRateId = tr.Id)
		      INNER JOIN dbo.Jurisdictions AS j ON trh.JurisdictionId = j.Id AND j.IsActive = 1
			  AND lm.CountryId = j.CountryId AND j.StateId = lm.StateId AND j.CityId = lm.CityId
			  AND j.CountyId = lm.CountyId AND tit.CountryId = lm.CountryId AND j.CountryId = lm.CountryId
			  ;

			  SELECT 
				ctr.[LineItemNumber],
				 CASE WHEN (@IsCountryTaxExemptAtContract = 1 AND ctr.JurisdictionLevel = @CountryJurisdictionLevel ) OR (@IsStateTaxExemptAtContract  = 1 AND ctr.JurisdictionLevel = @StateJurisdictionLevel )  OR
					       (@IsCountyTaxExemptAtContract  = 1 AND ctr.JurisdictionLevel = @CountyJurisdictionLevel ) OR (@IsCityTaxExemptAtContract  = 1 AND ctr.JurisdictionLevel = @CityJurisdictionLevel ) OR 
						   (CTR.JurisdictionLevel = @CountryJurisdictionLevel  AND CTR.IsCountryTaxExempt = 1) OR (CTR.JurisdictionLevel = @StateJurisdictionLevel  AND CTR.IsStateTaxExempt = 1) OR 
			  			   (CTR.JurisdictionLevel = @CityJurisdictionLevel AND CTR.IsCityTaxExempt = 1) OR (CTR.JurisdictionLevel = @CountyJurisdictionLevel AND CTR.IsCountyTaxExempt = 1)THEN 
								CAST(ISNULL(T.Rate,0) AS DECIMAL(12,10))
				ELSE T.Rate END EffectiveRate,
			  	ctr.TaxBasisType,
			  	ctr.UpfrontTaxMode,
			  	ctr.JurisdictionLevel,
				ctr.ImpositionType,
				ctr.TaxType
			  INTO #TaxRates
			  FROM #ConsolidatedTaxRates AS ctr
			  	LEFT JOIN (select RANK() OVER ( PARTITION BY T.[LineItemNumber],T.JurisdictionLevel ORDER BY T.EffectiveDate ,T.Id DESC )filter,* from  ( 
			  	SELECT RANK() OVER ( PARTITION BY ctrtemp.[LineItemNumber],ctrtemp.JurisdictionLevel ORDER BY trd.EffectiveDate DESC , trd.Id DESC )rank, 
			  	trd.*,ctrtemp.[LineItemNumber],ctrtemp.JurisdictionLevel, ctrtemp.impositiontype,
			  	ctrtemp.TaxTypeId
			  			  FROM dbo.TaxRateDetails AS trd
			  				INNER JOIN #ConsolidatedTaxRates ctrtemp ON trd.TaxRateId = ctrtemp.TaxRateId
			  					 AND trd.EffectiveDate <= ctrtemp.DueDate
			  					 AND trd.IsActive = 1
			  					 AND (((ctrtemp.JurisdictionLevel = @CountyJurisdictionLevel  AND ((ctrtemp.TaxTypeId = ctrtemp.CountyTaxTypeId) OR 
			  					 	  (ctrtemp.CountyTaxTypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
			  					 	OR ((ctrtemp.JurisdictionLevel = @StateJurisdictionLevel  AND ((ctrtemp.TaxTypeId = ctrtemp.StateTaxtypeId) OR
			  					 		 ctrtemp.StateTaxtypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
								 	OR ((ctrtemp.JurisdictionLevel = @CityJurisdictionLevel  AND ((ctrtemp.TaxTypeId = ctrtemp.CityTaxTypeId) OR
			  					 		 ctrtemp.CityTaxTypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
			  					 	)
			  					 	OR ctrtemp.CountryShortName <> 'USA')
			  
			  					 UNION 
			  		 
			  					 SELECT RANK() OVER ( PARTITION BY ctrtemp.[LineItemNumber],ctrtemp.JurisdictionLevel ORDER BY trd.EffectiveDate,trd.Id DESC )rank, trd.*,
			  					 ctrtemp.[LineItemNumber],ctrtemp.JurisdictionLevel, ctrtemp.impositiontype,ctrtemp.TaxTypeId
			  			  FROM dbo.TaxRateDetails AS trd
			  				INNER JOIN #ConsolidatedTaxRates ctrtemp ON trd.TaxRateId = ctrtemp.TaxRateId
			  					 AND trd.EffectiveDate > ctrtemp.DueDate
			  					 AND trd.IsActive = 1
	 		  					 AND (((ctrtemp.JurisdictionLevel = @CountyJurisdictionLevel  AND ((ctrtemp.TaxTypeId = ctrtemp.CountyTaxTypeId) OR 
			  					 	  (ctrtemp.CountyTaxTypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
			  					 	OR ((ctrtemp.JurisdictionLevel = @StateJurisdictionLevel  AND ((ctrtemp.TaxTypeId = ctrtemp.StateTaxtypeId) OR
			  					 		 ctrtemp.StateTaxtypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
								 	OR ((ctrtemp.JurisdictionLevel = @CityJurisdictionLevel  AND ((ctrtemp.TaxTypeId = ctrtemp.CityTaxTypeId) OR
			  					 		 ctrtemp.CityTaxTypeId IS NULL AND ctrtemp.ImpositionTaxTypeId = ctrtemp.DefaultTaxTypeId)))
			  					 	)
			  					 	OR ctrtemp.CountryShortName <> 'USA')
			  
			  					  )T WHERE T.rank = 1
			  					 )
			  					 AS T ON ctr.TaxRateId = T.TaxRateId 
			  					 AND T.[LineItemNumber] = ctr.[LineItemNumber]
			  					 AND T.filter = 1
			  					 AND ((ctr.JurisdictionLevel = @CountryJurisdictionLevel  AND ctr.IsCountryTaxExempt = 0) OR 
			  						  (ctr.JurisdictionLevel = @StateJurisdictionLevel  AND ctr.IsStateTaxExempt = 0) OR 
			  						  (ctr.JurisdictionLevel = @CityJurisdictionLevel AND ctr.IsCityTaxExempt = 0) OR 
			  						  (ctr.JurisdictionLevel = @CountyJurisdictionLevel AND ctr.IsCountyTaxExempt = 0) )
			  ;				
			  
			  DELETE FROM #TaxRates WHERE EffectiveRate IS NULL
			  ;
			  
			  SELECT [LineItemNumber],
			  	CAST(SUM(EffectiveRate) AS DECIMAL(12,10)) EffectiveRate,
			  	TaxBasisType,
			  	UpfrontTaxMode,
			  	JurisdictionLevel,
				ImpositionType,
				TaxType
			  FROM #TaxRates 
			  GROUP BY 
			  	[LineItemNumber], TaxBasisType, UpfrontTaxMode, JurisdictionLevel,ImpositionType,TaxType;    
			  ;

END

GO

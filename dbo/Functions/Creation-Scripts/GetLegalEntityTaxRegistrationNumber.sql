SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[GetLegalEntityTaxRegistrationNumber]
(
	@ReceivableLEList		ReceivableLECollection READONLY,
	@RunDate			DATE	
)
	RETURNS @ReceivableLETaxRegnNoList TABLE
	(
		ReceivableId	BIGINT,
		DueDate			DATE,
		LegalEntityId	BIGINT,
		LocationId		BIGINT,
		TaxLevel		NVARCHAR(10),
		TaxRegName		NVARCHAR(200),
		TaxRegId		NVARCHAR(200),
		EffectiveDate	DATE
	)
AS
BEGIN
	
	;WITH CTE_LEStateDetails AS
	(
		SELECT
			LED.ReceivableId,
			LED.LegalEntityId,
			LED.DueDate,
			LED.LocationId,
			LED.TaxLevel,
			LETRD.EffectiveDate,
			(CASE WHEN LED.DueDate > @RunDate THEN @RunDate ELSE LED.DueDate END) AS DateToCompare
		FROM @ReceivableLEList LED
		JOIN LegalEntityTaxRegistrationDetails LETRD ON LED.LegalEntityId = LETRD.LegalEntityId
		AND LETRD.IsActive = 1 AND LED.LocationId = LETRD.StateId
		WHERE LED.TaxLevel = 'State'
	),
	CTE_LEMAXEffStateDetails AS
	(
		SELECT 
			ReceivableId,
			DueDate,
			LegalEntityId,
			LocationId,
			TaxLevel,
			MAX(EffectiveDate) EffectiveDate
		FROM CTE_LEStateDetails
		WHERE DateToCompare >= EffectiveDate
		GROUP BY
			ReceivableId,
			LegalEntityId,
			DueDate,
			LocationId,
			TaxLevel
	)
	INSERT INTO @ReceivableLETaxRegnNoList 
		(ReceivableId, DueDate, LegalEntityId, LocationId, TaxLevel, TaxRegName, TaxRegId, EffectiveDate)
	SELECT
		ReceivableId,
		DueDate,
		LEMAX.LegalEntityId,
		LocationId,
		TaxLevel,
		LETRD.TaxRegistrationName,
		LETRD.TaxRegistrationId,
		LETRD.EffectiveDate
	FROM CTE_LEMAXEffStateDetails LEMAX
	JOIN LegalEntityTaxRegistrationDetails LETRD ON LEMAX.EffectiveDate = LETRD.EffectiveDate
	AND LEMAX.LocationId = LETRD.StateId AND LETRD.IsActive = 1 AND LEMAX.LegalEntityId = LETRD.LegalEntityId
	;
	
	;WITH CTE_LECountryDetails AS
	(
		SELECT
			LED.ReceivableId,
			LED.LegalEntityId,
			LED.DueDate,
			LED.LocationId,
			LED.TaxLevel,
			LETRD.EffectiveDate,
			(CASE WHEN LED.DueDate > @RunDate THEN @RunDate ELSE LED.DueDate END) AS DateToCompare
		FROM @ReceivableLEList LED
		JOIN LegalEntityTaxRegistrationDetails LETRD ON LED.LegalEntityId = LETRD.LegalEntityId
		AND LETRD.IsActive = 1 AND LED.LocationId = LETRD.CountryId
		WHERE LED.TaxLevel = 'Country'
	),
	CTE_LEMAXEffCountryDetails AS
	(
		SELECT 
			ReceivableId,
			DueDate,
			LegalEntityId,
			LocationId,
			TaxLevel,
			MAX(EffectiveDate) EffectiveDate
		FROM CTE_LECountryDetails
		WHERE DateToCompare >= EffectiveDate
		GROUP BY
			ReceivableId,
			LegalEntityId,
			DueDate,
			LocationId,
			TaxLevel
	)
	INSERT INTO @ReceivableLETaxRegnNoList 
		(ReceivableId, DueDate, LegalEntityId, LocationId, TaxLevel, TaxRegName, TaxRegId, EffectiveDate)
	SELECT
		ReceivableId,
		DueDate,
		LEMAX.LegalEntityId,
		LocationId,
		TaxLevel,
		LETRD.TaxRegistrationName,
		LETRD.TaxRegistrationId,
		LETRD.EffectiveDate
	FROM CTE_LEMAXEffCountryDetails LEMAX
	JOIN LegalEntityTaxRegistrationDetails LETRD ON LEMAX.EffectiveDate = LETRD.EffectiveDate
	AND LEMAX.LocationId = LETRD.CountryId AND LETRD.IsActive = 1 AND LEMAX.LegalEntityId = LETRD.LegalEntityId
	;

	RETURN 

END

GO

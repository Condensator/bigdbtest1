SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[GetCustomerTaxRegistrationNumber]
(
	@ReceivableCustomerList	ReceivableCustomerCollection READONLY,
	@RunDate				DATE	
)
	RETURNS @ReceivableCustomerTaxRegnNoList TABLE
	(
		ReceivableId	BIGINT,
		DueDate			DATE,
		CustomerId		BIGINT,
		LocationId		BIGINT,
		TaxLevel		NVARCHAR(10),
		TaxRegName		NVARCHAR(200),
		TaxRegId		NVARCHAR(200),
		EffectiveDate	DATE
	)
AS
BEGIN

	;WITH CTE_CustomerStateDetails AS
	(
		SELECT
			CD.ReceivableId,
			CD.CustomerId,
			CD.DueDate,
			CD.LocationId,
			CD.TaxLevel,
			PTRD.TaxRegistrationName,
			PTRD.TaxRegistrationId,
			PTRD.EffectiveDate,
			(CASE WHEN CD.DueDate > @RunDate THEN @RunDate ELSE CD.DueDate END) AS DateToCompare
		FROM @ReceivableCustomerList CD
		JOIN PartyTaxRegistrationDetails PTRD ON CD.CustomerId = PTRD.PartyId
		AND PTRD.IsActive = 1 AND CD.LocationId = PTRD.StateId
		WHERE CD.TaxLevel = 'State'
	),
	CTE_CustomerMAXEffStateDetails AS
	(
		SELECT 
			ReceivableId,
			DueDate,
			CustomerId,
			LocationId,
			TaxLevel,
			MAX(EffectiveDate) EffectiveDate
		FROM CTE_CustomerStateDetails
		WHERE DateToCompare >= EffectiveDate
		GROUP BY
			ReceivableId,
			CustomerId,
			DueDate,
			LocationId,
			TaxLevel
		)
		INSERT INTO @ReceivableCustomerTaxRegnNoList 
		(ReceivableId, DueDate, CustomerId, LocationId, TaxLevel, TaxRegName, TaxRegId, EffectiveDate)
		SELECT
			ReceivableId,
			DueDate,
			CustomerId,
			LocationId,
			TaxLevel,
			PTRD.TaxRegistrationName,
			PTRD.TaxRegistrationId,
			PTRD.EffectiveDate
		FROM CTE_CustomerMAXEffStateDetails CUMAX
		JOIN PartyTaxRegistrationDetails PTRD ON CUMAX.EffectiveDate = PTRD.EffectiveDate
		AND CUMAX.LocationId = PTRD.StateId AND PTRD.IsActive = 1 AND CUMAX.CustomerId = PTRD.PartyId
	;

	;WITH CTE_CustomerCountryDetails AS
	(
		SELECT
			CD.ReceivableId,
			CD.CustomerId,
			CD.DueDate,
			CD.LocationId,
			CD.TaxLevel,
			PTRD.TaxRegistrationName,
			PTRD.TaxRegistrationId,
			PTRD.EffectiveDate,
			(CASE WHEN CD.DueDate > @RunDate THEN @RunDate ELSE CD.DueDate END) AS DateToCompare
		FROM @ReceivableCustomerList CD
		JOIN PartyTaxRegistrationDetails PTRD ON CD.CustomerId = PTRD.PartyId
		AND PTRD.IsActive = 1 AND CD.LocationId = PTRD.CountryId
		WHERE CD.TaxLevel = 'Country'
	),
	CTE_CustomerMAXEffCountryDetails AS
	(
		SELECT 
			ReceivableId,
			DueDate,
			CustomerId,
			LocationId,
			TaxLevel,
			MAX(EffectiveDate) EffectiveDate
		FROM CTE_CustomerCountryDetails
		WHERE DateToCompare >= EffectiveDate
		GROUP BY
			ReceivableId,
			CustomerId,
			DueDate,
			LocationId,
			TaxLevel
		)
		INSERT INTO @ReceivableCustomerTaxRegnNoList 
		(ReceivableId, DueDate, CustomerId, LocationId, TaxLevel, TaxRegName, TaxRegId, EffectiveDate)
		SELECT
			ReceivableId,
			DueDate,
			CustomerId,
			LocationId,
			TaxLevel,
			PTRD.TaxRegistrationName,
			PTRD.TaxRegistrationId,
			PTRD.EffectiveDate
		FROM CTE_CustomerMAXEffCountryDetails CUMAX
		JOIN PartyTaxRegistrationDetails PTRD ON CUMAX.EffectiveDate = PTRD.EffectiveDate
		AND CUMAX.LocationId = PTRD.CountryId AND PTRD.IsActive = 1 AND CUMAX.CustomerId = PTRD.PartyId
	;

	RETURN

END

GO

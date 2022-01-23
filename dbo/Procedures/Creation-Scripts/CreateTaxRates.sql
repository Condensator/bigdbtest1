SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateTaxRates]
@GeoCode              NVARCHAR(MAX)  = NULL ,
@CountryId            BIGINT ,
@CityId               BIGINT ,
@StateId              BIGINT ,
@CountyId             BIGINT ,
@ParentJurisdictionId BIGINT ,
@CreatedTime          DATETIMEOFFSET ,
@CreatedById          BIGINT
AS
BEGIN
CREATE TABLE #InsertedJurisdictions (ID BIGINT,CountryId BIGINT,CityId BIGINT NULL,StateId BIGINT NULL,CountyId BIGINT NULL);
CREATE TABLE #InsertedTaxRates (ID BIGINT);
DECLARE @InsertedTaxRateHeaderID BIGINT;
INSERT INTO #InsertedJurisdictions ( ID , CountryId , CityId , StateId , CountyId)
VALUES ( @ParentJurisdictionId , @CountryId , @CityId , @StateId , @CountyId);
IF NOT EXISTS (SELECT * FROM TaxRateHeaders WHERE IsActive = 1 AND dbo.TaxRateHeaders.CountryId = @CountryId)
BEGIN
INSERT INTO dbo.TaxRateHeaders (IsActive,CreatedById,CreatedTime,CityId,CountyId,CountryId,StateId)
VALUES(1,@CreatedById , @CreatedTime ,NULL,NULL,@CountryId,NULL)
END
IF NOT EXISTS (SELECT * FROM TaxRateHeaders WHERE IsActive = 1 AND dbo.TaxRateHeaders.CountryId = @CountryId AND dbo.TaxRateHeaders.StateId = @StateId)
BEGIN
INSERT INTO dbo.TaxRateHeaders (IsActive,CreatedById,CreatedTime,CityId,CountyId,CountryId,StateId)
VALUES(1,@CreatedById , @CreatedTime ,NULL,NULL,@CountryId,@StateId)
END
IF NOT EXISTS (SELECT * FROM TaxRateHeaders WHERE IsActive = 1 AND dbo.TaxRateHeaders.CountryId = @CountryId AND dbo.TaxRateHeaders.StateId = @StateId AND dbo.TaxRateHeaders.CountyId = @CountyId)
BEGIN
INSERT INTO dbo.TaxRateHeaders (IsActive,CreatedById,CreatedTime,CityId,CountyId,CountryId,StateId)
VALUES(1,@CreatedById , @CreatedTime ,NULL,@CountyId,@CountryId,@StateId)
END
IF NOT EXISTS (SELECT * FROM TaxRateHeaders WHERE IsActive = 1 AND dbo.TaxRateHeaders.CountryId = @CountryId AND dbo.TaxRateHeaders.StateId = @StateId AND dbo.TaxRateHeaders.CountyId = @CountyId AND dbo.TaxRateHeaders.CityId = @CityId)
BEGIN
INSERT INTO dbo.TaxRateHeaders ( IsActive,CreatedById,CreatedTime,CityId,CountyId,CountryId,StateId)
SELECT 1 , @CreatedById , @CreatedTime , J.CityId,J.CountyId,J.CountryId,J.StateId
FROM #InsertedJurisdictions AS J
WHERE J.CountryId = @CountryId;
SET @InsertedTaxRateHeaderID = SCOPE_IDENTITY()
END
ELSE
BEGIN
SET @InsertedTaxRateHeaderID =(SELECT TOP 1 ID FROM TaxRateHeaders WHERE IsActive = 1 AND dbo.TaxRateHeaders.CountryId = @CountryId AND dbo.TaxRateHeaders.StateId = @StateId AND dbo.TaxRateHeaders.CountyId = @CountyId AND dbo.TaxRateHeaders.CityId = @CityId)
END
UPDATE dbo.Jurisdictions
SET dbo.Jurisdictions.TaxRateHeaderId = @InsertedTaxRateHeaderID,UpdatedTime=@CreatedTime,UpdatedById=@CreatedById WHERE dbo.Jurisdictions.Id = @ParentJurisdictionId
END;

GO

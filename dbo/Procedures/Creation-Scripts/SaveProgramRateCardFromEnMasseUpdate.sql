SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SaveProgramRateCardFromEnMasseUpdate]
(
@ProgramDetailIds ProgramDetailIdTable READONLY,
@IsDefault BIT,
@RateCardId BIGINT,
@CurrencyId BIGINT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @PId BIGINT;
DECLARE @PRId BIGINT;
DECLARE while_Cursor CURSOR FOR
SELECT Id FROM @ProgramDetailIds;
OPEN while_Cursor;
FETCH NEXT FROM while_Cursor INTO @PId;
WHILE @@FETCH_STATUS = 0
BEGIN
IF EXISTS(SELECT * FROM ProgramRateCards WHERE ProgramDetailId = @PId AND RateCardId = @RateCardId)
BEGIN
UPDATE vrc SET vrc.IsActive = rc.IsActive
FROM ProgramRateCards vrc
JOIN RateCards rc ON vrc.RateCardId = rc.Id
WHERE rc.Id = @RateCardId AND vrc.ProgramDetailId = @PId
END
ELSE
BEGIN
IF Exists(Select * from ProgramRateCards where IsDefault=1 AND ProgramDetailId=@PId AND IsActive=1) AND (@IsDefault=1)
BEGIN
UPDATE ProgramRateCards
SET IsDefault=0 WHERE ProgramDetailId = @PId AND ProgramRateCards.CurrencyId = @CurrencyId AND ProgramRateCards.IsActive = 1
INSERT INTO ProgramRateCards
(Name, IsActive, IsDefault, Description, RateCardFile_Content, RateCardFile_Source, RateCardFile_Type, CreatedById, CreatedTime, CurrencyId, ProgramDetailId, RateCardId)
SELECT 	r.Name, r.IsActive, @IsDefault, r.Description, r.RateCardFile_Content, r.RateCardFile_Source, r.RateCardFile_Type,
@CreatedById, @CreatedTime, r.CurrencyId, @PId, @RateCardId
FROM RateCards r WHERE r.Id = @RateCardId
SET @PRId = (SELECT SCOPE_IDENTITY());
INSERT INTO ProgramRateCardParameters
(ParameterNumber, IsBlankAllowed, IsActive, CreatedById, CreatedTime, ProgramParameterId, ProgramRateCardId)
SELECT rcp.ParameterNumber, rcp.IsBlankAllowed, rcp.IsActive, @CreatedById, @CreatedTime, rcp.ProgramParameterId, @PRId
FROM RateCardParameters rcp WHERE rcp.RateCardId = @RateCardId
END
ELSE
BEGIN
INSERT INTO ProgramRateCards
(Name, IsActive, IsDefault, Description, RateCardFile_Content, RateCardFile_Source, RateCardFile_Type, CreatedById, CreatedTime, CurrencyId, ProgramDetailId, RateCardId)
SELECT 	r.Name, r.IsActive, @IsDefault, r.Description, r.RateCardFile_Content, r.RateCardFile_Source, r.RateCardFile_Type,
@CreatedById, @CreatedTime, r.CurrencyId, @PId, @RateCardId
FROM RateCards r WHERE r.Id = @RateCardId
SET @PRId = (SELECT SCOPE_IDENTITY());
INSERT INTO ProgramRateCardParameters
(ParameterNumber, IsBlankAllowed, IsActive, CreatedById, CreatedTime, ProgramParameterId, ProgramRateCardId)
SELECT rcp.ParameterNumber, rcp.IsBlankAllowed, rcp.IsActive, @CreatedById, @CreatedTime, rcp.ProgramParameterId, @PRId
FROM RateCardParameters rcp WHERE rcp.RateCardId = @RateCardId
END
END
FETCH NEXT FROM while_Cursor INTO @PId
END
CLOSE while_Cursor;
DEALLOCATE while_Cursor;
END

GO

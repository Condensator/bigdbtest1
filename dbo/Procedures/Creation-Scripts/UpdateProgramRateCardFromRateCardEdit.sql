SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateProgramRateCardFromRateCardEdit]
(
@RateCardParam RateCardParamInfo READONLY,
@RateCardId BIGINT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE vrc SET vrc.IsActive = rc.IsActive, vrc.RateCardFile_Content = rc.RateCardFile_Content, vrc.RateCardFile_Source = rc.RateCardFile_Source,
vrc.RateCardFile_Type = rc.RateCardFile_Type, vrc.CurrencyId = rc.CurrencyId, vrc.UpdatedById = @CreatedById, vrc.UpdatedTime = @CreatedTime
FROM ProgramRateCards vrc
JOIN RateCards rc on vrc.RateCardId = rc.Id
WHERE rc.Id = @RateCardId AND vrc.IsActive = 1
UPDATE vrcp SET vrcp.IsBlankAllowed = temp.IsBlankAllowed, vrcp.IsActive = temp.IsActive, vrcp.UpdatedById = @CreatedById, vrcp.UpdatedTime = @CreatedTime
FROM ProgramRateCardParameters vrcp
JOIN @RateCardParam temp ON vrcp.ProgramParameterId = temp.Id
JOIN ProgramRateCards vrc ON vrcp.ProgramRateCardId = vrc.Id
WHERE vrc.RateCardId = @RateCardId AND vrc.IsActive = 1
DECLARE @NewCount INT = (SELECT COUNT(*) FROM @RateCardParam WHERE IsNew = 1);
IF (@NewCount > 0)
BEGIN
DECLARE @MaxParameterNumber INT = (SELECT MAX(ParameterNumber) FROM RateCardParameters rcp WHERE rcp.RateCardId = @RateCardId)
SET @MaxParameterNumber = @MaxParameterNumber - @NewCount + 1;
DECLARE @ParamId BIGINT;
DECLARE Loop_Cursor CURSOR FOR
SELECT Id FROM @RateCardParam WHERE IsNew = 1;
OPEN Loop_Cursor;
FETCH NEXT FROM Loop_Cursor INTO @ParamId;
WHILE @@FETCH_STATUS = 0
BEGIN
DECLARE @ProgramRateCardId BIGINT;
DECLARE Nested_Loop_Cursor CURSOR FOR
SELECT vrc.Id FROM ProgramRateCards vrc WHERE vrc.RateCardId = @RateCardId AND vrc.IsActive = 1;
OPEN Nested_Loop_Cursor;
FETCH NEXT FROM Nested_Loop_Cursor INTO @ProgramRateCardId;
WHILE @@FETCH_STATUS = 0
BEGIN
INSERT INTO ProgramRateCardParameters (ParameterNumber,IsBlankAllowed,IsActive,CreatedById,CreatedTime,ProgramParameterId,ProgramRateCardId)
SELECT @MaxParameterNumber, tempTable.IsBlankAllowed, 1, @CreatedById,@CreatedTime,tempTable.Id, @ProgramRateCardId
FROM @RateCardParam tempTable
WHERE tempTable.Id = @ParamId
FETCH NEXT FROM Nested_Loop_Cursor INTO @ProgramRateCardId;
END
CLOSE Nested_Loop_Cursor;
DEALLOCATE Nested_Loop_Cursor;
SET @MaxParameterNumber = @MaxParameterNumber + 1;
FETCH NEXT FROM Loop_Cursor INTO @ParamId;
END
CLOSE Loop_Cursor;
DEALLOCATE Loop_Cursor;
END
END

GO

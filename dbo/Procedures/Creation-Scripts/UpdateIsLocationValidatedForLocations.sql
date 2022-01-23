SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateIsLocationValidatedForLocations]
(
@LocationIds NVARCHAR(MAX) NULL,
@UpdatedTime DATETIME,
@UpdatedById BIGINT
)
AS
BEGIN
SELECT * INTO #LocationIds FROM ConvertCSVToBigIntTable(@LocationIds,',');
UPDATE L SET IsLocationValidated = 1,
L.UpdatedTime = @UpdatedTime,
L.UpdatedById =  @UpdatedById
FROM stgLocation L
JOIN #LocationIds LIds on L.Id = LIds.id
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateTaxAssessedForReceivables]
(
@ReceivableIds NVARCHAR(MAX),
@UpdatedById bigint,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE
ReceivableDetails
SET
IsTaxAssessed = 1 ,UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
WHERE ReceivableId IN (SELECT Id FROM ConvertCSVToBigIntTable(@ReceivableIds,','))
END

GO

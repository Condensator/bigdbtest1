SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InactivateReceivableTaxImpositionsOnReversal]
(
@ReceivableTaxDetailIds NVARCHAR(MAX),
@UpdateTime DATETIME,
@UserId BIGINT
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN

SELECT * INTO #ReceivableTaxDetails from ConvertCSVToBigIntTable(@ReceivableTaxDetailIds,',')

UPDATE RTI SET IsActive = 0,
UpdatedById = @UserId,
UpdatedTime = @UpdateTime
FROM ReceivableTaxImpositions RTI
JOIN #ReceivableTaxDetails RTD ON RTI.ReceivableTaxDetailId = RTD.ID
Where RTI.IsActive = 1

END

GO

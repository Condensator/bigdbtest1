SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateIsPayOffTemplateParametersChangedofPayoff]
(
@PayoffIds NVARCHAR(MAX))
AS
SET NOCOUNT ON
UPDATE Payoffs SET IsPayOffTemplateParametersChanged=1 WHERE Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@PayoffIds,','))

GO

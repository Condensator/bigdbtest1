SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateIsPaydownTemplateParametersChangedofLoanPaydown]
(
@LoanPaydownIds NVARCHAR(MAX))
AS
SET NOCOUNT ON
UPDATE LoanPaydowns SET IsPaydownTemplateParametersChanged=1 WHERE Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@LoanPaydownIds,','))

GO

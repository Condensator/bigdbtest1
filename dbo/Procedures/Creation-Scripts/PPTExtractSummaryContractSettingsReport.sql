SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PPTExtractSummaryContractSettingsReport]
AS
BEGIN
SET NOCOUNT ON
SELECT
LeaseContractType
,IsBankQualified
,IsFederalIncomeTaxExempt
FROM PropertyTaxContractSettings
WHERE PropertyTaxContractSettings.IsActive=1
SET NOCOUNT OFF
END

GO

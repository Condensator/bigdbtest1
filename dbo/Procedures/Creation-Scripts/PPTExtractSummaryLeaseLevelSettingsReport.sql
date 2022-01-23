SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PPTExtractSummaryLeaseLevelSettingsReport]
AS
BEGIN
SET NOCOUNT ON
SELECT
Contracts.SequenceNumber AS LeaseNumber
,PropertyTaxLeaseLevelSettings.IncludeInExtract AS IncludeInExtract
,PropertyTaxLeaseLevelSettings.IsReportCSA AS ReportCSA
,PropertyTaxLeaseLevelSettings.IncludeAllPPTExemptCodes AS IncludeAllPPTExemptCodes
FROM PropertyTaxLeaseLevelSettings
JOIN Contracts ON PropertyTaxLeaseLevelSettings.ContractId = Contracts.Id
WHERE PropertyTaxLeaseLevelSettings.IsActive=1
ORDER BY Contracts.SequenceNumber
SET NOCOUNT OFF
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[PopulatePropertyTaxImportSummaryReportData]
(    
	@PropertyTaxImportSummaryReportData PropertyTaxImportSummaryReportData READONLY,
	@CreatedById BIGINT
)
AS
	BEGIN
	SET NOCOUNT ON  
	SET ANSI_WARNINGS OFF
		
		INSERT INTO [dbo].[PropertyTaxImportSummaryReport_Extract]
           ([JobId]
		   ,[JobStepInstanceId]
           ,[FileName]
           ,[UploadedDate]
           ,[RecordsSuccessfullyUploaded]
           ,[RecordsErroredOut]
           ,[TotalTaxAmountUploaded]
           ,[TotalTaxAmountErroredOut]
           ,[Currency]
           ,[CreatedById]
           ,[CreatedTime])		
        SELECT importData.JobId
		   ,importData.JobStepInstanceId
		   ,importData.FileName
		   ,importData.UploadedDate
		   ,importData.RecordsSuccessfullyUploaded
		   ,importData.RecordsErroredOut
		   ,importData.TotalTaxAmountUploaded
		   ,importData.TotalTaxAmountErroredOut
		   ,importData.Currency
		   ,@CreatedById
		   ,GETDATE()		
		FROM @PropertyTaxImportSummaryReportData importData
			
	SET NOCOUNT OFF  
	SET ANSI_WARNINGS ON 				
	END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SummarizePTEExport]
(
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@ExportDate DATETIMEOFFSET,
	@JobStepInstanceId BIGINT,
	@IsPreview BIT,
	@PPTExportSource VARCHAR(20)
)
AS
BEGIN

SET NOCOUNT ON;
DECLARE @id BIGINT;


IF EXISTS (SELECT TOP 1 Id FROM PropertyTaxExportJobExtracts WHERE JobStepInstanceId = @JobStepInstanceId)
	BEGIN

		SELECT AssetNumber AssetId, AsOfDate INTO #tmpReportedDisposedAssets FROM PtmsExportDetailExtracts WHERE 1 = 2
		-- ****** This Block is to insert data into ExportFileDetails and for disposed assets ******* --
		IF(@PPTExportSource = 'PTMS')
		BEGIN
			INSERT INTO [dbo].[PropertyTaxExportFileDetails] ([ExportFile],[IsPreview],[IsExported]
			   ,[JobStepInstanceId],[CreatedById],[CreatedTime])     
			Select DISTINCT FileName, @IsPreview, ~@IsPreview,  
				@JobStepInstanceId, @CreatedById, @CreatedTime
			FROM PtmsExportDetailExtracts 
			WHERE JobStepInstanceId = @JobStepInstanceId AND IsIncluded = 1

			INSERT INTO #tmpReportedDisposedAssets
			SELECT AssetNumber, AsOfDate 
			FROM PtmsExportDetailExtracts 
			WHERE JobStepInstanceId = @JobStepInstanceId AND IsDisposedAssetReported = 1		
		END
		ELSE IF(@PPTExportSource = 'OneSource')
		BEGIN
			INSERT INTO [dbo].[PropertyTaxExportFileDetails] ([ExportFile],[IsPreview],[IsExported]
			   ,[JobStepInstanceId],[CreatedById],[CreatedTime])     
			Select DISTINCT FileName, @IsPreview, ~@IsPreview,  
				@JobStepInstanceId, @CreatedById, @CreatedTime
			FROM OneSourceExportDetailExtracts 
			WHERE JobStepInstanceId = @JobStepInstanceId AND IsIncluded = 1	

			INSERT INTO #tmpReportedDisposedAssets
			SELECT AssetNumber, AsOfDate 
			FROM OneSourceExportDetailExtracts 
			WHERE JobStepInstanceId = @JobStepInstanceId AND IsDisposedAssetReported = 1
		END

		IF (EXISTS(SELECT TOP 1 AssetId FROM #tmpReportedDisposedAssets) AND @IsPreview = 0)
		BEGIN
			Update Asset SET DisposedDate = DisposedAsset.AsOfDate, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
			FROM Assets Asset
			JOIN #tmpReportedDisposedAssets DisposedAsset 
					ON Asset.Id = DisposedAsset.AssetId AND Asset.DisposedDate IS NULL
		END

		IF OBJECT_ID('tempDB..#tmpPTMSReportedDisposedAssets') IS NOT NULL
			DROP TABLE #tmpPTMSReportedDisposedAssets

		-- This summarize is working only for PTMS as of now, if required need to correct
		IF(@PPTExportSource = 'PTMS')
		BEGIN

			--PPTExtractDetails PARENT TABLE CREATION
			INSERT INTO PPTExtractDetails
				(
					ExportDate
					,CreatedById
					,CreatedTime		
				)
			VALUES
				(
					@exportDate,
					@CreatedById,
					@CreatedTime
				)
		
			SELECT @id=MAX(Id) FROM PPTExtractDetails	
	
			SELECT PropertyTaxCost_Currency, FileName, LegalEntityId
					,COUNT(StateId) NumberOfAssets
					,SUM(CASE WHEN IsTransferAsset=1 THEN 1 ELSE 0 END) NumberOfAssetsToTransfer
					,SUM(PropertyTaxCost_Amount) TotalPPTBasis_Amount
			INTO #includedAssets
			FROM PtmsExportDetailExtracts 
			WHERE IsIncluded=1 AND PtmsExportDetailExtracts.JobStepInstanceId = @JobStepInstanceId
			GROUP BY [PropertyTaxCost_Currency],FileName,LegalEntityId


			SELECT	COUNT(Id) NumberOfAssets,
					RejectReason RejectionReason,
					CASE WHEN SUM(PropertyTaxCost_Amount) IS NULL THEN 0.00 ELSE SUM(PropertyTaxCost_Amount) END TotalPPTBasisAmount,
					PropertyTaxCost_Currency TotalPPTBasisCurrency,
					StateId StateId,
					LegalEntityId LegalEntityId
			INTO #excludedAssetDetails
			FROM PtmsExportDetailExtracts 
			WHERE IsIncluded = 0 AND PtmsExportDetailExtracts.JobStepInstanceId = @JobStepInstanceId
			GROUP BY PropertyTaxCost_Currency,LegalEntityId,StateId,RejectReason


			SELECT  PropertyTaxCost_Currency, FileName, LegalEntityId, StateId,
					COUNT(StateId) NumberOfAssets,
					SUM(CASE WHEN IsTransferAsset=1 THEN 1 ELSE 0 END) NumberOfAssetsToTransfer,
					SUM(PropertyTaxCost_Amount) TotalPPTBasis_Amount,
					SUM(CASE WHEN IsTransferAsset=1 THEN PropertyTaxCost_Amount ELSE 0 END) TotalPPTBasisToTransfer_Amount
			INTO #includedAssetByState
			FROM PtmsExportDetailExtracts
			WHERE IsIncluded = 1 AND PtmsExportDetailExtracts.JobStepInstanceId = @JobStepInstanceId
			GROUP by [PropertyTaxCost_Currency],FileName,LegalEntityId,StateId

			--PPTExtractIncludedAssetDetails
			INSERT INTO PPTExtractIncludedAssetDetails
				(
					NumberOfAssets
					,NumberOfAssetsToTransfer
					,TotalPPTBasis_Currency
					,TotalPPTBasis_Amount
					,TotalPPTBasisToTransfer_Currency
					,TotalPPTBasisToTransfer_Amount
					,StateId
					,LegalEntityId
					,ExportFile
					,PPTExtractDetailId
					,CreatedById
					,CreatedTime
				)
			SELECT t1.NumberOfAssets
				,t1.NumberOfAssetsToTransfer
				,t1.PropertyTaxCost_Currency
				,t1.TotalPPTBasis_Amount
				,t1.PropertyTaxCost_Currency
				,t1.TotalPPTBasisToTransfer_Amount
				,t1.StateId
				,t1.LegalEntityId
				,t1.FileName
				,@id
				,@CreatedById
				,@CreatedTime
			FROM #includedAssetByState as t1


			INSERT INTO PPTExtractExcludedAssetDetails
				(
					 NumberOfAssets
					,Reason
					,TotalPPTBasis_Currency
					,TotalPPTBasis_Amount
					,StateId
					,LegalEntityId
					,ExportFile
					,PPTExtractDetailId
					,CreatedById
					,CreatedTime
				)
			SELECT excludedAssetDetail.NumberOfAssets
				   ,excludedAssetDetail.RejectionReason
				   ,excludedAssetDetail.TotalPPTBasisCurrency
				   ,excludedAssetDetail.TotalPPTBasisAmount
				   ,excludedAssetDetail.StateId
				   ,excludedAssetDetail.LegalEntityId
				   ,includedAsset.FileName
				   ,@id
				   ,@CreatedById
				   ,@CreatedTime
			FROM #excludedAssetDetails excludedAssetDetail
			JOIN #includedAssetByState  includedAsset 
				ON excludedAssetDetail.TotalPPTBasisCurrency=includedAsset.PropertyTaxCost_Currency
					AND excludedAssetDetail.LegalEntityId=includedAsset.LegalEntityId

			INSERT INTO PPTExtractExcludedAssetDetails
				(
					 NumberOfAssets
					,Reason
					,TotalPPTBasis_Currency
					,TotalPPTBasis_Amount
					,StateId
					,LegalEntityId
					,ExportFile
					,PPTExtractDetailId
					,CreatedById
					,CreatedTime
				)
			SELECT    includedAssetGroupByLE.NumberOfAssets
					 ,excludedAssetDetail.RejectionReason
					 ,excludedAssetDetail.TotalPPTBasisCurrency
					 ,excludedAssetDetail.TotalPPTBasisAmount
					 ,excludedAssetDetail.StateId
					 ,includedAssetGroupByLE.LegalEntityId
					 ,NULL
					 ,@id
					 ,@CreatedById
					 ,@CreatedTime

			FROM #excludedAssetDetails excludedAssetDetail
			LEFT JOIN #includedAssets includedAssetGroupByLE
			ON excludedAssetDetail.LegalEntityId=includedAssetGroupByLE.LegalEntityId
			where includedAssetGroupByLE.LegalEntityId IS NULL



			IF OBJECT_ID('tempDB..#excludedAssetDetails') IS NOT NULL
					DROP TABLE #excludedAssetDetails

			IF OBJECT_ID('tempDB..#includedAssetByState') IS NOT NULL
					DROP TABLE #includedAssetByState

			IF OBJECT_ID('tempDB..#excludedAssetsNotInLegalEntity') IS NOT NULL
					DROP TABLE #excludedAssetsNotInLegalEntity

			IF OBJECT_ID('tempDB..#includedAssets') IS NOT NULL
					DROP TABLE #includedAssets


		END
	END 
END

GO

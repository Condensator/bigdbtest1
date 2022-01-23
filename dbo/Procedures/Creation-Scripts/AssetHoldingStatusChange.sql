SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[AssetHoldingStatusChange]
(
@Param AssetHoldingStatusChangeParamType READONLY,
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SELECT * INTO #Param FROM @Param
CREATE INDEX Index_AssetId ON #Param (AssetId);
UPDATE AGL
SET AGL.HoldingStatus = param.NewHoldingStatus
,AGL.InstrumentTypeId = ISNULL(param.InstrumentTypeId,AGL.InstrumentTypeId)
,AGL.LineofBusinessId = ISNULL(param.LineofBusinessId,AGL.LineofBusinessId)
,AGL.OriginalInstrumentTypeId = ISNULL(param.OriginalInstrumentTypeId, AGL.OriginalInstrumentTypeId)
,AGL.OriginalLineofBusinessId = ISNULL(param.OriginalLineofBusinessId, AGL.OriginalLineofBusinessId)
,AGL.AssetBookValueAdjustmentGLTemplateId = ISNULL(param.AssetBookValueAdjustmentGLTemplateId, AGL.AssetBookValueAdjustmentGLTemplateId)
,AGL.BookDepreciationGLTemplateId = ISNULL(param.BookDepreciationGLTemplateId, AGL.BookDepreciationGLTemplateId)
,AGL.CostCenterId = ISNULL(param.CostCenterId, AGL.CostCenterId)
,AGL.BranchId = ISNULL(param.BranchId,AGL.BranchId)
,AGL.UpdatedById = @UserId
,AGL.UpdatedTime = @Time
FROM AssetGLDetails AGL
JOIN #Param param ON AGL.Id = param.AssetId
;

INSERT INTO [dbo].[AssetHistories]
([Reason]
,[AsOfDate]
,[AcquisitionDate]
,[Status]
,[FinancialType]
,[SourceModule]
,[SourceModuleId]
,[CreatedById]
,[CreatedTime]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[ContractId]
,[AssetId]
,[PropertyTaxReportCodeId]
,[IsReversed])
SELECT HistoryReason
,AsOfDate
,AcquisitionDate
,Status
,FinancialType
,SourceModule
,SourceId
,@UserId
,@Time
,CustomerId
,ParentAssetId
,LegalEntityId
,NULL
,AssetId
,PropertyTaxReportCodeId
,0
FROM @Param 
WHERE AssetHoldingStatusChangeId > 0
;
END
;

GO

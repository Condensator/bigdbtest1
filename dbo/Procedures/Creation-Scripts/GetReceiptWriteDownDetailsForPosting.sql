SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetReceiptWriteDownDetailsForPosting]
(
@ContractIds IdCollection READONLY,
@JobStepInstanceId BIGINT
)
AS
BEGIN
SELECT Id INTO #ContractIds FROM @ContractIds
SELECT
RC.[ContractId]
,RC.[ContractType]
,RC.[WriteDownId]
,RC.[TotalWriteDownAmount]
,RC.[TotalRecoveryAmountForWriteDown] [TotalRecoveryAmount]
,RC.[NetWriteDown]
,RC.[WriteDownGLTemplateId] [GLTemplateId]
,RC.[RecoveryGLTemplateId] [RecoveryGLTemplateId]
,RC.[RecoveryReceivableCodeId]
,RC.[WriteDownDate]
,RC.[WriteDownReason]
,RC.[LeaseFinanceId]
,RC.[LoanFinanceId]
FROM #ContractIds AS ContractIds
JOIN ReceiptContractRecoveryDetails_Extract RC ON RC.JobStepInstanceId = @JobStepInstanceId
AND ContractIds.Id = RC.ContractId AND WriteDownId IS NOT NULL
SELECT
RCA.ContractId
,RCA.AssetId
,RCA.TotalWriteDownAmount [TotalWriteDownAmountForAsset]
,RCA.LeaseComponentWriteDownAmount [LeaseComponentWriteDownAmount]
,RCA.NonLeaseComponentWriteDownAmount [NonLeaseComponentWriteDownAmount]
FROM #ContractIds AS ContractIds
JOIN ReceiptContractRecoveryAssetDetails_Extract RCA ON RCA.JobStepInstanceId = @JobStepInstanceId
AND ContractIds.Id = RCA.ContractId AND RCA.WriteDownId IS NOT NULL
DROP TABLE #ContractIds
END

GO

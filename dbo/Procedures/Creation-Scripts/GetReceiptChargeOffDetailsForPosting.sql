SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetReceiptChargeOffDetailsForPosting]  
(    
@ContractIds IdCollection READONLY,    
@JobStepInstanceId BIGINT    
) AS    
BEGIN    
SELECT  
RC.ContractId,  
RC.ChargeOffId,  
RC.TotalChargeOffAmount,  
RC.TotalRecoveryAmount,  
RC.ContractType,  
RC.ChargeOffReasonCodeConfigId,  
RC.NetInvestmentWithBlended,  
RC.ChargeOffGLTemplateId  
,TotalLeaseComponentChargeOffAmount  
,TotalNonLeaseComponentChargeOffAmount  
,TotalLeaseComponentRecoveryAmount  
,TotalNonLeaseComponentRecoveryAmount  
,TotalLeaseComponentGainAmount  
,TotalNonLeaseComponentGainAmount  
FROM @ContractIds AS ContractIds  
JOIN ReceiptContractRecoveryDetails_Extract RC ON RC.JobStepInstanceId = @JobStepInstanceId  
AND ContractIds.Id = RC.ContractId AND ChargeOffId IS NOT NULL  
  
SELECT    
RCA.AssetId,    
RCA.ChargeOffId,    
RCA.NetWriteDownForChargeOff [NetWriteDown],    
RCA.NetInvestmentWithBlended [NetInvestmentWithBlended]    
FROM @ContractIds AS ContractIds    
JOIN ReceiptContractRecoveryAssetDetails_Extract RCA ON RCA.JobStepInstanceId = @JobStepInstanceId    
AND ContractIds.Id = RCA.ContractId AND RCA.ChargeOffId IS NOT NULL   
END

GO

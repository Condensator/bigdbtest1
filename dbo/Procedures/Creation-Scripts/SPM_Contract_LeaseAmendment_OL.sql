SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Contract_LeaseAmendment_OL]  
AS    
BEGIN    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    
 SELECT DISTINCT EC.contractid ContractId,    
                Sum (CASE    
                       WHEN LA.amendmenttype = 'Renewal' THEN 1    
                       ELSE 0    
                     END) AS IsRenewal,    
                Sum (CASE    
                       WHEN LA.amendmenttype = 'Assumption' THEN 1    
                       ELSE 0    
                     END) AS IsAssumed    
INTO   ##Contract_LeaseAmendment_OL    
FROM   ##Contract_EligibleContracts EC     
   INNER JOIN LeaseFinances LF ON lf.ContractId = ec.ContractId  AND EC.LeaseContractType = 'Operating'    
   INNER JOIN LeaseAmendments LA ON LA.currentleasefinanceid = LF.Id     
   AND LA.leaseamendmentstatus = 'Approved'    
GROUP  BY EC.contractid;     
 CREATE NONCLUSTERED INDEX IX_LeaseAmendment_OL_ContractId ON  ##Contract_LeaseAmendment_OL(ContractId);     
    
End

GO

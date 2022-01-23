SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE   PROC [dbo].[SPM_Contract_ChargeOff]
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SELECT C.ContractId as ContractId, CO.ChargeOffDate
    INTO ##Contract_ChargeOff
    FROM ##Contract_EligibleContracts c
        INNER JOIN LeaseFinanceDetails LFD ON LFD.Id = c.LeaseFinanceId
        INNER JOIN ChargeOffs CO ON CO.ContractId = c.ContractId
    WHERE CO.IsActive = 1
          AND CO.Status = 'Approved'
          AND CO.IsRecovery = 0
          AND CO.ReceiptId IS NULL
    CREATE NONCLUSTERED INDEX IX_ChargeOffContractId ON ##Contract_ChargeOff(ContractId) ;

END

GO

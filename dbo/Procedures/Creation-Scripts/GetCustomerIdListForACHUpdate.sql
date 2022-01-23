SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetCustomerIdListForACHUpdate]
(@PendingStatus            NVARCHAR(18),
 @ThresholdExceededStatus  NVARCHAR(18),
 @PartiallyCompletedStatus NVARCHAR(18),
 @ProcessThroughDate       DATE,
 @UnCommencedStatus        NVARCHAR(16),
 @CommencedStatus          NVARCHAR(16),
 @LegalEntityIds           NVARCHAR(MAX),
 @BatchCount               BIGINT
)
AS
  BEGIN

    SELECT ConvertCSVToBigIntTable.Id AS LegalEntityId
    INTO #LegalEntityIds
    FROM dbo.ConvertCSVToBigIntTable(@LegalEntityIds, ',');

    CREATE TABLE #CustomerCount
    (CustomerId BIGINT
    --,RecCount BIGINT
    );

    INSERT INTO #CustomerCount
    SELECT DISTINCT
           LF.CustomerId --, count(*) RecCount
    FROM dbo.ACHSchedules AS ACH
    JOIN dbo.Contracts AS c ON C.Id = ACH.ContractBillingId
    JOIN dbo.ContractBillings AS CB ON CB.Id = ACH.ContractBillingId
    INNER JOIN dbo.LeaseFinances AS LF ON LF.ContractId = C.Id
                                          AND Lf.IsCurrent = 1
    INNER JOIN dbo.LeaseFinanceDetails AS LDf ON LDF.Id = LF.Id
    INNER JOIN #LegalEntityIds ON #LegalEntityIds.LegalEntityId = ISNULL(CB.ReceiptLegalEntityId, LF.LegalEntityId) -- we need to validate whether any performance issue
    WHERE ACH.IsActive = 1
          AND ACH.STATUS IN(@PendingStatus, @ThresholdExceededStatus)
         AND ACH.SettlementDate <= @ProcessThroughDate
         AND
             ( C.STATUS = @CommencedStatus
               OR LDF.CreateInvoiceForAdvanceRental = 0
             )
    GROUP BY LF.CustomerId;

    INSERT INTO #CustomerCount
    SELECT DISTINCT
           OTACH.CustomerID  --, count(*) RecCount
    FROM dbo.OneTimeACHes AS OTACH
    INNER JOIN #LegalEntityIds ON #LegalEntityIds.LegalEntityId = OTACH.LegalEntityId
    WHERE OTACH.IsActive = 1
          AND OTACH.Status IN(@PendingStatus, @PartiallyCompletedStatus)
         AND OTACH.SettlementDate <= @ProcessThroughDate
    GROUP BY OTACH.CustomerId;

    --;WITH CTE_1
    --AS(
    --Select
    --CustomerId,
    --RecCount,
    --FLOOR(SUM(RecCount) OVER (ORDER By CustomerId)/@BatchCount) Rank
    --from #CustomerCount
    --)
    --Select MAX( CustomerId) TillCustomerId from CTE_1
    --Group  by Rank

    SELECT DISTINCT
           #CustomerCount.CustomerId
    FROM #CustomerCount
    ORDER BY #CustomerCount.CustomerId;
  END;

GO

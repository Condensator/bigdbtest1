SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DbOptimize]
AS
BEGIN
		
EXECUTE sp_updatestats

ALTER INDEX ALL ON dbo.[Receivables] REBUILD 
PARTITION = ALL WITH (Fillfactor=97)

ALTER INDEX [IX_Asset] ON [AssetIncomeSchedules] REBUILD
PARTITION = ALL WITH (Fillfactor=97)

ALTER INDEX [IX_Asset] ON [AssetValueHistories] REBUILD
PARTITION = ALL WITH (Fillfactor=97)
 
ALTER INDEX [ClusteredIndex_LeaseFinanceDetailId] ON [LeasePaymentSchedules] REBUILD
PARTITION = ALL WITH (Fillfactor=97)

ALTER INDEX [IX_LeaseFinance] ON [LeaseIncomeSchedules] REBUILD
PARTITION = ALL WITH (Fillfactor=97)

END

GO

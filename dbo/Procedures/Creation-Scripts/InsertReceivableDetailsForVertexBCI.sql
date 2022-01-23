SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InsertReceivableDetailsForVertexBCI]
(@bciTransactionTableParameters          BCITransactionTableParameters READONLY,
@bciControlTableParameters              BCIControlTableParameters READONLY,
@CreatedById                            BIGINT,
@CreatedTime                            DATETIMEOFFSET,
@JobStepInstanceId                                  BIGINT,
@BatchId                                BIGINT)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @RequestBatchStatus INT = 1;
INSERT INTO JobVertexBatches (JobStepInstanceId, batchId, IsProcessed, CreatedById,CreatedTime)
VALUES(@JobStepInstanceId, @BatchId, 0, @CreatedById,@CreatedTime)
INSERT INTO VertexBCIControls (BatchId,BatchStatus) VALUES (@BatchId, @RequestBatchStatus)
INSERT INTO VertexBCITransactions (AmountBilledToDate, AdminDestinationCity, BatchStatus, Status,
LineItemNumber, BatchId, CustomerCode, CurrencyCode, Cost,
CompanyCode, DocumentNumber, DocumentDate, DestinationTaxAreaId,
DestinationPostalCode, DestinationMainDivision, DestinationCountry,
ExtendedPrice, FlexibleNumericField1, FlexibleNumericField2,
FlexibleNumericField3, FlexibleNumericField4, FlexibleNumericField5,
FlexibleDateField1, FlexibleCodeField1, FlexibleCodeField2,
FlexibleCodeField3, FlexibleCodeField4, FlexibleCodeField5,
FlexibleCodeField6, FlexibleCodeField7, FlexibleCodeField8,
FlexibleCodeField9, FlexibleCodeField10, FlexibleCodeField11,
FlexibleCodeField12, FlexibleCodeField13, FlexibleCodeField14,
FlexibleCodeField15, FlexibleCodeField16, FlexibleCodeField17,
FlexibleCodeField18, FlexibleCodeField19, FlexibleCodeField20,
FairMarketValue, GeneralLedgerAccount, LocationCode, ProductCode,
TaxAreaId, TransactionType, TransactionId)
SELECT BCITransactionRecords.AmountBilledToDate, BCITransactionRecords.AdminDestinationCity,
BCITransactionRecords.BatchStatus, BCITransactionRecords.Status, BCITransactionRecords.LineItemNumber,
@BatchId, BCITransactionRecords.CustomerCode, BCITransactionRecords.CurrencyCode,
BCITransactionRecords.Cost, BCITransactionRecords.CompanyCode, BCITransactionRecords.DocumentNumber,
BCITransactionRecords.DocumentDate, BCITransactionRecords.DestinationTaxAreaId,
BCITransactionRecords.DestinationPostalCode,	BCITransactionRecords.DestinationMainDivision,
BCITransactionRecords.DestinationCountry, BCITransactionRecords.ExtendedPrice,
BCITransactionRecords.FlexibleNumericField1, BCITransactionRecords.FlexibleNumericField2,
BCITransactionRecords.FlexibleNumericField3, BCITransactionRecords.FlexibleNumericField4,
BCITransactionRecords.FlexibleNumericField5, BCITransactionRecords.FlexibleDateField1,
BCITransactionRecords.FlexibleCodeField1, BCITransactionRecords.FlexibleCodeField2,
BCITransactionRecords.FlexibleCodeField3, BCITransactionRecords.FlexibleCodeField4,
BCITransactionRecords.FlexibleCodeField5, BCITransactionRecords.FlexibleCodeField6,
BCITransactionRecords.FlexibleCodeField7, BCITransactionRecords.FlexibleCodeField8,
BCITransactionRecords.FlexibleCodeField9, BCITransactionRecords.FlexibleCodeField10,
BCITransactionRecords.FlexibleCodeField11, BCITransactionRecords.FlexibleCodeField12,
BCITransactionRecords.FlexibleCodeField13, BCITransactionRecords.FlexibleCodeField14,
BCITransactionRecords.FlexibleCodeField15, BCITransactionRecords.FlexibleCodeField16,
BCITransactionRecords.FlexibleCodeField17, BCITransactionRecords.FlexibleCodeField18,
BCITransactionRecords.FlexibleCodeField19, BCITransactionRecords.FlexibleCodeField20,
BCITransactionRecords.FairMarketValue, BCITransactionRecords.GeneralLedgerAccount,
BCITransactionRecords.LocationCode, BCITransactionRecords.ProductCode,
BCITransactionRecords.TaxAreaId, BCITransactionRecords.TransactionType,
BCITransactionRecords.TransactionId
FROM @bciTransactionTableParameters as BCITransactionRecords
INSERT INTO VertexBCIControlTrackers (BatchId, JobStepInstanceId, BatchType, BatchStatus, CreatedById,CreatedTime)
VALUES (@BatchId, @JobStepInstanceId, 'Request', @RequestBatchStatus, @CreatedById, @CreatedTime)
INSERT INTO VertexBCITransactionTrackers (AmountBilledToDate, AdminDestinationCity, BatchStatus, Status,
LineItemNumber, BatchId, CustomerCode, CurrencyCode, Cost,
CompanyCode, DocumentNumber, DocumentDate, DestinationTaxAreaId,
DestinationPostalCode, DestinationMainDivision, DestinationCountry,
ExtendedPrice, FlexibleNumericField1, FlexibleNumericField2,
FlexibleNumericField3, FlexibleNumericField4, FlexibleNumericField5,
FlexibleDateField1, FlexibleCodeField1, FlexibleCodeField2,
FlexibleCodeField3, FlexibleCodeField4, FlexibleCodeField5,
FlexibleCodeField6, FlexibleCodeField7, FlexibleCodeField8,
FlexibleCodeField9, FlexibleCodeField10, FlexibleCodeField11,
FlexibleCodeField12, FlexibleCodeField13, FlexibleCodeField14,
FlexibleCodeField15, FlexibleCodeField16, FlexibleCodeField17,
FlexibleCodeField18, FlexibleCodeField19, FlexibleCodeField20,
FairMarketValue, GeneralLedgerAccount, LocationCode, ProductCode,
TaxAreaId, TransactionType, TransactionId, JobStepInstanceId, BatchType,CreatedById, CreatedTime)
SELECT BCITransactionRecords.AmountBilledToDate, BCITransactionRecords.AdminDestinationCity,
BCITransactionRecords.BatchStatus, BCITransactionRecords.Status, BCITransactionRecords.LineItemNumber,
@BatchId, BCITransactionRecords.CustomerCode, BCITransactionRecords.CurrencyCode,
BCITransactionRecords.Cost, BCITransactionRecords.CompanyCode, BCITransactionRecords.DocumentNumber,
BCITransactionRecords.DocumentDate, BCITransactionRecords.DestinationTaxAreaId,
BCITransactionRecords.DestinationPostalCode,	BCITransactionRecords.DestinationMainDivision,
BCITransactionRecords.DestinationCountry, BCITransactionRecords.ExtendedPrice,
BCITransactionRecords.FlexibleNumericField1, BCITransactionRecords.FlexibleNumericField2,
BCITransactionRecords.FlexibleNumericField3, BCITransactionRecords.FlexibleNumericField4,
BCITransactionRecords.FlexibleNumericField5, BCITransactionRecords.FlexibleDateField1,
BCITransactionRecords.FlexibleCodeField1, BCITransactionRecords.FlexibleCodeField2,
BCITransactionRecords.FlexibleCodeField3, BCITransactionRecords.FlexibleCodeField4,
BCITransactionRecords.FlexibleCodeField5, BCITransactionRecords.FlexibleCodeField6,
BCITransactionRecords.FlexibleCodeField7, BCITransactionRecords.FlexibleCodeField8,
BCITransactionRecords.FlexibleCodeField9, BCITransactionRecords.FlexibleCodeField10,
BCITransactionRecords.FlexibleCodeField11, BCITransactionRecords.FlexibleCodeField12,
BCITransactionRecords.FlexibleCodeField13, BCITransactionRecords.FlexibleCodeField14,
BCITransactionRecords.FlexibleCodeField15, BCITransactionRecords.FlexibleCodeField16,
BCITransactionRecords.FlexibleCodeField17, BCITransactionRecords.FlexibleCodeField18,
BCITransactionRecords.FlexibleCodeField19, BCITransactionRecords.FlexibleCodeField20,
BCITransactionRecords.FairMarketValue, BCITransactionRecords.GeneralLedgerAccount,
BCITransactionRecords.LocationCode, BCITransactionRecords.ProductCode,
BCITransactionRecords.TaxAreaId, BCITransactionRecords.TransactionType,
BCITransactionRecords.TransactionId,@JobStepInstanceId, 'Request', @CreatedById, @CreatedTime
FROM @bciTransactionTableParameters as BCITransactionRecords
END

GO

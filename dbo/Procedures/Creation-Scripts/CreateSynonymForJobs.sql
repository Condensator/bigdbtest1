SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateSynonymForJobs]
(
	@RecreateSynonym BIT = 0
)
AS
BEGIN

-- Create synonym for Post Receivable To GL Job
IF OBJECT_ID('PostReceivableToGLJob_Extracts') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM PostReceivableToGLJob_Extracts
END
IF OBJECT_ID('PostReceivableToGLJob_Extracts') IS NULL
BEGIN
DECLARE @PostReceivableToGLJobExtracts nvarchar(400)= 'tempdb..PostReceivableToGLJobExtracts_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL nvarchar(MAX) = 'CREATE SYNONYM PostReceivableToGLJob_Extracts FOR ' + @PostReceivableToGLJobExtracts;
EXEC(@DynamicSynonymSQL)
END

-- Create synonym for Lease Income Recognition Job
IF OBJECT_ID('LeaseIncomeRecognitionJob_Extracts') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM LeaseIncomeRecognitionJob_Extracts
END
IF OBJECT_ID('LeaseIncomeRecognitionJob_Extracts') IS NULL
BEGIN
DECLARE @LeaseIncomeRecognitionJobExtracts nvarchar(400)= 'tempdb..LeaseIncomeRecognitionJobExtracts_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL1 nvarchar(MAX) = 'CREATE SYNONYM LeaseIncomeRecognitionJob_Extracts FOR ' + @LeaseIncomeRecognitionJobExtracts;
EXEC(@DynamicSynonymSQL1)
END

-- Create synonym for Sales Tax Job
IF OBJECT_ID('SalesTaxReceivableDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM SalesTaxReceivableDetailExtract
END
IF OBJECT_ID('SalesTaxReceivableDetailExtract') IS NULL
BEGIN
DECLARE @SalesTaxReceivableDetailExtract nvarchar(400)= 'tempdb..SalesTaxReceivableDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL2 nvarchar(MAX) = 'CREATE SYNONYM SalesTaxReceivableDetailExtract FOR ' + @SalesTaxReceivableDetailExtract;
EXEC(@DynamicSynonymSQL2)
END

IF OBJECT_ID('SalesTaxReceivableSKUDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM SalesTaxReceivableSKUDetailExtract
END
IF OBJECT_ID('SalesTaxReceivableSKUDetailExtract') IS NULL
BEGIN
DECLARE @SalesTaxReceivableSKUDetailExtract nvarchar(400)= 'tempdb..SalesTaxReceivableSKUDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL3 nvarchar(MAX) = 'CREATE SYNONYM SalesTaxReceivableSKUDetailExtract FOR ' + @SalesTaxReceivableSKUDetailExtract;
EXEC(@DynamicSynonymSQL3)
END

IF OBJECT_ID('SalesTaxContractBasedSplitupReceivableDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM SalesTaxContractBasedSplitupReceivableDetailExtract
END
IF OBJECT_ID('SalesTaxContractBasedSplitupReceivableDetailExtract') IS NULL
BEGIN
DECLARE @SalesTaxContractBasedSplitupReceivableDetailExtract nvarchar(400)= 'tempdb..SalesTaxContractBasedSplitupReceivableDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL4 nvarchar(MAX) = 'CREATE SYNONYM SalesTaxContractBasedSplitupReceivableDetailExtract FOR ' + @SalesTaxContractBasedSplitupReceivableDetailExtract;
EXEC(@DynamicSynonymSQL4)
END

IF OBJECT_ID('SalesTaxAssetDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM SalesTaxAssetDetailExtract
END
IF OBJECT_ID('SalesTaxAssetDetailExtract') IS NULL
BEGIN
DECLARE @SalesTaxAssetDetailExtract nvarchar(400)= 'tempdb..SalesTaxAssetDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL5 nvarchar(MAX) = 'CREATE SYNONYM SalesTaxAssetDetailExtract FOR ' + @SalesTaxAssetDetailExtract;
EXEC(@DynamicSynonymSQL5)
END

IF OBJECT_ID('SalesTaxAssetSKUDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM SalesTaxAssetSKUDetailExtract
END
IF OBJECT_ID('SalesTaxAssetSKUDetailExtract') IS NULL
BEGIN
DECLARE @SalesTaxAssetSKUDetailExtract nvarchar(400)= 'tempdb..SalesTaxAssetSKUDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL6 nvarchar(MAX) = 'CREATE SYNONYM SalesTaxAssetSKUDetailExtract FOR ' + @SalesTaxAssetSKUDetailExtract;
EXEC(@DynamicSynonymSQL6)
END

IF OBJECT_ID('SalesTaxAssetLocationDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM SalesTaxAssetLocationDetailExtract
END
IF OBJECT_ID('SalesTaxAssetLocationDetailExtract') IS NULL
BEGIN
DECLARE @SalesTaxAssetLocationDetailExtract nvarchar(400)= 'tempdb..SalesTaxAssetLocationDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL7 nvarchar(MAX) = 'CREATE SYNONYM SalesTaxAssetLocationDetailExtract FOR ' + @SalesTaxAssetLocationDetailExtract;
EXEC(@DynamicSynonymSQL7)
END

IF OBJECT_ID('SalesTaxLocationDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM SalesTaxLocationDetailExtract
END
IF OBJECT_ID('SalesTaxLocationDetailExtract') IS NULL
BEGIN
DECLARE @SalesTaxLocationDetailExtract nvarchar(400)= 'tempdb..SalesTaxLocationDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL8 nvarchar(MAX) = 'CREATE SYNONYM SalesTaxLocationDetailExtract FOR ' + @SalesTaxLocationDetailExtract;
EXEC(@DynamicSynonymSQL8)
END

IF OBJECT_ID('VertexLocationTaxAreaDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexLocationTaxAreaDetailExtract
END
IF OBJECT_ID('VertexLocationTaxAreaDetailExtract') IS NULL
BEGIN
DECLARE @VertexLocationTaxAreaDetailExtract nvarchar(400)= 'tempdb..VertexLocationTaxAreaDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL9 nvarchar(MAX) = 'CREATE SYNONYM VertexLocationTaxAreaDetailExtract FOR ' + @VertexLocationTaxAreaDetailExtract;
EXEC(@DynamicSynonymSQL9)
END

IF OBJECT_ID('VertexCustomerDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexCustomerDetailExtract
END
IF OBJECT_ID('VertexCustomerDetailExtract') IS NULL
BEGIN
DECLARE @VertexCustomerDetailExtract nvarchar(400)= 'tempdb..VertexCustomerDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL10 nvarchar(MAX) = 'CREATE SYNONYM VertexCustomerDetailExtract FOR ' + @VertexCustomerDetailExtract;
EXEC(@DynamicSynonymSQL10)
END

IF OBJECT_ID('VertexContractDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexContractDetailExtract
END
IF OBJECT_ID('VertexContractDetailExtract') IS NULL
BEGIN
DECLARE @VertexContractDetailExtract nvarchar(400)= 'tempdb..VertexContractDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL11 nvarchar(MAX) = 'CREATE SYNONYM VertexContractDetailExtract FOR ' + @VertexContractDetailExtract;
EXEC(@DynamicSynonymSQL11)
END

IF OBJECT_ID('VertexAssetDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexAssetDetailExtract
END
IF OBJECT_ID('VertexAssetDetailExtract') IS NULL
BEGIN
DECLARE @VertexAssetDetailExtract nvarchar(400)= 'tempdb..VertexAssetDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL12 nvarchar(MAX) = 'CREATE SYNONYM VertexAssetDetailExtract FOR ' + @VertexAssetDetailExtract;
EXEC(@DynamicSynonymSQL12)
END	

IF OBJECT_ID('VertexAssetSKUDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexAssetSKUDetailExtract
END
IF OBJECT_ID('VertexAssetSKUDetailExtract') IS NULL
BEGIN
DECLARE @VertexAssetSKUDetailExtract nvarchar(400)= 'tempdb..VertexAssetSKUDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL13 nvarchar(MAX) = 'CREATE SYNONYM VertexAssetSKUDetailExtract FOR ' + @VertexAssetSKUDetailExtract;
EXEC(@DynamicSynonymSQL13)
END	

IF OBJECT_ID('VertexReceivableCodeDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexReceivableCodeDetailExtract
END
IF OBJECT_ID('VertexReceivableCodeDetailExtract') IS NULL
BEGIN
DECLARE @VertexReceivableCodeDetailExtract nvarchar(400)= 'tempdb..VertexReceivableCodeDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL14 nvarchar(MAX) = 'CREATE SYNONYM VertexReceivableCodeDetailExtract FOR ' + @VertexReceivableCodeDetailExtract;
EXEC(@DynamicSynonymSQL14)
END		

IF OBJECT_ID('VertexUpfrontRentalDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexUpfrontRentalDetailExtract
END
IF OBJECT_ID('VertexUpfrontRentalDetailExtract') IS NULL
BEGIN
DECLARE @VertexUpfrontRentalDetailExtract nvarchar(400)= 'tempdb..VertexUpfrontRentalDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL15 nvarchar(MAX) = 'CREATE SYNONYM VertexUpfrontRentalDetailExtract FOR ' + @VertexUpfrontRentalDetailExtract;
EXEC(@DynamicSynonymSQL15)
END

IF OBJECT_ID('VertexUpfrontCostDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexUpfrontCostDetailExtract
END
IF OBJECT_ID('VertexUpfrontCostDetailExtract') IS NULL
BEGIN
DECLARE @VertexUpfrontCostDetailExtract nvarchar(400)= 'tempdb..VertexUpfrontCostDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL16 nvarchar(MAX) = 'CREATE SYNONYM VertexUpfrontCostDetailExtract FOR ' + @VertexUpfrontCostDetailExtract;
EXEC(@DynamicSynonymSQL16)
END

IF OBJECT_ID('VertexWSTransactionExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexWSTransactionExtract
END
IF OBJECT_ID('VertexWSTransactionExtract') IS NULL
BEGIN
DECLARE @VertexWSTransactionExtract nvarchar(400)= 'tempdb..VertexWSTransaction_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL17 nvarchar(MAX) = 'CREATE SYNONYM VertexWSTransactionExtract FOR ' + @VertexWSTransactionExtract;
EXEC(@DynamicSynonymSQL17)
END			

IF OBJECT_ID('VertexWSTransactionChunksExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexWSTransactionChunksExtract
END
IF OBJECT_ID('VertexWSTransactionChunksExtract') IS NULL
BEGIN
DECLARE @VertexWSTransactionChunksExtract nvarchar(400)= 'tempdb..VertexWSTransactionChunks_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL18 nvarchar(MAX) = 'CREATE SYNONYM VertexWSTransactionChunksExtract FOR ' + @VertexWSTransactionChunksExtract;
EXEC(@DynamicSynonymSQL18)
END

IF OBJECT_ID('VertexWSTransactionChunkDetailsExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VertexWSTransactionChunkDetailsExtract
END
IF OBJECT_ID('VertexWSTransactionChunkDetailsExtract') IS NULL
BEGIN
DECLARE @VertexWSTransactionChunkDetailsExtract nvarchar(400)= 'tempdb..VertexWSTransactionChunkDetails_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL19 nvarchar(MAX) = 'CREATE SYNONYM VertexWSTransactionChunkDetailsExtract FOR ' + @VertexWSTransactionChunkDetailsExtract;
EXEC(@DynamicSynonymSQL19)
END

IF OBJECT_ID('NonVertexAssetDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexAssetDetailExtract
END
IF OBJECT_ID('NonVertexAssetDetailExtract') IS NULL
BEGIN
DECLARE @NonVertexAssetDetailExtract nvarchar(400)= 'tempdb..NonVertexAssetDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL20 nvarchar(MAX) = 'CREATE SYNONYM NonVertexAssetDetailExtract FOR ' + @NonVertexAssetDetailExtract;
EXEC(@DynamicSynonymSQL20)
END

IF OBJECT_ID('NonVertexLocationDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexLocationDetailExtract
END
IF OBJECT_ID('NonVertexLocationDetailExtract') IS NULL
BEGIN
DECLARE @NonVertexLocationDetailExtract nvarchar(400)= 'tempdb..NonVertexLocationDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL21 nvarchar(MAX) = 'CREATE SYNONYM NonVertexLocationDetailExtract FOR ' + @NonVertexLocationDetailExtract;
EXEC(@DynamicSynonymSQL21)
END

IF OBJECT_ID('NonVertexReceivableCodeDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexReceivableCodeDetailExtract
END
IF OBJECT_ID('NonVertexReceivableCodeDetailExtract') IS NULL
BEGIN
DECLARE @NonVertexReceivableCodeDetailExtract nvarchar(400)= 'tempdb..NonVertexReceivableCodeDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL22 nvarchar(MAX) = 'CREATE SYNONYM NonVertexReceivableCodeDetailExtract FOR ' + @NonVertexReceivableCodeDetailExtract;
EXEC(@DynamicSynonymSQL22)
END

IF OBJECT_ID('NonVertexCustomerDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexCustomerDetailExtract
END
IF OBJECT_ID('NonVertexCustomerDetailExtract') IS NULL
BEGIN
DECLARE @NonVertexCustomerDetailExtract nvarchar(400)= 'tempdb..NonVertexCustomerDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL23 nvarchar(MAX) = 'CREATE SYNONYM NonVertexCustomerDetailExtract FOR ' + @NonVertexCustomerDetailExtract;
EXEC(@DynamicSynonymSQL23)
END

IF OBJECT_ID('NonVertexLeaseDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexLeaseDetailExtract
END
IF OBJECT_ID('NonVertexLeaseDetailExtract') IS NULL
BEGIN
DECLARE @NonVertexLeaseDetailExtract nvarchar(400)= 'tempdb..NonVertexLeaseDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL24 nvarchar(MAX) = 'CREATE SYNONYM NonVertexLeaseDetailExtract FOR ' + @NonVertexLeaseDetailExtract;
EXEC(@DynamicSynonymSQL24)
END

IF OBJECT_ID('NonVertexUpfrontRentalDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexUpfrontRentalDetailExtract
END
IF OBJECT_ID('NonVertexUpfrontRentalDetailExtract') IS NULL
BEGIN
DECLARE @NonVertexUpfrontRentalDetailExtract nvarchar(400)= 'tempdb..NonVertexUpfrontRentalDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL25 nvarchar(MAX) = 'CREATE SYNONYM NonVertexUpfrontRentalDetailExtract FOR ' + @NonVertexUpfrontRentalDetailExtract;
EXEC(@DynamicSynonymSQL25)
END

IF OBJECT_ID('NonVertexUpfrontCostDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexUpfrontCostDetailExtract
END
IF OBJECT_ID('NonVertexUpfrontCostDetailExtract') IS NULL
BEGIN
DECLARE @NonVertexUpfrontCostDetailExtract nvarchar(400)= 'tempdb..NonVertexUpfrontCostDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL26 nvarchar(MAX) = 'CREATE SYNONYM NonVertexUpfrontCostDetailExtract FOR ' + @NonVertexUpfrontCostDetailExtract;
EXEC(@DynamicSynonymSQL26)
END

IF OBJECT_ID('NonVertexTaxExemptExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexTaxExemptExtract
END
IF OBJECT_ID('NonVertexTaxExemptExtract') IS NULL
BEGIN
DECLARE @NonVertexTaxExemptExtract nvarchar(400)= 'tempdb..NonVertexTaxExempt_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL27 nvarchar(MAX) = 'CREATE SYNONYM NonVertexTaxExemptExtract FOR ' + @NonVertexTaxExemptExtract;
EXEC(@DynamicSynonymSQL27)
END

IF OBJECT_ID('NonVertexReceivableDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexReceivableDetailExtract
END
IF OBJECT_ID('NonVertexReceivableDetailExtract') IS NULL
BEGIN
DECLARE @NonVertexReceivableDetailExtract nvarchar(400)= 'tempdb..NonVertexReceivableDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL28 nvarchar(MAX) = 'CREATE SYNONYM NonVertexReceivableDetailExtract FOR ' + @NonVertexReceivableDetailExtract;
EXEC(@DynamicSynonymSQL28)
END

IF OBJECT_ID('NonVertexTaxRateDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexTaxRateDetailExtract
END
IF OBJECT_ID('NonVertexTaxRateDetailExtract') IS NULL
BEGIN
DECLARE @NonVertexTaxRateDetailExtract nvarchar(400)= 'tempdb..NonVertexTaxRateDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL29 nvarchar(MAX) = 'CREATE SYNONYM NonVertexTaxRateDetailExtract FOR ' + @NonVertexTaxRateDetailExtract;
EXEC(@DynamicSynonymSQL29)
END

IF OBJECT_ID('NonVertexImpositionLevelTaxDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexImpositionLevelTaxDetailExtract
END
IF OBJECT_ID('NonVertexImpositionLevelTaxDetailExtract') IS NULL
BEGIN
DECLARE @NonVertexImpositionLevelTaxDetailExtract nvarchar(400)= 'tempdb..NonVertexImpositionLevelTaxDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL30 nvarchar(MAX) = 'CREATE SYNONYM NonVertexImpositionLevelTaxDetailExtract FOR ' + @NonVertexImpositionLevelTaxDetailExtract;
EXEC(@DynamicSynonymSQL30)
END

IF OBJECT_ID('NonVertexTaxExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM NonVertexTaxExtract
END
IF OBJECT_ID('NonVertexTaxExtract') IS NULL
BEGIN
DECLARE @NonVertexTaxExtract nvarchar(400)= 'tempdb..NonVertexTax_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL31 nvarchar(MAX) = 'CREATE SYNONYM NonVertexTaxExtract FOR ' + @NonVertexTaxExtract;
EXEC(@DynamicSynonymSQL31)
END

IF OBJECT_ID('VATReceivableLocationDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VATReceivableLocationDetailExtract
END
IF OBJECT_ID('VATReceivableLocationDetailExtract') IS NULL
BEGIN
DECLARE @VATReceivableLocationDetailExtract nvarchar(400)= 'tempdb..VATReceivableLocationDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL32 nvarchar(MAX) = 'CREATE SYNONYM VATReceivableLocationDetailExtract FOR ' + @VATReceivableLocationDetailExtract;
EXEC(@DynamicSynonymSQL32)
END

IF OBJECT_ID('VATReceivableDetailExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VATReceivableDetailExtract
END
IF OBJECT_ID('VATReceivableDetailExtract') IS NULL
BEGIN
DECLARE @VATReceivableDetailExtract nvarchar(400)= 'tempdb..VATReceivableDetail_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL33 nvarchar(MAX) = 'CREATE SYNONYM VATReceivableDetailExtract FOR ' + @VATReceivableDetailExtract;
EXEC(@DynamicSynonymSQL33)
END

IF OBJECT_ID('VATReceivableDetailChunkExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VATReceivableDetailChunkExtract
END
IF OBJECT_ID('VATReceivableDetailChunkExtract') IS NULL
BEGIN
DECLARE @VATReceivableDetailChunkExtract nvarchar(400)= 'tempdb..VATReceivableDetailChunk_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL34 nvarchar(MAX) = 'CREATE SYNONYM VATReceivableDetailChunkExtract FOR ' + @VATReceivableDetailChunkExtract;
EXEC(@DynamicSynonymSQL34)
END

IF OBJECT_ID('VATReceivableDetailChunkDetailsExtract') IS NOT NULL AND @RecreateSynonym = 1
BEGIN
DROP SYNONYM VATReceivableDetailChunkDetailsExtract
END
IF OBJECT_ID('VATReceivableDetailChunkDetailsExtract') IS NULL
BEGIN
DECLARE @VATReceivableDetailChunkDetailsExtract nvarchar(400)= 'tempdb..VATReceivableDetailChunkDetails_Extract_'+ REPLACE(DB_NAME(), '_BuildHelper', '');
DECLARE @DynamicSynonymSQL35 nvarchar(MAX) = 'CREATE SYNONYM VATReceivableDetailChunkDetailsExtract FOR ' + @VATReceivableDetailChunkDetailsExtract;
EXEC(@DynamicSynonymSQL35)
END
END

GO

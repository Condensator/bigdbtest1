SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE  PROCEDURE [dbo].[UpdateToolIdentifier]  
(
@TotalNodes int
)
AS 
BEGIN

;WITH CTE_LeaseNumberofContracts
     AS (
			
			SELECT  Count(*)  NumberofContracts,CustomerPartyNumber FROM stgLease
			GROUP BY CustomerPartyNumber
		)
		, CTE_LoanNumberofContracts	
		AS
		(	
			SELECT Count(*)  NumberofContracts,CustomerPartyNumber FROM  stgLoan
			GROUP BY CustomerPartyNumber
		)
		, CTE_CustomerScore AS
		(
			SELECT stgCustomer.CustomerNumber,ISNULL(CTE_LeaseNumberofContracts.NumberofContracts,0)+ISNULL(CTE_LoanNumberofContracts.NumberofContracts,0) AS NumberofContracts
			FROM stgCustomer
			LEFT JOIN CTE_LeaseNumberofContracts ON stgCustomer.CustomerNumber=CTE_LeaseNumberofContracts.CustomerPartyNumber			
			LEFT JOIN CTE_LoanNumberofContracts ON stgCustomer.CustomerNumber=CTE_LoanNumberofContracts.CustomerPartyNumber
		)

Select 
Row_Number() OVER (ORDER BY NumberofContracts DESC) RowNumber, NumberofContracts, CustomerNumber, 
0 AS IsValidRecord, NULL AS ToolIdentifier, NULL AS ModulusWithTotalNodes INTO #CustomerScore FROM CTE_CustomerScore		

--DELETE FROM #CustomerScore WHERE NumberOfContracts = 0;

UPDATE #CustomerScore SET ToolIdentifier = CASE WHEN RowNumber % @TotalNodes = 0 THEN @TotalNodes ELSE RowNumber % @TotalNodes END
FROM #CustomerScore

SELECT IsValidRecord, ToolIdentifier,RowNumber,SUM(NumberofContracts) OVER (PARTITION BY ToolIdentifier ORDER BY RowNumber) AS RunningContractTotal
INTO #CustomersToProcessPerIteration FROM #CustomerScore 

DECLARE @MaxContractPerTool BIGINT = (SELECT Sum(NumberofContracts)/@TotalNodes FROM #CustomerScore);
DECLARE @ToolIdentifier INT = 1;

WHILE(@ToolIdentifier <= @TotalNodes)
BEGIN

UPDATE #CustomersToProcessPerIteration SET IsValidRecord = 1 
WHERE ToolIdentifier = @ToolIdentifier AND RunningContractTotal <= @MaxContractPerTool;

UPDATE T1 SET ToolIdentifier = T2.ToolIdentifier + 1 FROM #CustomerScore T1 
INNER JOIN #CustomersToProcessPerIteration T2 ON T1.RowNumber = T2.RowNumber 
WHERE T2.IsValidRecord = 0 AND T2.ToolIdentifier = @ToolIdentifier;

UPDATE T1 SET ToolIdentifier = T2.ToolIdentifier, IsValidRecord = T2.IsValidRecord
FROM #CustomerScore T1 JOIN #CustomersToProcessPerIteration T2 ON T1.RowNumber = T2.RowNumber WHERE T2.IsValidRecord = 1;

DELETE FROM #CustomersToProcessPerIteration;

INSERT INTO #CustomersToProcessPerIteration
SELECT IsValidRecord, ToolIdentifier,RowNumber,SUM(NumberofContracts) OVER (PARTITION BY ToolIdentifier ORDER BY RowNumber) AS RunningContractTotal 
FROM #CustomerScore WHERE IsValidRecord != 1;

SET @ToolIdentifier = @ToolIdentifier + 1;

END

CREATE TABLE #ToolIdentifierUpdatedTables
(
tableName NVARCHAR(MAX)
)

UPDATE #CustomerScore SET ToolIdentifier = CASE WHEN RowNumber % @TotalNodes = 0 THEN @TotalNodes ELSE RowNumber % @TotalNodes END
FROM #CustomerScore WHERE IsValidRecord != 1
			
	UPDATE stgLease SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgLease
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLease.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgLease')

	UPDATE stgLoan SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgLoan
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLoan.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgLoan')

	UPDATE stgLienFiling SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgLienFiling
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLienFiling.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgLienFiling')

	UPDATE stgPropertyTax SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgPropertyTax
	INNER JOIN stgLease ON stgLease.SequenceNumber=stgPropertyTax.ContractSequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLease.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgPropertyTax')

	UPDATE stgPropertyTax SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgPropertyTax
	INNER JOIN stgLoan ON stgLoan.SequenceNumber=stgPropertyTax.ContractSequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLoan.CustomerPartyNumber

    UPDATE stgDiscounting SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgDiscounting
	INNER JOIN stgLease ON stgLease.SequenceNumber=stgDiscounting.SequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLease.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgDiscounting')
		
	UPDATE stgDiscounting SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgDiscounting
	INNER JOIN stgLoan ON stgLoan.SequenceNumber=stgDiscounting.SequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLoan.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgDiscounting')

	UPDATE stgCreditProfile SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgCreditProfile
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgCreditProfile.CustomerNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgCreditProfile')

	UPDATE stgPayableInvoice SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgPayableInvoice
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgPayableInvoice.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgPayableInvoice')

	UPDATE stgTaxDepEntity SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgTaxDepEntity
	INNER JOIN stgAsset ON stgAsset.Alias=stgTaxDepEntity.AssetAlias
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgAsset.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgTaxDepEntity')

	UPDATE stgSecurityDeposit SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgSecurityDeposit
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgSecurityDeposit.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgSecurityDeposit')

	UPDATE stgSundry SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgSundry
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgSundry.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgSundry')
	
	UPDATE stgSundryRecurring SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgSundryRecurring
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgSundryRecurring.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgSundryRecurring')
	
	UPDATE stgNonAccrual SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgNonAccrual
	INNER JOIN stgLease ON stgLease.SequenceNumber=stgNonAccrual.ContractSequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLease.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgNonAccrual')
	
	UPDATE stgUnallocatedReceipt SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgUnallocatedReceipt
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgUnallocatedReceipt.CustomerPartyNumber	
	WHERE stgUnallocatedReceipt.EntityType = 'Customer'
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgUnallocatedReceipt')

    UPDATE stgUnallocatedReceipt SET ToolIdentifier = 1 WHERE EntityType = '_'
	
	UPDATE stgInsurancePolicy SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgInsurancePolicy
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgInsurancePolicy.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgInsurancePolicy')

	UPDATE stgChargeoffContract SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgChargeoffContract
	INNER JOIN stgLease ON stgLease.SequenceNumber=stgChargeoffContract.SequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLease.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgChargeoffContract')

	UPDATE stgChargeoffContract SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgChargeoffContract
	INNER JOIN stgLoan ON stgLoan.SequenceNumber=stgChargeoffContract.SequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLoan.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgChargeoffContract')
	
	
	UPDATE stgSalesTaxAssessment SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgSalesTaxAssessment
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgSalesTaxAssessment.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgSalesTaxAssessment')
	
	UPDATE stgInvoiceGeneration SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgInvoiceGeneration
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgInvoiceGeneration.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgInvoiceGeneration')

	UPDATE stgDummyReceipt SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgDummyReceipt
	INNER JOIN stgLease ON stgLease.SequenceNumber=stgDummyReceipt.ContractSequencenumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLease.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgDummyReceipt')
	
	UPDATE stgDummyReceipt SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgDummyReceipt
	INNER JOIN stgLoan ON stgLoan.SequenceNumber=stgDummyReceipt.ContractSequencenumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLoan.CustomerPartyNumber

	UPDATE stgLateFeeHistory SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgLateFeeHistory
	INNER JOIN stgLease ON stgLease.SequenceNumber=stgLateFeeHistory.SequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLease.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgLateFeeHistory')

	UPDATE stgLateFeeHistory SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgLateFeeHistory
	INNER JOIN stgLoan ON stgLoan.SequenceNumber=stgLateFeeHistory.SequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLoan.CustomerPartyNumber

	UPDATE stgReceipt SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgReceipt
	INNER JOIN stgLease ON stgLease.SequenceNumber=stgReceipt.ContractSequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLease.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgReceipt')

	UPDATE stgReceipt SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgReceipt
	INNER JOIN stgLoan ON stgLoan.SequenceNumber=stgReceipt.ContractSequenceNumber
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgLoan.CustomerPartyNumber
	
	UPDATE stgCPUContract SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgCPUContract
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgCPUContract.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgCPUContract')

	UPDATE stgCPUAssetMeterReadingUploadRecord SET ToolIdentifier = stgCPUContract.ToolIdentifier
	FROM stgCPUAssetMeterReadingUploadRecord
	INNER JOIN stgCPUContract 
		ON stgCPUAssetMeterReadingUploadRecord.CPINumber =  stgCPUContract.Id 
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgCPUAssetMeterReadingUploadRecord')

	UPDATE stgSalesTaxReceivableTax SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgSalesTaxReceivableTax
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgSalesTaxReceivableTax.CustomerPartyNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgSalesTaxReceivableTax')

	UPDATE stgReceivableInvoice SET ToolIdentifier = CustomerToolIdentifier.ToolIdentifier 
	FROM stgReceivableInvoice
	INNER JOIN #CustomerScore CustomerToolIdentifier
		ON CustomerToolIdentifier.CustomerNumber=stgReceivableInvoice.CustomerNumber
	INSERT INTO #ToolIdentifierUpdatedTables VALUES ('stgReceivableInvoice')

	DECLARE @sql NVARCHAR(MAX)=''
	SELECT @sql =  @sql + 'update ' +  tableName + ' set ToolIdentifier = 1 where ToolIdentifier is null;' 
	 from #ToolIdentifierUpdatedTables 
	EXEC sp_executesql @sql;
END

GO

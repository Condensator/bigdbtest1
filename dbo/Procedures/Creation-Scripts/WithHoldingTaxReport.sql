SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--@FromDate DATE = '2017-09-21',
--@ToDate DATE = '2019-09-18',
--@EntityType NVARCHAR(max) = NULL,
--@EntityId NVARCHAR(MAX) = NULL,
--@TransactionType nvarchar(max)=NULL,
--@LegalEntityName nvarchar(max) = NULL
CREATE PROCEDURE [dbo].[WithHoldingTaxReport] @FromDate DATE = NULL,
	@ToDate DATE = NULL,
	@EntityType NVARCHAR(250) = NULL,
	@EntityId NVARCHAR(250) = NULL,
	@TransactionType NVARCHAR(250) = NULL,
	@LegalEntityName NVARCHAR(250) = NULL,
	@Entity NVARCHAR(250) = NULL
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @WithHoldingTaxReportResultType WithHoldingTaxReportResultType

	CREATE TABLE #WithHoldingTaxReportReceivable (
		[TransactionDate] VARCHAR(30),
		[TransactionType] NVARCHAR(50),
		[Receipt#] NVARCHAR(20),
		[WithholdingTaxRate] DECIMAL(16, 2),
		[WithholdingTaxBase] DECIMAL(16, 2),
		[Customer] NVARCHAR(250),
		[TaxId#] NVARCHAR(150),
		[Currency] NVARCHAR(400),
		[TaxWithheld] DECIMAL(16, 2),
		[ReceiptId#] BIGINT,
		[ContractId#] BIGINT,
		[CustomerId#] BIGINT,
		[AssetSalesId#] BIGINT,
		)

	CREATE TABLE #WithHoldingTaxReportPayable (
		[TransactionDate] VARCHAR(30),
		[TransactionType] NVARCHAR(50),
		[PaymentVoucher#] NVARCHAR(20),
		[WithholdingTaxRate] DECIMAL(16, 2),
		[WithholdingTaxBase] DECIMAL(16, 2),
		[Vendor] NVARCHAR(250),
		[TaxId#] NVARCHAR(150),
		[Currency] NVARCHAR(50),
		[TaxWithheld] DECIMAL(16, 2),
		)

	IF (@TransactionType = 'Receivable')
	BEGIN
		WITH LatestReceiptApplication AS
		(
			SELECT
				ReceiptId,
				Max(Id) AS ReceiptApplicationId
			FROM ReceiptApplications
			GROUP BY ReceiptId
		)
		INSERT INTO #WithHoldingTaxReportReceivable
		SELECT CONVERT(VARCHAR(30), Receipts.PostDate, 103),
			@TransactionType,
			Receipts.Number,
			ReceivableWithholdingTaxDetails.TaxRate,
			SUM(ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount * 100 / ReceivableWithholdingTaxDetails.TaxRate),
			Parties.PartyName,
			Parties.LastFourDigitUniqueIdentificationNumber,
			Receipts.ReceiptAmount_Currency,
			SUM(ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount),
			Receipts.Id,
			Contracts.Id,
			Customers.Id,
			AssetSales.Id
		FROM Receipts
		JOIN LatestReceiptApplication ON Receipts.Id = LatestReceiptApplication.ReceiptId
		JOIN ReceiptApplications ON LatestReceiptApplication.ReceiptApplicationId = ReceiptApplications.Id
		JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
		JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
		JOIN ReceivableWithholdingTaxDetails ON Receivables.Id = ReceivableWithholdingTaxDetails.ReceivableId
		JOIN Customers ON Receivables.CustomerId = Customers.Id
		JOIN Parties ON Customers.Id = Parties.Id
		JOIN LegalEntities ON Receipts.LegalEntityId = LegalEntities.Id
			OR Receivables.LegalEntityId = LegalEntities.Id
		LEFT JOIN Contracts ON Receivables.EntityId = Contracts.Id
			AND Receivables.EntityType = 'CT'
		LEFT JOIN AssetSaleReceivables ON Receivables.Id = AssetSaleReceivables.ReceivableId
		LEFT JOIN AssetSales ON AssetSaleReceivables.AssetSaleId = AssetSales.Id
		WHERE ReceivableWithholdingTaxDetails.TaxRate > 0
			AND (@LegalEntityName IS NULL OR LegalEntities.Name = @LegalEntityName)
			AND Receipts.PostDate >= @FromDate
			AND Receipts.PostDate <= @ToDate
			AND Receipts.STATUS = 'Posted'
			AND ReceivableWithholdingTaxDetails.IsActive = 1
			AND Receivables.IsActive = 1
			AND ReceiptApplicationReceivableDetails.IsActive = 1
			AND ReceiptApplications.CreditApplied_Amount = 0
		GROUP BY Receivables.Id,
			Receipts.Id,
			Receipts.PostDate,
			Receipts.Number,
			ReceivableWithholdingTaxDetails.TaxRate,
			Parties.PartyName,
			Parties.LastFourDigitUniqueIdentificationNumber,
			Contracts.Id,
			Customers.Id,
			AssetSales.Id,
			Receipts.ReceiptAmount_Currency
	END

	IF (@TransactionType = 'Payable')
	BEGIN
	CREATE TABLE #WHTReportJoinedPaymentVoucherDetailsTable(
		[Transaction_Date] VARCHAR(30),
		[PaymentVoucher#] NVARCHAR(20),
		[Withholding_TaxRate$] DECIMAL(16, 2),
		[Withholding_TaxBase$] DECIMAL(16, 2),
		[TaxWithheld$] DECIMAL(16, 2),
		[TreasuryPayableId#] BIGINT)

	CREATE TABLE #WHTJoinedTreasuryPayableDetailsTable(
		[Transaction_Date] VARCHAR(30),
		[PaymentVoucher#] NVARCHAR(20),
		[Withholding_TaxRate$] DECIMAL(16, 2),
		[Withholding_TaxBase$] DECIMAL(16, 2),
		[TaxWithheld$] DECIMAL(16, 2),
		[PayableId#] BIGINT)

	CREATE TABLE #WHTJoinedPayableTable(
		[Transaction_Date] VARCHAR(30),
		[PaymentVoucher#] NVARCHAR(20),
		[Withholding_TaxRate$] DECIMAL(16, 2),
		[Withholding_TaxBase$] DECIMAL(16, 2),
		[TaxWithheld$] DECIMAL(16, 2),
		[PayeeId#] BIGINT,
		[Currency$] NVARCHAR(50))

	CREATE TABLE #WHTJoinedVendorTable(
		[Transaction_Date] VARCHAR(30),
		[PaymentVoucher#] NVARCHAR(20),
		[Currency$] NVARCHAR(50),
		[VendorId#] BIGINT)

	CREATE TABLE #WHTJoinedPartiesTable(
		[Transaction_Date] VARCHAR(30),
		[PaymentVoucher#] NVARCHAR(20),
		[Vendor] NVARCHAR(250),
		[TaxId] NVARCHAR(150),
		[Currency$] NVARCHAR(50))

		CREATE TABLE #WHTReportTaxCalculationTable(
		[PaymentVoucher#] NVARCHAR(20),
		[Withholding_TaxRate$] DECIMAL(16, 2),
		[Withholding_TaxBase$] DECIMAL(16, 2),
		[TaxWithheld$] DECIMAL(16, 2))


		INSERT INTO #WHTReportJoinedPaymentVoucherDetailsTable
		SELECT CONVERT(VARCHAR(10), PaymentVouchers.PostDate, 103),
		Paymentvouchers.VoucherNumber,
		(PaymentVoucherDetails.WithholdingTaxAmount_Amount / (PaymentVoucherDetails.Amount_Amount + PaymentVoucherDetails.WithholdingTaxAmount_Amount))*100,
		PaymentVoucherDetails.Amount_Amount + PaymentVoucherDetails.WithholdingTaxAmount_Amount,
		PaymentVoucherDetails.WithholdingTaxAmount_Amount,
		PaymentVoucherDetails.TreasuryPayableId
		FROM Paymentvouchers
		JOIN PaymentVoucherDetails ON PaymentVouchers.Id = PaymentVoucherDetails.PaymentVoucherId
		JOIN LegalEntities ON LegalEntities.Id = Paymentvouchers.LegalEntityId
		WHERE (@LegalEntityName IS NULL OR LegalEntities.Name = @LegalEntityName)
			AND PaymentVouchers.PostDate >= @FromDate
			AND PaymentVouchers.PostDate <= @ToDate
			AND Paymentvouchers.[Status]='Paid'

		INSERT INTO #WHTJoinedTreasuryPayableDetailsTable
		SELECT 
		[Transaction_Date],
		[PaymentVoucher#],
		[Withholding_TaxRate$],
		[Withholding_TaxBase$],
		[TaxWithheld$],
		Payables.Id
		FROM  #WHTReportJoinedPaymentVoucherDetailsTable
		JOIN TreasuryPayables ON TreasuryPayables.Id = #WHTReportJoinedPaymentVoucherDetailsTable.TreasuryPayableId#
		JOIN TreasuryPayableDetails ON TreasuryPayables.Id = TreasuryPayableDetails.TreasuryPayableId
		JOIN Payables ON Payables.Id = TreasuryPayableDetails.PayableId
		WHERE TreasuryPayableDetails.IsActive = 1

		INSERT INTO #WHTJoinedPayableTable
		SELECT 
		[Transaction_Date],
		[PaymentVoucher#],
		[Withholding_TaxRate$],
		[Withholding_TaxBase$],
		[TaxWithheld$],
		Payables.PayeeId,
		Payables.TaxPortion_Currency
		FROM  #WHTJoinedTreasuryPayableDetailsTable
		JOIN Payables ON Payables.Id = #WHTJoinedTreasuryPayableDetailsTable.PayableId#

		INSERT INTO #WHTJoinedVendorTable
		SELECT 
		[Transaction_Date],
		[PaymentVoucher#],
		[Currency$],
		Vendors.Id 
		FROM  #WHTJoinedPayableTable
		JOIN Vendors ON Vendors.Id = #WHTJoinedPayableTable.PayeeId#

		INSERT INTO #WHTJoinedPartiesTable
		SELECT 
		[Transaction_Date],
		[PaymentVoucher#],
		Parties.PartyName,
		Parties.LastFourDigitUniqueIdentificationNumber,
		[Currency$]
		FROM  #WHTJoinedVendorTable
		JOIN Parties ON Parties.Id = #WHTJoinedVendorTable.VendorId#

		INSERT INTO #WHTReportTaxCalculationTable
		SELECT [PaymentVoucher#],SUM([Withholding_TaxRate$]),SUM([Withholding_TaxBase$]), SUM([TaxWithheld$])
		FROM #WHTJoinedTreasuryPayableDetailsTable 
		GROUP BY [PaymentVoucher#]

		INSERT INTO  #WithHoldingTaxReportPayable 
		SELECT 	DISTINCT								   
		[Transaction_Date],						   
		@TransactionType,
		#WHTReportTaxCalculationTable.[PaymentVoucher#],
		[Withholding_TaxRate$],
		[Withholding_TaxBase$],
		[Vendor],
		[TaxId],
		[Currency$],
		[TaxWithheld$]
		FROM #WHTReportTaxCalculationTable JOIN #WHTJoinedPartiesTable ON #WHTReportTaxCalculationTable.PaymentVoucher#=#WHTJoinedPartiesTable.PaymentVoucher#

		drop table  #WHTReportJoinedPaymentVoucherDetailsTable
		drop table  #WHTJoinedTreasuryPayableDetailsTable
		drop table  #WHTJoinedPayableTable
		drop table #WHTReportTaxCalculationTable
		drop table #WHTJoinedVendorTable
		drop table #WHTJoinedPartiesTable

	END

	IF (@EntityType IS NULL)
	BEGIN
		INSERT INTO @WithHoldingTaxReportResultType
		SELECT [TransactionDate],
			[TransactionType],
			[Receipt#],
			[WithholdingTaxRate],
			[WithholdingTaxBase],
			[Customer],
			[TaxId#],
			[Currency],
			[TaxWithheld]
		FROM #WithHoldingTaxReportReceivable;
	END

	IF (@EntityType = 'Customer')
	BEGIN
		INSERT INTO @WithHoldingTaxReportResultType
		SELECT [TransactionDate],
			[TransactionType],
			[Receipt#],
			[WithholdingTaxRate],
			[WithholdingTaxBase],
			[Customer],
			[TaxId#],
			[Currency],
			[TaxWithheld]
		FROM #WithHoldingTaxReportReceivable
		WHERE (
				@EntityId IS NULL
				OR #WithHoldingTaxReportReceivable.[CustomerId#] = @EntityId
				);
	END

	IF (@EntityType = 'Receipts')
	BEGIN
		INSERT INTO @WithHoldingTaxReportResultType
		SELECT [TransactionDate],
			[TransactionType],
			[Receipt#],
			[WithholdingTaxRate],
			[WithholdingTaxBase],
			[Customer],
			[TaxId#],
			[Currency],
			[TaxWithheld]
		FROM #WithHoldingTaxReportReceivable
		WHERE (
				@EntityId IS NULL
				OR #WithHoldingTaxReportReceivable.[ReceiptId#] = @EntityId
				)
	END

	IF (@EntityType = 'AssetSale')
	BEGIN
		INSERT INTO @WithHoldingTaxReportResultType
		SELECT [TransactionDate],
			[TransactionType],
			[Receipt#],
			[WithholdingTaxRate],
			[WithholdingTaxBase],
			[Customer],
			[TaxId#],
			[Currency],
			[TaxWithheld]
		FROM #WithHoldingTaxReportReceivable
		WHERE (
				@EntityId IS NULL
				OR #WithHoldingTaxReportReceivable.AssetSalesId# = @EntityId
				)
	END

	IF (@EntityType = 'Lease')
	BEGIN
		INSERT INTO @WithHoldingTaxReportResultType
		SELECT [TransactionDate],
			[TransactionType],
			[Receipt#],
			[WithholdingTaxRate],
			[WithholdingTaxBase],
			[Customer],
			[TaxId#],
			[Currency],
			[TaxWithheld]
		FROM #WithHoldingTaxReportReceivable
		JOIN LeaseFinances ON #WithHoldingTaxReportReceivable.[ContractId#] = LeaseFinances.ContractId
		WHERE (
				@EntityId IS NULL
				OR #WithHoldingTaxReportReceivable.[ContractId#] = @EntityId
				)
			AND LeaseFinances.IsCurrent = 1
			--select * from #WithHoldingTaxReport
	END

	IF (@EntityType = 'Loan')
	BEGIN
		INSERT INTO @WithHoldingTaxReportResultType
		SELECT [TransactionDate],
			[TransactionType],
			[Receipt#],
			[WithholdingTaxRate],
			[WithholdingTaxBase],
			[Customer],
			[TaxId#],
			[Currency],
			[TaxWithheld]
		FROM #WithHoldingTaxReportReceivable
		JOIN LoanFinances ON #WithHoldingTaxReportReceivable.[ContractId#] = LoanFinances.ContractId
		WHERE (
				@EntityId IS NULL
				OR #WithHoldingTaxReportReceivable.[ContractId#] = @EntityId
				)
			AND LoanFinances.IsCurrent = 1
	END

	IF (@EntityType = 'PaymentVoucher')
	BEGIN
		INSERT INTO @WithHoldingTaxReportResultType
		SELECT * FROM #WithHoldingTaxReportPayable
		WHERE ( @Entity IS NULL OR #WithHoldingTaxReportPayable.PaymentVoucher# = @Entity)
	END

	SELECT * FROM @WithHoldingTaxReportResultType WHERE [TaxWithheld] > 0

	DROP TABLE #WithHoldingTaxReportReceivable

	DROP TABLE #WithHoldingTaxReportPayable
END

GO

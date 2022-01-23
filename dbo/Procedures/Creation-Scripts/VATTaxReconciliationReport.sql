SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[VATTaxReconciliationReport]
(
@CustomerId Int,
@VendorId Int,
@CountryId Int,
@TaxCodeId Int,
@FromDate DateTime,
@ToDate DateTime,
@CommaSeparatedLegalEntityIds Nvarchar(max),
@Culture NVARCHAR(10)
)
As
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON
Declare @ReconciliationString nvarchar(Max)
Set @ReconciliationString = '
(SELECT 
		RI.Id As InvoiceId,
		LE.Name AS LegalEntity,
		RI.CurrencyISO,
		''Customer'' AS EntityType,
		RI.CustomerName As EntityName,
		CASE WHEN RI.InvoiceAmount_Amount < 0 
					THEN ''Credit Note'' 
							ELSE ''Receivable Invoice'' END AS InvoiceType,
		RI.Number as InvoiceNumber,
		RI.InvoiceRunDate As InvoiceDate,
		RI.DueDate,
		RI.InvoiceAmount_Amount As InvoiceTotal,
		TC.Name as TaxCode,
		RTD.Amount_Amount as TaxAmount,
		RTI.AppliedTaxRate,
		''No'' as InputTax,
		CT.LongName as Country,
		LE.Id as LegalEntityId,
		C.Id as CurrencyId 
		into #temp
FROM ReceivableInvoices				 RI
INNER JOIN ReceivableInvoiceDetails  RID  ON RI.Id = RID.ReceivableInvoiceId AND RI.IsActive=1 AND RI.ReceivableTaxType=''VAT''
INNER JOIN ReceivableTaxDetails      RTD  ON RID.ReceivableDetailId = RTD.ReceivableDetailId AND RID.IsActive = 1
INNER JOIN ReceivableTaxImpositions  RTI  ON RTD.Id = RTI.ReceivableTaxDetailId AND RTD.IsActive=1
INNER JOIN Countries                 CT    ON RI.DealCountryId = CT.Id
INNER JOIN LegalEntities             LE   ON RI.LegalEntityId = LE.Id
INNER JOIN Currencies				 C	  ON RI.CurrencyId = C.Id 
LEFT JOIN TaxCodes                   TC   ON RTD.TaxCodeId = TC.Id AND RTI.IsActive =1
RECEIVABLEINVOICEWHERECONDITION)
UNION
(SELECT 
		PIS.Id as InvoiceId,
		LE.Name AS LegalEntity,
		C.Name AS CurrencyISO,
		''Vendor'' AS EntityType,
		P.CompanyName As EntityName,
		''PayableInvoice''  AS InvoiceType,
		PIS.InvoiceNumber,
		PIS.InvoiceDate As InvoiceDate,
		PIS.DueDate,
		(PIS.InvoiceTotal_Amount * -1) As InvoiceTotal,
		TC.Name as TaxCode,
		(PIOC.Amount_Amount * -1)  as TaxAmount,
		TCR.Rate As AppliedTaxRate,
		''Yes'' as InputTax,
		CT.LongName as Country,
		LE.Id as LegalEntityId,
		C.Id as CurrencyId
FROM PayableInvoices PIS
INNER JOIN PayableInvoiceOtherCosts  PIOC ON PIS.Id = PIOC.PayableInvoiceId AND PIS.Status=''Completed'' 
INNER JOIN Countries                 CT   ON PIS.CountryId = CT.Id AND PIOC.IsActive =1 AND PIOC.VATType in (''VAT'',''Finance'')
INNER JOIN TaxCodeRates				 TCR  ON PIOC.TaxCodeRateId = TCR.Id
INNER JOIN LegalEntities             LE   ON PIS.LegalEntityId = LE.Id
INNER JOIN Currencies				 C    ON PIS.CurrencyId = C.Id
INNER JOIN Parties					 P    ON PIS.VendorId = P.Id
LEFT JOIN TaxCodes                   TC   ON PIOC.TaxCodeId = TC.Id 
LEFT JOIN (SELECT LeaseFundings.FundingId, LeaseFinances.ContractId, LeaseFinances.IsCurrent FROM LeaseFundings JOIN LeaseFinances ON LeaseFundings.LeaseFinanceId = LeaseFinances.Id) AS ls ON PIS.Id = ls.FundingId
where (ls.FundingId IS NULL OR (ls.ContractId=PIS.ContractId and ls.IsCurrent=1))
PAYABLEINVOICEWHERECONDITION)


(SELECT DISTINCT ReceivableInvoices.LegalEntityId ,ReceivableInvoices.CurrencyId,ReceivableInvoices.InvoiceAmount_Amount As InvoiceTotalAmount,ReceivableInvoices.Number  into #InvoiceAmountTemp FROM #Temp 
INNER JOIN  ReceivableInvoices on #temp.InvoiceId = ReceivableInvoices.Id
WHERE #temp.InvoiceType=''Receivable Invoice'' or #temp.InvoiceType=''Credit Note'' )
UNION
(SELECT DISTINCT PayableInvoices.LegalEntityId,PayableInvoices.CurrencyId ,(PayableInvoices.InvoiceTotal_Amount * -1) As InvoiceTotalAmount,PayableInvoices.InvoiceNumber FROM #Temp 
INNER JOIN PayableInvoices on #temp.InvoiceId = PayableInvoices.Id
WHERE #temp.InvoiceType=''PayableInvoice'' )


SELECT LE.Id as LegalEntityId, C.Id As CurrencyId,Sum(#InvoiceAmountTemp.InvoiceTotalAmount) As InvoiceTotalAmount Into #TotalAmountTemp FROM #InvoiceAmountTemp
INNER JOIN LegalEntities             LE   ON #InvoiceAmountTemp.LegalEntityId = LE.Id
INNER JOIN Currencies				 C    ON #InvoiceAmountTemp.CurrencyId = C.Id
GROUP by LE.Id,C.Id


SELECT t.InvoiceId,
		t.LegalEntity,
		t.CurrencyISO,
		t.EntityType,
		t.EntityName,
		t.InvoiceType,
		t.InvoiceNumber,
		t.InvoiceDate,
		t.DueDate,
		t.InvoiceTotal,
		t.TaxCode,
		Sum(t.TaxAmount) as TaxAmount,
		t.AppliedTaxRate,
		t.InputTax,
		t.Country,
		tat.InvoiceTotalAmount from #temp t
INNER JOIN #TotalAmountTemp tat ON t.LegalEntityId = tat.LegalEntityId and t.CurrencyId = tat.CurrencyId
GROUP BY t.InvoiceId,t.InvoiceNumber,t.LegalEntity,t.CurrencyISO,t.Country,t.EntityName,t.EntityType,t.InvoiceDate,t.DueDate,t.TaxCode,t.TaxCode,t.InvoiceTotal,t.AppliedTaxRate,tat.InvoiceTotalAmount,t.InvoiceType,t.InputTax

DROP TABLE #temp
DROP TABLE #TotalAmountTemp
DROP TABLE #InvoiceAmountTemp'
Declare @ReceivableInvoiceWhereCondition nvarchar(Max)
Set @ReceivableInvoiceWhereCondition = ''

If @CustomerId Is Not Null  
begin
Set @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' Where RI.CustomerID = @CustomerId '
end
If @CountryId Is Not Null
Begin
If Len(@ReceivableInvoiceWhereCondition) = 0  Set @ReceivableInvoiceWhereCondition = ' Where ' Else  Set @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' And '
Set @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' RI.DealCountryId = @CountryId'
End
If @TaxCodeId Is Not Null
Begin
If Len(@ReceivableInvoiceWhereCondition) = 0 Set @ReceivableInvoiceWhereCondition = ' Where ' Else  Set @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' And '
Set @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' RTD.TaxCodeId = @TaxCodeId'
End
If @FromDate Is Not Null And @ToDate Is Not Null
Begin
If Len(@ReceivableInvoiceWhereCondition) = 0 Set @ReceivableInvoiceWhereCondition = ' Where ' Else  Set @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' And '
Set @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' (RI.DueDate Between @FromDate And @ToDate)  '
End
Else If @FromDate Is Not Null And @ToDate Is Null
Begin
If Len(@ReceivableInvoiceWhereCondition) = 0 Set @ReceivableInvoiceWhereCondition = ' Where ' Else  Set @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' And '
Set @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' (RI.DueDate = @FromDate) '
End
IF LEN(@CommaSeparatedLegalEntityIds) > 0
BEGIN
If Len(@ReceivableInvoiceWhereCondition) = 0 Set @ReceivableInvoiceWhereCondition = ' Where ' Else  Set @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' And '
SET @ReceivableInvoiceWhereCondition = @ReceivableInvoiceWhereCondition + ' RI.LegalEntityId IN (' + @CommaSeparatedLegalEntityIds + ') '
END
If Len(@ReceivableInvoiceWhereCondition) <> 0 AND (@CustomerId Is Not  NUll OR (@VendorId Is NULL AND @CustomerId Is  NUll))
Set @ReconciliationString = Replace(@ReconciliationString, 'RECEIVABLEINVOICEWHERECONDITION', @ReceivableInvoiceWhereCondition)
Else if @VendorId Is NULL AND @CustomerId Is  NUll
Set @ReconciliationString = Replace(@ReconciliationString, 'RECEIVABLEINVOICEWHERECONDITION', '')
Else 
Set @ReconciliationString = Replace(@ReconciliationString, 'RECEIVABLEINVOICEWHERECONDITION', 'WHERE 1=0')


--Payable Invoice Condition-------
Declare @PayableInvoiceWhereCondition nvarchar(Max)
Set @PayableInvoiceWhereCondition = ''

If @VendorId Is Not Null 
begin
Set @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' And PIS.VendorId = @VendorId '
end
If @CountryId Is Not Null
Begin
If Len(@PayableInvoiceWhereCondition) = 0 Set @PayableInvoiceWhereCondition = ' And ' Else  Set @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' And '
Set @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' PIS.CountryId = @CountryId'
End
If @TaxCodeId Is Not Null
Begin
If Len(@PayableInvoiceWhereCondition) = 0 Set @PayableInvoiceWhereCondition = ' And ' Else  Set @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' And '
Set @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' PIOC.TaxCodeId = @TaxCodeId'
End
If @FromDate Is Not Null And @ToDate Is Not Null
Begin
If Len(@PayableInvoiceWhereCondition) = 0 Set @PayableInvoiceWhereCondition = ' And ' Else  Set @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' And '
Set @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' (PIS.DueDate Between @FromDate And @ToDate)  '
End
Else If @FromDate Is Not Null And @ToDate Is Null
Begin
If Len(@PayableInvoiceWhereCondition) = 0 Set @PayableInvoiceWhereCondition = ' And ' Else  Set @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' And '
Set @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' (PIS.DueDate = @FromDate) '
End
IF LEN(@CommaSeparatedLegalEntityIds) > 0
BEGIN
If Len(@PayableInvoiceWhereCondition) = 0 Set @PayableInvoiceWhereCondition = ' And ' Else  Set @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' And '
SET @PayableInvoiceWhereCondition = @PayableInvoiceWhereCondition + ' PIS.LegalEntityId IN (' + @CommaSeparatedLegalEntityIds + ') '
END
If Len(@PayableInvoiceWhereCondition) <> 0 AND ( @VendorId Is Not NULL OR (@VendorId Is NULL AND @CustomerId Is  NUll)) 
Set @ReconciliationString = Replace(@ReconciliationString, 'PAYABLEINVOICEWHERECONDITION', @PayableInvoiceWhereCondition)
Else if @VendorId Is NULL AND @CustomerId Is  NUll
Set @ReconciliationString = Replace(@ReconciliationString, 'PAYABLEINVOICEWHERECONDITION', '')
Else
Set @ReconciliationString = Replace(@ReconciliationString, 'PAYABLEINVOICEWHERECONDITION', 'And 1=0')

exec sp_executesql @ReconciliationString,
N'@CustomerId Int,@VendorId Int, @CountryId Int,@TaxCodeId Int, @FromDate DateTime, @ToDate DateTime, @Culture NVARCHAR(10)',
@CustomerId,@VendorId,@CountryId,@TaxCodeId, @FromDate, @ToDate, @Culture

GO

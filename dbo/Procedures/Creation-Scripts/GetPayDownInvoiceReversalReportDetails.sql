SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetPayDownInvoiceReversalReportDetails]
(
@LoanPaydownId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
CREATE TABLE #PaydownReversalAmountDetails
(
Id BIGINT,
Particulars nvarchar(50),
Rent DECIMAL(18,2),
Tax DECIMAL(18,2),
Total DECIMAL(18,2),
OrderId int
)
INSERT INTO #PaydownReversalAmountDetails(Id,Particulars,Rent,Tax,Total,OrderId)
SELECT
LPDS.LoanPaydownId
,RC.Name
,AR.TotalAmount_Amount
,ISNULL(-RT.Amount_Amount,0.0)
,(AR.TotalAmount_Amount + ISNULL(-RT.Amount_Amount,0.0))
,3
FROM LoanPaydowns LPD
INNER JOIN LoanPaydownSundries LPDS ON LPD.Id = LPDS.LoanPaydownId
JOIN Sundries SD ON LPDS.SundryId = SD.Id
JOIN Receivables R ON SD.ReceivableId = R.Id
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceivableDetails ARD ON Rd.Id = ARD.AdjustmentBasisReceivableDetailId
JOIN Receivables AR ON ARD.ReceivableId = AR.Id
JOIN ReceivableCodes RC ON LPDS.SundryReceivableCodeId = RC.Id
LEFT JOIN ReceivableTaxes RT ON RT.ReceivableId = SD.ReceivableId AND RT.IsActive = 1
WHERE LPDS.IncludeInPaydownInvoice = 1
AND LPDS.SundryType = 'ReceivableOnly'
AND LPDS.IsActive = 1
AND LPD.Id = @LoanPaydownId
INSERT INTO #PaydownReversalAmountDetails(Id,Particulars,Rent,Tax,Total,OrderId)
SELECT
LPD.Id
,RC.Name
,AR.TotalAmount_Amount
,ISNULL(-RT.Amount_Amount,0.0)
,(AR.TotalAmount_Amount + ISNULL(-RT.Amount_Amount,0.0))
,3
FROM LoanPaydowns LPD
INNER JOIN Receivables R on R.SourceId= LPD.Id AND R.SourceTable ='LoanPaydown' AND R.IsActive=1
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
INNER JOIN ReceivableDetails ARD ON RD.Id = ARD.AdjustmentBasisReceivableDetailId
INNER JOIN Receivables AR ON ARD.ReceivableId = AR.Id
INNER JOIN ReceivableCodes RC ON LPD.CasualtyReceivableCodeId = RC.Id
INNER JOIN Sundries SD ON R.Id = SD.ReceivableId
LEFT JOIN ReceivableTaxes RT ON RT.ReceivableId = SD.ReceivableId AND RT.IsActive = 1
WHERE
LPD.Id = @LoanPaydownId
INSERT INTO #PaydownReversalAmountDetails(Id,Particulars,Rent,Tax,Total,OrderId)
SELECT
LPDSD.LoanPaydownId
,'Security Deposit Applied'
,SUM(-LPDSD.AmountAppliedToPayDown_Amount)
,0.0
,SUM(-LPDSD.AmountAppliedToPayDown_Amount)
,4
FROM LoanPaydownSecurityDeposits LPDSD
INNER JOIN LoanPaydowns LPD ON LPD.Id = LPDSD.LoanPaydownId
WHERE LPDSD.IsActive = 1 AND LPD.Id = @LoanPaydownId
GROUP BY LPDSD.LoanPaydownId
INSERT INTO #PaydownReversalAmountDetails(Id,Particulars,Rent,Tax,Total,OrderId)
SELECT
LPD.Id,
'LOAN PRINCIPAL',
AR.TotalAmount_Amount,
0.0,
AR.TotalAmount_Amount,
1
FROM LoanPaydowns LPD
JOIN Receivables R ON LPD.Id = R.SourceId AND R.SourceTable = 'LoanPaydown'
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceivableDetails ARD ON RD.Id = ARD.AdjustmentBasisReceivableDetailId
JOIN Receivables AR ON ARD.ReceivableId = AR.ID
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND  RT.Name = 'LoanPrincipal'
WHERE LPD.Id = @LoanPaydownId
AND (LPD.PaydownReason ='VoluntaryPrePayment' OR LPD.PaydownReason ='FullPaydown')
INSERT INTO #PaydownReversalAmountDetails(Id,Particulars,Rent,Tax,Total,OrderId)
SELECT
LPD.Id,
'LOAN INTEREST',
AR.TotalAmount_Amount,
0.0,
AR.TotalAmount_Amount,
2
FROM LoanPaydowns LPD
JOIN Receivables R ON LPD.Id = R.SourceId AND R.SourceTable = 'LoanPaydown'
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceivableDetails ARD ON RD.Id = ARD.AdjustmentBasisReceivableDetailId
JOIN Receivables AR ON ARD.ReceivableId = AR.Id
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND  RT.Name = 'LoanInterest'
WHERE LPD.Id = @LoanPaydownId
AND (LPD.PaydownReason ='VoluntaryPrePayment' OR LPD.PaydownReason ='FullPaydown' OR LPD.PaydownReason ='CollateralRelease')
SELECT
LPD.InvoiceDate
,LPD.DueDate
,CT.SequenceNumber AS ContractNumber
,LE.LessorWebAddress
,CASE WHEN LEL.LogoImageFile_Content IS NOT NULL AND LEL.LogoImageFile_Content <> 0x THEN
(SELECT FS.Content FROM FileStores FS WHERE FS.Guid = dbo.GetContentGuid(LEL.LogoImageFile_Content))
ELSE NULL END AS LogoImageFile_Content
,LEL.LogoImageFile_Source
,'image/'+LEL.LogoImageFile_Type AS LogoImageFile_Type
,LEA.AddressLine1 LegalEntityAddressLine1
,LEA.AddressLine2 LegalEntityAddressLine2
,LEA.City LegalEntityCity
,LEA.Division LegalEntityDivision
,LEA.PostalCode LegalEntityPostalCode
,LEAST.LongName LegalEntityStateName
,LEACT.LongName LegalEntityCountryName
,PT.PartyName CustomerName
,BillToAddress.AddressLine1 BillToAddressLine1
,BillToAddress.AddressLine2 BillToAddressLine2
,BillToAddress.City BillToCity
,BillToAddress.Division BillToDivision
,BillToAddress.PostalCode BillToPostalCode
,BTST.LongName BillToStateName
,BTCT.LongName BillToCountryName
,LPD.PrincipalPaydown_Amount
,LPD.PrincipalPaydown_Currency
,LPD.InterestPaydown_Amount
,LPD.InterestPaydown_Currency
--,BillToContact.PhoneNumber1 LessorContactPhone
--,BillToContact.EMailId LessorContactEmail
,ISNULL(Substring(PC.PhoneNumber1,Len(PC.PhoneNumber1)-15,3)+' '+Substring(PC.PhoneNumber1,Len(PC.PhoneNumber1)-12,3)+' '+
Substring(PC.PhoneNumber1,Len(PC.PhoneNumber1)-9,3)+' '+Substring(PC.PhoneNumber1,Len(PC.PhoneNumber1)-6,3)+' '+
Substring(PC.PhoneNumber1,Len(PC.PhoneNumber1)-3,4),
Substring(lec.PhoneNumber1,Len(lec.PhoneNumber1)-15,3)+' '+Substring(lec.PhoneNumber1,Len(lec.PhoneNumber1)-12,3)+' '+
Substring(lec.PhoneNumber1,Len(lec.PhoneNumber1)-9,3)+' '+Substring(lec.PhoneNumber1,Len(lec.PhoneNumber1)-6,3)+' '+
Substring(lec.PhoneNumber1,Len(lec.PhoneNumber1)-3,4)) 'LessorContactPhone',
ISNULL(PC.EMailId,lec.EMailId) 'LessorContactEmail'
,CCD.ISO CurrencyCode
,RI.Number InvoiceNumber
,pd.*
,PAD.Total  as SecurityDepositTotal
FROM LoanPaydowns LPD
INNER JOIN LoanFinances LF ON LPD.LoanFinanceId = LF.Id
INNER JOIN Contracts CT ON LF.ContractId =  CT.Id
INNER JOIN Customers CU ON LF.CustomerId = CU.Id
INNER JOIN Parties PT ON CU.Id =  PT.Id
INNER JOIN BillToes BILLTO ON LPD.BillToId = BILLTO.Id
INNER JOIN Currencies CR ON CT.CurrencyId = CR.Id
INNER JOIN CurrencyCodes CCD ON CCD.Id = CR.CurrencyCodeId
Inner JOIN ReceivableInvoices RI ON LPD.InvoiceId = RI.Id
INNER JOIN #PaydownReversalAmountDetails pd ON pd.Id = LPD.Id
INNER JOIN RemitToes rt ON rt.Id = RI.RemitToId
LEFT JOIN #PaydownReversalAmountDetails PAD on PAD.Id = LPD.Id AND PAD.Particulars='Security Deposit Applied'
LEFT JOIN PartyAddresses BillToAddress ON BILLTO.BillingAddressId = BillToAddress.Id
LEFT JOIN States BTST ON BillToAddress.StateId = BTST.Id
LEFT JOIN Countries BTCT ON BTST.CountryId = BTCT.Id
LEFT JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
LEFT JOIN LegalEntityAddresses LEA ON LE.Id = LEA.LegalEntityId AND LEA.IsActive = 1 AND LEA.IsMain = 1
LEFT JOIN States LEAST ON LEA.StateId = LEAST.Id
LEFT JOIN Countries LEACT ON LEAST.CountryId =  LEACT.Id
LEFT JOIN LegalEntityLogoes LEL ON LE.Id = LEL.Id
LEFT JOIN PartyContacts PC ON rt.PartyContactId = PC.Id
LEFT JOIN dbo.LegalEntityContacts lec ON rt.LegalEntityContactId = lec.Id
WHERE LPD.Id = @LoanPaydownId
ORDER BY pd.OrderId
END

GO

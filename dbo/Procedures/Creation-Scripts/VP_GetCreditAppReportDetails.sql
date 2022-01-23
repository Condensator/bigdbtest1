SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetCreditAppReportDetails]
(
@CreditDecisionStatus NVARCHAR(40)=NULL
,@ContractsFunded NVARCHAR(1)=NULL
,@ContractsBooked NVARCHAR(1)=NULL
,@AvailableBalance NVARCHAR(1)=NULL
,@ProgramVendorNumber NVARCHAR(1000)=NULL
,@DealerOrDistributerNumber NVARCHAR(1000)=NULL
,@IsProgramVendor NVARCHAR(1)=NULL
,@CustomerNumber NVARCHAR(40)=NULL
,@ApplicationStatus NVARCHAR(40)=NULL
,@UDF1Value NVARCHAR(40)=NULL
,@UDF2Value NVARCHAR(40)=NULL
,@UDF3Value NVARCHAR(40)=NULL
,@UDF4Value NVARCHAR(40)=NULL
,@UDF5Value NVARCHAR(40)=NULL
,@CreditApplicationNumberFrom BIGINT=NULL
,@CreditApplicationNumberTo BIGINT=NULL
,@DateSubmittedFrom DATETIME=NULL
,@DateSubmittedTo DATETIME=NULL
,@PrivateLabel NVARCHAR(1)=NULL
,@IsDealerFilterAppliedExternally NVARCHAR(1) = NULL
,@ProgramName NVARCHAR(40) = NULL
,@LegalEntityName NVARCHAR(100)
)
AS
DECLARE @Query NVARCHAR(MAX)
DECLARE @ORIGINATIONWHERECONDITION NVARCHAR(MAX)
DECLARE @CreditApplicationNumber_Condition NVARCHAR(1000)
DECLARE @DateSubmitted_Condition NVARCHAR(1000)
DECLARE @CREDITDECISIONJOINCONDITION NVARCHAR(1000)
DECLARE @CONTRACTSFUNDED_CONDITION NVARCHAR(1000)
DECLARE @CONTRACTSBOOKED_CONDITION NVARCHAR(1000)
DECLARE @PRIVATELABEL_CONDITION NVARCHAR(1000)
DECLARE @vIsProgramVendorType NVARCHAR(20)
DECLARE @vIsProgramVendor NVARCHAR(1)
DECLARE @PROGRAMWHERECONDITION NVARCHAR(40)
SELECT @vIsProgramVendorType= VendorProgramType from Vendors where Id IN (select Id from Parties where PartyNumber=@ProgramVendorNumber)
Set @vIsProgramVendor = case WHEN @vIsProgramVendorType='ProgramVendor' THEN '1'
ELSE '0' END
BEGIN
SET @Query =N'
WITH CTE_Contracts AS
(
SELECT
O.Id
,CT.Id contractid
,CT.SequenceNumber
,CP.Id CreditProfileId
,LEF.Id LeaseFinanceId
,LOF.Id LoanFinanceId
FROM Opportunities O
JOIN  CreditProfiles CP ON CP.OpportunityId = O.Id
JOIN CreditApprovedStructures CAS ON CP.Id = CAS.CreditProfileId
JOIN Contracts CT ON CAS.Id = CT.CreditApprovedStructureId
LEFT JOIN LeaseFinances LEF ON CT.Id = LEF.ContractId AND LEF.IsCurrent = 1 AND (LEF.BookingStatus = ''Commenced'' OR LEF.BookingStatus = ''FullyPaidOff'')
LEFT JOIN LoanFinances LOF ON CT.Id = LOF.ContractId AND LOF.IsCurrent = 1 AND (LOF.Status = ''Commenced'' OR LOF.Status = ''FullyPaidOff'' OR LOF.Status = ''FullyPaid'')
WHERE (LEF.Id IS NOT NULL OR LOF.Id IS NOT NULL)
),
CTE_ContractsBooked AS
(
SELECT
CTE_Contracts.ID
,STUFF((SELECT '',''+ CTS.SequenceNumber  From CTE_Contracts CTS WHERE CTS.id = CTE_Contracts.id
FOR XML PATH(''''), TYPE).value(''.'',''NVARCHAR(MAX)''),1,1,'''') ContractsBooked
FROM CTE_Contracts
GROUP BY CTE_Contracts.ID
),
CTE_DisbursementRequest AS
(
SELECT
PayableInvoice.Id PayableInvoiceId
,PayableInvoice.Balance_Amount
,DisbursementRequest.Status
FROM Opportunities O
LEFT JOIN  CreditProfiles CP ON CP.OpportunityId = O.Id
LEFT JOIN CreditApprovedStructures CAS ON CP.Id = CAS.CreditProfileId
LEFT JOIN Contracts CT ON CAS.Id = CT.CreditApprovedStructureId
LEFT JOIN PayableInvoices PayableInvoice ON PayableInvoice.ContractId = CT.Id
LEFT JOIN Payables Payable ON Payable.EntityType = ''PI'' AND Payable.EntityId = PayableInvoice.Id
LEFT JOIN DisbursementRequestPayables DisbursementRequestPayable  ON Payable.Id=DisbursementRequestPayable.PayableId
LEFT JOIN DisbursementRequestPayees DisbursementRequestPayee ON DisbursementRequestPayable.Id=DisbursementRequestPayee.DisbursementRequestPayableId
LEFT JOIN DisbursementRequestPaymentDetails DisbursementRequestPaymentDetail ON DisbursementRequestPayee.PayeeId=DisbursementRequestPaymentDetail.Id
LEFT JOIN DisbursementRequests DisbursementRequest ON DisbursementRequestPaymentDetail.DisbursementRequestId=DisbursementRequest.Id
WHERE PayableInvoice.Id IS NOT NULL AND PayableInvoice.Balance_Amount = 0.00 AND DisbursementRequest.Status = ''Completed''
GROUP BY
PayableInvoice.Id
,PayableInvoice.Balance_Amount
,DisbursementRequest.Status
),
CTE_ContractsFundedDetail AS
(
SELECT
O.Id
,CT.SequenceNumber
FROM Opportunities O
LEFT JOIN  CreditProfiles CP ON CP.OpportunityId = O.Id
LEFT JOIN CreditApprovedStructures CAS ON CP.Id = CAS.CreditProfileId
LEFT JOIN Contracts CT ON CAS.Id = CT.CreditApprovedStructureId
LEFT JOIN PayableInvoices PayableInvoice ON PayableInvoice.ContractId = CT.Id
LEFT JOIN Payables Payable ON Payable.EntityType = ''PI'' AND Payable.EntityId = PayableInvoice.Id
LEFT JOIN TreasuryPayableDetails TRP ON TRP.PayableId = Payable.Id
LEFT JOIN TreasuryPayables TP ON TP.Id = TRP.TreasuryPayableId
LEFT JOIN PaymentVoucherDetails PVD ON PVD.TreasuryPayableId = TP.Id
LEFT JOIN PaymentVouchers PV ON PV.Id = PVD.PaymentVoucherId AND PV.Status = ''Paid''
LEFT JOIN CTE_DisbursementRequest DR ON DR.PayableInvoiceId = PayableInvoice.Id
WHERE ((DR.Balance_Amount = 0.00 AND DR.Status = ''Completed'') OR PV.Status IS NOT NULL)
GROUP BY
O.Id
,CT.SequenceNumber
),
CTE_InvoicePaidDetail AS
(
SELECT
O.Id
,PayableInvoice.InvoiceNumber
FROM Opportunities O
LEFT JOIN  CreditProfiles CP ON CP.OpportunityId = O.Id
LEFT JOIN CreditApprovedStructures CAS ON CP.Id = CAS.CreditProfileId
LEFT JOIN Contracts CT ON CAS.Id = CT.CreditApprovedStructureId
LEFT JOIN PayableInvoices PayableInvoice ON PayableInvoice.ContractId = CT.Id
LEFT JOIN Payables Payable ON Payable.EntityType = ''PI'' AND Payable.EntityId = PayableInvoice.Id
LEFT JOIN TreasuryPayableDetails TRP ON TRP.PayableId = Payable.Id
LEFT JOIN TreasuryPayables TP ON TP.Id = TRP.TreasuryPayableId
LEFT JOIN PaymentVoucherDetails PVD ON PVD.TreasuryPayableId = TP.Id
LEFT JOIN PaymentVouchers PV ON PV.Id = PVD.PaymentVoucherId AND PV.Status = ''Paid''
LEFT JOIN CTE_DisbursementRequest DR ON DR.PayableInvoiceId = PayableInvoice.Id
WHERE ((DR.Balance_Amount = 0.00 AND DR.Status = ''Completed'') OR PV.Status IS NOT NULL)
GROUP BY
O.Id
,PayableInvoice.InvoiceNumber
),
CTE_ContractsFunded AS
(
SELECT
CTE_ContractsFundedDetail.ID Id
,STUFF((SELECT '',''+ CP.SequenceNumber FROM  CTE_ContractsFundedDetail CP
WHERE CTE_ContractsFundedDetail.Id = CP.Id
FOR XML PATH(''''), TYPE).value(''.'',''NVARCHAR(MAX)''),1,1,'''') ContractsFunded
FROM CTE_ContractsFundedDetail
GROUP BY CTE_ContractsFundedDetail.ID
),
CTE_InvoicePaid AS
(
SELECT
CTE_InvoicePaidDetail.ID Id
,STUFF((SELECT '',''+ PV.InvoiceNumber FROM  CTE_InvoicePaidDetail PV
WHERE CTE_InvoicePaidDetail.Id = PV.Id
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''') InvoicesPaid
FROM CTE_InvoicePaidDetail
GROUP BY CTE_InvoicePaidDetail.ID
),
CTE_MAXCreditDecision AS
(
SELECT
CD.CreditProfileId
,CP.ApprovedAmount_Amount ApprovedAmount
,CD.DecisionStatus CreditDecisionStatus
,CD.ExpiryDate ExpirationDate
,O.Id OpportunityId
FROM Opportunities O
LEFT JOIN CreditProfiles CP ON O.Id = CP.OpportunityId
LEFT JOIN CreditDecisions CD ON CD.CreditProfileId = CP.Id
LEFT JOIN CreditApprovedStructures CAS ON CP.Id = CAS.CreditProfileId
WHERE CD.IsActive = 1 AND  (@CreditDecisionStatus  IS NULL OR CD.DecisionStatus LIKE REPLACE(@CreditDecisionStatus ,''*'',''%''))
GROUP BY
CD.CreditProfileId
,CP.ApprovedAmount_Amount
,CD.DecisionStatus
,CD.ExpiryDate
,O.Id
),
CTE_Result AS
(
SELECT
CAST(O.Number AS BIGINT) CreditApplicationNumber
,P.PartyName CustomerName
,CASE
WHEN CA.VendorId IS NOT NULL
THEN (SELECT OP.PartyName FROM Parties OP WHERE OP.Id = CA.VendorId)
ELSE
(SELECT OP.PartyName FROM Parties OP WHERE OP.Id = O.OriginationSourceId)
END AS ProgramVendor
,CASE
WHEN CA.VendorId IS NOT NULL
THEN (SELECT OP.PartyName FROM Parties OP WHERE OP.Id = O.OriginationSourceId)
ELSE
'' ''
END AS VendorName
,CA.Status ApplicationStatus
,CAST(CA.SubmittedToCreditDate AS DATE) DateSubmitted
,CASE WHEN CA.IsFromVendorPortal = 0 THEN @LegalEntityName ELSE U.FullName END AS FullName
,PD.CreditApplicationAmount_Amount RequestedAmount
,DPT.Name TransactionType
,CA.EquipmentDescription
,Programs.Name ProgramName
,PD.Term
,PD.Frequency
,PD.Advance IsAdvance
,PD.RequestEOTOption RequestedEOTOption
,PD.RequestedPromotionId
,PP.PromotionCode RequestedPromotion
,PP.IsPrivateLabel IsPrivateLabel
,CD.CreditDecisionStatus
,CD.ApprovedAmount
,(ApprovedAmount_Amount - UsedAmount_Amount) AvailableBalance
,CD.ExpirationDate
,CTE_ContractsBooked.ContractsBooked
,CTE_InvoicePaid.InvoicesPaid
,CTE_ContractsFunded.ContractsFunded
,UDF.UDF1Value
,UDF.UDF2Value
,UDF.UDF3Value
,UDF.UDF4Value
,UDF.UDF5Value
FROM Opportunities O
JOIN CreditApplications CA ON O.Id = CA.Id
LEFT JOIN Programs ON CA.ProgramId=Programs.Id
JOIN CreditApplicationPricingDetails PD ON CA.ID = PD.Id
JOIN Customers C ON O.CustomerId = C.Id
JOIN Parties P ON P.Id = C.Id
JOIN Users U ON CA.CreatedById = U.Id
CREDITDECISIONJOINCONDITION
LEFT JOIN UDFs UDF ON O.Number = UDF.CreditApplicationNumber
LEFT JOIN ProgramPromotions PP ON PD.RequestedPromotionId = PP.Id
JOIN Parties OriginationSource ON OriginationSource.Id = O.OriginationSourceId
LEFT JOIN Parties Vendor ON Vendor.Id = CA.VendorId
LEFT JOIN CreditProfiles CP ON O.Id = CP.OpportunityId
LEFT JOIN CTE_ContractsBooked ON CTE_ContractsBooked.Id =  O.Id
LEFT JOIN CTE_ContractsFunded ON CTE_ContractsFunded.Id = O.Id
LEFT JOIN CTE_InvoicePaid ON CTE_InvoicePaid.Id = O.Id
LEFT JOIN DealProductTypes DPT ON DPT.Id = CA.TransactionTypeId
LEFT JOIN LegalEntities LE ON O.LegalEntityId = LE.Id
WHERE
(ORIGINATIONWHERECONDITION
AND CA.CreditApplicationSourceType =''Vendor'')
AND (@CustomerNumber IS NULL OR P.PartyNumber LIKE REPLACE(@CustomerNumber ,''*'',''%''))
AND (@ApplicationStatus IS NULL OR CA.Status LIKE REPLACE(@ApplicationStatus ,''*'',''%''))
AND (@UDF1Value IS NULL OR UDF.UDF1Value LIKE REPLACE(@UDF1Value,''*'',''%''))
AND (@UDF2Value IS NULL OR UDF.UDF2Value LIKE REPLACE(@UDF2Value,''*'',''%''))
AND (@UDF3Value IS NULL OR UDF.UDF3Value LIKE REPLACE(@UDF3Value,''*'',''%''))
AND (@UDF4Value IS NULL OR UDF.UDF4Value LIKE REPLACE(@UDF4Value,''*'',''%''))
AND (@UDF5Value IS NULL OR UDF.UDF5Value LIKE REPLACE(@UDF5Value,''*'',''%''))
CreditApplicationNumber_Condition
DateSubmitted_Condition
ContractsFunded_Condition
ContractsBooked_Condition
PROGRAMWHERECONDITION
)
SELECT
CreditApplicationNumber
,CustomerName
,VendorName
,ProgramVendor
,ProgramName
,ApplicationStatus
,DateSubmitted
,FullName
,RequestedAmount
,TransactionType
,EquipmentDescription
,Term
,Frequency
,IsAdvance
,RequestedEOTOption
,RequestedPromotionId
,RequestedPromotion
,IsPrivateLabel
,CreditDecisionStatus
,ApprovedAmount
,CASE WHEN AvailableBalance = 0 OR AvailableBalance IS NULL THEN  0.00 ELSE AvailableBalance END AvailableBalance
,ExpirationDate
,ContractsBooked
,InvoicesPaid
,ContractsFunded
,UDF1Value
,UDF2Value
,UDF3Value
,UDF4Value
,UDF5Value
FROM  CTE_Result
PrivateLabel_Condition
GROUP BY
CreditApplicationNumber
,CustomerName
,VendorName
,ProgramVendor
,ProgramName
,ApplicationStatus
,DateSubmitted
,FullName
,RequestedAmount
,TransactionType
,EquipmentDescription
,Term
,Frequency
,IsAdvance
,RequestedEOTOption
,RequestedPromotionId
,RequestedPromotion
,IsPrivateLabel
,CreditDecisionStatus
,ApprovedAmount
,AvailableBalance
,ExpirationDate
,ContractsBooked
,InvoicesPaid
,ContractsFunded
,UDF1Value
,UDF2Value
,UDF3Value
,UDF4Value
,UDF5Value
'
IF(@vIsProgramVendor = '0')
SET @ORIGINATIONWHERECONDITION = '(@DealerOrDistributerNumber IS NULL OR @DealerOrDistributerNumber =''''
OR (OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributerNumber,'',''))
AND (@ProgramVendorNumber IS NULL OR @ProgramVendorNumber =''''  OR
Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'','')))))'
ELSE
IF(@IsDealerFilterAppliedExternally = '0')
SET @ORIGINATIONWHERECONDITION = '
(OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributerNumber,'',''))
AND Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
OR (OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
))'
ELSE
SET @ORIGINATIONWHERECONDITION = '
(OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributerNumber,'',''))
AND Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
OR ((@DealerOrDistributerNumber IS NULL OR @DealerOrDistributerNumber ='''')
AND (@ProgramVendorNumber IS NULL OR @ProgramVendorNumber =''''
OR OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
OR  Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))))
)'
IF (@CreditApplicationNumberFrom IS NOT NULL AND @CreditApplicationNumberTo IS NOT NULL AND @CreditApplicationNumberFrom <> '' AND @CreditApplicationNumberTo <> '')
SET @CreditApplicationNumber_Condition =  'AND O.Number BETWEEN @CreditApplicationNumberFrom AND @CreditApplicationNumberTo '
ELSE IF(@CreditApplicationNumberFrom IS NOT NULL AND @CreditApplicationNumberFrom <> '')
SET @CreditApplicationNumber_Condition =  'AND O.Number = @CreditApplicationNumberFrom '
ELSE IF(@CreditApplicationNumberTo IS NOT NULL AND @CreditApplicationNumberTo <> '')
SET @CreditApplicationNumber_Condition =  'AND O.Number = @CreditApplicationNumberTo '
ELSE
SET @CreditApplicationNumber_Condition =  ''
IF(@ContractsFunded IS NULL)
SET @CONTRACTSFUNDED_CONDITION =  ''
ELSE IF (@ContractsFunded='1')
SET @CONTRACTSFUNDED_CONDITION = 'AND CTE_ContractsFunded.ContractsFunded IS NOT NULL'
Else
SET @CONTRACTSFUNDED_CONDITION = 'AND CTE_ContractsFunded.ContractsFunded IS NULL'
IF(@ContractsBooked IS NULL)
SET @CONTRACTSBOOKED_CONDITION =  ''
ELSE IF (@ContractsBooked='1')
SET @CONTRACTSBOOKED_CONDITION = 'AND CTE_ContractsBooked.ContractsBooked IS NOT NULL'
Else
SET @CONTRACTSBOOKED_CONDITION = 'AND CTE_ContractsBooked.ContractsBooked IS NULL'
IF (@PrivateLabel='1')
SET @PRIVATELABEL_CONDITION = 'WHERE IsPrivateLabel = 1'
Else IF(@PrivateLabel='0')
SET @PRIVATELABEL_CONDITION = 'WHERE IsPrivateLabel = 0'
ELSE
SET @PRIVATELABEL_CONDITION = ''
IF (@ProgramName IS NOT NULL AND @ProgramName <> '')
SET @PROGRAMWHERECONDITION =  'AND Programs.Name =''@ProgramName'''
ELSE
SET @PROGRAMWHERECONDITION =  ''
IF (@DateSubmittedFrom IS NOT NULL AND @DateSubmittedTo IS NOT NULL AND @DateSubmittedFrom <> '' AND @DateSubmittedTo <> '')
SET @DateSubmitted_Condition =  'AND CAST(CA.SubmittedToCreditDate AS DATE) BETWEEN CAST(@DateSubmittedFrom AS DATE) AND CAST(@DateSubmittedTo AS DATE) '
ELSE IF(@DateSubmittedFrom IS NOT NULL AND @DateSubmittedFrom <> '')
SET @DateSubmitted_Condition =  'AND CAST(CA.SubmittedToCreditDate AS DATE) = CAST(@DateSubmittedFrom AS DATE) '
ELSE IF(@DateSubmittedTo IS NOT NULL AND @DateSubmittedTo <> '')
SET @DateSubmitted_Condition =  'AND CAST(CA.SubmittedToCreditDate AS DATE) = CAST(@DateSubmittedTo AS DATE) '
ELSE
SET @DateSubmitted_Condition =  ''
IF(@CreditDecisionStatus IS NULL OR @CreditDecisionStatus = '')
SET @CREDITDECISIONJOINCONDITION = 'LEFT JOIN CTE_MAXCreditDecision CD ON CD.OpportunityId = CA.Id'
ELSE
SET @CREDITDECISIONJOINCONDITION = 'INNER JOIN CTE_MAXCreditDecision CD ON CD.OpportunityId = CA.Id'
SET @Query =  REPLACE(@Query, 'ORIGINATIONWHERECONDITION', @ORIGINATIONWHERECONDITION);
SET @Query =  REPLACE(@Query, 'CreditApplicationNumber_Condition', @CreditApplicationNumber_Condition);
SET @Query =  REPLACE(@Query, 'DateSubmitted_Condition', @DateSubmitted_Condition);
SET @Query =  REPLACE(@Query, 'CREDITDECISIONJOINCONDITION', @CREDITDECISIONJOINCONDITION);
SET @Query =  REPLACE(@Query, 'ContractsFunded_Condition', @CONTRACTSFUNDED_CONDITION);
SET @Query =  REPLACE(@Query, 'ContractsBooked_Condition', @CONTRACTSBOOKED_CONDITION);
SET @Query =  REPLACE(@Query, 'PrivateLabel_Condition', @PRIVATELABEL_CONDITION);
SET @Query =  REPLACE(@Query, 'PROGRAMWHERECONDITION', @PROGRAMWHERECONDITION);
--Print @query
EXEC sp_executesql @Query,N'
@CreditDecisionStatus NVARCHAR(40)=NULL
,@ContractsFunded NVARCHAR(1)=NULL
,@ContractsBooked NVARCHAR(1)=NULL
,@AvailableBalance NVARCHAR(1)=NULL
,@ProgramVendorNumber NVARCHAR(40)=NULL
,@DealerOrDistributerNumber NVARCHAR(40)=NULL
,@IsProgramVendor NVARCHAR(1)=NULL
,@CustomerNumber NVARCHAR(40)=NULL
,@ApplicationStatus NVARCHAR(40)=NULL
,@UDF1Value NVARCHAR(40)=NULL
,@UDF2Value NVARCHAR(40)=NULL
,@UDF3Value NVARCHAR(40)=NULL
,@UDF4Value NVARCHAR(40)=NULL
,@UDF5Value NVARCHAR(40)=NULL
,@CreditApplicationNumberFrom BIGINT = NULL
,@CreditApplicationNumberTo BIGINT = NULL
,@DateSubmittedFrom Date=NULL
,@DateSubmittedTo Date=NULL
,@PrivateLabel NVARCHAR(1)=NULL
,@IsDealerFilterAppliedExternally NVARCHAR(1) = NULL
,@ProgramName NVARCHAR(40)=NULL
,@LegalEntityName NVARCHAR(100)'
,@CreditDecisionStatus
,@ContractsFunded
,@ContractsBooked
,@AvailableBalance
,@ProgramVendorNumber
,@DealerOrDistributerNumber
,@IsProgramVendor
,@CustomerNumber
,@ApplicationStatus
,@UDF1Value
,@UDF2Value
,@UDF3Value
,@UDF4Value
,@UDF5Value
,@CreditApplicationNumberFrom
,@CreditApplicationNumberTo
,@DateSubmittedFrom
,@DateSubmittedTo
,@PrivateLabel
,@IsDealerFilterAppliedExternally
,@ProgramName
,@LegalEntityName

END

GO

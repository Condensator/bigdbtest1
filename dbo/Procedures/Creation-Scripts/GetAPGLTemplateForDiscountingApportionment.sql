SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[GetAPGLTemplateForDiscountingApportionment]
@DiscountingIds AS dbo.DiscountingIds READONLY
AS
BEGIN
WITH cte_temp(DiscountingId, GLTemplateId , DiscountingPrincipalPayableCodeId, DiscountingInterestPayableCodeId, rn) AS
(
SELECT  D.Id AS DiscountingId,
COALESCE(APP.GLTemplateId,DF.APTemplateId) AS GLTemplateId,
DF.DiscountingPrincipalPayableCodeId,
DF.DiscountingInterestPayableCodeId,
ROW_NUMBER() OVER (PARTITION BY d.id ORDER BY DRS.DueDate DESC) AS rn
FROM DiscountingRepaymentSchedules DRS
JOIN DiscountingFinances DF ON DRS.DiscountingFinanceId = DF.Id
JOIN Discountings D ON DF.DiscountingId = D.Id
JOIN @DiscountingIds DID ON D.Id = DID.Id
JOIN DiscountingSundries DS ON DRS.Id = DS.PaymentScheduleId
JOIN Sundries S ON DS.Id = S.Id
JOIN Payables P ON S.PayableId = P.Id
JOIN PayableCodes PC ON P.PayableCodeId = PC.Id
LEFT OUTER JOIN TreasuryPayableDetails TPD ON P.Id = TPD.PayableId
LEFT OUTER JOIN TreasuryPayables TP ON TPD.TreasuryPayableId=TP.Id
LEFT OUTER JOIN AccountsPayableDetails APD ON TP.Id = APD.TreasuryPayableId
LEFT OUTER JOIN AccountsPayables AP ON APD.AccountsPayableId = AP.Id
LEFT OUTER JOIN PaymentVoucherInfoes PVI ON AP.Id=PVI.AccountsPayableId
LEFT OUTER JOIN PaymentVouchers PV ON PVI.Id = PV.PaymentVoucherInfoId
LEFT OUTER JOIN AccountsPayablePaymentVouchers APPV ON PV.Id = APPV.PaymentVoucherId
LEFT OUTER JOIN AccountsPayablePayments APP ON APPV.AccountsPayablePaymentId = APP.Id
WHERE DF.IsCurrent=1
AND DRS.IsActive=1 AND S.IsActive=1 AND (TPD.Id IS NULL OR  TPD.IsActive=1)
AND (TPD.Id IS NULL OR TP.Status != 'Inactive')
AND (PV.Id IS NULL OR PV.Status = 'Paid')
AND P.Status !='Pending' AND P.Status != 'Inactive'
AND (APP.GLTemplateId IS NOT NULL  OR DF.APTemplateId IS NOT NULL)
)
SELECT t.DiscountingId,t.GLTemplateId, PC1.GLTemplateId InterestMatchingGLTemplateId , PC2.GLTemplateId PrincipleMatchingGLTemplateId
FROM cte_temp t
LEFT JOIN PayableCodes PC1 ON t.DiscountingInterestPayableCodeId = PC1.Id
LEFT JOIN PayableCodes PC2 ON t.DiscountingPrincipalPayableCodeId = PC2.Id
WHERE rn = 1
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateCustomerForCustomerReviews]
(
@UpdatedById BIGINT,
@customerInfoForUpdate CustomerInfoForUpdate READONLY
)
AS
BEGIN
UPDATE Customers
SET
Customers.AnnualCreditReviewDate = CASE WHEN Customers.NextReviewDate IS NULL OR CustomerToUpdate.SetAnnualReviewDate=0  THEN Customers.AnnualCreditReviewDate
ELSE Customers.NextReviewDate END,
Customers.NextReviewDate = CASE WHEN Customers.NextReviewDate IS NULL THEN Customers.NextReviewDate
WHEN Customers.CreditReviewFrequency = 'Monthly' THEN DATEADD(MONTH, 1, Customers.NextReviewDate)
WHEN Customers.CreditReviewFrequency = 'Quarterly' THEN DATEADD(MONTH, 3, Customers.NextReviewDate)
WHEN Customers.CreditReviewFrequency = 'SemiAnnually' THEN DATEADD(MONTH, 6, Customers.NextReviewDate)
WHEN Customers.CreditReviewFrequency = 'Annually' THEN DATEADD(MONTH, 12, Customers.NextReviewDate)
ELSE Customers.NextReviewDate END,
UpdatedById=@UpdatedById,
UpdatedTime=SYSDATETIMEOFFSET()
FROM Customers
INNER JOIN @customerInfoForUpdate CustomerToUpdate ON Customers.Id = CustomerToUpdate.CustomerId
END

GO

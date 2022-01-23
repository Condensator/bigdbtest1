SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateLastrunDateForAmendment]
(
@ContractId bigint,
@LastExtensionARUpdateRunDate Datetime,
@LastSupplementalARUpdateRunDate Datetime
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
ID
INTO
#LeaseSummary
FROM LeaseFinances
where ContractId = @ContractId
AND BookingStatus!='Inactive'
UPDATE LeaseFinanceDetails
SET
LastExtensionARUpdateRunDate = @LastExtensionARUpdateRunDate,
LastSupplementalARUpdateRunDate = @LastSupplementalARUpdateRunDate
From
#LeaseSummary
JOIN LeaseFinanceDetails on #LeaseSummary.Id = LeaseFinanceDetails.Id
END

GO

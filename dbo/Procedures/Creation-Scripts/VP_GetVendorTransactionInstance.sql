SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[VP_GetVendorTransactionInstance]
(
@CurrentVendorId BIGINT,
@IsOFACReview BIT OUT
)
AS
BEGIN
SELECT
@IsOFACReview = (CASE WHEN COUNT(*)>=1 THEN 1
ELSE 0
END)
FROM TransactionInstances TI
JOIN WorkItems WI ON TI.Id = WI.TransactionInstanceId
JOIN WorkItemConfigs WIC ON WI.WorkItemConfigId = WIC.Id
WHERE TI.EntityId = @CurrentVendorId
AND TI.EntityName='Party'
AND TI.WorkflowSource = 'VendorApprovalWorkflow.xaml'
AND WIC.Name='OFAC Review'
AND (WI.Status='Assigned' OR WI.Status='Unassigned')
END

GO

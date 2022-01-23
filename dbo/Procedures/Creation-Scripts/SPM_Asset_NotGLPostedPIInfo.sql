SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_NotGLPostedPIInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	DISTINCT pia.AssetId,p.EntityId  INTO ##Asset_NotGLPostedPIInfo
FROM
	PayableInvoices pin
INNER JOIN
	PayableInvoiceAssets pia ON pin.Id = pia.PayableInvoiceId
INNER JOIN
	##Asset_EligibleAssets ea ON pia.AssetId = ea.AssetId
INNER JOIN
	Payables p ON p.SourceId = pia.Id
	AND p.EntityId = pin.Id AND p.EntityType = 'PI'
WHERE
	pin.Status = 'Completed' AND pia.IsActive = 1
	AND p.SourceTable = 'PayableInvoiceAsset'
	AND p.IsGLPosted = 0 AND p.Status != 'Inactive'

INSERT INTO ##Asset_NotGLPostedPIInfo
SELECT
	DISTINCT ea.AssetId,p.EntityId
FROM
	PayableInvoiceOtherCosts pioc
INNER JOIN
	##Asset_EligibleAssets ea ON pioc.AssetId = ea.AssetId AND pioc.IsActive = 1
INNER JOIN
	PayableInvoices pin ON pioc.PayableInvoiceId = pin.Id 
INNER JOIN 
	Payables p ON p.EntityId = pin.Id AND pioc.Id = p.SourceId
WHERE
	pin.Status = 'Completed' AND pioc.IsActive = 1 AND p.IsGLPosted = 0
	AND pioc.AllocationMethod = 'SpecificCostAdjustment' AND EntityType = 'PI'
	AND p.SourceTable = 'PayableInvoiceOtherCost' AND p.Status != 'Inactive'

CREATE NONCLUSTERED INDEX IX_NotGLPostedPIInfo_AssetId ON ##Asset_NotGLPostedPIInfo(AssetId);

END

GO

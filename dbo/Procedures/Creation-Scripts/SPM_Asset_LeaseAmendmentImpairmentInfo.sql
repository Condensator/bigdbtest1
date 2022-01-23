SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Asset_LeaseAmendmentImpairmentInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	ea.AssetId  as AssetId
	,SUM(CASE WHEN ea.IsLeaseComponent = 1 THEN lai.PVOfAsset_Amount ELSE 0.00 END) AS [ResidualImpairmentAmount_LeaseComponent]
	,SUM(CASE WHEN ea.IsLeaseComponent = 0 THEN lai.PVOfAsset_Amount ELSE 0.00 END) AS [ResidualImpairmentAmount_FinanceComponent] 
	INTO ##Asset_LeaseAmendmentImpairmentInfo
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAmendmentImpairmentAssetDetails lai ON lai.AssetId = ea.AssetId
INNER JOIN
	LeaseAmendments la ON la.Id = lai.LeaseAmendmentId
	AND la.LeaseAmendmentStatus = 'Approved'
	AND lai.IsActive = 1 AND la.AmendmentType = 'ResidualImpairment'
GROUP BY
	ea.AssetId;

CREATE NONCLUSTERED INDEX IX_AssetId ON ##Asset_LeaseAmendmentImpairmentInfo(AssetId);

END

GO

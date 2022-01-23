SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[ValidateAssetBookDepByInterimRentStartDate]
(
@LeaseAssetInterimDetail LeaseAssetInterimDetail READONLY
)
AS
Begin
SET NOCOUNT ON
select Distinct LA.AssetId,A.Alias from BookDepreciations BD
JOIN @LeaseAssetInterimDetail LA on BD.AssetId = LA.AssetId
join Assets A on A.Id = LA.AssetId
where BD.IsActive = 1
AND (((BD.TerminatedDate IS NOT NULL AND (BD.LastAmortRunDate IS NULL OR BD.LastAmortRunDate < BD.TerminatedDate))
OR (BD.TerminatedDate IS NULL AND BD.EndDate <= LA.InterimRentStartDate))
OR ((BD.TerminatedDate IS NOT NULL AND BD.TerminatedDate > LA.InterimRentStartDate)
OR (BD.TerminatedDate IS NULL AND BD.EndDate > LA.InterimRentStartDate)))
End

GO

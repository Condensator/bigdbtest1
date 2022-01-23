SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Dinesh>
-- Create date: <22-Oct-2021>
-- Description:	<To Update the Age of each asset based on DateOfProduction and untildate passed from client>
-- NOTE : LOGIC IS COPIED FROM ASSETACTIONS.CS - SETAGEOFASSET() METHOD ANY CHANGES MAY NEEDS TO CONSIDER CHANGING IN THE ACTION ALSO..
-- =============================================
CREATE PROCEDURE [dbo].[UpdateAssetAge] 
	@untilDate Date
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--SELECT DateofProduction, CASE WHEN DateofProduction IS NULL THEN CONVERT(DECIMAL(16,2),0) ELSE CONVERT(DECIMAL(16,2), CEILING((DATEDIFF(DAY,DateofProduction,GETDATE())/30))) END FROM Assets WHERE [Status] NOT IN ('Sold','Scrap')

    -- Insert statements for procedure here
	UPDATE Assets SET AgeofAsset = (CASE 
										WHEN DateofProduction IS NULL THEN CONVERT(DECIMAL(16,2),0)
										ELSE CONVERT(DECIMAL(16,2), CEILING((DATEDIFF(DAY,DateofProduction,@untilDate)/30))) 
									END)
					, UpdatedTime = GETDATE()
					, UpdatedById = 1
	WHERE [Status] NOT IN ('Sold','Scrap')
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[InitializeCDCCapture]
As
	execute as user='cdc'
	EXEC SYS.sp_replflush
	exec sys.sp_cdc_scan @continuous=0
	revert

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetMasterUpdateFlag]
(@IsMasterUpdateRequired bit out)
AS
	set xact_abort on;
	BEGIN Transaction;
		-- Lock table till end of transaction
		SELECT @IsMasterUpdateRequired=cast(Value as bit) FROM globalparameters 
		WITH(Tablockx,Holdlock) WHERE Category='App' AND Name='MasterUpdateRequired'

		if @IsMasterUpdateRequired=1
		BEGIN
			  UPDATE globalparameters
			  SET Value='False'
			  WHERE Category='App' AND Name='MasterUpdateRequired'
		END
		else
		set @IsMasterUpdateRequired = 0
   IF @@TRANCOUNT > 0  
	   COMMIT TRANSACTION; -- completion of transaction will release lock

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROCEDURE [dbo].[CreateBaseSequences]
AS

IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE NAME = 'Automation.Iteration')
BEGIN  
	DECLARE @startcount BIGINT = (SELECT (Next + 1) FROM [dbo].[SequenceGenerators] WHERE Module = 'Automation.Iteration')  
	IF @startcount IS NULL
	BEGIN 
		SET @startcount = 1
	END
	DECLARE @sql NVARCHAR(200) = 'CREATE SEQUENCE [Automation.Iteration] AS BIGINT START WITH ' + CAST(@startcount as nvarchar(100)) + ' INCREMENT BY 1'  
	EXEC sp_executesql @sql  
END

GO

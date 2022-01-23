SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateJobStepForInvoiceReRun](    
    @JobStepInstanceId BIGINT,    
    @NewBillToActions NVARCHAR(MAX) NULL     
)    
AS    
BEGIN    
    DECLARE @JobStepId BIGINT    
    SET @JobStepId = (SELECT JobStepId FROM JobStepInstances WHERE Id=@JobStepInstanceId)    
    
    DECLARE @PreviousBillToActions NVARCHAR(MAX)    
    
    DECLARE @String NVARCHAR(MAX)    
    DECLARE @NewString NVARCHAR(MAX)    
    
    DECLARE @StringPartOne NVARCHAR(MAX)    
    DECLARE @StringPartTwo NVARCHAR(MAX)    
    DECLARE @NewStringPartTwo NVARCHAR(MAX)    
    DECLARE @StringPartThree NVARCHAR(MAX)    
    DECLARE @IndexForSource BIGINT    
    DECLARE @IndexForFaulted BIGINT    
    
    SET @String = (SELECT TaskParam FROM JobSteps WHERE Id=@JobStepId)     
    SET @IndexForSource = (SELECT CHARINDEX('&lt;Name&gt;SourceJobStepInstanceId&lt;/Name&gt;', @String, 0))     
    SET @IndexForFaulted = (SELECT CHARINDEX('&lt;Name&gt;FaultedBillToActions&lt;/Name&gt;', @String, 0))     
    SET @StringPartOne = (SELECT SUBSTRING(@String, 0, @IndexForSource))     
    SET @StringPartThree = (SELECT SUBSTRING(@String, @IndexForFaulted, LEN(@String)))     
    SELECT @StringPartTwo = (SELECT SUBSTRING(@String, @IndexForSource, @IndexForFaulted-@IndexForSource))     
    
    DECLARE @IndexForDataOpen BIGINT     
    DECLARE @IndexForDataClose BIGINT     
    SET @IndexForDataOpen = (SELECT CHARINDEX('&lt;Data&gt;', @StringPartTwo, 0))    
    SET @IndexForDataClose = (SELECT CHARINDEX('&lt;/Data&gt;', @StringPartTwo, 0))    
    
    SET @PreviousBillToActions = (SELECT SUBSTRING(@StringPartTwo, @IndexForDataOpen+12, @IndexForDataClose-@IndexForDataOpen-12))     
    SET @NewStringPartTwo = (SELECT CONCAT(SUBSTRING(@StringPartTwo, 0, @IndexForDataOpen+12), @NewBillToActions, SUBSTRING(@StringPartTwo, @IndexForDataClose, LEN(@StringPartTwo))))    
    SET @NewString = (SELECT CONCAT(@StringPartOne, @NewStringPartTwo, @StringPartThree))    
    
    IF @NewBillToActions IS NULL    
    BEGIN    
	   SELECT @PreviousBillToActions AS 'Previous Bill To Actions'    
    END    
    ELSE IF (LEN(@String) - LEN(@PreviousBillToActions)) = (LEN(@NewString) - LEN(@NewBillToActions))    
    BEGIN    
	   SELECT @PreviousBillToActions AS 'Previous Bill To Actions'    
	   SELECT @NewBillToActions AS 'Updated Successfully To New BillToActions'    
	   UPDATE JobSteps SET TaskParam = @NewString WHERE Id=@JobStepId    
    END    
    ELSE    
    BEGIN    
	   SELECT 'Processing Error'    
    END    
END

GO

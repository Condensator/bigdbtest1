SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create   PROCEDURE [dbo].[GetNextSqlSequence]    
(    
 @Module NVARCHAR(100),    
 @IncrementBy INT = 1,    
 @NextValue BIGINT OUTPUT,
 @FirstValue BIGINT OUTPUT
)    
AS    
SET NOCOUNT ON;    
BEGIN      
DECLARE @FirstSeqNum sql_variant,
        @LastSeqNum sql_variant;   

set @Module = '[' + @Module + ']'  

EXEC sys.sp_sequence_get_range  
@sequence_name = @Module  
, @range_size = @IncrementBy  
, @range_first_value = @FirstSeqNum OUTPUT   
, @range_last_value = @LastSeqNum OUTPUT   

SELECT @FirstValue =  Cast (@FirstSeqNum as BIGINT);   
SELECT @NextValue =  Cast (@LastSeqNum as BIGINT);    
  
END

GO

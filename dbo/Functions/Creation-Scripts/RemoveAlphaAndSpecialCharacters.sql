SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[RemoveAlphaAndSpecialCharacters](@Temp VarChar(1000))
Returns VarChar(1000)
AS
Begin
Declare @KeepValues as varchar(50)
Set @KeepValues = '%[^0-9]%'
While PatIndex(@KeepValues, @Temp) > 0
begin
Set @Temp = Stuff(@Temp, PatIndex(@KeepValues, @Temp), 1, '')
--print @temp
end
Return @Temp
End

GO

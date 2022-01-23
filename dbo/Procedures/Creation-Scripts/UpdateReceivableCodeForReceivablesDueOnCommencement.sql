SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create Procedure [dbo].[UpdateReceivableCodeForReceivablesDueOnCommencement]
(
@IncomeType nvarchar(10),
@ReceivableEntityTypeValue nvarchar(10),
@ContractId BIGINT,
@CommencementDate DATETIME,
@LoanPrincipalReceivableCodeId BIGINT
)
As
Begin
Update Receivables Set ReceivableCodeId = @LoanPrincipalReceivableCodeId where Id in ( Select Id from Receivables Where EntityType = @ReceivableEntityTypeValue and EntityId = @ContractId and Duedate <= @CommencementDate and IncomeType = @IncomeType and IsActive = 1 )
End

GO

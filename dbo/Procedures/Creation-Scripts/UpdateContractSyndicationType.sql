SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateContractSyndicationType]
(
@ContractId BIGINT,
@SyndicationType NVARCHAR(40),
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE Contracts SET SyndicationType = @SyndicationType, IsNonAccrual = 0, UpdatedById = @UpdatedById,UpdatedTime = @UpdatedTime WHERE Id =  @ContractId
UPDATE LeaseFinances SET HoldingStatus='_',HoldingStatusComment= NULL WHERE IsCurrent = 1 AND ContractId = @ContractId
UPDATE LoanFinances SET HoldingStatus='_' WHERE IsCurrent = 1 AND ContractId = @ContractId
END

GO

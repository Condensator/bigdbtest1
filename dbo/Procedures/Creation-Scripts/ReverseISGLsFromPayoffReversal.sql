SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[ReverseISGLsFromPayoffReversal]
(
@PayoffId BigInt,
@PayoffCreatedLFId BigInt,
@CurrentUserId BigInt,
@PostDate DateTimeOffset
)
AS
Declare @GLJournalId BigInt = NULL, @ContractId BigInt = NULL;
Declare @CurrentSystemDate DateTimeOffset = (Select SYSDATETIMEOFFSET());
Declare @NonAccrualDate DateTimeOffset = Null, @PayoffEffectiveDate DateTimeOffset = Null;
Declare @GLJournalIdTemp Table (RowNumber Int Not Null, GLJournalId BigInt Not Null, ScheduleName NVarchar(50));
select @ContractId = LeaseFinances.ContractId, @PayoffEffectiveDate = Payoffs.PayoffEffectiveDate  From Payoffs
Join LeaseFinances On LeaseFinances.Id = Payoffs.LeaseFinanceId
Where Payoffs.Id = @PayoffId;
SET @NonAccrualDate = (Select NonAccrualContracts.NonAccrualDate From NonAccrualContracts
Join NonAccruals On NonAccrualContracts.NonAccrualId = NonAccruals.Id
And NonAccruals.Status = 'Approved'
Where NonAccrualContracts.ContractId = @ContractId And NonAccrualContracts.IsActive = 1)
IF @NonAccrualDate IS NOT NULL
BEGIN
With CTE_TotalGLJournals As
(
Select Min(GLJD.GLJournalId) As GLJournalId, 'Lease Income' As ScheduleName From GLJournalDetails GLJD
Join LeaseIncomeSchedules LIS On GLJD.SourceId = LIS.Id And GLJD.EntityId = @ContractId
And LIS.LeaseFinanceId = @PayoffCreatedLFId And LIS.AdjustmentEntry = 1
Where
GLJD.EntityType = 'Contract' And LIS.IncomeDate > @NonAccrualDate And LIS.IsGLPosted = 1
And LIS.IncomeDate <= @PayoffEffectiveDate And LIS.LeaseModificationType = 'Payoff' And LIS.LeaseModificationID = @PayoffId
Group By GLJD.GLJournalId
Union
Select Min(GLJD.GLJournalId) As GLJournalId , 'Lease Float Rate Income' As ScheduleName From GLJournalDetails GLJD
Join LeaseFloatRateIncomes LFIS On GLJD.SourceId = LFIS.Id And GLJD.EntityId = @ContractId
And LFIS.LeaseFinanceId = @PayoffCreatedLFId And LFIS.AdjustmentEntry = 1
Where
GLJD.EntityType = 'Contract' And LFIS.IncomeDate > @NonAccrualDate And LFIS.IsGLPosted = 1
And LFIS.IncomeDate <= @PayoffEffectiveDate And LFIS.ModificationType = 'Payoff' And LFIS.ModificationId = @PayoffId
Group By GLJD.GLJournalId
Union
Select Min(GLJD.GLJournalId) As GLJournalId, 'Blended Income' As ScheduleName From GLJournalDetails GLJD
Join BlendedIncomeSchedules LBIS On GLJD.SourceId = LBIS.Id And GLJD.EntityId = @ContractId
And LBIS.LeaseFinanceId = @PayoffCreatedLFId And LBIS.AdjustmentEntry = 1
Where
GLJD.EntityType = 'Contract' And LBIS.IncomeDate > @NonAccrualDate
And LBIS.IncomeDate <= @PayoffEffectiveDate And LBIS.ModificationType = 'Payoff' And LBIS.ModificationId = @PayoffId
Group By GLJD.GLJournalId
)
Insert Into @GLJournalIdTemp
Select row_number() Over (Order By GLJournalId) RowNumber, GLJournalId, ScheduleName From CTE_TotalGLJournals;
Declare @TotalCount Int;
Set @TotalCount = (Select Count(RowNumber) From @GLJournalIdTemp);
BEGIN TRAN T1
BEGIN TRY
Declare @CntFlag Int;
Set @CntFlag = 1;
WHILE (@CntFlag <= @TotalCount)
BEGIN  -- While
Insert Into GLJournals (PostDate,IsManualEntry,IsReversalEntry,CreatedById,CreatedTime,LegalEntityId)
Select
@CurrentSystemDate As PostDate
,0 As IsManualEntry
,1 As IsReversalEntry
,@CurrentUserId As CreatedById
,@CurrentSystemDate As CreatedTime
,LegalEntityId
From GLJournals Where Id = (Select GLJournalId From @GLJournalIdTemp Where RowNumber = @CntFlag);
Set @GLJournalId = SCOPE_IDENTITY();
IF @GLJournalId IS NOT NULL
BEGIN
Insert Into GLJournalDetails
(
EntityId,EntityType,GLAccountNumber,Description,IsActive
,GLAccountId,GLTemplateDetailId,MatchingGLTemplateDetailId
,ExportJobId,LineOfBusinessId
,IsDebit
,Amount_Amount
,Amount_Currency
,SourceId
,CreatedById
,CreatedTime
,GLJournalId
,InstrumentTypeGLAccountId
)
Select
EntityId,EntityType,GLAccountNumber,Description + ' - Payoff Reversal',IsActive
,GLAccountId,GLTemplateDetailId,MatchingGLTemplateDetailId
,ExportJobId,LineOfBusinessId
,CASE WHEN IsDebit = 1 THEN 0 ELSE 1 END as IsDebit
,Amount_Amount
,Amount_Currency
,SourceId
,@CurrentUserId As CreatedById
,@CurrentSystemDate As CreatedTime
,@GLJournalId as GLJournalId
,InstrumentTypeGLAccountId
From GLJournalDetails
Where GLJournalId = (Select GLJournalId From @GLJournalIdTemp Where RowNumber = @CntFlag);
END -- If  @GLJournalId IS NOT NULL
PRINT @CntFlag;
PRINT @GLJournalId;
Set @CntFlag = @CntFlag + 1;
END --While
END TRY
BEGIN CATCH
ROLLBACK TRAN T1;
END CATCH
COMMIT TRAN T1;
END -- @NonAccrualDate IS NOT NULL

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ReversePayoffGLs]
(
@PayoffId BIGINT,
@PayoffCreatedLFId BIGINT,
@CurrentUserId BIGINT,
@PostDate DATETIMEOFFSET,
@ClearAccumulatedAccountsDetails ClearAccumulatedAccountsAssetsDetail READONLY,
@IsClearAccumulatedAccountsforHFSAssets BIT,
@IsAccumulateDepreciationForDFL BIT,
@ReclassIncomeGLDetails ReclassIncomeGLDetail READONLY
)
AS
DECLARE @GLJournalId BIGINT, @GLJournalIdToUpdate BIGINT = NULL;
DECLARE @IsPayoffGL BIT;
DECLARE @CurrentSystemDate DATETIMEOFFSET = (SELECT SYSDATETIMEOFFSET());
DECLARE  @GLJournalIdTemp TABLE (RowNumber INT NOT NULL, GLJournalId BIGINT NOT NULL, IsPayoffGL BIT, AssetId BIGINT, SourceModuleId BIGINT);
DECLARE  @GLUnearnedInfoTemp TABLE (GLJournalId BIGINT NOT NULL);

BEGIN
With CTE_TotalGLJournals As
(
Select GLJournalId, 1 As IsPayoffGL, Null as AssetId , Payoffs.Id As SourceModuleId From Payoffs
Where Payoffs.Id = @PayoffId and Payoffs.GLJournalId is not null
Union
Select GLJournalId, 0 As IsPayoffGL, Null As AssetId, Null As SourceModuleId From PayoffBlendedItems Where PayoffId = @PayoffId and GLJournalId is not null
Union
Select AVH.GLJournalId, 0 As IsPayoffGL, Null As AssetId, AVH.SourceModuleId From AssetValueHistories AVH
Join LeaseAmendments On LeaseAmendments.Id = AVH.SourceModuleId And AVH.SourceModule = 'NBVImpairments'
Where LeaseAmendments.CurrentLeaseFinanceId = @PayoffCreatedLFId
And LeaseAmendments.AmendmentType = 'NBVImpairment' And LeaseAmendments.LeaseAmendmentStatus = 'Approved'
And AVH.GLJournalId Is Not Null And AVH.ReversalGLJournalId Is Null  AND AVH.IsLessorOwned = 1
Union
Select WritedownGLJournalId As GLJournalId, 0 As IsPayoffGL, 0 As AssetId, WriteDowns.Id as SourceModuleId From WriteDowns
Where WriteDowns.SourceId = @PayoffId And WriteDowns.SourceModule = 'Payoff' And WriteDowns.IsActive = 1
And WriteDowns.ContractType = 'Lease' And WriteDowns.Status = 'Approved' And WriteDowns.WritedownGLJournalId Is Not Null
)
INSERT INTO @GLJournalIdTemp
SELECT row_number() OVER (ORDER BY GLJournalId) RowNumber, GLJournalId, IsPayoffGL, AssetId, SourceModuleId FROM CTE_TotalGLJournals;
INSERT INTO @GLUnearnedInfoTemp
SELECT  GT.GLJournalId
FROM GLJournalView GV
JOIN @ReclassIncomeGLDetails RI ON GV.EntryItem = RI.GLEntryItemName
JOIN  @GLJournalIdTemp GT ON GV.GLJournalId = GT.GLJournalId
Declare @TotalCount Int;
Set @TotalCount = (Select Count(RowNumber) From @GLJournalIdTemp);
BEGIN TRAN T1
BEGIN TRY
Declare @CntFlag Int;
Set @CntFlag = 1;
Declare @flag Int;
Set @flag = @CntFlag;
WHILE (@CntFlag <= @TotalCount)
BEGIN
Set @IsPayoffGL = 0;
Set @IsPayoffGL = (Select IsPayoffGL From @GLJournalIdTemp Where RowNumber = @CntFlag);
Insert Into GLJournals (PostDate,IsManualEntry,IsReversalEntry,CreatedById,CreatedTime,LegalEntityId)
Select
@PostDate As PostDate
,0 As IsManualEntry
,1 As IsReversalEntry
,@CurrentUserId As CreatedById
,@CurrentSystemDate As CreatedTime
,LegalEntityId
From GLJournals Where Id = (Select GLJournalId From @GLJournalIdTemp Where RowNumber = @CntFlag);
Set @GLJournalId = SCOPE_IDENTITY();
IF @GLJournalId IS NOT NULL
BEGIN
INSERT INTO GLJournalDetails
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
SELECT
EntityId,EntityType,GLAccountNumber,Description + ' - Payoff Reversal',GJ.IsActive
,GJ.GLAccountId,GLTemplateDetailId,MatchingGLTemplateDetailId
,Null,LineOfBusinessId
,CASE WHEN GJ.IsDebit = 1 THEN 0 ELSE 1 END AS IsDebit
,Amount_Amount
,Amount_Currency
,SourceId
,@CurrentUserId AS CreatedById
,@CurrentSystemDate AS CreatedTime
,@GLJournalId AS GLJournalId
,InstrumentTypeGLAccountId
FROM GLJournalDetails GJ
JOIN GLTemplateDetails GTD ON GJ.GLTemplateDetailId = GTD.Id
JOIN GLEntryItems GE ON GTD.EntryItemId = GE.ID
WHERE GLJournalId = (SELECT GT.GLJournalId FROM @GLJournalIdTemp GT
WHERE GT.RowNumber = @CntFlag) AND GE.Name NOT IN (SELECT GLEntryItemName FROM @ReclassIncomeGLDetails);

IF EXISTS (SELECT GLJournalId FROM  @GLUnearnedInfoTemp)
BEGIN
INSERT INTO GLJournalDetails
(
EntityId
,EntityType
,GLAccountNumber
,Description
,IsActive
,GLAccountId
,GLTemplateDetailId
,MatchingGLTemplateDetailId
,ExportJobId
,LineOfBusinessId
,IsDebit
,Amount_Amount
,Amount_Currency
,SourceId
,CreatedById
,CreatedTime
,GLJournalId
,InstrumentTypeGLAccountId
)
SELECT 
EntityId = GLJD.EntityId,
EntityType = GLJD.EntityType,
GLAccountNumber = GLJD.GLAccountNumber,
Description = GLJD.Description + ' - Payoff Reversal',
IsActive = GLJD.IsActive,
GLAccountId = GLJD.GLAccountId,
GLTemplateDetailId = GLTemplateDetailId,
MatchingGLTemplateDetailId = MatchingGLTemplateDetailId,
ExportJobId = NULL,
LineOfBusinessId = LineOfBusinessId,
IsDebit = CASE WHEN GLJD.IsDebit = 1 THEN 0 ELSE 1 END, 
Amount_Amount = (CASE WHEN GLJD.IsDebit = 1
					  THEN ABS(GLJD.Amount_Amount  + RI.Amount) 
					  ELSE ABS(GLJD.Amount_Amount  - RI.Amount)
				 END),
Amount_Currency = Amount_Currency,
SourceId = GLJD.SourceId,
CreatedById = @CurrentUserId,  
CreatedTime = @CurrentSystemDate, 
GLJournalId = @GLJournalId,
InstrumentTypeGLAccountId = InstrumentTypeGLAccountId
FROM GLJournalDetails GLJD
JOIN GLTemplateDetails GTD ON GLJD.GLTemplateDetailId = GTD.Id
JOIN GLEntryItems GE ON GTD.EntryItemId = GE.ID
Join @ReclassIncomeGLDetails RI on GE.Name = RI.GLEntryItemName
WHERE GLJD.GLJournalId IN (SELECT DISTINCT GLJournalId FROM @GLUnearnedInfoTemp);

DELETE FROM @GLUnearnedInfoTemp;
END
BEGIN
Update Payoffs Set ReversalGLJournalId = @GLJournalId, ReversalPostDate = @PostDate,
UpdatedById = @CurrentUserId ,UpdatedTime = @CurrentSystemDate Where Id = @PayoffId;
Update AssetValueHistories Set ReversalGLJournalId = @GLJournalId, ReversalPostDate = @PostDate, UpdatedById = @CurrentUserId
,UpdatedTime = @CurrentSystemDate, IsAccounted = 0, IsSchedule = 0, IsCleared = 0
Where SourceModuleId = @PayoffId And SourceModule = 'Payoff' And ReversalGLJournalId Is Null;
END
IF (Select Count(RowNumber) From @GLJournalIdTemp Where RowNumber = @CntFlag And SourceModuleId Is Not Null) > 0
BEGIN
Update AssetValueHistories Set
AssetValueHistories.ReversalGLJournalId = @GLJournalId,AssetValueHistories.ReversalPostDate = @PostDate,IsAccounted = 0, IsSchedule = 0, IsCleared = 0
, UpdatedById = @CurrentUserId ,UpdatedTime = @CurrentSystemDate
From AssetValueHistories
Join @GLJournalIdTemp as GLJournalIdTemp On AssetValueHistories.SourceModuleId = GLJournalIdTemp.SourceModuleId AND AssetValueHistories.SourceModule = 'NBVImpairments'
Join PayoffAssets On PayoffAssets.PayoffId = @PayoffId And PayoffAssets.IsActive = 1
Join LeaseAssets On LeaseAssets.Id = PayoffAssets.LeaseAssetId And LeaseAssets.AssetId = AssetValueHistories.AssetId
Where GLJournalIdTemp.RowNumber = @CntFlag;
END
END -- If
PRINT @CntFlag;
PRINT @GLJournalId;
Set @CntFlag = @CntFlag + 1;
END --While
--If (Select Count(RowNumber) From @GLJournalIdTemp where AssetId = 0 And SourceModuleId Is Not Null) > 0
BEGIN
Update WriteDowns Set IsActive = 0, Status = 'Rejected'
, UpdatedById = @CurrentUserId ,UpdatedTime = @CurrentSystemDate
Where Id in (Select SourceModuleId From @GLJournalIdTemp where AssetId = 0);
Update WriteDownAssetDetails Set IsActive = 0
, UpdatedById = @CurrentUserId ,UpdatedTime = @CurrentSystemDate
Where WriteDownAssetDetails.WriteDownId in (Select SourceModuleId From @GLJournalIdTemp where AssetId = 0);

UPDATE LeaseAmendments 
SET 
	LeaseAmendmentStatus = 'Inactive', 
	UpdatedById = @CurrentUserId,
	UpdatedTime = @CurrentSystemDate
FROM LeaseAmendments
JOIN AssetValueHistories ON AssetValueHistories.SourceModuleId = LeaseAmendments.Id
JOIN LeaseAssets on LeaseAssets.AssetId = AssetValueHistories.AssetId
JOIN PayoffAssets on PayoffAssets.LeaseAssetId = LeaseAssets.Id
WHERE LeaseAmendments.CurrentLeaseFinanceId = @PayoffCreatedLFId
And LeaseAmendments.AmendmentType = 'NBVImpairment' And LeaseAmendments.LeaseAmendmentStatus = 'Approved' 
And AssetValueHistories.SourceModule = 'NBVImpairments'
And PayoffAssets.PayoffId = @PayoffId;

--Declare @IsClearAccumulatedAccountsatPayoff Bit
--Set @IsClearAccumulatedAccountsatPayoff =( @ClearAccumulatedAccountsatPayoff);
--Declare @IsAccumulateDepreciationForDFL Bit
--Set @IsAccumulateDepreciationForDFL =( Select value from GlobalParameters Where Category='LeaseFinance' And Name='AccumulateDepreciationForDFL');
Declare @ContractType Nvarchar(16)
Set @ContractType =( Select LeaseContractType from LeaseFinanceDetails Where Id=@PayoffCreatedLFId);
Declare @AccountingTreatment Nvarchar(12)
Set @AccountingTreatment =( Select Accountingtreatment from ReceivableCodes
join LeaseFinanceDetails On ReceivableCodes.Id=LeaseFinanceDetails.OTPReceivableCodeId  Where LeaseFinanceDetails.Id=@PayoffCreatedLFId);
Declare @ContractId Int
Set @ContractId= (Select ContractId from LeaseFinances where Id=@PayoffCreatedLFId);
Update lastestRecord Set
lastestRecord.NetValue_Amount =
CASE WHEN lastestRecord.SourceModule = 'FixedTermDepreciation' And (CanClearAccumulatedAccount = 1 OR (@IsClearAccumulatedAccountsforHFSAssets =1 AND HeldForSale =1)) then LeaseAssets_NBV_Amount
WHEN  lastestRecord.SourceModule != 'FixedTermDepreciation' And  (@ContractType!='DirectFinance'or @AccountingTreatment!='CashBased' or @IsAccumulateDepreciationForDFL !=0) then LeaseAssets_BookedResidual_Amount
ELSE lastestRecord.NetValue_Amount
END,
lastestRecord.IsCleared = CASE
WHEN (lastestRecord.SourceModule = 'FixedTermDepreciation' And (CanClearAccumulatedAccount = 1 OR (@IsClearAccumulatedAccountsforHFSAssets =1 AND HeldForSale =1)))  or ( lastestRecord.SourceModule != 'FixedTermDepreciation' And  (@ContractType!='DirectFinance'or @AccountingTreatment!='CashBased' or @IsAccumulateDepreciationForDFL !=0)) then 0
ELSE lastestRecord.IsCleared
END,
lastestRecord.UpdatedById =CASE
WHEN (lastestRecord.SourceModule = 'FixedTermDepreciation' And (CanClearAccumulatedAccount = 1 OR  (@IsClearAccumulatedAccountsforHFSAssets =1 AND HeldForSale =1)))  or ( lastestRecord.SourceModule != 'FixedTermDepreciation' And  (@ContractType!='DirectFinance'or @AccountingTreatment!='CashBased' or @IsAccumulateDepreciationForDFL !=0)) THEN @CurrentUserId
ELSE  lastestRecord.UpdatedById
END,
lastestRecord.UpdatedTime = CASE
WHEN (lastestRecord.SourceModule = 'FixedTermDepreciation' And (CanClearAccumulatedAccount = 1 OR (@IsClearAccumulatedAccountsforHFSAssets =1 AND HeldForSale =1))) or ( lastestRecord.SourceModule != 'FixedTermDepreciation' And  (@ContractType!='DirectFinance'or @AccountingTreatment!='CashBased' or @IsAccumulateDepreciationForDFL !=0)) THEN @CurrentSystemDate
ELSE lastestRecord.UpdatedTime
END
FROM
(SELECT PayoffAssets.HeldForSale,avh.*,CanClearAccumulatedAccount,LeaseAssets.NBV_Amount as LeaseAssets_NBV_Amount,LeaseAssets.BookedResidual_Amount as LeaseAssets_BookedResidual_Amount, ROW_NUMBER() OVER( PARTITION BY avh.Assetid,avh.IsLeaseComponent ORDER BY IncomeDate DESC, avh.Id DESC) AS ranking
From dbo.AssetValueHistories avh
Join LeaseAssets On LeaseAssets.AssetId = avh.AssetId
Join PayoffAssets On LeaseAssets.Id = PayoffAssets.LeaseAssetId  And PayoffAssets.IsActive = 1
Join @ClearAccumulatedAccountsDetails CAAD on PayoffAssets.Id = CAAD.PayoffAssetId
join Payoffs On PayoffAssets.PayoffId = Payoffs.Id
Where
avh.IsAccounted = 1
AND avh.IsSchedule = 1 AND avh.IsLessorOwned = 1 And ((
Payoffs.PayoffAtInception = 1 And avh.IncomeDate < =DATEADD(day,-1,Payoffs.PayoffEffectiveDate)) or avh.IncomeDate<= Payoffs.PayoffEffectiveDate)
And avh.SourceModuleId in (select id from Leasefinances where ContractId=@ContractId)
And Payoffs.Id=@PayoffId) as lastestRecord
Where ranking = 1
END
END TRY
BEGIN CATCH
ROLLBACK TRAN T1;
END CATCH
COMMIT TRAN T1;
END

GO

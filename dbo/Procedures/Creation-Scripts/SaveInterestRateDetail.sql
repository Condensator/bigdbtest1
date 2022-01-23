SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInterestRateDetail]
(
 @val [dbo].[InterestRateDetail] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[InterestRateDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BankIndexDescription]=S.[BankIndexDescription],[BaseRate]=S.[BaseRate],[CeilingPercent]=S.[CeilingPercent],[CompoundingFrequency]=S.[CompoundingFrequency],[EffectiveDate]=S.[EffectiveDate],[EffectiveDayofMonth]=S.[EffectiveDayofMonth],[FirstResetDate]=S.[FirstResetDate],[FloatRateIndexId]=S.[FloatRateIndexId],[FloatRateResetFrequency]=S.[FloatRateResetFrequency],[FloatRateResetUnit]=S.[FloatRateResetUnit],[FloorPercent]=S.[FloorPercent],[HolidayMoveMethod]=S.[HolidayMoveMethod],[InterestConfiguration]=S.[InterestConfiguration],[InterestRate]=S.[InterestRate],[IsActive]=S.[IsActive],[IsFloatRate]=S.[IsFloatRate],[IsHighPrimeInterest]=S.[IsHighPrimeInterest],[IsIndexPercentage]=S.[IsIndexPercentage],[IsLeadUnitsinBusinessDays]=S.[IsLeadUnitsinBusinessDays],[IsManualInterestMargin]=S.[IsManualInterestMargin],[IsMoveAcrossMonth]=S.[IsMoveAcrossMonth],[IsNewlyAdded]=S.[IsNewlyAdded],[LeadFrequency]=S.[LeadFrequency],[LeadUnits]=S.[LeadUnits],[ModificationType]=S.[ModificationType],[Percentage]=S.[Percentage],[PercentageBasis]=S.[PercentageBasis],[RateCardInterest]=S.[RateCardInterest],[Spread]=S.[Spread],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BankIndexDescription],[BaseRate],[CeilingPercent],[CompoundingFrequency],[CreatedById],[CreatedTime],[EffectiveDate],[EffectiveDayofMonth],[FirstResetDate],[FloatRateIndexId],[FloatRateResetFrequency],[FloatRateResetUnit],[FloorPercent],[HolidayMoveMethod],[InterestConfiguration],[InterestRate],[IsActive],[IsFloatRate],[IsHighPrimeInterest],[IsIndexPercentage],[IsLeadUnitsinBusinessDays],[IsManualInterestMargin],[IsMoveAcrossMonth],[IsNewlyAdded],[LeadFrequency],[LeadUnits],[ModificationType],[Percentage],[PercentageBasis],[RateCardInterest],[Spread])
    VALUES (S.[BankIndexDescription],S.[BaseRate],S.[CeilingPercent],S.[CompoundingFrequency],S.[CreatedById],S.[CreatedTime],S.[EffectiveDate],S.[EffectiveDayofMonth],S.[FirstResetDate],S.[FloatRateIndexId],S.[FloatRateResetFrequency],S.[FloatRateResetUnit],S.[FloorPercent],S.[HolidayMoveMethod],S.[InterestConfiguration],S.[InterestRate],S.[IsActive],S.[IsFloatRate],S.[IsHighPrimeInterest],S.[IsIndexPercentage],S.[IsLeadUnitsinBusinessDays],S.[IsManualInterestMargin],S.[IsMoveAcrossMonth],S.[IsNewlyAdded],S.[LeadFrequency],S.[LeadUnits],S.[ModificationType],S.[Percentage],S.[PercentageBasis],S.[RateCardInterest],S.[Spread])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

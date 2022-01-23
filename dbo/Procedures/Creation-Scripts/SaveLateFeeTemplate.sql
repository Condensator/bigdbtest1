SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLateFeeTemplate]
(
 @val [dbo].[LateFeeTemplate] READONLY
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
MERGE [dbo].[LateFeeTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingTreatment]=S.[AccountingTreatment],[BasisPercentage]=S.[BasisPercentage],[CeilingAmount_Amount]=S.[CeilingAmount_Amount],[CeilingAmount_Currency]=S.[CeilingAmount_Currency],[Comment]=S.[Comment],[Compounding]=S.[Compounding],[CurrencyId]=S.[CurrencyId],[DayCountConvention]=S.[DayCountConvention],[EffectiveDayofMonth]=S.[EffectiveDayofMonth],[FloatRateIndexId]=S.[FloatRateIndexId],[FloatRateResetFrequency]=S.[FloatRateResetFrequency],[FloatRateResetUnit]=S.[FloatRateResetUnit],[FloorAmount_Amount]=S.[FloorAmount_Amount],[FloorAmount_Currency]=S.[FloorAmount_Currency],[IsActive]=S.[IsActive],[IsAssessedOnlyOnce]=S.[IsAssessedOnlyOnce],[IsAssessedOnTax]=S.[IsAssessedOnTax],[IsFloatRate]=S.[IsFloatRate],[IsLeadUnitsinBusinessDays]=S.[IsLeadUnitsinBusinessDays],[LateFeeBasis]=S.[LateFeeBasis],[LateFeeType]=S.[LateFeeType],[LeadFrequency]=S.[LeadFrequency],[LeadUnits]=S.[LeadUnits],[Name]=S.[Name],[ReceivableCodeId]=S.[ReceivableCodeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingTreatment],[BasisPercentage],[CeilingAmount_Amount],[CeilingAmount_Currency],[Comment],[Compounding],[CreatedById],[CreatedTime],[CurrencyId],[DayCountConvention],[EffectiveDayofMonth],[FloatRateIndexId],[FloatRateResetFrequency],[FloatRateResetUnit],[FloorAmount_Amount],[FloorAmount_Currency],[IsActive],[IsAssessedOnlyOnce],[IsAssessedOnTax],[IsFloatRate],[IsLeadUnitsinBusinessDays],[LateFeeBasis],[LateFeeType],[LeadFrequency],[LeadUnits],[Name],[ReceivableCodeId])
    VALUES (S.[AccountingTreatment],S.[BasisPercentage],S.[CeilingAmount_Amount],S.[CeilingAmount_Currency],S.[Comment],S.[Compounding],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[DayCountConvention],S.[EffectiveDayofMonth],S.[FloatRateIndexId],S.[FloatRateResetFrequency],S.[FloatRateResetUnit],S.[FloorAmount_Amount],S.[FloorAmount_Currency],S.[IsActive],S.[IsAssessedOnlyOnce],S.[IsAssessedOnTax],S.[IsFloatRate],S.[IsLeadUnitsinBusinessDays],S.[LateFeeBasis],S.[LateFeeType],S.[LeadFrequency],S.[LeadUnits],S.[Name],S.[ReceivableCodeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

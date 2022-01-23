SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUOverageTierEscalation]
(
 @val [dbo].[CPUOverageTierEscalation] READONLY
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
MERGE [dbo].[CPUOverageTierEscalations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EffectiveDate]=S.[EffectiveDate],[EscalationMethod]=S.[EscalationMethod],[IsActive]=S.[IsActive],[IsCreatedFromBooking]=S.[IsCreatedFromBooking],[OverageDecimalPlaces]=S.[OverageDecimalPlaces],[Percentage]=S.[Percentage],[Rate]=S.[Rate],[StepPeriod]=S.[StepPeriod],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CPUOverageStructureId],[CreatedById],[CreatedTime],[EffectiveDate],[EscalationMethod],[IsActive],[IsCreatedFromBooking],[OverageDecimalPlaces],[Percentage],[Rate],[StepPeriod])
    VALUES (S.[CPUOverageStructureId],S.[CreatedById],S.[CreatedTime],S.[EffectiveDate],S.[EscalationMethod],S.[IsActive],S.[IsCreatedFromBooking],S.[OverageDecimalPlaces],S.[Percentage],S.[Rate],S.[StepPeriod])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

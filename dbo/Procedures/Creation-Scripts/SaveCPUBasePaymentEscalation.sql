SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUBasePaymentEscalation]
(
 @val [dbo].[CPUBasePaymentEscalation] READONLY
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
MERGE [dbo].[CPUBasePaymentEscalations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[EffectiveDate]=S.[EffectiveDate],[EscalationMethod]=S.[EscalationMethod],[IsActive]=S.[IsActive],[IsCreatedFromBooking]=S.[IsCreatedFromBooking],[Percentage]=S.[Percentage],[StepPeriod]=S.[StepPeriod],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[CPUBaseStructureId],[CreatedById],[CreatedTime],[EffectiveDate],[EscalationMethod],[IsActive],[IsCreatedFromBooking],[Percentage],[StepPeriod])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[CPUBaseStructureId],S.[CreatedById],S.[CreatedTime],S.[EffectiveDate],S.[EscalationMethod],S.[IsActive],S.[IsCreatedFromBooking],S.[Percentage],S.[StepPeriod])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLockboxDefaultParameterConfig]
(
 @val [dbo].[LockboxDefaultParameterConfig] READONLY
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
MERGE [dbo].[LockboxDefaultParameterConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CashTypeId]=S.[CashTypeId],[CostCenterId]=S.[CostCenterId],[CurrencyId]=S.[CurrencyId],[InstrumentTypeId]=S.[InstrumentTypeId],[IsActive]=S.[IsActive],[LegalEntityId]=S.[LegalEntityId],[LineOfBusinessId]=S.[LineOfBusinessId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CashTypeId],[CostCenterId],[CreatedById],[CreatedTime],[CurrencyId],[InstrumentTypeId],[IsActive],[LegalEntityId],[LineOfBusinessId])
    VALUES (S.[CashTypeId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[InstrumentTypeId],S.[IsActive],S.[LegalEntityId],S.[LineOfBusinessId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

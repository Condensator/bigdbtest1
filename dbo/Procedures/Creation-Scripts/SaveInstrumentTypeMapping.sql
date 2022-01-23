SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInstrumentTypeMapping]
(
 @val [dbo].[InstrumentTypeMapping] READONLY
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
MERGE [dbo].[InstrumentTypeMappings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingTreatment]=S.[AccountingTreatment],[ContractType]=S.[ContractType],[FederalTaxExempt]=S.[FederalTaxExempt],[HoldingStatus]=S.[HoldingStatus],[InstrumentTypeId]=S.[InstrumentTypeId],[IsActive]=S.[IsActive],[IsBankQualified]=S.[IsBankQualified],[IsFloatingRate]=S.[IsFloatingRate],[IsNonAccrual]=S.[IsNonAccrual],[IsRecovery]=S.[IsRecovery],[IsRevolving]=S.[IsRevolving],[ProductType]=S.[ProductType],[SOPStatus]=S.[SOPStatus],[TransactionType]=S.[TransactionType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingTreatment],[ContractType],[CreatedById],[CreatedTime],[FederalTaxExempt],[HoldingStatus],[InstrumentTypeId],[IsActive],[IsBankQualified],[IsFloatingRate],[IsNonAccrual],[IsRecovery],[IsRevolving],[ProductType],[SOPStatus],[TransactionType])
    VALUES (S.[AccountingTreatment],S.[ContractType],S.[CreatedById],S.[CreatedTime],S.[FederalTaxExempt],S.[HoldingStatus],S.[InstrumentTypeId],S.[IsActive],S.[IsBankQualified],S.[IsFloatingRate],S.[IsNonAccrual],S.[IsRecovery],S.[IsRevolving],S.[ProductType],S.[SOPStatus],S.[TransactionType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

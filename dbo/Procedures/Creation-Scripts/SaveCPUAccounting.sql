SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUAccounting]
(
 @val [dbo].[CPUAccounting] READONLY
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
MERGE [dbo].[CPUAccountings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BaseFeePayableCodeId]=S.[BaseFeePayableCodeId],[BaseFeePayableWithholdingTaxRate]=S.[BaseFeePayableWithholdingTaxRate],[BaseFeeReceivableCodeId]=S.[BaseFeeReceivableCodeId],[BranchId]=S.[BranchId],[CostCenterId]=S.[CostCenterId],[InstrumentTypeId]=S.[InstrumentTypeId],[LineofBusinessId]=S.[LineofBusinessId],[OverageFeePayableCodeId]=S.[OverageFeePayableCodeId],[OverageFeePayableWithholdingTaxRate]=S.[OverageFeePayableWithholdingTaxRate],[OverageFeeReceivableCodeId]=S.[OverageFeeReceivableCodeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BaseFeePayableCodeId],[BaseFeePayableWithholdingTaxRate],[BaseFeeReceivableCodeId],[BranchId],[CostCenterId],[CreatedById],[CreatedTime],[Id],[InstrumentTypeId],[LineofBusinessId],[OverageFeePayableCodeId],[OverageFeePayableWithholdingTaxRate],[OverageFeeReceivableCodeId])
    VALUES (S.[BaseFeePayableCodeId],S.[BaseFeePayableWithholdingTaxRate],S.[BaseFeeReceivableCodeId],S.[BranchId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[Id],S.[InstrumentTypeId],S.[LineofBusinessId],S.[OverageFeePayableCodeId],S.[OverageFeePayableWithholdingTaxRate],S.[OverageFeeReceivableCodeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

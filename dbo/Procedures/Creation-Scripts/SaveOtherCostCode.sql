SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOtherCostCode]
(
 @val [dbo].[OtherCostCode] READONLY
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
MERGE [dbo].[OtherCostCodes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllocationMethod]=S.[AllocationMethod],[BlendedItemCodeId]=S.[BlendedItemCodeId],[CostTypeId]=S.[CostTypeId],[Description]=S.[Description],[EntityType]=S.[EntityType],[IsActive]=S.[IsActive],[IsPrepaidUpfrontTax]=S.[IsPrepaidUpfrontTax],[Name]=S.[Name],[PayableCodeId]=S.[PayableCodeId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[PortfolioId]=S.[PortfolioId],[ReceivableCodeId]=S.[ReceivableCodeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AllocationMethod],[BlendedItemCodeId],[CostTypeId],[CreatedById],[CreatedTime],[Description],[EntityType],[IsActive],[IsPrepaidUpfrontTax],[Name],[PayableCodeId],[PayableWithholdingTaxRate],[PortfolioId],[ReceivableCodeId])
    VALUES (S.[AllocationMethod],S.[BlendedItemCodeId],S.[CostTypeId],S.[CreatedById],S.[CreatedTime],S.[Description],S.[EntityType],S.[IsActive],S.[IsPrepaidUpfrontTax],S.[Name],S.[PayableCodeId],S.[PayableWithholdingTaxRate],S.[PortfolioId],S.[ReceivableCodeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

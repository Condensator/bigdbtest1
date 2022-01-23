SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayable]
(
 @val [dbo].[Payable] READONLY
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
MERGE [dbo].[Payables] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentBasisPayableId]=S.[AdjustmentBasisPayableId],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[CreationSourceId]=S.[CreationSourceId],[CreationSourceTable]=S.[CreationSourceTable],[CurrencyId]=S.[CurrencyId],[DueDate]=S.[DueDate],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[InternalComment]=S.[InternalComment],[IsGLPosted]=S.[IsGLPosted],[LegalEntityId]=S.[LegalEntityId],[PayableCodeId]=S.[PayableCodeId],[PayeeId]=S.[PayeeId],[RemitToId]=S.[RemitToId],[SourceId]=S.[SourceId],[SourceTable]=S.[SourceTable],[Status]=S.[Status],[TaxPortion_Amount]=S.[TaxPortion_Amount],[TaxPortion_Currency]=S.[TaxPortion_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithholdingTaxRate]=S.[WithholdingTaxRate]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentBasisPayableId],[Amount_Amount],[Amount_Currency],[Balance_Amount],[Balance_Currency],[CreatedById],[CreatedTime],[CreationSourceId],[CreationSourceTable],[CurrencyId],[DueDate],[EntityId],[EntityType],[InternalComment],[IsGLPosted],[LegalEntityId],[PayableCodeId],[PayeeId],[RemitToId],[SourceId],[SourceTable],[Status],[TaxPortion_Amount],[TaxPortion_Currency],[WithholdingTaxRate])
    VALUES (S.[AdjustmentBasisPayableId],S.[Amount_Amount],S.[Amount_Currency],S.[Balance_Amount],S.[Balance_Currency],S.[CreatedById],S.[CreatedTime],S.[CreationSourceId],S.[CreationSourceTable],S.[CurrencyId],S.[DueDate],S.[EntityId],S.[EntityType],S.[InternalComment],S.[IsGLPosted],S.[LegalEntityId],S.[PayableCodeId],S.[PayeeId],S.[RemitToId],S.[SourceId],S.[SourceTable],S.[Status],S.[TaxPortion_Amount],S.[TaxPortion_Currency],S.[WithholdingTaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveFeeDetail]
(
 @val [dbo].[FeeDetail] READONLY
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
MERGE [dbo].[FeeDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingTreatment]=S.[AccountingTreatment],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BlendedItemCodeId]=S.[BlendedItemCodeId],[CeilingAmount_Amount]=S.[CeilingAmount_Amount],[CeilingAmount_Currency]=S.[CeilingAmount_Currency],[Description]=S.[Description],[FeeAssessmentLevel]=S.[FeeAssessmentLevel],[FeeBasis]=S.[FeeBasis],[FeeCategoryId]=S.[FeeCategoryId],[FeePercent]=S.[FeePercent],[FeeType]=S.[FeeType],[FloorAmount_Amount]=S.[FloorAmount_Amount],[FloorAmount_Currency]=S.[FloorAmount_Currency],[GracePeriodInMonths]=S.[GracePeriodInMonths],[IsActive]=S.[IsActive],[IsImport]=S.[IsImport],[Name]=S.[Name],[Number]=S.[Number],[Occurrence]=S.[Occurrence],[PayableCodeId]=S.[PayableCodeId],[ReceivableCodeId]=S.[ReceivableCodeId],[SundryOrBlendedItem]=S.[SundryOrBlendedItem],[SundryType]=S.[SundryType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UsageCondition]=S.[UsageCondition]
WHEN NOT MATCHED THEN
	INSERT ([AccountingTreatment],[Amount_Amount],[Amount_Currency],[BlendedItemCodeId],[CeilingAmount_Amount],[CeilingAmount_Currency],[CreatedById],[CreatedTime],[Description],[FeeAssessmentLevel],[FeeBasis],[FeeCategoryId],[FeePercent],[FeeTemplateId],[FeeType],[FloorAmount_Amount],[FloorAmount_Currency],[GracePeriodInMonths],[IsActive],[IsImport],[Name],[Number],[Occurrence],[PayableCodeId],[ReceivableCodeId],[SundryOrBlendedItem],[SundryType],[UsageCondition])
    VALUES (S.[AccountingTreatment],S.[Amount_Amount],S.[Amount_Currency],S.[BlendedItemCodeId],S.[CeilingAmount_Amount],S.[CeilingAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[Description],S.[FeeAssessmentLevel],S.[FeeBasis],S.[FeeCategoryId],S.[FeePercent],S.[FeeTemplateId],S.[FeeType],S.[FloorAmount_Amount],S.[FloorAmount_Currency],S.[GracePeriodInMonths],S.[IsActive],S.[IsImport],S.[Name],S.[Number],S.[Occurrence],S.[PayableCodeId],S.[ReceivableCodeId],S.[SundryOrBlendedItem],S.[SundryType],S.[UsageCondition])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

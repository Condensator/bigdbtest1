SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePropertyTaxDetail]
(
 @val [dbo].[PropertyTaxDetail] READONLY
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
MERGE [dbo].[PropertyTaxDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdministrativeFee_Amount]=S.[AdministrativeFee_Amount],[AdministrativeFee_Currency]=S.[AdministrativeFee_Currency],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AssessedValue_Amount]=S.[AssessedValue_Amount],[AssessedValue_Currency]=S.[AssessedValue_Currency],[AssetId]=S.[AssetId],[BillToId]=S.[BillToId],[IsActive]=S.[IsActive],[ReportedCost_Amount]=S.[ReportedCost_Amount],[ReportedCost_Currency]=S.[ReportedCost_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdministrativeFee_Amount],[AdministrativeFee_Currency],[Amount_Amount],[Amount_Currency],[AssessedValue_Amount],[AssessedValue_Currency],[AssetId],[BillToId],[CreatedById],[CreatedTime],[IsActive],[PropertyTaxId],[ReportedCost_Amount],[ReportedCost_Currency])
    VALUES (S.[AdministrativeFee_Amount],S.[AdministrativeFee_Currency],S.[Amount_Amount],S.[Amount_Currency],S.[AssessedValue_Amount],S.[AssessedValue_Currency],S.[AssetId],S.[BillToId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[PropertyTaxId],S.[ReportedCost_Amount],S.[ReportedCost_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseAssetDownPaymentVATDetails]
(
 @val [dbo].[LeaseAssetDownPaymentVATDetails] READONLY
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
MERGE [dbo].[LeaseAssetDownPaymentVATDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsActive]=S.[IsActive],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATAmount_Amount]=S.[VATAmount_Amount],[VATAmount_Currency]=S.[VATAmount_Currency],[VATCodeId]=S.[VATCodeId],[VATTypeId]=S.[VATTypeId]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[IsActive],[LeaseAssetId],[VATAmount_Amount],[VATAmount_Currency],[VATCodeId],[VATTypeId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[LeaseAssetId],S.[VATAmount_Amount],S.[VATAmount_Currency],S.[VATCodeId],S.[VATTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDealType]
(
 @val [dbo].[DealType] READONLY
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
MERGE [dbo].[DealTypes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractType]=S.[ContractType],[IsActive]=S.[IsActive],[IsIncomeTaxExempt]=S.[IsIncomeTaxExempt],[IsLoan]=S.[IsLoan],[Name]=S.[Name],[ProductType]=S.[ProductType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractType],[CreatedById],[CreatedTime],[IsActive],[IsIncomeTaxExempt],[IsLoan],[Name],[ProductType])
    VALUES (S.[ContractType],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsIncomeTaxExempt],S.[IsLoan],S.[Name],S.[ProductType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

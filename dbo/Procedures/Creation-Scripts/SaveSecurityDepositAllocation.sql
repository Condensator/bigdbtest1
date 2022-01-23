SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSecurityDepositAllocation]
(
 @val [dbo].[SecurityDepositAllocation] READONLY
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
MERGE [dbo].[SecurityDepositAllocations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[ContractId]=S.[ContractId],[EntityType]=S.[EntityType],[GlDescription]=S.[GlDescription],[IsActive]=S.[IsActive],[IsAllocation]=S.[IsAllocation],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[ContractId],[CreatedById],[CreatedTime],[EntityType],[GlDescription],[IsActive],[IsAllocation],[SecurityDepositId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[EntityType],S.[GlDescription],S.[IsActive],S.[IsAllocation],S.[SecurityDepositId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRemitToWireDetail]
(
 @val [dbo].[RemitToWireDetail] READONLY
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
MERGE [dbo].[RemitToWireDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHOriginatorID]=S.[ACHOriginatorID],[BankAccountId]=S.[BankAccountId],[IsActive]=S.[IsActive],[IsBeneficiary]=S.[IsBeneficiary],[IsCorrespondent]=S.[IsCorrespondent],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHOriginatorID],[BankAccountId],[CreatedById],[CreatedTime],[IsActive],[IsBeneficiary],[IsCorrespondent],[RemitToId],[UniqueIdentifier])
    VALUES (S.[ACHOriginatorID],S.[BankAccountId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsBeneficiary],S.[IsCorrespondent],S.[RemitToId],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePartyBlackList]
(
 @val [dbo].[PartyBlackList] READONLY
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
MERGE [dbo].[PartyBlackLists] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Address]=S.[Address],[Comment]=S.[Comment],[CompanyName]=S.[CompanyName],[EGNOrEIKNumber]=S.[EGNOrEIKNumber],[FirstName]=S.[FirstName],[IsActive]=S.[IsActive],[LastName]=S.[LastName],[PhoneNumber]=S.[PhoneNumber],[Reason]=S.[Reason],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Address],[Comment],[CompanyName],[CreatedById],[CreatedTime],[EGNOrEIKNumber],[FirstName],[IsActive],[LastName],[PhoneNumber],[Reason])
    VALUES (S.[Address],S.[Comment],S.[CompanyName],S.[CreatedById],S.[CreatedTime],S.[EGNOrEIKNumber],S.[FirstName],S.[IsActive],S.[LastName],S.[PhoneNumber],S.[Reason])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

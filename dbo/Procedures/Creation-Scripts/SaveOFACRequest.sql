SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOFACRequest]
(
 @val [dbo].[OFACRequest] READONLY
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
MERGE [dbo].[OFACRequests] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [PartyContactId]=S.[PartyContactId],[PartyId]=S.[PartyId],[RequestDate]=S.[RequestDate],[RequestType]=S.[RequestType],[RequestXml]=S.[RequestXml],[ResponseDate]=S.[ResponseDate],[ResponseType]=S.[ResponseType],[ResponseXml]=S.[ResponseXml],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[PartyContactId],[PartyId],[RequestDate],[RequestType],[RequestXml],[ResponseDate],[ResponseType],[ResponseXml])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[PartyContactId],S.[PartyId],S.[RequestDate],S.[RequestType],S.[RequestXml],S.[ResponseDate],S.[ResponseType],S.[ResponseXml])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

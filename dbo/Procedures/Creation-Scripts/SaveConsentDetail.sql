SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveConsentDetail]
(
 @val [dbo].[ConsentDetail] READONLY
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
MERGE [dbo].[ConsentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ConsentCaptureMode]=S.[ConsentCaptureMode],[ConsentConfigId]=S.[ConsentConfigId],[ConsentStatus]=S.[ConsentStatus],[DocumentInstanceId]=S.[DocumentInstanceId],[EffectiveDate]=S.[EffectiveDate],[EntityType]=S.[EntityType],[ExpiryDate]=S.[ExpiryDate],[IsActive]=S.[IsActive],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ConsentCaptureMode],[ConsentConfigId],[ConsentStatus],[CreatedById],[CreatedTime],[DocumentInstanceId],[EffectiveDate],[EntityType],[ExpiryDate],[IsActive])
    VALUES (S.[ConsentCaptureMode],S.[ConsentConfigId],S.[ConsentStatus],S.[CreatedById],S.[CreatedTime],S.[DocumentInstanceId],S.[EffectiveDate],S.[EntityType],S.[ExpiryDate],S.[IsActive])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

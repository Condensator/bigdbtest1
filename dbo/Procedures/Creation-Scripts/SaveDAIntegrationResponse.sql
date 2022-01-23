SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDAIntegrationResponse]
(
 @val [dbo].[DAIntegrationResponse] READONLY
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
MERGE [dbo].[DAIntegrationResponses] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EGN_CT]=S.[EGN_CT],[ExceptionMessage]=S.[ExceptionMessage],[NationalId_CT]=S.[NationalId_CT],[Reports]=S.[Reports],[UniqueId]=S.[UniqueId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[XMLResponse_Content]=S.[XMLResponse_Content],[XMLResponse_Source]=S.[XMLResponse_Source],[XMLResponse_Type]=S.[XMLResponse_Type]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EGN_CT],[ExceptionMessage],[NationalId_CT],[Reports],[UniqueId],[XMLResponse_Content],[XMLResponse_Source],[XMLResponse_Type])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[EGN_CT],S.[ExceptionMessage],S.[NationalId_CT],S.[Reports],S.[UniqueId],S.[XMLResponse_Content],S.[XMLResponse_Source],S.[XMLResponse_Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

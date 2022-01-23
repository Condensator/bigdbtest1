SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveQuoteRequest]
(
 @val [dbo].[QuoteRequest] READONLY
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
MERGE [dbo].[QuoteRequests] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BusinessUnitId]=S.[BusinessUnitId],[Description]=S.[Description],[IsActive]=S.[IsActive],[LastRequestedDate]=S.[LastRequestedDate],[LegalEntityId]=S.[LegalEntityId],[Number]=S.[Number],[ProgramId]=S.[ProgramId],[ProgramVendorId]=S.[ProgramVendorId],[QuoteDate]=S.[QuoteDate],[ReasonofDeclineId]=S.[ReasonofDeclineId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BusinessUnitId],[CreatedById],[CreatedTime],[Description],[IsActive],[LastRequestedDate],[LegalEntityId],[Number],[ProgramId],[ProgramVendorId],[QuoteDate],[ReasonofDeclineId],[Status])
    VALUES (S.[BusinessUnitId],S.[CreatedById],S.[CreatedTime],S.[Description],S.[IsActive],S.[LastRequestedDate],S.[LegalEntityId],S.[Number],S.[ProgramId],S.[ProgramVendorId],S.[QuoteDate],S.[ReasonofDeclineId],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

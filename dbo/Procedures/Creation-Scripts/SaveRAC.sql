SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRAC]
(
 @val [dbo].[RAC] READONLY
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
MERGE [dbo].[RACs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApplicationType]=S.[ApplicationType],[BusinessUnitId]=S.[BusinessUnitId],[Corporate]=S.[Corporate],[IsAllVendors]=S.[IsAllVendors],[Name]=S.[Name],[Number]=S.[Number],[OriginalRACId]=S.[OriginalRACId],[ProgramId]=S.[ProgramId],[RACProgramId]=S.[RACProgramId],[Replacement]=S.[Replacement],[Status]=S.[Status],[UnderwriterInstructions]=S.[UnderwriterInstructions],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ApplicationType],[BusinessUnitId],[Corporate],[CreatedById],[CreatedTime],[IsAllVendors],[Name],[Number],[OriginalRACId],[ProgramId],[RACProgramId],[Replacement],[Status],[UnderwriterInstructions])
    VALUES (S.[ApplicationType],S.[BusinessUnitId],S.[Corporate],S.[CreatedById],S.[CreatedTime],S.[IsAllVendors],S.[Name],S.[Number],S.[OriginalRACId],S.[ProgramId],S.[RACProgramId],S.[Replacement],S.[Status],S.[UnderwriterInstructions])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

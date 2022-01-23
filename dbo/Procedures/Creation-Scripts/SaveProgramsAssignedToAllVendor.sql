SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveProgramsAssignedToAllVendor]
(
 @val [dbo].[ProgramsAssignedToAllVendor] READONLY
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
MERGE [dbo].[ProgramsAssignedToAllVendors] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssignmentDate]=S.[AssignmentDate],[ExternalVendorCode]=S.[ExternalVendorCode],[IsAssigned]=S.[IsAssigned],[IsDefault]=S.[IsDefault],[LineofBusinessId]=S.[LineofBusinessId],[ProgramId]=S.[ProgramId],[ProgramVendorId]=S.[ProgramVendorId],[UnassignmentDate]=S.[UnassignmentDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssignmentDate],[CreatedById],[CreatedTime],[ExternalVendorCode],[IsAssigned],[IsDefault],[LineofBusinessId],[ProgramId],[ProgramVendorId],[UnassignmentDate],[VendorId])
    VALUES (S.[AssignmentDate],S.[CreatedById],S.[CreatedTime],S.[ExternalVendorCode],S.[IsAssigned],S.[IsDefault],S.[LineofBusinessId],S.[ProgramId],S.[ProgramVendorId],S.[UnassignmentDate],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

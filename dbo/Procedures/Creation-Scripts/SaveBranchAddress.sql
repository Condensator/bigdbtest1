SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBranchAddress]
(
 @val [dbo].[BranchAddress] READONLY
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
MERGE [dbo].[BranchAddresses] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[AddressLine3]=S.[AddressLine3],[City]=S.[City],[Description]=S.[Description],[Division]=S.[Division],[IsActive]=S.[IsActive],[IsHeadquarter]=S.[IsHeadquarter],[IsMain]=S.[IsMain],[Neighborhood]=S.[Neighborhood],[PostalCode]=S.[PostalCode],[StateId]=S.[StateId],[SubdivisionOrMunicipality]=S.[SubdivisionOrMunicipality],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AddressLine1],[AddressLine2],[AddressLine3],[BranchId],[City],[CreatedById],[CreatedTime],[Description],[Division],[IsActive],[IsHeadquarter],[IsMain],[Neighborhood],[PostalCode],[StateId],[SubdivisionOrMunicipality])
    VALUES (S.[AddressLine1],S.[AddressLine2],S.[AddressLine3],S.[BranchId],S.[City],S.[CreatedById],S.[CreatedTime],S.[Description],S.[Division],S.[IsActive],S.[IsHeadquarter],S.[IsMain],S.[Neighborhood],S.[PostalCode],S.[StateId],S.[SubdivisionOrMunicipality])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

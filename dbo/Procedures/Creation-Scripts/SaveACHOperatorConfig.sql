SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHOperatorConfig]
(
 @val [dbo].[ACHOperatorConfig] READONLY
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
MERGE [dbo].[ACHOperatorConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHOperatorname]=S.[ACHOperatorname],[Currencyname]=S.[Currencyname],[Destination]=S.[Destination],[DestName]=S.[DestName],[FileFormat]=S.[FileFormat],[IsActive]=S.[IsActive],[LastFileCreationNumber]=S.[LastFileCreationNumber],[OrigDFIID]=S.[OrigDFIID],[Origin]=S.[Origin],[OriginName]=S.[OriginName],[SEC]=S.[SEC],[TaxID]=S.[TaxID],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHOperatorname],[CreatedById],[CreatedTime],[Currencyname],[Destination],[DestName],[FileFormat],[IsActive],[LastFileCreationNumber],[OrigDFIID],[Origin],[OriginName],[SEC],[TaxID])
    VALUES (S.[ACHOperatorname],S.[CreatedById],S.[CreatedTime],S.[Currencyname],S.[Destination],S.[DestName],S.[FileFormat],S.[IsActive],S.[LastFileCreationNumber],S.[OrigDFIID],S.[Origin],S.[OriginName],S.[SEC],S.[TaxID])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

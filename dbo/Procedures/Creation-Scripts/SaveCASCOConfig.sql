SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCASCOConfig]
(
 @val [dbo].[CASCOConfig] READONLY
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
MERGE [dbo].[CASCOConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ExternalDealer]=S.[ExternalDealer],[InsuranceCompanyId]=S.[InsuranceCompanyId],[InternalDealer]=S.[InternalDealer],[IsActive]=S.[IsActive],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VehicleAgeFrom]=S.[VehicleAgeFrom],[VehicleAgeTo]=S.[VehicleAgeTo]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[ExternalDealer],[InsuranceCompanyId],[InternalDealer],[IsActive],[VehicleAgeFrom],[VehicleAgeTo])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[ExternalDealer],S.[InsuranceCompanyId],S.[InternalDealer],S.[IsActive],S.[VehicleAgeFrom],S.[VehicleAgeTo])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

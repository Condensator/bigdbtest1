SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRegistrationHistory]
(
 @val [dbo].[RegistrationHistory] READONLY
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
MERGE [dbo].[RegistrationHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DateOfRegistration]=S.[DateOfRegistration],[DeliveredOn]=S.[DeliveredOn],[EffectiveFromDate]=S.[EffectiveFromDate],[EffectiveTillDate]=S.[EffectiveTillDate],[EngineNumber]=S.[EngineNumber],[IsActive]=S.[IsActive],[PlateNumber]=S.[PlateNumber],[PreviousLeaseAgreement]=S.[PreviousLeaseAgreement],[RegistrationCertificateNumber]=S.[RegistrationCertificateNumber],[RowNumber]=S.[RowNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CreatedById],[CreatedTime],[DateOfRegistration],[DeliveredOn],[EffectiveFromDate],[EffectiveTillDate],[EngineNumber],[IsActive],[PlateNumber],[PreviousLeaseAgreement],[RegistrationCertificateNumber],[RowNumber])
    VALUES (S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[DateOfRegistration],S.[DeliveredOn],S.[EffectiveFromDate],S.[EffectiveTillDate],S.[EngineNumber],S.[IsActive],S.[PlateNumber],S.[PreviousLeaseAgreement],S.[RegistrationCertificateNumber],S.[RowNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

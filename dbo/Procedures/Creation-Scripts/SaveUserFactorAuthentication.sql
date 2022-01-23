SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveUserFactorAuthentication]
(
 @val [dbo].[UserFactorAuthentication] READONLY
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
MERGE [dbo].[UserFactorAuthentications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DeviceVerified]=S.[DeviceVerified],[EffectiveDate]=S.[EffectiveDate],[Email]=S.[Email],[EmailVerified]=S.[EmailVerified],[ExpiryDate]=S.[ExpiryDate],[FactorProvider]=S.[FactorProvider],[FailureCounter]=S.[FailureCounter],[IsUserRegistrationRequired]=S.[IsUserRegistrationRequired],[LoginName]=S.[LoginName],[PhoneNumber]=S.[PhoneNumber],[PhoneVerified]=S.[PhoneVerified],[SecretKey]=S.[SecretKey],[SecurityStamp]=S.[SecurityStamp],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DeviceVerified],[EffectiveDate],[Email],[EmailVerified],[ExpiryDate],[FactorProvider],[FailureCounter],[IsUserRegistrationRequired],[LoginName],[PhoneNumber],[PhoneVerified],[SecretKey],[SecurityStamp])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DeviceVerified],S.[EffectiveDate],S.[Email],S.[EmailVerified],S.[ExpiryDate],S.[FactorProvider],S.[FailureCounter],S.[IsUserRegistrationRequired],S.[LoginName],S.[PhoneNumber],S.[PhoneVerified],S.[SecretKey],S.[SecurityStamp])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

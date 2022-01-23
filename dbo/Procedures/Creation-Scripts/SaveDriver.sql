SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDriver]
(
 @val [dbo].[Driver] READONLY
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
MERGE [dbo].[Drivers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[Active]=S.[Active],[AnnualInsuranceCost]=S.[AnnualInsuranceCost],[ClassCode]=S.[ClassCode],[CreationDate]=S.[CreationDate],[CustomerId]=S.[CustomerId],[DeactivationDate]=S.[DeactivationDate],[DriverCode]=S.[DriverCode],[DriverType]=S.[DriverType],[EmployeeID]=S.[EmployeeID],[ExternalDriverId]=S.[ExternalDriverId],[LicenseExpiryDate]=S.[LicenseExpiryDate],[LicenseIssueDate]=S.[LicenseIssueDate],[LicenseNumber]=S.[LicenseNumber],[LicenseStateId]=S.[LicenseStateId],[MVRLastReviewedDate]=S.[MVRLastReviewedDate],[MVRLastRunDate]=S.[MVRLastRunDate],[MVRRequired]=S.[MVRRequired],[MVRReviewedBy]=S.[MVRReviewedBy],[MVRStatus]=S.[MVRStatus],[PIN]=S.[PIN],[PortfolioId]=S.[PortfolioId],[Reason]=S.[Reason],[RelatedDriverId]=S.[RelatedDriverId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[Active],[AnnualInsuranceCost],[ClassCode],[CreatedById],[CreatedTime],[CreationDate],[CustomerId],[DeactivationDate],[DriverCode],[DriverType],[EmployeeID],[ExternalDriverId],[LicenseExpiryDate],[LicenseIssueDate],[LicenseNumber],[LicenseStateId],[MVRLastReviewedDate],[MVRLastRunDate],[MVRRequired],[MVRReviewedBy],[MVRStatus],[PIN],[PortfolioId],[Reason],[RelatedDriverId])
    VALUES (S.[ActivationDate],S.[Active],S.[AnnualInsuranceCost],S.[ClassCode],S.[CreatedById],S.[CreatedTime],S.[CreationDate],S.[CustomerId],S.[DeactivationDate],S.[DriverCode],S.[DriverType],S.[EmployeeID],S.[ExternalDriverId],S.[LicenseExpiryDate],S.[LicenseIssueDate],S.[LicenseNumber],S.[LicenseStateId],S.[MVRLastReviewedDate],S.[MVRLastRunDate],S.[MVRRequired],S.[MVRReviewedBy],S.[MVRStatus],S.[PIN],S.[PortfolioId],S.[Reason],S.[RelatedDriverId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

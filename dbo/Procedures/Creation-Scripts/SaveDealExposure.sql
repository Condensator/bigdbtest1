SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDealExposure]
(
 @val [dbo].[DealExposure] READONLY
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
MERGE [dbo].[DealExposures] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CommencedDealExposure_Amount]=S.[CommencedDealExposure_Amount],[CommencedDealExposure_Currency]=S.[CommencedDealExposure_Currency],[CommencedDealRNI_Amount]=S.[CommencedDealRNI_Amount],[CommencedDealRNI_Currency]=S.[CommencedDealRNI_Currency],[CustomerId]=S.[CustomerId],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[ExposureCustomerId]=S.[ExposureCustomerId],[ExposureDate]=S.[ExposureDate],[ExposureType]=S.[ExposureType],[IsActive]=S.[IsActive],[LOCBalanceExposure_Amount]=S.[LOCBalanceExposure_Amount],[LOCBalanceExposure_Currency]=S.[LOCBalanceExposure_Currency],[LOCBalanceNonRevolving_Amount]=S.[LOCBalanceNonRevolving_Amount],[LOCBalanceNonRevolving_Currency]=S.[LOCBalanceNonRevolving_Currency],[LOCBalanceRevolving_Amount]=S.[LOCBalanceRevolving_Amount],[LOCBalanceRevolving_Currency]=S.[LOCBalanceRevolving_Currency],[OriginatingVendorId]=S.[OriginatingVendorId],[OTPLeaseExposure_Amount]=S.[OTPLeaseExposure_Amount],[OTPLeaseExposure_Currency]=S.[OTPLeaseExposure_Currency],[OTPLeaseRNI_Amount]=S.[OTPLeaseRNI_Amount],[OTPLeaseRNI_Currency]=S.[OTPLeaseRNI_Currency],[RelationshipPercentage]=S.[RelationshipPercentage],[RNIId]=S.[RNIId],[TotalExposure_Amount]=S.[TotalExposure_Amount],[TotalExposure_Currency]=S.[TotalExposure_Currency],[UncommencedDealExposure_Amount]=S.[UncommencedDealExposure_Amount],[UncommencedDealExposure_Currency]=S.[UncommencedDealExposure_Currency],[UncommencedDealRNI_Amount]=S.[UncommencedDealRNI_Amount],[UncommencedDealRNI_Currency]=S.[UncommencedDealRNI_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CommencedDealExposure_Amount],[CommencedDealExposure_Currency],[CommencedDealRNI_Amount],[CommencedDealRNI_Currency],[CreatedById],[CreatedTime],[CustomerId],[EntityId],[EntityType],[ExposureCustomerId],[ExposureDate],[ExposureType],[IsActive],[LOCBalanceExposure_Amount],[LOCBalanceExposure_Currency],[LOCBalanceNonRevolving_Amount],[LOCBalanceNonRevolving_Currency],[LOCBalanceRevolving_Amount],[LOCBalanceRevolving_Currency],[OriginatingVendorId],[OTPLeaseExposure_Amount],[OTPLeaseExposure_Currency],[OTPLeaseRNI_Amount],[OTPLeaseRNI_Currency],[RelationshipPercentage],[RNIId],[TotalExposure_Amount],[TotalExposure_Currency],[UncommencedDealExposure_Amount],[UncommencedDealExposure_Currency],[UncommencedDealRNI_Amount],[UncommencedDealRNI_Currency])
    VALUES (S.[CommencedDealExposure_Amount],S.[CommencedDealExposure_Currency],S.[CommencedDealRNI_Amount],S.[CommencedDealRNI_Currency],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[EntityId],S.[EntityType],S.[ExposureCustomerId],S.[ExposureDate],S.[ExposureType],S.[IsActive],S.[LOCBalanceExposure_Amount],S.[LOCBalanceExposure_Currency],S.[LOCBalanceNonRevolving_Amount],S.[LOCBalanceNonRevolving_Currency],S.[LOCBalanceRevolving_Amount],S.[LOCBalanceRevolving_Currency],S.[OriginatingVendorId],S.[OTPLeaseExposure_Amount],S.[OTPLeaseExposure_Currency],S.[OTPLeaseRNI_Amount],S.[OTPLeaseRNI_Currency],S.[RelationshipPercentage],S.[RNIId],S.[TotalExposure_Amount],S.[TotalExposure_Currency],S.[UncommencedDealExposure_Amount],S.[UncommencedDealExposure_Currency],S.[UncommencedDealRNI_Amount],S.[UncommencedDealRNI_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

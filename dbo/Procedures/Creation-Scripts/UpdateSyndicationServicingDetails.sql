SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateSyndicationServicingDetails]
(
@IsLease BIT
,@FinanceId BIGINT
,@SyndicationServicingDetail SyndicationServicingDetail READONLY
,@CreatedById INT
,@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
IF @IsLease = 1
BEGIN
UPDATE LeaseSyndicationServicingDetails SET IsActive=0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime WHERE LeaseSyndicationId=@FinanceId AND IsActive=1
INSERT INTO LeaseSyndicationServicingDetails
(
EffectiveDate
,IsServiced
,IsCobrand
,IsPerfectPay
,IsCollected
,IsPrivateLabel
,PropertyTaxResponsibility
,IsActive
,CreatedById
,CreatedTime
,RemitToId
,LeaseSyndicationId
)
SELECT
LSSD.EffectiveDate
,LSSD.IsServiced
,LSSD.IsCobrand
,LSSD.IsPerfectPay
,LSSD.IsCollected
,LSSD.IsPrivateLabel
,LSSD.PropertyTaxResponsibility
,1
,@CreatedById
,@CreatedTime
,LSSD.RemitToId
,LSSD.SyndicationId
FROM @SyndicationServicingDetail LSSD
END
ELSE
BEGIN
UPDATE LoanSyndicationServicingDetails SET IsActive=0,UpdatedById = @CreatedById, UpdatedTime = @CreatedTime WHERE LoanSyndicationId=@FinanceId AND IsActive=1
INSERT INTO LoanSyndicationServicingDetails
(
EffectiveDate
,IsServiced
,IsCobrand
,IsPerfectPay
,IsCollected
,IsPrivateLabel
,PropertyTaxResponsibility
,IsActive
,CreatedById
,CreatedTime
,RemitToId
,LoanSyndicationId
)
SELECT
LSSD.EffectiveDate
,LSSD.IsServiced
,LSSD.IsCobrand
,LSSD.IsPerfectPay
,LSSD.IsCollected
,LSSD.IsPrivateLabel
,LSSD.PropertyTaxResponsibility
,1
,@CreatedById
,@CreatedTime
,LSSD.RemitToId
,LSSD.SyndicationId
FROM @SyndicationServicingDetail LSSD
END
END

GO

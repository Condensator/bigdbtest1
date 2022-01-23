CREATE TYPE [dbo].[TaxSourceDetailInfo] AS TABLE(
	[LeasePaymentScheduleId] [bigint] NULL,
	[TaxSourceDetailId] [bigint] NULL,
	[DealCountryId] [bigint] NULL,
	[TaxSourceType] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL
)
GO

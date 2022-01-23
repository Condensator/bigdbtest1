CREATE TYPE [dbo].[SyndicationServicingDetail] AS TABLE(
	[EffectiveDate] [date] NULL,
	[IsServiced] [bit] NULL,
	[IsCobrand] [bit] NULL,
	[IsPerfectPay] [bit] NULL,
	[IsCollected] [bit] NULL,
	[IsPrivateLabel] [bit] NULL,
	[PropertyTaxResponsibility] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[RemitToId] [bigint] NULL,
	[SyndicationId] [bigint] NULL
)
GO

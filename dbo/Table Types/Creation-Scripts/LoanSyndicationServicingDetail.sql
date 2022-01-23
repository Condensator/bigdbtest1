CREATE TYPE [dbo].[LoanSyndicationServicingDetail] AS TABLE(
	[EffectiveDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsServiced] [bit] NOT NULL,
	[IsCobrand] [bit] NOT NULL,
	[IsPerfectPay] [bit] NOT NULL,
	[IsCollected] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[PropertyTaxResponsibility] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[RemitToId] [bigint] NULL,
	[LoanSyndicationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO

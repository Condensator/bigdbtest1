CREATE TYPE [dbo].[PayoffPricingOption] AS TABLE(
	[PayoffAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayoffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[TerminationOption] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DefaultpayoffTemplate] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsSelected] [bit] NOT NULL,
	[PayoffId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO

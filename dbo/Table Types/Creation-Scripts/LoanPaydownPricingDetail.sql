CREATE TYPE [dbo].[LoanPaydownPricingDetail] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaydownAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaydownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaydownTemplate] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LoanPaydownId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO

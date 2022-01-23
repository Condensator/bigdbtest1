CREATE TYPE [dbo].[InsuranceAgency] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[PhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[FaxNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ActivationDate] [date] NULL,
	[InactivationDate] [date] NULL,
	[InactivationReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO

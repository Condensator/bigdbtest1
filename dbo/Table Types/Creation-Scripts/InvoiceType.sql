CREATE TYPE [dbo].[InvoiceType] AS TABLE(
	[Name] [nvarchar](27) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InvoiceNumberPrefix] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceNumberPadding] [int] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO

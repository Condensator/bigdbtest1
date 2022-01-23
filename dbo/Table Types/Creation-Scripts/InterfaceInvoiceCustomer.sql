CREATE TYPE [dbo].[InterfaceInvoiceCustomer] AS TABLE(
	[CustomerNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MaxInvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsWilliamsCustomer] [bit] NOT NULL,
	[DueDate] [date] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO

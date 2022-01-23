CREATE TYPE [dbo].[OneTimeACHSchedule] AS TABLE(
	[ACHAmount_Amount] [decimal](16, 2) NOT NULL,
	[ACHAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[IsSeparateReceipt] [bit] NOT NULL,
	[ReceivableId] [bigint] NULL,
	[ReceivableInvoiceId] [bigint] NULL,
	[OneTimeACHId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO

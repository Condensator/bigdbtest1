CREATE TYPE [dbo].[ReceiptBatch] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PostDate] [date] NULL,
	[ReceivedDate] [date] NOT NULL,
	[DepositAmount_Amount] [decimal](16, 2) NOT NULL,
	[DepositAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsPartiallyPosted] [bit] NOT NULL,
	[ReceiptAmountAlreadyPosted_Amount] [decimal](16, 2) NOT NULL,
	[ReceiptAmountAlreadyPosted_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[ReceiptBatchGLTemplateId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO

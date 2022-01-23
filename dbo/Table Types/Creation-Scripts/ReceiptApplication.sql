CREATE TYPE [dbo].[ReceiptApplication] AS TABLE(
	[PostDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AmountApplied_Amount] [decimal](16, 2) NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsFullCash] [bit] NOT NULL,
	[CreditApplied_Amount] [decimal](16, 2) NOT NULL,
	[CreditApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableDisplayOption] [nvarchar](24) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApplyByReceivable] [bit] NOT NULL,
	[ReceiptId] [bigint] NOT NULL,
	[ReceiptHierarchyTemplateId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO

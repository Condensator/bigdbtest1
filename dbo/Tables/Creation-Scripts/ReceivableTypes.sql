SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsRental] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[MemoAllowed] [bit] NOT NULL,
	[CashBasedAllowed] [bit] NOT NULL,
	[LeaseBased] [bit] NOT NULL,
	[LoanBased] [bit] NOT NULL,
	[InvoicePreferenceAllowed] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLTransactionTypeId] [bigint] NOT NULL,
	[SyndicationGLTransactionTypeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[EARApplicable] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableTypes]  WITH CHECK ADD  CONSTRAINT [EReceivableType_GLTransactionType] FOREIGN KEY([GLTransactionTypeId])
REFERENCES [dbo].[GLTransactionTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypes] CHECK CONSTRAINT [EReceivableType_GLTransactionType]
GO
ALTER TABLE [dbo].[ReceivableTypes]  WITH CHECK ADD  CONSTRAINT [EReceivableType_SyndicationGLTransactionType] FOREIGN KEY([SyndicationGLTransactionTypeId])
REFERENCES [dbo].[GLTransactionTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypes] CHECK CONSTRAINT [EReceivableType_SyndicationGLTransactionType]
GO

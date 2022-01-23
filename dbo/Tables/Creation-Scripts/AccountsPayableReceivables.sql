SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccountsPayableReceivables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountToApply_Amount] [decimal](16, 2) NOT NULL,
	[AmountToApply_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableId] [bigint] NOT NULL,
	[AccountsPayableId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AccountsPayableReceivables]  WITH CHECK ADD  CONSTRAINT [EAccountsPayable_AccountsPayableReceivables] FOREIGN KEY([AccountsPayableId])
REFERENCES [dbo].[AccountsPayables] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AccountsPayableReceivables] CHECK CONSTRAINT [EAccountsPayable_AccountsPayableReceivables]
GO
ALTER TABLE [dbo].[AccountsPayableReceivables]  WITH CHECK ADD  CONSTRAINT [EAccountsPayableReceivable_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[AccountsPayableReceivables] CHECK CONSTRAINT [EAccountsPayableReceivable_Receivable]
GO

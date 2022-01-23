SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RemitToWireDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsBeneficiary] [bit] NOT NULL,
	[IsCorrespondent] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ACHOriginatorID] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BankAccountId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RemitToWireDetails]  WITH CHECK ADD  CONSTRAINT [ERemitTo_RemitToWireDetails] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RemitToWireDetails] CHECK CONSTRAINT [ERemitTo_RemitToWireDetails]
GO
ALTER TABLE [dbo].[RemitToWireDetails]  WITH CHECK ADD  CONSTRAINT [ERemitToWireDetail_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[RemitToWireDetails] CHECK CONSTRAINT [ERemitToWireDetail_BankAccount]
GO

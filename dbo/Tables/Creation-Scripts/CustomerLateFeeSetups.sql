SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerLateFeeSetups](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssessLateFee] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerLateFeeSetups]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerLateFeeSetups] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CustomerLateFeeSetups] CHECK CONSTRAINT [ECustomer_CustomerLateFeeSetups]
GO
ALTER TABLE [dbo].[CustomerLateFeeSetups]  WITH CHECK ADD  CONSTRAINT [ECustomerLateFeeSetup_ReceivableType] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[CustomerLateFeeSetups] CHECK CONSTRAINT [ECustomerLateFeeSetup_ReceivableType]
GO

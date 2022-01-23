SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerPayoffTemplateAssignments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[AvailableInCustomerPortal] [bit] NOT NULL,
	[PayOffTemplateId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerPayoffTemplateAssignments]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerPayoffTemplateAssignments] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CustomerPayoffTemplateAssignments] CHECK CONSTRAINT [ECustomer_CustomerPayoffTemplateAssignments]
GO
ALTER TABLE [dbo].[CustomerPayoffTemplateAssignments]  WITH CHECK ADD  CONSTRAINT [ECustomerPayoffTemplateAssignment_PayOffTemplate] FOREIGN KEY([PayOffTemplateId])
REFERENCES [dbo].[PayOffTemplates] ([Id])
GO
ALTER TABLE [dbo].[CustomerPayoffTemplateAssignments] CHECK CONSTRAINT [ECustomerPayoffTemplateAssignment_PayOffTemplate]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RMAExpenses](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ExpenseNumber] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[SundryId] [bigint] NOT NULL,
	[RMAProfileId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RMAExpenses]  WITH CHECK ADD  CONSTRAINT [ERMAExpense_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[RMAExpenses] CHECK CONSTRAINT [ERMAExpense_Sundry]
GO
ALTER TABLE [dbo].[RMAExpenses]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_RMAExpenses] FOREIGN KEY([RMAProfileId])
REFERENCES [dbo].[RMAProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RMAExpenses] CHECK CONSTRAINT [ERMAProfile_RMAExpenses]
GO

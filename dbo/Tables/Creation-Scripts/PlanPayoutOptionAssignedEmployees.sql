SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PlanPayoutOptionAssignedEmployees](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveStartDate] [date] NOT NULL,
	[EffectiveEndDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SalesOfficerId] [bigint] NOT NULL,
	[PlanBasesPayoutId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PlanPayoutOptionAssignedEmployees]  WITH CHECK ADD  CONSTRAINT [EPlanBasesPayout_PlanPayoutOptionAssignedEmployees] FOREIGN KEY([PlanBasesPayoutId])
REFERENCES [dbo].[PlanBasesPayouts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PlanPayoutOptionAssignedEmployees] CHECK CONSTRAINT [EPlanBasesPayout_PlanPayoutOptionAssignedEmployees]
GO
ALTER TABLE [dbo].[PlanPayoutOptionAssignedEmployees]  WITH CHECK ADD  CONSTRAINT [EPlanPayoutOptionAssignedEmployee_SalesOfficer] FOREIGN KEY([SalesOfficerId])
REFERENCES [dbo].[SalesOfficers] ([Id])
GO
ALTER TABLE [dbo].[PlanPayoutOptionAssignedEmployees] CHECK CONSTRAINT [EPlanPayoutOptionAssignedEmployee_SalesOfficer]
GO

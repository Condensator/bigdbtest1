SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeEnMasseUpdates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EmployeeId] [bigint] NULL,
	[RoleFunctionId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsReplace] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmployeeEnMasseUpdates]  WITH CHECK ADD  CONSTRAINT [EEmployeeEnMasseUpdate_Employee] FOREIGN KEY([EmployeeId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[EmployeeEnMasseUpdates] CHECK CONSTRAINT [EEmployeeEnMasseUpdate_Employee]
GO
ALTER TABLE [dbo].[EmployeeEnMasseUpdates]  WITH CHECK ADD  CONSTRAINT [EEmployeeEnMasseUpdate_RoleFunction] FOREIGN KEY([RoleFunctionId])
REFERENCES [dbo].[RoleFunctions] ([Id])
GO
ALTER TABLE [dbo].[EmployeeEnMasseUpdates] CHECK CONSTRAINT [EEmployeeEnMasseUpdate_RoleFunction]
GO

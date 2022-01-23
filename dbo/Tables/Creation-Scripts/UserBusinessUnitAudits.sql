SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserBusinessUnitAudits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[UserLoginAuditId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UserBusinessUnitAudits]  WITH CHECK ADD  CONSTRAINT [EUserBusinessUnitAudit_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[UserBusinessUnitAudits] CHECK CONSTRAINT [EUserBusinessUnitAudit_BusinessUnit]
GO
ALTER TABLE [dbo].[UserBusinessUnitAudits]  WITH CHECK ADD  CONSTRAINT [EUserLoginAudit_UserBusinessUnitAudits] FOREIGN KEY([UserLoginAuditId])
REFERENCES [dbo].[UserLoginAudits] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserBusinessUnitAudits] CHECK CONSTRAINT [EUserLoginAudit_UserBusinessUnitAudits]
GO
